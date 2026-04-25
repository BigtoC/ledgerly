// `CalculatorKeypad` — Wave 2 §8.
//
// Fixed-height numeric keypad. Layout per PRD → Layout Primitives:
//
//   7 8 9 ⌫
//   4 5 6 .
//   1 2 3
//   0 00 C
//
// Notes:
//   - The decimal key is greyed out when `decimals == 0` (JPY).
//   - The `00` key pastes two zeros via two `onDigit(0)` calls.
//   - `C` clears the amount (calls `onClear`).
//   - Save lives in the AppBar, not the keypad — keep the surface
//     numeric-only so the user can type quickly with one thumb.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    super.key,
    required this.decimals,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onClear,
  });

  final int decimals;
  final ValueChanged<int> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

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
            _IconKey(
              icon: Icons.backspace_outlined,
              tooltip: l10n.txKeypadBackspace,
              onTap: onBackspace,
            ),
          ]),
          _row([
            _DigitKey(label: '4', onTap: () => onDigit(4)),
            _DigitKey(label: '5', onTap: () => onDigit(5)),
            _DigitKey(label: '6', onTap: () => onDigit(6)),
            _DigitKey(label: '.', onTap: decimalEnabled ? onDecimal : null),
          ]),
          _row([
            _DigitKey(label: '1', onTap: () => onDigit(1)),
            _DigitKey(label: '2', onTap: () => onDigit(2)),
            _DigitKey(label: '3', onTap: () => onDigit(3)),
            const _SpacerKey(),
          ]),
          _row([
            _DigitKey(label: '0', onTap: () => onDigit(0)),
            _DigitKey(
              label: '00',
              onTap: () {
                onDigit(0);
                onDigit(0);
              },
            ),
            _DigitKey(label: 'C', tooltip: l10n.txKeypadClear, onTap: onClear),
            const _SpacerKey(),
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
  const _DigitKey({required this.label, required this.onTap, this.tooltip});
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final colors = Theme.of(context).colorScheme;
    final button = SizedBox(
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
    if (tooltip != null) return Tooltip(message: tooltip!, child: button);
    return button;
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(child: Icon(icon)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpacerKey extends StatelessWidget {
  const _SpacerKey();
  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 56, child: SizedBox.shrink());
}
