import 'dart:ffi' show Abi;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/app_update_repository.dart';
import 'package:ledgerly/data/services/app_release_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAppReleaseService extends Mock implements AppReleaseService {}

const _arm64Url = 'https://example.com/ledgerly-v0.7.2-arm64-v8a.apk';
const _armUrl = 'https://example.com/ledgerly-v0.7.2-armeabi-v7a.apk';
const _x64Url = 'https://example.com/ledgerly-v0.7.2-x86_64.apk';

typedef _Release = ({String tagName, List<({String name, String url})> assets});

_Release _release({
  String tag = 'v0.7.2',
  List<({String name, String url})>? assets,
}) => (
  tagName: tag,
  assets:
      assets ??
      const [
        (name: 'ledgerly-v0.7.2-arm64-v8a.apk', url: _arm64Url),
        (name: 'ledgerly-v0.7.2-armeabi-v7a.apk', url: _armUrl),
        (name: 'ledgerly-v0.7.2-x86_64.apk', url: _x64Url),
        (
          name: 'ledgerly-v0.7.2-checksums.txt',
          url: 'https://example.com/ledgerly-v0.7.2-checksums.txt',
        ),
      ],
);

void main() {
  late MockAppReleaseService service;
  late int versionCalls;

  setUp(() {
    service = MockAppReleaseService();
    versionCalls = 0;
  });

  AppUpdateRepository repo({
    Abi abi = Abi.androidArm64,
    String installed = '0.7.1',
  }) => AppUpdateRepository(
    service,
    installedVersion: () async {
      versionCalls++;
      return installed;
    },
    abi: abi,
  );

  void stubRelease(_Release? release) {
    when(() => service.fetchLatestRelease()).thenAnswer((_) async => release);
  }

  group('AppUpdateRepository.findUpdate', () {
    test('androidArm64 returns the arm64-v8a URL', () async {
      stubRelease(_release());
      expect(await repo().findUpdate(), Uri.parse(_arm64Url));
    });

    test('androidArm returns armeabi-v7a, not arm64-v8a', () async {
      stubRelease(_release());
      expect(await repo(abi: Abi.androidArm).findUpdate(), Uri.parse(_armUrl));
    });

    test('androidX64 returns the x86_64 URL', () async {
      stubRelease(_release());
      expect(await repo(abi: Abi.androidX64).findUpdate(), Uri.parse(_x64Url));
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
          assets: const [(name: 'ledgerly-v0.7.2-x86_64.apk', url: _x64Url)],
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
}
