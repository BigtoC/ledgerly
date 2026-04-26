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
          _SplashDisplayTextField(text: splashDisplayText),
          _SplashButtonLabelField(label: splashButtonLabel),
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
      leading: const Icon(Icons.play_circle_outline),
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

class _SplashDisplayTextField extends ConsumerStatefulWidget {
  const _SplashDisplayTextField({required this.text});

  final String? text;

  @override
  ConsumerState<_SplashDisplayTextField> createState() =>
      _SplashDisplayTextFieldState();
}

class _SplashDisplayTextFieldState
    extends ConsumerState<_SplashDisplayTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _lastSyncedText = '';

  @override
  void initState() {
    super.initState();
    _lastSyncedText = widget.text ?? '';
    _controller = TextEditingController(text: _lastSyncedText);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _SplashDisplayTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pull upstream changes in — but only when they actually differ from
    // what we last synced, so we don't clobber mid-edit values.
    final incoming = widget.text ?? '';
    if (incoming != _lastSyncedText) {
      _lastSyncedText = incoming;
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
    if (value == _lastSyncedText) return;
    _lastSyncedText = value;
    ref.read(settingsControllerProvider.notifier).setSplashDisplayText(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        key: const ValueKey('splashSettings:displayTextField'),
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.settingsSplashDisplayText,
          hintText: l10n.settingsSplashDisplayTextHint,
        ),
      ),
    );
  }
}

class _SplashButtonLabelField extends ConsumerStatefulWidget {
  const _SplashButtonLabelField({required this.label});

  final String? label;

  @override
  ConsumerState<_SplashButtonLabelField> createState() =>
      _SplashButtonLabelFieldState();
}

class _SplashButtonLabelFieldState
    extends ConsumerState<_SplashButtonLabelField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _lastSyncedLabel = '';

  @override
  void initState() {
    super.initState();
    _lastSyncedLabel = widget.label ?? '';
    _controller = TextEditingController(text: _lastSyncedLabel);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _SplashButtonLabelField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.label ?? '';
    if (incoming != _lastSyncedLabel) {
      _lastSyncedLabel = incoming;
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
    if (value == _lastSyncedLabel) return;
    _lastSyncedLabel = value;
    ref.read(settingsControllerProvider.notifier).setSplashButtonLabel(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        key: const ValueKey('splashSettings:buttonLabelField'),
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.settingsSplashButtonLabel,
          hintText: l10n.splashEnter,
        ),
      ),
    );
  }
}
