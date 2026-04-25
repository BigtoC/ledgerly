// `AmountDisplay` — Wave 2 §4.1.
//
// Renders the keypad-accumulated amount above the calculator. Re-renders
// on every digit press because `amountMinorUnits` lives on
// `TransactionFormData`, which the screen watches.
//
// Display rules:
//   - In integer mode, no decimal separator is shown (e.g. "12").
//   - In fractional mode, the decimal separator is shown plus exactly
//     `fractionalDigitsEntered` digits after it (so "1." renders mid-typing
//     before the user has typed any fractional digit).
//   - Currency code is rendered to the right of the value as a small chip
//     so the user can see which account currency is active without
//     scanning the account row.

import 'package:flutter/material.dart';

import '../../../data/models/currency.dart';
import '../keypad_state.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.keypad,
    required this.currency,
    this.hasError = false,
  });

  /// Source of truth for what to render. The screen reads it from the
  /// controller's `keypadSnapshot` getter on each rebuild — a value-typed
  /// snapshot keeps the widget free of controller-instance coupling.
  final KeypadState keypad;

  final Currency? currency;

  /// When true, the display draws an error-toned outline and the
  /// surrounding label switches to the inline-validation color (Wave 2 §9
  /// inline validation).
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = currency?.code ?? '';
    final text = _renderAmountText();
    final foreground = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: hasError
            ? Border.all(color: theme.colorScheme.error, width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          if (code.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                code,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _renderAmountText() {
    final c = currency;
    final decimals = c?.decimals ?? 2;
    final amount = keypad.amountMinorUnits;
    if (decimals == 0) {
      return amount.toString();
    }
    if (!keypad.isFractionalMode) {
      // Integer-mode preview hides the fractional zeros so an empty form
      // shows "0" rather than "0.00".
      final unit = _pow10(decimals);
      final whole = amount ~/ unit;
      return whole.toString();
    }
    final unit = _pow10(decimals);
    final whole = amount ~/ unit;
    final fracPart = (amount % unit)
        .toString()
        .padLeft(decimals, '0')
        .substring(0, keypad.fractionalDigitsEntered);
    if (keypad.fractionalDigitsEntered == 0) {
      return '$whole.';
    }
    return '$whole.$fracPart';
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
