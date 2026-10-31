import 'package:package_info_plus/package_info_plus.dart';

/// Reads the installed app's version from the platform.
///
/// Returns a record rather than a model: services may not import
/// `data/models/` (`services_forbid_upstream_and_siblings`).
class PackageInfoService {
  const PackageInfoService();

  Future<({String version, String buildNumber})> read() async {
    final info = await PackageInfo.fromPlatform();
    return (version: info.version, buildNumber: info.buildNumber);
  }
}
