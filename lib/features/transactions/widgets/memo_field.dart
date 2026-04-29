// `MemoField` — Wave 2 §4.1.
//
// Single-line text field for the optional memo. The keypad must NOT be
// covered by the soft keyboard when this field has focus; that invariant
// is enforced by `Scaffold(resizeToAvoidBottomInset: false)` on the screen,
// not by this widget.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class MemoField extends StatefulWidget {
  const MemoField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<MemoField> createState() => _MemoFieldState();
}

class _MemoFieldState extends State<MemoField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant MemoField old) {
    super.didUpdateWidget(old);
    if (widget.initialValue != old.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: l10n.txMemoLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.notes_outlined),
      ),
      maxLines: 1,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      onChanged: widget.onChanged,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
