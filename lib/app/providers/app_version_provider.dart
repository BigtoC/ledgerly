import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'service_providers.dart';

part 'app_version_provider.g.dart';

/// Installed app version and build number, shown in the Settings footer.
///
/// Features read this instead of the package-info service, which the
/// layer rules in `import_analysis_options.yaml` keep out of
/// `lib/features/`.
@Riverpod(keepAlive: true)
Future<({String version, String buildNumber})> appVersion(Ref ref) =>
    ref.watch(packageInfoServiceProvider).read();
