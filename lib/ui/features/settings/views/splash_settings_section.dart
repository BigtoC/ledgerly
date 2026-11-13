// Splash settings subsection (plan §3.1, §6).
//
// Renders the four splash controls: enabled toggle, conditional
// start-date row, display-text field, button-label field. The enabled
// toggle hides the other three when off (plan §6).
//
// Text fields debounce writes via an explicit "on submit / on focus out"
// contract (plan §13 risk #6) rather than write on every keystroke —
// this avoids churning the Drift stream. Values are kept in a local
// controller sync'd to the incoming value via `didUpdateWidget` so that
// upstream edits (e.g. resetting to defaults from another path) still
// reflect in the UI.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../l10n/app_localizations.dart';
import '../view_models/settings_controller.dart';
import '../view_models/settings_state.dart';
import 'settings_section.dart';

@Dependencies([SettingsController])
class const SplashSettingsSection({
  super.key,
  required final bool splashEnabled,
  required final DateTime? splashStartDate,

  /// `null` means "use localized default template" — the widget renders
  /// the default as a placeholder so the user can see what they'd get.
  required final String? splashDisplayText,
  required final String? splashButtonLabel,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsSplashSection,
      children: [
        SwitchListTile(
          key: const ValueKey('splashSettings:enabledSwitch'),
          title: Text(l10n.settingsSplashEnabled),
          value: splashEnabled,
          onChanged: (v) async {
            final messenger = ScaffoldMessenger.of(context);
            final outcome = await ref
                .read(settingsControllerProvider.notifier)
                .setSplashEnabled(v);
            switch (outcome) {
              case SettingsWriteOk():
                break;
              case SettingsWriteFailed():
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.errorSnackbarGeneric)),
                );
            }
          },
        ),
        if (splashEnabled) ...[
          _SplashStartDateRow(startDate: splashStartDate),
          _SplashTextField(
            fieldKey: const ValueKey('splashSettings:displayTextField'),
            value: splashDisplayText,
            labelText: l10n.settingsSplashDisplayText,
            // The literal '{date}' / '{days}' arguments are the actual tokens
            // DateHelpers.applySplashTemplateSegments substitutes; the ARB
            // declares dateToken/daysToken placeholders only because gen_l10n
            // cannot embed literal braces in a plain message.
            hintText: l10n.settingsSplashDisplayTextHint('{date}', '{days}'),
            // Multi-line input so users can split the splash text across visual
            // lines with explicit `\n` separators (the splash renders via
            // `Text.rich`, which honours newlines). Save still happens on
            // focus-out; `onSubmitted` is retained so programmatic submissions
            // and platforms that surface a "done" affordance continue to persist.
            multiline: true,
            write: (c, v) => c.setSplashDisplayText(v),
          ),
          _SplashTextField(
            fieldKey: const ValueKey('splashSettings:buttonLabelField'),
            value: splashButtonLabel,
            labelText: l10n.settingsSplashButtonLabel,
            hintText: l10n.splashEnter,
            write: (c, v) => c.setSplashButtonLabel(v),
          ),
          const _SplashPreviewTile(),
        ],
      ],
    );
  }
}

class _SplashPreviewTile extends StatelessWidget {
  const _SplashPreviewTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      key: const ValueKey('splashSettings:previewTile'),
      leading: Icon(
        Icons.play_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(l10n.settingsSplashPreviewCta),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/splash/preview'),
    );
  }
}

@Dependencies([SettingsController])
class const _SplashStartDateRow({required final DateTime? startDate})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final formatted = startDate == null
        ? l10n.settingsSplashStartDate
        : DateFormat.yMMMMd(locale).format(startDate!);
    return ListTile(
      key: const ValueKey('splashSettings:startDateTile'),
      title: Text(l10n.settingsSplashStartDate),
      subtitle: Text(formatted),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: startDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(9999, 12, 31),
        );
        if (picked == null) return;
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final outcome = await ref
            .read(settingsControllerProvider.notifier)
            .setSplashStartDate(picked);
        switch (outcome) {
          case SettingsWriteOk():
            break;
          case SettingsWriteFailed():
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.errorSnackbarGeneric)),
            );
        }
      },
    );
  }
}

@Dependencies([SettingsController])
class const _SplashTextField({
  required final Key fieldKey,
  required final String? value,
  required final String labelText,
  required final String hintText,
  required final Future<SettingsWriteOutcome> Function(
    SettingsController controller,
    String value,
  )
  write,
  final bool multiline = false,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SplashTextField> createState() => _SplashTextFieldState();
}

class _SplashTextFieldState extends ConsumerState<_SplashTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _lastSynced = '';

  /// The value whose write is in flight. A submit via the keyboard action
  /// also unfocuses the field, and that focus-out must not write it again.
  String? _writing;

  @override
  void initState() {
    super.initState();
    _lastSynced = widget.value ?? '';
    _controller = TextEditingController(text: _lastSynced);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _SplashTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pull upstream changes in — but only when they actually differ from
    // what we last synced, so we don't clobber mid-edit values.
    final incoming = widget.value ?? '';
    if (incoming != _lastSynced) {
      _lastSynced = incoming;
      _controller.text = incoming;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      unawaited(_submit());
    }
  }

  Future<void> _submit() async {
    final value = _controller.text;
    if (value == _lastSynced || value == _writing) return;
    _writing = value;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final outcome = await widget.write(
      ref.read(settingsControllerProvider.notifier),
      value,
    );
    if (_writing == value) _writing = null;
    switch (outcome) {
      case SettingsWriteOk():
        // Record the value as synced only once it is stored, so a failed
        // write is retried on the next submit or focus-out.
        _lastSynced = value;
      case SettingsWriteFailed():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorSnackbarGeneric)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        key: widget.fieldKey,
        controller: _controller,
        focusNode: _focusNode,
        maxLines: widget.multiline ? null : 1,
        minLines: widget.multiline ? 1 : null,
        keyboardType: widget.multiline ? TextInputType.multiline : null,
        textInputAction: widget.multiline ? null : TextInputAction.done,
        onSubmitted: (_) => unawaited(_submit()),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
      ),
    );
  }
}
