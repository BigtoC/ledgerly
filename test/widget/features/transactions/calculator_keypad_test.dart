// CalculatorKeypad widget tests — Wave 2 §4.3.
//
// Covers:
//   - Decimal point disabled when `decimals = 0` (JPY).
//   - Decimal point enabled when `decimals > 0` (USD).
//   - Digit overflow after max decimals reached: extra digits drop on
//     the floor (clamping is the helper's job, but the widget must keep
//     calling `onDigit` so we can verify the clamp's downstream effect
//     when the screen plumbs both into the controller).
//   - Operator keys (÷ × − +) emit the correct CalcOperator enum values.
//   - The 5 × 4 grid (issue #144): AC, %, = and Save fire their callbacks;
//     = and Save are disabled without one.
//   - Long-pressing ⌫ triggers onClear.
//   - Old 00 / C keys are gone.
//   - Text scale clamping at 1.5×.
//   - Key taps fire a light haptic; the disabled decimal key does not.

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/features/transactions/view_models/keypad_state.dart';
import 'package:ledgerly/ui/features/transactions/views/calculator_keypad.dart';

import '../../../support/text_scale.dart';

Widget _wrap(Widget child, {double? textScale}) => MaterialApp(
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: textScale == null ? null : textScaleBuilder(textScale),
  home: Scaffold(body: child),
);

/// A keypad whose callbacks default to no-ops. [onEquals] and [onSave] stay
/// null (disabled) unless given.
CalculatorKeypad _keypad({
  int decimals = 2,
  ValueChanged<int>? onDigit,
  VoidCallback? onDecimal,
  VoidCallback? onBackspace,
  VoidCallback? onClear,
  ValueChanged<CalcOperator>? onOperator,
  VoidCallback? onPercent,
  VoidCallback? onEquals,
  VoidCallback? onSave,
}) => CalculatorKeypad(
  decimals: decimals,
  onDigit: onDigit ?? (_) {},
  onDecimal: onDecimal ?? () {},
  onBackspace: onBackspace ?? () {},
  onClear: onClear ?? () {},
  onOperator: onOperator ?? (_) {},
  onPercent: onPercent ?? () {},
  onEquals: onEquals,
  onSave: onSave,
);

/// Records the haptic types requested via `HapticFeedback` during a test.
List<String?> _recordHaptics(WidgetTester tester) {
  final haptics = <String?>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      haptics.add(call.arguments as String?);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return haptics;
}

