import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';

/// Shows a Cancel / [confirmLabel] dialog. Resolves to true only when the
/// user confirms; Cancel and a barrier dismiss resolve to false. [tonal]
/// renders the confirm action as a `FilledButton.tonal`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  String? title,
  required String body,
  required String confirmLabel,
  bool tonal = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      void confirm() => Navigator.of(ctx).pop(true);
      final label = Text(confirmLabel);
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          tonal
              ? FilledButton.tonal(onPressed: confirm, child: label)
              : FilledButton(onPressed: confirm, child: label),
        ],
      );
    },
  );
  return confirmed ?? false;
}
