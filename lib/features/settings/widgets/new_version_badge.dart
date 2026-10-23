// Pink "new version" pill shown beside the app version at the bottom of
// Settings when a newer GitHub release exists. Tapping it opens the APK
// download URL in the system browser.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

typedef LaunchUrlFn = Future<bool> Function(Uri url, {LaunchMode mode});

class NewVersionBadge extends StatelessWidget {
  const NewVersionBadge({
    super.key,
    required this.url,
    @visibleForTesting this.launch = launchUrl,
  });

  final Uri url;
  final LaunchUrlFn launch;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = AppLocalizations.of(context).settingsNewVersionOpenFailed;
    bool launched;
    try {
      // System browser, not the in-app WebView.
      launched = await launch(url, mode: LaunchMode.externalApplication);
    } on PlatformException {
      // url_launcher_android throws rather than returning false.
      launched = false;
    }
    if (!launched) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const ValueKey('settingsNewVersionBadge'),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        // onPrimary fails WCAG AA on pinkAccent in both themes; black passes.
        foregroundColor: Colors.black,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        // Small pill, but still a padded 48dp tap target.
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: () => _open(context),
      child: Text(AppLocalizations.of(context).settingsNewVersionBadge),
    );
  }
}
