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
//   - While an expression is in progress, a one-line history above the
//     amount shows the formula as typed with its pending operator
//     ("3.5 + 10.5 + 11 +"), and the main amount shows the operand being
//     typed, with its `%` once that is pressed ("10%").
//   - When `showingResult` is true, the history line shows the whole
//     formula ("3.5 + 10.5 + 11 + 3 =") and the main amount shows the
//     fixed-precision result (e.g. "28.00" for USD). This includes a
//     formula loaded from a saved transaction, and a lone percent
//     ("10% ="). A dangling operator finished with `=` ("12 +") leaves no
//     formula, so only the result shows and the history line is hidden.
//   - Brackets show the left-to-right order where it differs from usual
//     precedence ("(1 + 2) × 2 ="). Operands keep the fractional digits as
//     typed, minus trailing zeros, with locale digit grouping ("1,234.5").

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../view_models/amount_formula.dart';
import '../view_models/keypad_state.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.keypad,
    required this.currency,
    this.currencyTouched = false,
    this.hasError = false,
  });

  /// Source of truth for what to render. The screen reads it from the
  /// form state's `keypad` snapshot on each rebuild — a value-typed
  /// snapshot keeps the widget free of controller-instance coupling.
  final KeypadState keypad;

  final Currency currency;

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
    final code = currency.code;
    final showPlaceholder =
        currencyTouched &&
        keypad.amountMinorUnits == 0 &&
        !keypad.hasVisibleInput;
    final expressionText = _buildExpressionText(locale: l10n.localeName);
    final text = showPlaceholder
        ? l10n.txAmountPlaceholderInCurrency(code)
        : '${_renderAmountText(locale: l10n.localeName)}'
              '${keypad.isPercent ? '%' : ''}';
    final foreground = hasError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final textColor = showPlaceholder
        ? foreground.withValues(alpha: 0.5)
        : foreground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // A long formula scrolls instead of being ellipsized, and starts
            // scrolled to its end so the operand being edited stays visible.
            // The minimum width keeps a short one left-aligned with the
            // amount below.
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      expressionText,
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
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
    if (keypad.showingResult) {
      return MoneyFormatter.formatBare(
        amountMinorUnits: keypad.amountMinorUnits,
        currency: currency,
        locale: locale,
      );
    }
    final decimals = currency.decimals;
    final amount = keypad.amountMinorUnits;
    if (decimals == 0) return amount.toString();
    final unit = pow10(decimals);
    final whole = amount ~/ unit;
    if (!keypad.isFractionalMode) return whole.toString();
    final fracPart = (amount % unit)
        .toString()
        .padLeft(decimals, '0')
        .substring(0, keypad.fractionalDigitsEntered);
    return keypad.fractionalDigitsEntered == 0 ? '$whole.' : '$whole.$fracPart';
  }

  String? _buildExpressionText({required String locale}) {
    // Evaluating, the formula ends with its pending operator; on a result
    // it is complete. A result without a formula has no history line.
    if (keypad.formulaOperands.isEmpty) return null;
    final text = _formulaText(
      keypad.formulaOperands,
      keypad.formulaOperators,
      decimals: currency.decimals,
      locale: locale,
    );
    return keypad.showingResult ? '$text =' : text;
  }

  /// The formula as typed, with display symbols and the same left-to-right
  /// brackets as the stored form: the keys `1 + 2 × 2` read
  /// "(1 + 2) × 2", the 6 they evaluate to, not 5.
  String _formulaText(
    List<FormulaOperand> operands,
    List<CalcOperator> operators, {
    required int decimals,
    required String locale,
  }) {
    final format = NumberFormat.decimalPattern(locale);
    return renderFormula(
      operands: operands,
      operators: operators,
      operand: (o) => _localizedOperand(o, decimals: decimals, format: format),
      operator: _operatorSymbol,
      separator: ' ',
    );
  }

  /// [operand] with the fractional digits as typed, but the whole part
  /// grouped and the decimal separator taken from [format]'s locale, like
  /// the result line below it ("1,234.5").
  static String _localizedOperand(
    FormulaOperand operand, {
    required int decimals,
    required NumberFormat format,
  }) {
    final text = encodeFormulaOperand(operand, decimals: decimals);
    final dot = text.indexOf('.');
    final whole = format.format(
      int.parse(dot < 0 ? text : text.substring(0, dot)),
    );
    if (dot < 0) return whole;
    return '$whole${format.symbols.DECIMAL_SEP}${text.substring(dot + 1)}';
  }

  String _operatorSymbol(CalcOperator op) => switch (op) {
    CalcOperator.add => '+',
    CalcOperator.subtract => '−',
    CalcOperator.multiply => '×',
    CalcOperator.divide => '÷',
  };
}
