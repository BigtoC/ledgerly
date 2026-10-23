import 'package:dio/dio.dart';

/// Reads the latest published Ledgerly release from the GitHub API.
///
/// A fixed GET with no query parameters and no user data. Returns raw
/// parsed data as records: the `services_forbid_upstream_and_siblings`
/// import rule forbids this layer from importing models or repositories.
///
/// Throws [DioException] on network or HTTP errors; the repository catches
/// it and logs only the exception type.
class AppReleaseService {
  AppReleaseService(this._dio);

  final Dio _dio;

  static const _latestReleaseUrl =
      'https://api.github.com/repos/BigtoC/ledgerly/releases/latest';

  /// The latest release's tag and assets, or null when the body does not
  /// have the expected shape. Asset entries without a string `name` and
  /// `browser_download_url` are skipped.
  Future<({String tagName, List<({String name, String url})> assets})?>
  fetchLatestRelease() async {
    final response = await _dio.get<Object?>(
      _latestReleaseUrl,
      options: Options(
        headers: const {'Accept': 'application/vnd.github+json'},
      ),
    );
    if (response.data case {
      'tag_name': final String tagName,
      'assets': final List<dynamic> assets,
    }) {
      return (
        tagName: tagName,
        assets: [
          for (final asset in assets)
            if (asset case {
              'name': final String name,
              'browser_download_url': final String url,
            })
              (name: name, url: url),
        ],
      );
    }
    return null;
  }
}
