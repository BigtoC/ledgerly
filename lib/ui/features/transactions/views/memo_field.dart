// `MemoField` — Wave 2 §4.1.
//
// Single-line text field for the optional memo. The keypad must NOT be
// covered by the soft keyboard when this field has focus; that invariant
// is enforced by `Scaffold(resizeToAvoidBottomInset: false)` on the screen,
// not by this widget.

import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

class const MemoField({
  super.key,
  required final String initialValue,
  required final ValueChanged<String> onChanged,
}) extends StatefulWidget {
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
      // Cursor at the end so a picked memo suggestion can be extended.
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
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
        isDense: true,
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