void main() {
  testWidgets('WK01: decimal point is enabled on USD (decimals = 2)', (
    tester,
  ) async {
    var decimalTaps = 0;
    await tester.pumpWidget(_wrap(_keypad(onDecimal: () => decimalTaps++)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('.'));
    expect(decimalTaps, 1);
  });

  testWidgets('WK02: decimal point is disabled on JPY (decimals = 0)', (
    tester,
  ) async {
    var decimalTaps = 0;
    await tester.pumpWidget(
      _wrap(_keypad(decimals: 0, onDecimal: () => decimalTaps++)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('.'));
    expect(decimalTaps, 0); // tap was a no-op (key disabled)
  });

  testWidgets(
    'WK04: digit overflow after max decimals — KeypadState clamps the 4th frac digit',
    (tester) async {
      // Drives the helper directly through the keypad's onDigit callback
      // to verify the round-trip stays clamped at currency.decimals.
      var keypad = const KeypadState.initial();
      const decimals = 2;
      await tester.pumpWidget(
        _wrap(
          _keypad(
            decimals: decimals,
            onDigit: (d) {
              keypad = keypad.push(d, decimals: decimals);
            },
            onDecimal: () {
              keypad = keypad.pushDecimal(decimals: decimals);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Type "1.234" — the 4 must be dropped (decimals=2).
      await tester.tap(find.text('1'));
      await tester.tap(find.text('.'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      expect(keypad.amountMinorUnits, 123);
      expect(keypad.fractionalDigitsEntered, 2);
    },
  );

  testWidgets(
    'WK10: operator keys render and forward the expected enum values',
    (tester) async {
      final tapped = <CalcOperator>[];

      await tester.pumpWidget(_wrap(_keypad(onOperator: tapped.add)));

      expect(find.text('÷'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);
      expect(find.text('−'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.tap(find.text('−'));
      await tester.tap(find.text('×'));
      await tester.tap(find.text('÷'));

      expect(tapped, const [
        CalcOperator.add,
        CalcOperator.subtract,
        CalcOperator.multiply,
        CalcOperator.divide,
      ]);
    },
  );

  testWidgets('WK11: old 00 and C keys are gone', (tester) async {
    await tester.pumpWidget(_wrap(_keypad()));

    expect(find.text('00'), findsNothing);
    expect(find.text('C'), findsNothing);
  });

  testWidgets('WK12: long-pressing backspace triggers clear', (tester) async {
    var clearCount = 0;

    await tester.pumpWidget(_wrap(_keypad(onClear: () => clearCount++)));

    await tester.longPress(find.byTooltip('Backspace'));
    expect(clearCount, 1);
  });

  testWidgets('WK12b: backspace exposes a custom clear semantics action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(_keypad()));

    expect(
      tester.getSemantics(find.byIcon(Icons.backspace_outlined)),
      matchesSemantics(
        hasTapAction: true,
        hasFocusAction: true,
        hasLongPressAction: true,
        isFocusable: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        onLongPressHint: 'Clear amount',
        customActions: const [CustomSemanticsAction(label: 'Clear amount')],
      ),
    );

    handle.dispose();
  });

  testWidgets('WK13: operator keys expose localized semantics labels', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_keypad()));

    expect(find.bySemanticsLabel('Add'), findsOneWidget);
    expect(find.bySemanticsLabel('Subtract'), findsOneWidget);
    expect(find.bySemanticsLabel('Multiply'), findsOneWidget);
    expect(find.bySemanticsLabel('Divide'), findsOneWidget);
  });

  testWidgets('WK14: operator labels clamp at 1.5x text scale', (tester) async {
    await tester.pumpWidget(_wrap(_keypad(), textScale: 2.0));

    final plusText = tester.widget<Text>(find.text('+'));
    expect(plusText.textScaler!.scale(10), lessThanOrEqualTo(15.0));
    expect(find.text('+'), findsOneWidget);
    expect(find.text('÷'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WK15: every key tap fires a light haptic', (tester) async {
    final haptics = _recordHaptics(tester);
    await tester.pumpWidget(_wrap(_keypad()));

    await tester.tap(find.text('7'));
    await tester.tap(find.text('.'));
    await tester.tap(find.text('+'));
    await tester.tap(find.byTooltip('Backspace'));

    expect(haptics, List.filled(4, 'HapticFeedbackType.lightImpact'));
  });

  testWidgets('WK16: the disabled decimal key fires no haptic', (tester) async {
    final haptics = _recordHaptics(tester);
    await tester.pumpWidget(_wrap(_keypad(decimals: 0)));

    await tester.tap(find.text('.'));

    expect(haptics, isEmpty);
  });

  group('key height follows the space given (issue #100, #144)', () {
    // Five rows share the height four rows of 48–56dp keys took before
    // issue #144, so a key is (height − 16) / 5 − 8: the SafeArea minimum
    // above and below, and 4dp of padding above and below each key.
    Widget keypad() => _keypad();

    /// Hosts the keypad at the bottom of [height] dp, as the form does.
    Widget hostWithHeight(double height) => _wrap(
      Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(height: height, child: keypad()),
      ),
    );

    double keyHeight(WidgetTester tester) => tester
        .getSize(
          find
              .ancestor(of: find.text('7'), matching: find.byType(Material))
              .first,
        )
        .height;

    testWidgets('WK17: keys are 43.2dp when there is room', (tester) async {
      // 4 × (56 + 8) / 5 − 8: the height of four 56dp rows, in five.
      await tester.pumpWidget(hostWithHeight(400));

      expect(keyHeight(tester), closeTo(43.2, 0.01));
    });

    testWidgets('WK18: keys are 43.2dp under unbounded height', (tester) async {
      // The recurring rule form puts the keypad in a plain Column.
      await tester.pumpWidget(
        _wrap(Column(mainAxisSize: MainAxisSize.min, children: [keypad()])),
      );

      expect(keyHeight(tester), closeTo(43.2, 0.01));
    });

    testWidgets('WK19: keys shrink to fill a shorter space', (tester) async {
      // (248 − 16) / 5 − 8.
      await tester.pumpWidget(hostWithHeight(248));

      expect(keyHeight(tester), closeTo(38.4, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('WK20: with less room than minHeight, keys still fit', (
      tester,
    ) async {
      // The screen reserves `minHeight` when it can. With less room still
      // (a landscape phone's dialog), shrinking further beats clipping the
      // bottom row. (200 − 16) / 5 − 8.
      await tester.pumpWidget(hostWithHeight(200));

      expect(keyHeight(tester), closeTo(28.8, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('WK21: minHeight is unchanged and gives 36.8dp keys', (
      tester,
    ) async {
      // 8 + 4 × (48 + 8) + 8: what four rows of 48dp keys took.
      expect(CalculatorKeypad.minHeight, 240);
      await tester.pumpWidget(hostWithHeight(CalculatorKeypad.minHeight));

      expect(keyHeight(tester), closeTo(36.8, 0.01));
    });
  });

  group('5 × 4 grid (issue #144)', () {
    Finder key(String label) => switch (label) {
      '⌫' => find.byTooltip('Backspace'),
      'save' => find.byTooltip('Save'),
      _ => find.text(label),
    };

    testWidgets('WK30: keys sit in the issue #144 grid', (tester) async {
      await tester.pumpWidget(_wrap(_keypad()));

      const rows = [
        ['AC', '%', '⌫', '÷'],
        ['7', '8', '9', '×'],
        ['4', '5', '6', '−'],
        ['1', '2', '3', '+'],
        ['save', '0', '.', '='],
      ];
      for (var r = 0; r < rows.length; r++) {
        for (var c = 0; c < 4; c++) {
          final center = tester.getCenter(key(rows[r][c]));
          expect(
            center.dy,
            tester.getCenter(key(rows[r][0])).dy,
            reason: rows[r][c],
          );
          expect(
            center.dx,
            tester.getCenter(key(rows[0][c])).dx,
            reason: rows[r][c],
          );
          if (r > 0) {
            expect(
              center.dy,
              greaterThan(tester.getCenter(key(rows[r - 1][c])).dy),
              reason: rows[r][c],
            );
          }
        }
      }
    });

    testWidgets('WK31: AC, %, = and Save fire their callbacks', (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        _wrap(
          _keypad(
            onClear: () => pressed.add('AC'),
            onPercent: () => pressed.add('%'),
            onEquals: () => pressed.add('='),
            onSave: () => pressed.add('save'),
          ),
        ),
      );

      for (final label in ['AC', '%', '=', 'save']) {
        await tester.tap(key(label));
      }

      expect(pressed, ['AC', '%', '=', 'save']);
    });

    testWidgets('WK32: = and Save are disabled without a callback', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(_wrap(_keypad()));

      await tester.tap(key('='));
      await tester.tap(key('save'));

      expect(haptics, isEmpty);
      final equals = find.ancestor(
        of: key('='),
        matching: find.byType(InkWell),
      );
      final save = find.descendant(
        of: key('save'),
        matching: find.byType(InkWell),
      );
      for (final inkWell in [equals.first, save]) {
        expect(tester.widget<InkWell>(inkWell).onTap, isNull);
      }
    });

    testWidgets('WK32b: screen readers hear when = and Save are disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_keypad()));

      expect(
        tester.getSemantics(find.text('=')),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      expect(
        tester.getSemantics(find.byIcon(Icons.save_outlined)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );

      await tester.pumpWidget(_wrap(_keypad(onEquals: () {}, onSave: () {})));
      expect(
        tester.getSemantics(find.text('=')),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.byIcon(Icons.save_outlined)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('WK33: the new keys fire a light haptic', (tester) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(_wrap(_keypad(onEquals: () {}, onSave: () {})));

      for (final label in ['AC', '%', '=', 'save']) {
        await tester.tap(key(label));
      }

      expect(haptics, List.filled(4, 'HapticFeedbackType.lightImpact'));
    });

    testWidgets('WK34: the new keys expose localized semantics labels', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_keypad(onEquals: () {}, onSave: () {})));

      expect(find.bySemanticsLabel('Clear amount'), findsOneWidget);
      expect(find.bySemanticsLabel('Percent'), findsOneWidget);
      expect(find.bySemanticsLabel('Equals'), findsOneWidget);
      expect(
        tester.getSemantics(find.byIcon(Icons.save_outlined)),
        isSemantics(tooltip: 'Save', hasTapAction: true),
      );
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('WK35: every label fits its key at ${scale}x text', (
        tester,
      ) async {
        // The smallest keys the form reserves room for, on a phone.
        await tester.pumpWidget(
          _wrap(
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 390,
                height: CalculatorKeypad.minHeight,
                child: _keypad(),
              ),
            ),
            textScale: scale,
          ),
        );

        expect(tester.takeException(), isNull);
        final labels = find.descendant(
          of: find.byType(CalculatorKeypad),
          matching: find.byType(Text),
        );
        expect(labels, findsNWidgets(18));
        for (final label in labels.evaluate()) {
          final paragraph = label.renderObject! as RenderParagraph;
          final key = tester.getSize(
            find
                .ancestor(
                  of: find.byWidget(label.widget),
                  matching: find.byType(Material),
                )
                .first,
          );
          final text = (label.widget as Text).data;
          expect(
            paragraph.textSize.height,
            lessThanOrEqualTo(key.height),
            reason: text,
          );
          expect(
            paragraph.textSize.width,
            lessThanOrEqualTo(key.width),
            reason: text,
          );
        }
      });
    }
  });
}
