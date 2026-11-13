// `CalculatorKeypad` — Wave 2 §8, issue #144.
//
// Calculator keypad pinned below the form, laid out like a phone
// calculator. Layout per PRD → Layout Primitives:
//
//   AC  %  ⌫  ÷
//   7   8  9  ×
//   4   5  6  −
//   1   2  3  +
//   💾  0  .  =
//
// Notes:
//   - The decimal key is greyed out when `decimals == 0` (JPY).
//   - AC and long-pressing ⌫ both trigger `onClear`.
//   - Every enabled key tap fires a light haptic.
//   - Operator keys (÷ × − +) emit `CalcOperator` values via `onOperator`.
//   - `=` and Save (💾) are greyed out while their callback is null: `=`
//     while no expression is pending, Save while the page can't save. The
//     transaction form keeps its AppBar Save too, so the thumb that typed
//     the amount can save without reaching the top of the screen.
//   - Five rows share the height four rows of 48–56dp keys took before
//     issue #144, so key faces are about 37–43dp tall. A key takes presses
//     over its whole cell, the 4dp around its face included, which is about
//     45–51dp tall (PRD → Accessibility). Given less height than
//     [minHeight], the keys shrink further (issue #100).

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/redirect_to_center.dart';
import '../view_models/keypad_state.dart';

class const CalculatorKeypad({
  super.key,
  required final int decimals,
  required final ValueChanged<int> onDigit,
  required final VoidCallback onDecimal,
  required final VoidCallback onBackspace,
  required final VoidCallback onClear,
  required final ValueChanged<CalcOperator> onOperator,
  required final VoidCallback onPercent,

  /// Finishes the pending calculation. Null greys `=` out.
  required final VoidCallback? onEquals,

  /// Saves what the page is editing. Null greys Save out.
  required final VoidCallback? onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget digit(int d) => _TextKey(label: '$d', onTap: () => onDigit(d));
    Widget operator(String label, String semanticsLabel, CalcOperator op) =>
        _TextKey(
          label: label,
          semanticsLabel: semanticsLabel,
          onTap: () => onOperator(op),
          accent: true,
        );
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Five rows, each with 4dp of padding above and below its keys.
          // The screen reserves [minHeight] when it can; given less, the
          // keys shrink further rather than clip the bottom row.
          final keyHeight = (constraints.maxHeight / 5 - 8).clamp(
            0.0,
            _maxKeyHeight,
          );
          Widget row(List<Widget> keys) => _row(keys, keyHeight);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row([
                _TextKey(
                  label: 'AC',
                  semanticsLabel: l10n.txKeypadClear,
                  onTap: onClear,
                ),
                _TextKey(
                  label: '%',
                  semanticsLabel: l10n.txKeypadPercent,
                  onTap: onPercent,
                ),
                _IconKey(
                  icon: Icons.backspace_outlined,
                  tooltip: l10n.txKeypadBackspace,
                  onTap: onBackspace,
                  onLongPress: onClear,
                ),
                operator('÷', l10n.txKeypadDivide, CalcOperator.divide),
              ]),
              row([
                digit(7),
                digit(8),
                digit(9),
                operator('×', l10n.txKeypadMultiply, CalcOperator.multiply),
              ]),
              row([
                digit(4),
                digit(5),
                digit(6),
                operator('−', l10n.txKeypadSubtract, CalcOperator.subtract),
              ]),
              row([
                digit(1),
                digit(2),
                digit(3),
                operator('+', l10n.txKeypadAdd, CalcOperator.add),
              ]),
              row([
                _IconKey(
                  icon: Icons.save_outlined,
                  tooltip: l10n.commonSave,
                  onTap: onSave,
                ),
                digit(0),
                _TextKey(label: '.', onTap: decimals > 0 ? onDecimal : null),
                _TextKey(
                  label: '=',
                  semanticsLabel: l10n.txKeypadEquals,
                  onTap: onEquals,
                  accent: true,
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  /// The height the screen reserves for the keypad: what four rows of 48dp
  /// keys took before issue #144 added a fifth. Five rows of 36.8dp keys
  /// share it now, each key with 4dp of padding above and below, plus the
  /// 8dp minimum padding above and below the keypad. A screen whose
  /// SafeArea has already taken the bottom inset can count on it.
  static const double minHeight = 4 * (48 + 8) + 16;

  /// The height four rows of 56dp keys took, shared by five rows.
  static const double _maxKeyHeight = 4 * (56 + 8) / 5 - 8;

  Widget _row(List<Widget> children, double keyHeight) {
    return SizedBox(
      height: keyHeight + 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in children)
            Expanded(
              // A press in the 4dp around a key's face, or on the face's
              // clipped corners, goes to the key, so none falls between
              // two keys (issue #159).
              child: RedirectToCenter(
                child: Padding(padding: const EdgeInsets.all(4), child: c),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wraps a key's tap handler so it fires a light haptic first. A null
/// handler stays null so disabled keys keep their disabled styling.
VoidCallback? _withHaptic(VoidCallback? onTap) {
  if (onTap == null) return null;
  return () {
    HapticFeedback.lightImpact();
    onTap();
  };
}

/// The background of a key, greyed out while [onTap] is null.
Color _keyColor(
  ColorScheme colors,
  VoidCallback? onTap, {
  bool accent = false,
}) {
  if (onTap == null) {
    return colors.surfaceContainerHighest.withValues(alpha: 0.4);
  }
  return accent ? colors.primaryContainer : colors.surfaceContainerHigh;
}

class const _TextKey({
  required final String label,
  required final VoidCallback? onTap,

  /// Read out instead of [label], for keys whose glyph isn't a word.
  final String? semanticsLabel,

  /// Operator keys take the primary container colour.
  final bool accent = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clamped = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    final foreground = accent ? colors.onPrimaryContainer : colors.onSurface;
    Widget child = Center(
      child: Text(
        label,
        textScaler: clamped,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: onTap == null
              ? colors.onSurface.withValues(alpha: 0.4)
              : foreground,
        ),
      ),
    );
    if (semanticsLabel != null) {
      child = Semantics(
        label: semanticsLabel,
        button: true,
        enabled: onTap != null,
        child: ExcludeSemantics(child: child),
      );
    }
    return Material(
      color: _keyColor(colors, onTap, accent: accent),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: _withHaptic(onTap), child: child),
    );
  }
}

class const _IconKey({
  required final IconData icon,
  required final String tooltip,
  required final VoidCallback? onTap,

  /// Clears the amount; announced as a custom semantics action.
  final VoidCallback? onLongPress,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      onLongPressHint: onLongPress == null ? null : l10n.txKeypadClear,
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.txKeypadClear): ?onLongPress,
      },
      child: Material(
        color: _keyColor(colors, onTap),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        // Inside the Material's clip, so that a press on a clipped corner
        // misses the tooltip too and goes to the key's centre.
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: _withHaptic(onTap),
            onLongPress: onLongPress,
            child: Center(
              child: Icon(
                icon,
                color: onTap == null
                    ? colors.onSurface.withValues(alpha: 0.4)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
