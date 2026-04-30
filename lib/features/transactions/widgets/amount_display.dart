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
//   - When `currencyTouched` is true and `amountMinorUnits == 0` and no
//     calculator state is active, a currency-specific placeholder is shown
//     instead of "0" so the user knows the amount was cleared for a
//     currency change.
//   - When the calculator is in `isEvaluating` state, a one-line history
//     showing the left operand and operator is rendered above the main
//     amount.
//   - When `showingResult` is true, the history line shows the full
//     expression ("12.00 + 5.00 =") and the main amount shows the
//     fixed-precision result (e.g. "17.00" for USD).

import 'package:flutter/material.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../keypad_state.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.keypad,
    required this.currency,
    this.currencyTouched = false,
    this.hasError = false,
  });

  /// Source of truth for what to render. The screen reads it from the
  /// controller's `keypadSnapshot` getter on each rebuild — a value-typed
  /// snapshot keeps the widget free of controller-instance coupling.
  final KeypadState keypad;

  final Currency? currency;

  /// When true and `amountMinorUnits == 0` and no calculator state is
  /// active, renders `txAmountPlaceholderInCurrency(code)` instead of "0"
  /// to signal the amount was cleared after a currency change.
  final bool currencyTouched;

  /// When true, the display draws an error-toned outline and the
  /// surrounding label switches to the inline-validation color (Wave 2 §9
  /// inline validation).
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final code = currency?.code ?? '';
    final showPlaceholder =
        currencyTouched &&
        keypad.amountMinorUnits == 0 &&
        code.isNotEmpty &&
        !keypad.hasVisibleInput;
    final expressionText = _buildExpressionText(locale: l10n.localeName);
    final text = showPlaceholder
        ? l10n.txAmountPlaceholderInCurrency(code)
        : _renderAmountText(locale: l10n.localeName);
    final foreground = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final textColor = showPlaceholder
        ? foreground.withValues(alpha: 0.5)
        : foreground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: hasError
            ? Border.all(color: theme.colorScheme.error, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expressionText != null)
            Text(
              expressionText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.6),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: textColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (code.isNotEmpty && !showPlaceholder)
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
        ],
      ),
    );
  }

  String _renderAmountText({required String locale}) {
    final c = currency;
    if (c != null && keypad.showingResult) {
      return MoneyFormatter.formatBare(
        amountMinorUnits: keypad.amountMinorUnits,
        currency: c,
        locale: locale,
      );
    }
    // currency == null means the form hasn't loaded a currency yet.
    // In that case we fall through to the live-entry preview below
    // (decimals defaults to 2), which is acceptable since showingResult
    // cannot be true before the user has entered an amount and pressed
    // an operator — both of which require a loaded currency.
    //
    // Existing live-entry preview behavior:
    final decimals = c?.decimals ?? 2;
    final amount = keypad.amountMinorUnits;
    if (decimals == 0) return amount.toString();
    if (!keypad.isFractionalMode) {
      final unit = _pow10(decimals);
      return (amount ~/ unit).toString();
    }
    final unit = _pow10(decimals);
    final whole = amount ~/ unit;
    final fracPart = (amount % unit)
        .toString()
        .padLeft(decimals, '0')
        .substring(0, keypad.fractionalDigitsEntered);
    return keypad.fractionalDigitsEntered == 0 ? '$whole.' : '$whole.$fracPart';
  }

  String? _buildExpressionText({required String locale}) {
    final c = currency;
    if (c == null) return null;

    if (keypad.isEvaluating &&
        keypad.leftOperand != null &&
        keypad.operator != null) {
      final left = MoneyFormatter.formatBare(
        amountMinorUnits: keypad.leftOperand!,
        currency: c,
        locale: locale,
      );
      return '$left ${_operatorSymbol(keypad.operator!)}';
    }

    if (keypad.showingResult &&
        keypad.leftOperand != null &&
        keypad.operator != null &&
        keypad.rightOperand != null) {
      final left = MoneyFormatter.formatBare(
        amountMinorUnits: keypad.leftOperand!,
        currency: c,
        locale: locale,
      );
      final right = MoneyFormatter.formatBare(
        amountMinorUnits: keypad.rightOperand!,
        currency: c,
        locale: locale,
      );
      return '$left ${_operatorSymbol(keypad.operator!)} $right =';
    }

    return null;
  }

  String _operatorSymbol(CalcOperator op) => switch (op) {
    CalcOperator.add => '+',
    CalcOperator.subtract => '−',
    CalcOperator.multiply => '×',
    CalcOperator.divide => '÷',
  };

  // Local copy of the pow10 helper used for the live-entry preview path.
  // The expression-history and result paths use MoneyFormatter.formatBare
  // which handles scaling internally.
  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
