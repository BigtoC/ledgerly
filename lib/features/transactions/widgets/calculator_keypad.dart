// `CalculatorKeypad` — Wave 2 §8.
//
// Fixed-height numeric keypad. Layout per PRD → Layout Primitives:
//
//   7 8 9 ÷
//   4 5 6 ×
//   1 2 3 −
//   . 0 ⌫ +
//
// Notes:
//   - The decimal key is greyed out when `decimals == 0` (JPY).
//   - Long-pressing ⌫ triggers `onClear`.
//   - Operator keys (÷ × − +) emit `CalcOperator` values via `onOperator`.
//   - Save lives in the AppBar, not the keypad — keep the surface
//     numeric-only so the user can type quickly with one thumb.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../l10n/app_localizations.dart';
import '../keypad_state.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    super.key,
    required this.decimals,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onClear,
    required this.onOperator,
  });

  final int decimals;
  final ValueChanged<int> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final ValueChanged<CalcOperator> onOperator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final decimalEnabled = decimals > 0;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row([
            _DigitKey(label: '7', onTap: () => onDigit(7)),
            _DigitKey(label: '8', onTap: () => onDigit(8)),
            _DigitKey(label: '9', onTap: () => onDigit(9)),
            _OperatorKey(
              label: '÷',
              semanticsLabel: l10n.txKeypadDivide,
              onTap: () => onOperator(CalcOperator.divide),
            ),
          ]),
          _row([
            _DigitKey(label: '4', onTap: () => onDigit(4)),
            _DigitKey(label: '5', onTap: () => onDigit(5)),
            _DigitKey(label: '6', onTap: () => onDigit(6)),
            _OperatorKey(
              label: '×',
              semanticsLabel: l10n.txKeypadMultiply,
              onTap: () => onOperator(CalcOperator.multiply),
            ),
          ]),
          _row([
            _DigitKey(label: '1', onTap: () => onDigit(1)),
            _DigitKey(label: '2', onTap: () => onDigit(2)),
            _DigitKey(label: '3', onTap: () => onDigit(3)),
            _OperatorKey(
              label: '−',
              semanticsLabel: l10n.txKeypadSubtract,
              onTap: () => onOperator(CalcOperator.subtract),
            ),
          ]),
          _row([
            _DigitKey(label: '.', onTap: decimalEnabled ? onDecimal : null),
            _DigitKey(label: '0', onTap: () => onDigit(0)),
            _IconKey(
              icon: Icons.backspace_outlined,
              tooltip: l10n.txKeypadBackspace,
              onTap: onBackspace,
              onLongPress: onClear,
            ),
            _OperatorKey(
              label: '+',
              semanticsLabel: l10n.txKeypadAdd,
              onTap: () => onOperator(CalcOperator.add),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [for (final c in children) Expanded(child: c)]),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final colors = Theme.of(context).colorScheme;
    final clamped = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: disabled
              ? colors.surfaceContainerHighest.withValues(alpha: 0.4)
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                textScaler: clamped,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: disabled
                      ? colors.onSurface.withValues(alpha: 0.4)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OperatorKey extends StatelessWidget {
  const _OperatorKey({
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clamped = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Semantics(
              label: semanticsLabel,
              button: true,
              child: ExcludeSemantics(
                child: Center(
                  child: Text(
                    label,
                    textScaler: clamped,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: tooltip,
          child: Semantics(
            onLongPressHint: l10n.txKeypadClear,
            customSemanticsActions: {
              CustomSemanticsAction(label: l10n.txKeypadClear):
                  onLongPress ?? () {},
            },
            child: Material(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Center(child: Icon(icon)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
