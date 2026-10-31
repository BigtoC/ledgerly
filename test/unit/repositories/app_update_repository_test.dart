import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/app_update.dart';
import 'package:ledgerly/data/repositories/app_update_repository.dart';
import 'package:ledgerly/data/services/apk_installer_service.dart';
import 'package:ledgerly/data/services/app_release_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAppReleaseService extends Mock implements AppReleaseService {}

class MockApkInstallerService extends Mock implements ApkInstallerService {}

const _arm64Url = 'https://example.com/ledgerly-v0.7.2-arm64-v8a.apk';
const _armUrl = 'https://example.com/ledgerly-v0.7.2-armeabi-v7a.apk';
const _x64Url = 'https://example.com/ledgerly-v0.7.2-x86_64.apk';
final _hex = 'ab' * 32;
final _digest = 'sha256:$_hex';

final _bytes = utf8.encode('fake apk bytes');
final _goodHex = sha256.convert(_bytes).toString();

AppUpdate _upd({String? hex}) => AppUpdate(
  version: 'v0.7.2',
  fileName: 'ledgerly-v0.7.2-arm64-v8a.apk',
  apkUrl: Uri.parse(_arm64Url),
  sha256: hex ?? _goodHex,
  sizeBytes: _bytes.length,
);

Matcher _hasApkUrl(String url) =>
    isA<AppUpdate>().having((u) => u.apkUrl, 'apkUrl', Uri.parse(url));

typedef _Release = ({String tagName, List<ReleaseAsset> assets});

_Release _release({String tag = 'v0.7.2', List<ReleaseAsset>? assets}) => (
  tagName: tag,
  assets:
      assets ??
      const [
        (
          name: 'ledgerly-v0.7.2-arm64-v8a.apk',
          url: _arm64Url,
          digest: null,
          size: null,
        ),
        (
          name: 'ledgerly-v0.7.2-armeabi-v7a.apk',
          url: _armUrl,
          digest: null,
          size: null,
        ),
        (
          name: 'ledgerly-v0.7.2-x86_64.apk',
          url: _x64Url,
          digest: null,
          size: null,
        ),
        (
          name: 'ledgerly-v0.7.2-checksums.txt',
          url: 'https://example.com/ledgerly-v0.7.2-checksums.txt',
          digest: null,
          size: null,
        ),
      ],
);

