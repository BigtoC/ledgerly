import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/app_release_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

const _latestUrl =
    'https://api.github.com/repos/BigtoC/ledgerly/releases/latest';

void main() {
  late MockDio mockDio;
  late AppReleaseService service;

  setUp(() {
    mockDio = MockDio();
    service = AppReleaseService(mockDio);
  });

  void stubBody(Object? data) {
    when(() => mockDio.get<Object?>(any(), options: any(named: 'options')))
        .thenAnswer(
          (_) async => Response<Object?>(
            data: data,
            statusCode: 200,
            requestOptions: RequestOptions(path: _latestUrl),
          ),
        );
  }

  group('AppReleaseService.fetchLatestRelease', () {
    test('parses the tag and assets', () async {
      stubBody({
        'tag_name': 'v0.7.2',
        'assets': [
          {
            'name': 'ledgerly-v0.7.2-arm64-v8a.apk',
            'browser_download_url': 'https://example.com/arm64.apk',
          },
          {
            'name': 'ledgerly-v0.7.2-checksums.txt',
            'browser_download_url': 'https://example.com/checksums.txt',
          },
        ],
      });

      final release = await service.fetchLatestRelease();

      expect(release, isNotNull);
      expect(release!.tagName, 'v0.7.2');
      expect(release.assets, [
        (
          name: 'ledgerly-v0.7.2-arm64-v8a.apk',
          url: 'https://example.com/arm64.apk',
        ),
        (
          name: 'ledgerly-v0.7.2-checksums.txt',
          url: 'https://example.com/checksums.txt',
        ),
      ]);
    });

    test('skips malformed asset entries', () async {
      stubBody({
        'tag_name': 'v0.7.2',
        'assets': [
          'not a map',
          {'name': 'missing-url.apk'},
          {'name': 42, 'browser_download_url': 'https://example.com/x.apk'},
          {
            'name': 'ledgerly-v0.7.2-x86_64.apk',
            'browser_download_url': 'https://example.com/x86_64.apk',
          },
        ],
      });

      final release = await service.fetchLatestRelease();

      expect(release!.assets, [
        (
          name: 'ledgerly-v0.7.2-x86_64.apk',
          url: 'https://example.com/x86_64.apk',
        ),
      ]);
    });

    test('missing tag_name gives null', () async {
      stubBody({'assets': <Object?>[]});
      expect(await service.fetchLatestRelease(), isNull);
    });

    test('wrong-typed tag_name gives null', () async {
      stubBody({'tag_name': 7, 'assets': <Object?>[]});
      expect(await service.fetchLatestRelease(), isNull);
    });

    test('non-map body gives null', () async {
      stubBody([
        {'tag_name': 'v0.7.2', 'assets': <Object?>[]},
      ]);
      expect(await service.fetchLatestRelease(), isNull);
    });

    test('null body gives null', () async {
      stubBody(null);
      expect(await service.fetchLatestRelease(), isNull);
    });

    test('DioException propagates', () async {
      when(() => mockDio.get<Object?>(any(), options: any(named: 'options')))
          .thenThrow(
            DioException(requestOptions: RequestOptions(path: _latestUrl)),
          );

      expect(service.fetchLatestRelease(), throwsA(isA<DioException>()));
    });

    test(
      'requests exactly the releases/latest URL with no query parameters',
      () async {
        stubBody({'tag_name': 'v0.7.2', 'assets': <Object?>[]});

        await service.fetchLatestRelease();

        final captured = verify(
          () => mockDio.get<Object?>(
            captureAny(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        expect(captured[0], _latestUrl);
        expect(captured[1], isNull);
        expect(
          (captured[2] as Options).headers,
          containsPair('Accept', 'application/vnd.github+json'),
        );
      },
    );
  });
}
