// Pink "new version" pill shown beside the app version at the bottom of
// Settings when a newer GitHub release exists. When the release publishes
// a SHA-256, tapping downloads, verifies and installs the APK in the app
// (AppUpdateController); otherwise, and as the fallback on every failure,
// it opens the APK URL in the system browser.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/system_browser.dart';
import '../../../data/models/app_update.dart';
import '../../../l10n/app_localizations.dart';
import '../app_update_controller.dart';
import '../app_update_state.dart';

class NewVersionBadge extends ConsumerWidget {
  const NewVersionBadge({
    super.key,
    required this.update,
    @visibleForTesting this.launch = defaultLaunch,
  });

  final AppUpdate update;
  final LaunchUrlFn launch;

  Future<void> _openInBrowser(
    ScaffoldMessengerState? messenger,
    String failed,
  ) async {
    final launched = await openInSystemBrowser(update.apkUrl, launch: launch);
    if (!launched) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    AppUpdateState state,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final sizeBytes = update.sizeBytes;
    if (update.sha256 == null || sizeBytes == null) {
      return _openInBrowser(messenger, l10n.settingsNewVersionOpenFailed);
    }
    final controller = ref.read(appUpdateControllerProvider.notifier);
    if (state is AppUpdateIdle || state is AppUpdateFailed) {
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.settingsUpdateConfirmTitle(update.version)),
          content: Text(l10n.settingsUpdateConfirmBody(sizeMb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settingsUpdateDownloadAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await controller.start(update);
  }

  /// Shows the SnackBar for a state the user must act on, if any.
  void _report(BuildContext context, AppUpdateState next) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = switch (next) {
      AppUpdateReady(needsPermission: true) =>
        l10n.settingsUpdatePermissionNeeded,
      AppUpdateFailed(:final reason) => switch (reason) {
        UpdateFailure.network => l10n.settingsUpdateFailedNetwork,
        UpdateFailure.checksum => l10n.settingsUpdateFailedChecksum,
        UpdateFailure.storage => l10n.settingsUpdateFailedStorage,
        UpdateFailure.signatureConflict => l10n.settingsUpdateFailedSignature,
        UpdateFailure.generic => l10n.settingsUpdateFailedGeneric,
      },
      _ => null,
    };
    if (message == null) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        action: next is AppUpdateFailed
            ? SnackBarAction(
                label: l10n.settingsUpdateOpenInBrowser,
                onPressed: () => _openInBrowser(
                  messenger,
                  l10n.settingsNewVersionOpenFailed,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appUpdateControllerProvider);
    ref.listen(appUpdateControllerProvider, (previous, next) {
      if (previous != next) _report(context, next);
    });
    final label = switch (state) {
      AppUpdateDownloading(:final percent) => l10n.settingsUpdateDownloading(
        percent,
      ),
      AppUpdateReady() => l10n.settingsUpdateInstall,
      AppUpdateInstalling() => l10n.settingsUpdateInstalling,
      AppUpdateIdle() || AppUpdateFailed() => l10n.settingsNewVersionBadge,
    };
    final fill = Theme.of(context).colorScheme.primary;
    return FilledButton(
      key: const ValueKey('settingsNewVersionBadge'),
      style: FilledButton.styleFrom(
        backgroundColor: fill,
        // onPrimary fails WCAG AA on pinkAccent in both themes, so pick
        // whichever of black or white contrasts more with the fill.
        foregroundColor: _labelColorOn(fill),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        // Small pill, but still a padded 48dp tap target.
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: () => _onTap(context, ref, state),
      child: Text(label),
    );
  }

  /// Black or white, whichever has the higher WCAG contrast ratio on [fill].
  static Color _labelColorOn(Color fill) {
    final l = fill.computeLuminance();
    // (l + 0.05) / 0.05 for black vs 1.05 / (l + 0.05) for white.
    return (l + 0.05) * (l + 0.05) > 1.05 * 0.05 ? Colors.black : Colors.white;
  }
}