void main() {
  late MockAppReleaseService service;
  late MockApkInstallerService installer;
  late Directory dir;
  late int versionCalls;

  setUpAll(() => registerFallbackValue(Uri()));

  setUp(() {
    service = MockAppReleaseService();
    installer = MockApkInstallerService();
    dir = Directory.systemTemp.createTempSync('upd');
    addTearDown(() => dir.deleteSync(recursive: true));
    versionCalls = 0;
  });

  AppUpdateRepository repo({
    Abi abi = Abi.androidArm64,
    String installed = '0.7.1',
  }) => AppUpdateRepository(
    service,
    installer: installer,
    updatesDir: () async => dir,
    installedVersion: () async {
      versionCalls++;
      return installed;
    },
    abi: abi,
  );

  void stubRelease(_Release? release) {
    when(() => service.fetchLatestRelease()).thenAnswer((_) async => release);
  }

  void stubDownloadWrites(List<int> bytes) {
    when(
      () =>
          service.download(any(), any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((inv) async {
      final cb = inv.namedArguments[#onProgress] as void Function(int, int)?;
      cb?.call(bytes.length, bytes.length);
      File(inv.positionalArguments[1] as String).writeAsBytesSync(bytes);
    });
  }

  group('AppUpdateRepository.findUpdate', () {
    test('androidArm returns armeabi-v7a, not arm64-v8a', () async {
      stubRelease(_release());
      expect(await repo(abi: Abi.androidArm).findUpdate(), _hasApkUrl(_armUrl));
    });

    test('androidX64 returns the x86_64 URL', () async {
      stubRelease(_release());
      expect(await repo(abi: Abi.androidX64).findUpdate(), _hasApkUrl(_x64Url));
    });

    test('carries tag, file name, sha256 and size', () async {
      stubRelease(
        _release(
          assets: [
            (
              name: 'ledgerly-v0.7.2-arm64-v8a.apk',
              url: _arm64Url,
              digest: _digest,
              size: 1234,
            ),
          ],
        ),
      );
      expect(
        await repo().findUpdate(),
        AppUpdate(
          version: 'v0.7.2',
          fileName: 'ledgerly-v0.7.2-arm64-v8a.apk',
          apkUrl: Uri.parse(_arm64Url),
          sha256: _hex,
          sizeBytes: 1234,
        ),
      );
    });

    for (final (label, digest, size) in [
      ('missing digest', null, 1234),
      ('non-sha256 digest', 'md5:abcd', 1234),
      ('short hex', 'sha256:abcd', 1234),
      ('missing size', _digest, null),
    ]) {
      test('$label: sha256 and size are null (browser only)', () async {
        stubRelease(
          _release(
            assets: [
              (
                name: 'ledgerly-v0.7.2-arm64-v8a.apk',
                url: _arm64Url,
                digest: digest,
                size: size,
              ),
            ],
          ),
        );
        final update = await repo().findUpdate();
        expect(update!.sha256, isNull);
        expect(update.sizeBytes, isNull);
      });
    }

    test('uppercase hex digest is normalised to lowercase', () async {
      stubRelease(
        _release(
          assets: [
            (
              name: 'ledgerly-v0.7.2-arm64-v8a.apk',
              url: _arm64Url,
              digest: 'sha256:${'AB' * 32}',
              size: 1,
            ),
          ],
        ),
      );
      expect((await repo().findUpdate())!.sha256, _hex);
    });

    test('same version gives null', () async {
      stubRelease(_release(tag: 'v0.7.1'));
      expect(await repo().findUpdate(), isNull);
    });

    test('older version gives null', () async {
      stubRelease(_release(tag: 'v0.7.0'));
      expect(await repo().findUpdate(), isNull);
    });

    test('no matching asset gives null', () async {
      stubRelease(
        _release(
          assets: const [
            (
              name: 'ledgerly-v0.7.2-x86_64.apk',
              url: _x64Url,
              digest: null,
              size: null,
            ),
          ],
        ),
      );
      expect(await repo().findUpdate(), isNull);
    });

    test('an APK for this ABI from another version gives null', () async {
      stubRelease(
        _release(
          assets: const [
            (
              name: 'ledgerly-v0.7.1-arm64-v8a.apk',
              url: 'https://example.com/ledgerly-v0.7.1-arm64-v8a.apk',
              digest: null,
              size: null,
            ),
          ],
        ),
      );
      expect(await repo().findUpdate(), isNull);
    });

    test('an http: URL gives null', () async {
      stubRelease(
        _release(
          assets: const [
            (
              name: 'ledgerly-v0.7.2-arm64-v8a.apk',
              url: 'http://example.com/ledgerly-v0.7.2-arm64-v8a.apk',
              digest: null,
              size: null,
            ),
          ],
        ),
      );
      expect(await repo().findUpdate(), isNull);
    });

    test('DioException gives null', () async {
      when(() => service.fetchLatestRelease())
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));
      expect(await repo().findUpdate(), isNull);
    });

    test('an Error while checking gives null', () async {
      stubRelease(_release());
      final failing = AppUpdateRepository(
        service,
        installer: installer,
        updatesDir: () async => dir,
        installedVersion: () async => throw StateError('no package info'),
        abi: Abi.androidArm64,
      );
      expect(await failing.findUpdate(), isNull);
    });

    test('service returning null gives null', () async {
      stubRelease(null);
      expect(await repo().findUpdate(), isNull);
    });

    test(
      'non-Android ABI gives null without network or version lookup',
      () async {
        stubRelease(_release());

        expect(await repo(abi: Abi.macosArm64).findUpdate(), isNull);

        verifyNever(() => service.fetchLatestRelease());
        expect(versionCalls, 0);
      },
    );
  });

  group('AppUpdateRepository.download', () {
    test(
      'verified download is renamed from .part and its path returned',
      () async {
        stubDownloadWrites(_bytes);
        final progress = <double>[];
        final path = await repo().download(_upd(), onProgress: progress.add);
        expect(path, '${dir.path}/ledgerly-v0.7.2-arm64-v8a.apk');
        expect(File(path).readAsBytesSync(), _bytes);
        expect(File('$path.part').existsSync(), isFalse);
        expect(progress, [1.0]);
      },
    );

    test('hash mismatch deletes the file and throws', () async {
      stubDownloadWrites(utf8.encode('tampered'));
      await expectLater(
        repo().download(_upd()),
        throwsA(isA<UpdateChecksumException>()),
      );
      expect(dir.listSync(), isEmpty);
    });

    test('an already verified file is reused without downloading', () async {
      File('${dir.path}/ledgerly-v0.7.2-arm64-v8a.apk')
          .writeAsBytesSync(_bytes);
      await repo().download(_upd());
      verifyNever(
        () => service.download(
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('network failure throws UpdateDownloadException', () async {
      when(
        () => service.download(
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenThrow(DioException(requestOptions: RequestOptions()));
      await expectLater(
        repo().download(_upd()),
        throwsA(isA<UpdateDownloadException>()),
      );
    });

    test('file-system failure throws UpdateStorageException', () async {
      when(
        () => service.download(
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenThrow(const FileSystemException('No space left on device'));
      await expectLater(
        repo().download(_upd()),
        throwsA(isA<UpdateStorageException>()),
      );
    });

    test(
      'write failure wrapped by dio throws UpdateStorageException',
      () async {
        // dio wraps an error from writing the received bytes (e.g. a full
        // disk) in a DioException.
        when(
          () => service.download(
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            error: const FileSystemException('No space left on device'),
          ),
        );
        await expectLater(
          repo().download(_upd()),
          throwsA(isA<UpdateStorageException>()),
        );
      },
    );
  });

  group('AppUpdateRepository.install', () {
    for (final (status, outcome) in [
      (0, InstallOutcome.success),
      (3, InstallOutcome.cancelled),
      (5, InstallOutcome.signatureConflict),
      (6, InstallOutcome.storage),
      (1, InstallOutcome.failed),
      (2, InstallOutcome.failed),
      (4, InstallOutcome.failed),
      (7, InstallOutcome.failed),
      (8, InstallOutcome.failed),
      (99, InstallOutcome.failed),
    ]) {
      test('status $status maps to $outcome', () async {
        when(() => installer.install('/a.apk')).thenAnswer((_) async => status);
        expect(await repo().install('/a.apk'), outcome);
      });
    }

    test('a channel error maps to failed', () async {
      when(() => installer.install(any()))
          .thenThrow(PlatformException(code: 'x'));
      expect(await repo().install('/a.apk'), InstallOutcome.failed);
    });

    test('canInstall and openInstallSettings delegate', () async {
      when(() => installer.canRequestInstalls()).thenAnswer((_) async => true);
      when(() => installer.openInstallSettings()).thenAnswer((_) async {});
      expect(await repo().canInstall(), isTrue);
      await repo().openInstallSettings();
      verify(() => installer.openInstallSettings()).called(1);
    });
  });

  group('AppUpdateRepository.cleanUp', () {
    test('keeps only the verified APK of the given update', () async {
      final keep = File('${dir.path}/ledgerly-v0.7.2-arm64-v8a.apk')
        ..writeAsBytesSync(_bytes);
      final part = File('${keep.path}.part')..writeAsBytesSync(_bytes);
      final old = File('${dir.path}/ledgerly-v0.7.1-arm64-v8a.apk')
        ..writeAsBytesSync(_bytes);
      await repo().cleanUp(keep: _upd());
      expect(keep.existsSync(), isTrue);
      expect(part.existsSync(), isFalse);
      expect(old.existsSync(), isFalse);
    });

    test('with no update everything is removed', () async {
      File('${dir.path}/x.apk').writeAsBytesSync(_bytes);
      await repo().cleanUp(keep: null);
      expect(dir.listSync(), isEmpty);
    });
  });

  group('isNewerVersion', () {
    const cases = <(String, String, bool)>[
      ('v0.7.2', '0.7.1', true),
      ('v0.10.0', '0.9.9', true),
      ('0.8.0', '0.7.1', true),
      ('v0.7.1', '0.7.1', false),
      ('v0.7.0', '0.7.1', false),
      ('v0.8.0-rc1', '0.7.1', false),
      ('garbage', '0.7.1', false),
      ('v0.8.0', 'garbage', false),
    ];
    for (final (latest, installed, expected) in cases) {
      test('$latest vs $installed is $expected', () {
        expect(isNewerVersion(latest, installed), expected);
      });
    }
  });

  group('AppUpdateRepository.isSupported', () {
    for (final (abi, expected) in [
      (Abi.androidArm64, true),
      (Abi.androidArm, true),
      (Abi.androidX64, true),
      (Abi.macosArm64, false),
      (Abi.iosArm64, false),
    ]) {
      test('$abi is ${expected ? '' : 'not '}supported', () {
        expect(repo(abi: abi).isSupported, expected);
      });
    }
  });
}
