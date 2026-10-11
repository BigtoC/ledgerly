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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_controller.dart';
import 'settings_section.dart';

class SplashSettingsSection extends ConsumerWidget {
  const SplashSettingsSection({
    super.key,
    required this.splashEnabled,
    required this.splashStartDate,
    required this.splashDisplayText,
    required this.splashButtonLabel,
  });

  final bool splashEnabled;
  final DateTime? splashStartDate;

  /// `null` means "use localized default template" — the widget renders
  /// the default as a placeholder so the user can see what they'd get.
  final String? splashDisplayText;
  final String? splashButtonLabel;

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
          onChanged: (v) =>
              ref.read(settingsControllerProvider.notifier).setSplashEnabled(v),
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

class _SplashStartDateRow extends ConsumerWidget {
  const _SplashStartDateRow({required this.startDate});

  final DateTime? startDate;

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
        await ref
            .read(settingsControllerProvider.notifier)
            .setSplashStartDate(picked);
      },
    );
  }
}

class _SplashTextField extends ConsumerStatefulWidget {
  const _SplashTextField({
    required this.fieldKey,
    required this.value,
    required this.labelText,
    required this.hintText,
    required this.write,
    this.multiline = false,
  });

  final Key fieldKey;
  final String? value;
  final String labelText;
  final String hintText;
  final Future<void> Function(SettingsController controller, String value)
  write;
  final bool multiline;

  @override
  ConsumerState<_SplashTextField> createState() => _SplashTextFieldState();
}

class _SplashTextFieldState extends ConsumerState<_SplashTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _lastSynced = '';

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
      _submit();
    }
  }

  void _submit() {
    final value = _controller.text;
    if (value == _lastSynced) return;
    _lastSynced = value;
    widget.write(ref.read(settingsControllerProvider.notifier), value);
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
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
      ),
    );
  }
}
