// Opening-balance numeric input that respects `currency.decimals`
// (plan §5, §12 risk #6).
//
// The widget parses the user's input via
// `MoneyFormatter.parseToMinorUnits(...)` on every change. Invalid
// inputs (non-numeric or fractional digits exceeding
// `currency.decimals`) surface an inline error and null the reported
// minor-unit value — the outer form treats `null` as "invalid" and
// guards Save accordingly. "100.5" into JPY (`decimals = 0`) is
// rejected.
//
// Currency changes reset the text field to the formatted representation
// of the last known minor-unit value. This keeps the stored integer
// stable across JPY↔USD toggles inside the form.

import 'package:flutter/material.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../data/models/currency.dart';

class AmountMinorUnitsField extends StatefulWidget {
  const AmountMinorUnitsField({
    super.key,
    required this.currency,
    required this.locale,
    required this.initialMinorUnits,
    required this.onChanged,
    required this.labelText,
  });

  final Currency currency;
  final String locale;
  final int initialMinorUnits;
  final String labelText;

  /// Called with a valid parsed minor-unit amount, or `null` when the
  /// input is unparseable / violates `currency.decimals`.
  final ValueChanged<int?> onChanged;

  @override
  State<AmountMinorUnitsField> createState() => _AmountMinorUnitsFieldState();
}

class _AmountMinorUnitsFieldState extends State<AmountMinorUnitsField> {
  late final TextEditingController _ctrl;
  String? _errorText;
  int? _lastValidMinorUnits;

  @override
  void initState() {
    super.initState();
    _lastValidMinorUnits = widget.initialMinorUnits;
    _ctrl = TextEditingController(
      text: MoneyFormatter.formatBare(
        amountMinorUnits: widget.initialMinorUnits,
        currency: widget.currency,
        locale: widget.locale,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AmountMinorUnitsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency.code != widget.currency.code ||
        oldWidget.locale != widget.locale) {
      // Currency swap — re-render the last known minor-unit value in
      // the new currency's decimals.
      final v = _lastValidMinorUnits ?? 0;
      _ctrl.text = MoneyFormatter.formatBare(
        amountMinorUnits: v,
        currency: widget.currency,
        locale: widget.locale,
      );
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = null;
        _lastValidMinorUnits = 0;
      });
      widget.onChanged(0);
      return;
    }
    try {
      final parsed = MoneyFormatter.parseToMinorUnits(
        input: trimmed,
        currency: widget.currency,
        locale: widget.locale,
      );
      setState(() {
        _errorText = null;
        _lastValidMinorUnits = parsed;
      });
      widget.onChanged(parsed);
    } on FormatException {
      setState(() => _errorText = _errorMessage());
      widget.onChanged(null);
    }
  }

  String _errorMessage() {
    // Simple, currency-scoped message so users know JPY rejects
    // fractional input without a dedicated ARB key.
    return widget.currency.decimals == 0
        ? 'Whole numbers only'
        : 'Up to ${widget.currency.decimals} decimal places';
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        errorText: _errorText,
        prefixText: widget.currency.symbol ?? widget.currency.code,
      ),
      onChanged: _onChanged,
    );
  }
}
