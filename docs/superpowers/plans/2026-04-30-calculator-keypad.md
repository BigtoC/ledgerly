# Calculator Keypad Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add inline calculator operations (`+`, `−`, `×`, `÷`) to the transaction form keypad so users can compute amounts without leaving the form.

**Architecture:** `KeypadState` remains the single calculator state machine. Add expression fields plus `hasCurrentInput` so the reducer can distinguish an empty right operand from an explicitly entered `0`; this is required for operator correction (`12 ×` then `−`) and for true divide-by-zero behavior (`12 ÷ 0`). Arithmetic stays integer-only: `+` / `−` are direct minor-unit math, `×` rounds half-up `(left * right) / unit`, and `÷` rounds half-up `(left * unit) / right` with `BigInt` helpers only. Because expression-only transitions can leave `amountMinorUnits` unchanged, add a `keypadRevision` field to `TransactionFormState.data` and bump it on every keypad mutation so Riverpod still rebuilds the form for operator correction and decimal-start states. `AmountDisplay` keeps the current live-entry preview while typing, but once `showingResult == true` both the expression line and the main result use `MoneyFormatter.formatBare(...)` so evaluated math is locale-aware and fixed-precision; the currency-change placeholder is suppressed whenever calculator expression state is active.

**Tech Stack:** Flutter, Riverpod, shared `MoneyFormatter` (backed by `intl`), mocktail-based unit/widget tests, Flutter l10n (`flutter gen-l10n`)

**Spec:** `docs/superpowers/specs/2026-04-30-calculator-keypad-design.md` (update this in the same change so it stays consistent with the plan)

**Scope Notes:**
- This plan ships the full agreed calculator slice in one change: state-machine updates, keypad UI, display formatting, controller/screen wiring, localization, and verification.
- Before each verification sequence below, run `dart format .`
- Snippets below pin down the non-obvious contracts. Use smaller repo-native edits when possible; do not treat every snippet as a required literal patch if a simpler equivalent keeps the same invariants and tests green.
- Intermediate commits are optional checkpoint boundaries, not required output of the plan.

---

## File Structure

| File                                                                                | Responsibility                                                                                            |
|-------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `lib/features/transactions/keypad_state.dart`                                       | Pure calculator state machine: expression fields, empty-vs-zero operand tracking, integer-only evaluation |
| `lib/features/transactions/widgets/calculator_keypad.dart`                          | 4x4 keypad layout, operator buttons, localized semantics labels, long-press clear, text-scale clamp       |
| `lib/features/transactions/widgets/amount_display.dart`                             | Expression line + fixed-precision evaluated result rendering                                              |
| `lib/features/transactions/transaction_form_controller.dart`                        | `applyOperator()`, `keypadRevision` mirroring, destructive-input gating for account/currency changes      |
| `lib/features/transactions/transaction_form_screen.dart`                            | Wire `onOperator`, expand destructive dialogs to cover active keypad input                                |
| `lib/features/transactions/transaction_form_state.dart`                             | Add `keypadRevision` so expression-only keypad changes trigger rebuilds                                   |
| `docs/superpowers/specs/2026-04-30-calculator-keypad-design.md`                     | Keep the referenced design spec aligned with the final calculator contract                                |
| `test/unit/utils/keypad_decimal_math_test.dart`                                     | Calculator arithmetic and state-transition tests                                                          |
| `test/widget/features/transactions/calculator_keypad_test.dart`                     | Keypad layout, semantics, long-press clear, text-scale behavior                                           |
| `test/widget/features/transactions/amount_display_test.dart`                        | Expression-line and fixed-result formatting tests                                                         |
| `test/unit/controllers/transaction_form_controller_test.dart`                       | Controller command tests using the existing mocktail + `ProviderContainer` harness                        |
| `test/widget/features/transactions/transaction_form_screen_test.dart`               | Screen-level operator flow, invalid-op save gating, destructive-change dialogs                            |
| `test/unit/l10n/arb_audit_test.dart`                                                | Keep the ARB inventory test aligned with new operator semantics keys                                      |
| `test/integration/transaction_mutation_flow_test.dart`                              | Update duplicate/edit clear interactions away from the removed `C` key                                    |
| `l10n/app_en.arb` / `l10n/app_zh.arb` / `l10n/app_zh_CN.arb` / `l10n/app_zh_TW.arb` | Localized semantics/dialog copy; keep the fallback `app_zh.arb` shim intact                               |
| `lib/l10n/app_localizations*.dart`                                                  | Generated after `flutter gen-l10n`                                                                        |

---

## Chunk 0: Spec Sync

### Task 0: Sync the referenced design spec first

**Files:**
- Modify: `docs/superpowers/specs/2026-04-30-calculator-keypad-design.md`

- [ ] **Step 1: Update the spec to match the final contracts**

Before changing code, sync the spec so it matches the implementation plan for:
- `hasCurrentInput`
- integer-only `×` / `÷` math
- `keypadRevision`
- placeholder suppression during calculator states
- destructive dialog copy for active calculations
- accessible full-clear behavior

- [ ] **Step 2: Re-read the plan and spec together**

Expected: no contradictions between this plan and `docs/superpowers/specs/2026-04-30-calculator-keypad-design.md`

---

## Chunk 1: KeypadState — Contracts First

### Task 1: Add calculator fields and empty-vs-zero bookkeeping

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write the failing state-shape tests**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState — calculator fields', () {
  test('K60: initial state has no expression and no current input', () {
    const s = KeypadState.initial();

    expect(s.leftOperand, isNull);
    expect(s.operator, isNull);
    expect(s.isEvaluating, isFalse);
    expect(s.showingResult, isFalse);
    expect(s.rightOperand, isNull);
    expect(s.hasCurrentInput, isFalse);
    expect(s.hasExpression, isFalse);
    expect(s.hasVisibleInput, isFalse);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dart format . && flutter test test/unit/utils/keypad_decimal_math_test.dart --name K60`
Expected: FAIL because `hasCurrentInput` / expression fields do not exist yet

- [ ] **Step 3: Add `CalcOperator`, expression fields, `hasCurrentInput`, `hasExpression`, and `hasVisibleInput`**

In `lib/features/transactions/keypad_state.dart`:

```dart
enum CalcOperator { add, subtract, multiply, divide }

class KeypadState {
  const KeypadState({
    required this.amountMinorUnits,
    required this.fractionalDigitsEntered,
    required this.isFractionalMode,
    this.leftOperand,
    this.operator,
    this.isEvaluating = false,
    this.showingResult = false,
    this.rightOperand,
    this.hasCurrentInput = false,
  });

  const KeypadState.initial()
    : amountMinorUnits = 0,
      fractionalDigitsEntered = 0,
      isFractionalMode = false,
      leftOperand = null,
      operator = null,
      isEvaluating = false,
      showingResult = false,
      rightOperand = null,
      hasCurrentInput = false;

  final int amountMinorUnits;
  final int fractionalDigitsEntered;
  final bool isFractionalMode;
  final int? leftOperand;
  final CalcOperator? operator;
  final bool isEvaluating;
  final bool showingResult;
  final int? rightOperand;
  final bool hasCurrentInput;

  bool get hasExpression =>
      leftOperand != null ||
      operator != null ||
      isEvaluating ||
      showingResult ||
      rightOperand != null;

  bool get hasVisibleInput => hasExpression || hasCurrentInput;
}
```

Update `==`, `hashCode`, and `toString()` to include every new calculator field, not only `hasCurrentInput`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `dart format . && flutter test test/unit/utils/keypad_decimal_math_test.dart --name K60`
Expected: PASS

---

### Task 2: Define arithmetic, operator correction, and explicit-zero behavior

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write the failing operator tests**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState.pushOperator', () {
  test('K69: operator on a truly untouched keypad is a no-op', () {
    const s = KeypadState.initial();

    final result = s.pushOperator(CalcOperator.add, decimals: 2);

    expect(result, s);
  });

  test('K70: first operator stores the left operand and clears the input', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2); // 12.00

    final result = s.pushOperator(CalcOperator.add, decimals: 2);

    expect(result.leftOperand, 1200);
    expect(result.operator, CalcOperator.add);
    expect(result.isEvaluating, isTrue);
    expect(result.amountMinorUnits, 0);
    expect(result.hasCurrentInput, isFalse);
  });

  test('K71: tapping a different operator before right input replaces the pending operator', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2)
        .pushOperator(CalcOperator.multiply, decimals: 2);

    final result = s.pushOperator(CalcOperator.subtract, decimals: 2);

    expect(result.leftOperand, 1200);
    expect(result.operator, CalcOperator.subtract);
    expect(result.amountMinorUnits, 0);
    expect(result.isEvaluating, isTrue);
    expect(result.hasCurrentInput, isFalse);
  });

  test('K72: repeating the same operator with no right input is a no-op', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2);

    final result = s.pushOperator(CalcOperator.add, decimals: 2);
    expect(result, s);
  });

  test('K73: explicit integer zero counts as divide-by-zero input', () {
    final s = const KeypadState.initial()
        .push(7, decimals: 2)
        .pushOperator(CalcOperator.divide, decimals: 2)
        .push(0, decimals: 2);

    final result = s.pushOperator(CalcOperator.divide, decimals: 2);

    expect(result.amountMinorUnits, 0);
    expect(result.showingResult, isTrue);
    expect(result.rightOperand, 0);
  });

  test('K74: explicit fractional zero also counts as right input', () {
    final s = const KeypadState.initial()
        .push(7, decimals: 2)
        .pushOperator(CalcOperator.divide, decimals: 2)
        .pushDecimal(decimals: 2)
        .push(0, decimals: 2);

    final result = s.pushOperator(CalcOperator.divide, decimals: 2);

    expect(result.amountMinorUnits, 0);
    expect(result.showingResult, isTrue);
    expect(result.rightOperand, 0);
  });

  test('K80: 12 + 5 = 17', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2);

    final result = s.pushOperator(CalcOperator.add, decimals: 2);
    expect(result.amountMinorUnits, 1700);
  });

  test('K81: 150 - 50 = 100', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(5, decimals: 2)
        .push(0, decimals: 2)
        .pushOperator(CalcOperator.subtract, decimals: 2)
        .push(5, decimals: 2)
        .push(0, decimals: 2);

    final result = s.pushOperator(CalcOperator.subtract, decimals: 2);
    expect(result.amountMinorUnits, 10000);
  });

  test('K82: 2 × 3 = 6', () {
    final s = const KeypadState.initial()
        .push(2, decimals: 2)
        .pushOperator(CalcOperator.multiply, decimals: 2)
        .push(3, decimals: 2);

    final result = s.pushOperator(CalcOperator.multiply, decimals: 2);
    expect(result.amountMinorUnits, 600);
  });

  test('K83: 100 ÷ 3 = 33.33', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(0, decimals: 2)
        .push(0, decimals: 2)
        .pushOperator(CalcOperator.divide, decimals: 2)
        .push(3, decimals: 2);

    final result = s.pushOperator(CalcOperator.divide, decimals: 2);
    expect(result.amountMinorUnits, 3333);
  });

  test('K84: division half-up tie rounds up (1 ÷ 8 = 0.13)', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .pushOperator(CalcOperator.divide, decimals: 2)
        .push(8, decimals: 2);

    final result = s.pushOperator(CalcOperator.divide, decimals: 2);
    expect(result.amountMinorUnits, 13);
  });

  test('K85: multiplication half-up tie rounds up (0.05 × 0.10 = 0.01)', () {
    final s = const KeypadState.initial()
        .pushDecimal(decimals: 2)
        .push(0, decimals: 2)
        .push(5, decimals: 2)
        .pushOperator(CalcOperator.multiply, decimals: 2)
        .pushDecimal(decimals: 2)
        .push(1, decimals: 2)
        .push(0, decimals: 2);

    final result = s.pushOperator(CalcOperator.multiply, decimals: 2);
    expect(result.amountMinorUnits, 1);
  });

  test('K86: subtraction underflow clamps to zero', () {
    final s = const KeypadState.initial()
        .push(3, decimals: 2)
        .pushOperator(CalcOperator.subtract, decimals: 2)
        .push(5, decimals: 2);

    final result = s.pushOperator(CalcOperator.subtract, decimals: 2);
    expect(result.amountMinorUnits, 0);
    expect(result.showingResult, isTrue);
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart format . && flutter test test/unit/utils/keypad_decimal_math_test.dart --name "KeypadState.pushOperator"`
Expected: FAIL because `pushOperator()` does not exist and the reducer cannot yet distinguish empty vs explicit zero input

- [ ] **Step 3: Implement `pushOperator()` and integer-only arithmetic**

In `lib/features/transactions/keypad_state.dart`, add the operator reducer using `hasCurrentInput`:

```dart
KeypadState pushOperator(CalcOperator op, {required int decimals}) {
  if (!hasCurrentInput && !showingResult && !hasExpression) {
    return this;
  }

  if (isEvaluating && operator != null && leftOperand != null) {
    if (!hasCurrentInput) {
      if (op == operator) return this;
      return KeypadState(
        amountMinorUnits: 0,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: leftOperand,
        operator: op,
        isEvaluating: true,
        showingResult: false,
        rightOperand: null,
        hasCurrentInput: false,
      );
    }

    final right = amountMinorUnits;
    final result = _evaluate(
      leftOperand: leftOperand!,
      rightOperand: right,
      operator: operator!,
      decimals: decimals,
    );

    if (op == operator) {
      return KeypadState(
        amountMinorUnits: result,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: leftOperand,
        operator: operator,
        isEvaluating: false,
        showingResult: true,
        rightOperand: right,
        hasCurrentInput: false,
      );
    }

    return KeypadState(
      amountMinorUnits: 0,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: result,
      operator: op,
      isEvaluating: true,
      showingResult: false,
      rightOperand: null,
      hasCurrentInput: false,
    );
  }

  if (showingResult) {
    return KeypadState(
      amountMinorUnits: 0,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: amountMinorUnits,
      operator: op,
      isEvaluating: true,
      showingResult: false,
      rightOperand: null,
      hasCurrentInput: false,
    );
  }

  return KeypadState(
    amountMinorUnits: 0,
    fractionalDigitsEntered: 0,
    isFractionalMode: false,
    leftOperand: amountMinorUnits,
    operator: op,
    isEvaluating: true,
    showingResult: false,
    rightOperand: null,
    hasCurrentInput: false,
  );
}

static int _evaluate({
  required int leftOperand,
  required int rightOperand,
  required CalcOperator operator,
  required int decimals,
}) {
  final unit = BigInt.from(_pow10(decimals));
  return switch (operator) {
    CalcOperator.add => leftOperand + rightOperand,
    CalcOperator.subtract => (leftOperand - rightOperand).clamp(0, leftOperand),
    CalcOperator.multiply => _roundHalfUp(
      BigInt.from(leftOperand) * BigInt.from(rightOperand),
      unit,
    ),
    CalcOperator.divide => rightOperand == 0
        ? 0
        : _roundHalfUp(
            BigInt.from(leftOperand) * unit,
            BigInt.from(rightOperand),
          ),
  };
}

static int _roundHalfUp(BigInt numerator, BigInt denominator) {
  final adjusted = numerator + (denominator ~/ BigInt.from(2));
  return (adjusted ~/ denominator).toInt();
}
```

Keep the zero-result policy for subtraction underflow and divide-by-zero. The expression stays visible and the form remains unsaveable because `TransactionFormState.canSave` still requires `amountMinorUnits > 0`.
This untouched-state no-op relies on seeded non-zero amounts initializing `hasCurrentInput = true`; account for that when updating `_keypadFromAmount(...)` and any remaining direct `KeypadState(...)` constructors.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `dart format . && flutter test test/unit/utils/keypad_decimal_math_test.dart --name "KeypadState.pushOperator"`
Expected: PASS

---

### Task 3: Preserve expression state while editing the right operand

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write the failing mutator tests**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState — editing the current operand', () {
  test('K90: digit during evaluating preserves the pending expression', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2);

    final result = s.push(5, decimals: 2);

    expect(result.amountMinorUnits, 500);
    expect(result.leftOperand, 100);
    expect(result.operator, CalcOperator.add);
    expect(result.isEvaluating, isTrue);
    expect(result.hasCurrentInput, isTrue);
  });

  test('K91: decimal during evaluating marks the right operand as started', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2);

    final result = s.pushDecimal(decimals: 2);

    expect(result.leftOperand, 100);
    expect(result.operator, CalcOperator.add);
    expect(result.isEvaluating, isTrue);
    expect(result.hasCurrentInput, isTrue);
  });

  test('K92: digit during showingResult clears the old expression and starts fresh', () {
    final s = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      showingResult: true,
      rightOperand: 500,
      hasCurrentInput: false,
    );

    final result = s.push(3, decimals: 2);

    expect(result.amountMinorUnits, 300);
    expect(result.leftOperand, isNull);
    expect(result.operator, isNull);
    expect(result.showingResult, isFalse);
    expect(result.hasCurrentInput, isTrue);
  });

  test('K93: pop with an empty right operand cancels the expression', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2);

    final result = s.pop(decimals: 2);

    expect(result.amountMinorUnits, 1200);
    expect(result.leftOperand, isNull);
    expect(result.operator, isNull);
    expect(result.isEvaluating, isFalse);
    expect(result.hasCurrentInput, isTrue);
  });

  test('K94: pop with a non-empty right operand preserves the expression', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2);

    final result = s.pop(decimals: 2);

    expect(result.amountMinorUnits, 0);
    expect(result.leftOperand, 1200);
    expect(result.operator, CalcOperator.add);
    expect(result.isEvaluating, isTrue);
    expect(result.hasCurrentInput, isFalse);
  });

  test('K95: backspacing an explicit zero returns to the empty-right-operand state', () {
    final s = const KeypadState.initial()
        .push(7, decimals: 2)
        .pushOperator(CalcOperator.divide, decimals: 2)
        .push(0, decimals: 2);

    final result = s.pop(decimals: 2);

    expect(result.amountMinorUnits, 0);
    expect(result.operator, CalcOperator.divide);
    expect(result.isEvaluating, isTrue);
    expect(result.hasCurrentInput, isFalse);
  });

  test('K96: clear resets every expression field', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2);

    final result = s.clear();

    expect(result.amountMinorUnits, 0);
    expect(result.leftOperand, isNull);
    expect(result.operator, isNull);
    expect(result.isEvaluating, isFalse);
    expect(result.showingResult, isFalse);
    expect(result.rightOperand, isNull);
    expect(result.hasCurrentInput, isFalse);
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart format . && flutter test test/unit/utils/keypad_decimal_math_test.dart --name "K9|K96"`
Expected: FAIL because `push`, `pushDecimal`, and `pop` still drop or mis-track expression state

- [ ] **Step 3: Update `push`, `pushDecimal`, `pop`, and `clear()`**

Add one helper that preserves the active expression only while editing the current operand:

```dart
KeypadState _copyCurrentOperand({
  required int amountMinorUnits,
  required int fractionalDigitsEntered,
  required bool isFractionalMode,
  required bool hasCurrentInput,
}) {
  return KeypadState(
    amountMinorUnits: amountMinorUnits,
    fractionalDigitsEntered: fractionalDigitsEntered,
    isFractionalMode: isFractionalMode,
    leftOperand: isEvaluating ? leftOperand : null,
    operator: isEvaluating ? operator : null,
    isEvaluating: isEvaluating,
    showingResult: false,
    rightOperand: null,
    hasCurrentInput: hasCurrentInput,
  );
}
```

Then update the mutators with these rules:
- `push(...)`: if `showingResult`, clear the old expression and start a fresh current operand; otherwise preserve `leftOperand` / `operator` while `isEvaluating == true`
- `pushDecimal(...)`: when it successfully enters fractional mode, set `hasCurrentInput = true`; this is what makes `.0` different from “empty operand” and keeps zero-valued in-progress input visible
- `pop(...)`: if `showingResult`, first convert the result into a plain current operand and then backspace it; if `isEvaluating && !hasCurrentInput`, cancel the expression and restore `leftOperand`; if backspacing reduces the current operand to an empty zero state, set `hasCurrentInput = false`
- `clear()`: still return `const KeypadState.initial()`

- [ ] **Step 4: Run the full keypad-state suite**

Run: `dart format . && flutter test test/unit/utils/keypad_decimal_math_test.dart`
Expected: ALL PASS

---

## Chunk 2: CalculatorKeypad — Layout, Accessibility, Text Scale

### Task 4: Replace the keypad layout and add localized operator semantics

**Files:**
- Modify: `lib/features/transactions/widgets/calculator_keypad.dart`
- Modify: `test/widget/features/transactions/calculator_keypad_test.dart`
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_CN.arb`
- Modify: `l10n/app_zh_TW.arb`
- Generated: `lib/l10n/app_localizations*.dart`
- Reference: `lib/features/splash/widgets/splash_day_count.dart` for the repo's `textScaler.clamp(maxScaleFactor: 1.5)` pattern

- [ ] **Step 1: Add failing keypad widget tests**

Update `test/widget/features/transactions/calculator_keypad_test.dart`:

```dart
Widget _wrap(Widget child, {double? textScale}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: textScale == null
      ? null
      : (context, inner) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: inner!,
        ),
  home: Scaffold(body: child),
);

testWidgets('WK10: operator keys render and forward the expected enum values', (tester) async {
  final tapped = <CalcOperator>[];

  await tester.pumpWidget(
    _wrap(
      CalculatorKeypad(
        decimals: 2,
        onDigit: (_) {},
        onDecimal: () {},
        onBackspace: () {},
        onClear: () {},
        onOperator: tapped.add,
      ),
    ),
  );

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
});

testWidgets('WK11: old 00 and C keys are gone', (tester) async {
  await tester.pumpWidget(
    _wrap(
      CalculatorKeypad(
        decimals: 2,
        onDigit: (_) {},
        onDecimal: () {},
        onBackspace: () {},
        onClear: () {},
        onOperator: (_) {},
      ),
    ),
  );

  expect(find.text('00'), findsNothing);
  expect(find.text('C'), findsNothing);
});

testWidgets('WK12: long-pressing backspace triggers clear', (tester) async {
  var clearCount = 0;

  await tester.pumpWidget(
    _wrap(
      CalculatorKeypad(
        decimals: 2,
        onDigit: (_) {},
        onDecimal: () {},
        onBackspace: () {},
        onClear: () => clearCount++,
        onOperator: (_) {},
      ),
    ),
  );

  await tester.longPress(find.byTooltip('Backspace'));
  expect(clearCount, 1);
});

testWidgets('WK13: operator keys expose localized semantics labels', (tester) async {
  await tester.pumpWidget(
    _wrap(
      CalculatorKeypad(
        decimals: 2,
        onDigit: (_) {},
        onDecimal: () {},
        onBackspace: () {},
        onClear: () {},
        onOperator: (_) {},
      ),
    ),
  );

  expect(find.bySemanticsLabel('Add'), findsOneWidget);
  expect(find.bySemanticsLabel('Subtract'), findsOneWidget);
  expect(find.bySemanticsLabel('Multiply'), findsOneWidget);
  expect(find.bySemanticsLabel('Divide'), findsOneWidget);
});

testWidgets('WK14: operator labels clamp at 1.5x text scale', (tester) async {
  await tester.pumpWidget(
    _wrap(
      CalculatorKeypad(
        decimals: 2,
        onDigit: (_) {},
        onDecimal: () {},
        onBackspace: () {},
        onClear: () {},
        onOperator: (_) {},
      ),
      textScale: 2.0,
    ),
  );

  final plusText = tester.widget<Text>(find.text('+'));
  expect(plusText.textScaler!.scale(10), lessThanOrEqualTo(15.0));
  expect(find.text('+'), findsOneWidget);
  expect(find.text('÷'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

Also update any pre-existing keypad tests to pass `onOperator: (_) {}` and remove or rewrite the old `00`-key assertion instead of preserving it.
Add one more regression for the non-touch clear path and one zero-decimal regression proving the `.` key is disabled or a no-op when `decimals == 0`.

- [ ] **Step 2: Run the keypad tests to verify they fail**

Run: `dart format . && flutter test test/widget/features/transactions/calculator_keypad_test.dart`
Expected: FAIL because `CalculatorKeypad` is still numeric-only and has no operator semantics labels

- [ ] **Step 3: Add operator l10n keys for semantics labels**

In `l10n/app_en.arb` add:

```json
"txKeypadAdd": "Add",
"txKeypadSubtract": "Subtract",
"txKeypadMultiply": "Multiply",
"txKeypadDivide": "Divide",
```

Add the matching translations to `l10n/app_zh_CN.arb` and `l10n/app_zh_TW.arb`.
Keep `l10n/app_zh.arb` in the repo; add mirrored placeholders there only if the current `flutter gen-l10n` configuration requires them, but do not remove the fallback shim.

Update `test/unit/l10n/arb_audit_test.dart` to add these four keys to `_expectedEnKeys` so the ARB inventory test stays aligned with the new localization surface.

Run: `flutter gen-l10n`
Expected: generated `lib/l10n/app_localizations*.dart` updates successfully

- [ ] **Step 4: Replace the layout and add operator semantics**

In `lib/features/transactions/widgets/calculator_keypad.dart`:

```dart
import '../keypad_state.dart';
```

Add the callback:

```dart
final ValueChanged<CalcOperator> onOperator;
```

Replace the old layout with:

```dart
7 8 9 ÷
4 5 6 ×
1 2 3 −
. 0 ⌫ +
```

Implementation rules:
- Remove `00`, `C`, and `_SpacerKey`
- `_OperatorKey` uses `colorScheme.primaryContainer`
- The `.` key keeps its grid slot but is disabled or a no-op when `decimals == 0`
- `_DigitKey` and `_OperatorKey` clamp `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5)`
- `_OperatorKey` wraps the visible glyph in `Semantics(label: semanticsLabel, button: true)` + `ExcludeSemantics`
- `_IconKey` keeps the backspace tooltip, adds `onLongPressHint: l10n.txKeypadClear`, and exposes a `CustomSemanticsAction(label: l10n.txKeypadClear)` so full clear is reachable without requiring a touch long-press gesture

Representative constructor shape:

```dart
_OperatorKey(
  label: '+',
  semanticsLabel: l10n.txKeypadAdd,
  onTap: () => onOperator(CalcOperator.add),
)
```

- [ ] **Step 5: Run the keypad tests again**

Run: `dart format . && flutter test test/widget/features/transactions/calculator_keypad_test.dart`
Expected: ALL PASS

---

## Chunk 3: AmountDisplay — Expression Line And Result Formatting

### Task 5: Add display tests for expression history and fixed-precision results

**Files:**
- Create: `test/widget/features/transactions/amount_display_test.dart`

- [ ] **Step 1: Write the failing display tests**

Create `test/widget/features/transactions/amount_display_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/transactions/keypad_state.dart';
import 'package:ledgerly/features/transactions/widgets/amount_display.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _wrap(Widget child, {double? textScale}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: textScale == null
      ? null
      : (context, inner) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: inner!,
        ),
  home: Scaffold(body: child),
);

final _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
final _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

void main() {
  testWidgets('AD01: no expression state renders no expression line', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AmountDisplay(
          keypad: KeypadState.initial(),
          currency: null,
        ),
      ),
    );

    expect(find.textContaining('='), findsNothing);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('AD02: evaluating state shows the left operand and operator', (tester) async {
    final keypad = KeypadState(
      amountMinorUnits: 500,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      isEvaluating: true,
      hasCurrentInput: true,
    );

    await tester.pumpWidget(_wrap(AmountDisplay(keypad: keypad, currency: _usd)));

    expect(find.textContaining('12.00 +'), findsOneWidget);
  });

  testWidgets('AD03: showingResult keeps expression history on the first line', (tester) async {
    final keypad = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      showingResult: true,
      rightOperand: 500,
      hasCurrentInput: false,
    );

    await tester.pumpWidget(_wrap(AmountDisplay(keypad: keypad, currency: _usd)));

    expect(find.textContaining('12.00 + 5.00 ='), findsOneWidget);
  });

  testWidgets('AD04: showingResult renders the main result at fixed precision', (tester) async {
    final keypad = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      showingResult: true,
      rightOperand: 500,
      hasCurrentInput: false,
    );

    await tester.pumpWidget(_wrap(AmountDisplay(keypad: keypad, currency: _usd)));

    expect(find.text('17.00'), findsOneWidget);
  });

  testWidgets('AD05: zero-decimal currencies keep zero-decimal formatting', (tester) async {
    final keypad = KeypadState(
      amountMinorUnits: 6,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 12,
      operator: CalcOperator.divide,
      showingResult: true,
      rightOperand: 2,
      hasCurrentInput: false,
    );

    await tester.pumpWidget(_wrap(AmountDisplay(keypad: keypad, currency: _jpy)));

    expect(find.textContaining('12 ÷ 2 ='), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('AD06: expression history and result remain visible at 2x text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final keypad = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      showingResult: true,
      rightOperand: 500,
      hasCurrentInput: false,
    );

    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: keypad, currency: _usd), textScale: 2.0),
    );

    expect(find.textContaining('12.00 + 5.00 ='), findsOneWidget);
    expect(find.text('17.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart format . && flutter test test/widget/features/transactions/amount_display_test.dart`
Expected: FAIL because `AmountDisplay` does not render expression history or fixed-precision evaluated results yet

Also cover the zero-valued decimal-start case: once the keypad has visible input, the currency placeholder stays hidden even if `amountMinorUnits == 0`.

---

### Task 6: Render the expression line and fixed-precision evaluated result with `MoneyFormatter`

**Files:**
- Modify: `lib/features/transactions/widgets/amount_display.dart`
- Reference: `lib/core/utils/money_formatter.dart`
- Test: `test/widget/features/transactions/amount_display_test.dart`

- [ ] **Step 1: Update `AmountDisplay` to use the shared formatter**

In `lib/features/transactions/widgets/amount_display.dart` add:

```dart
import '../../../core/utils/money_formatter.dart';
```

Then change the render contract:
- While typing (`showingResult == false`), keep the current `_renderAmountText()` preview behavior
- While showing a result (`showingResult == true`), render the main amount with `MoneyFormatter.formatBare(...)`
- The expression line ends at `=`; the main line carries the computed result
- The currency-change placeholder must be suppressed whenever `keypad.hasVisibleInput == true` so zero-valued calculator results and decimal-start input remain visible

Representative implementation shape:

```dart
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
  ...
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

  // Existing live-entry preview behavior for integer/fractional typing.
}

String? _buildExpressionText({required String locale}) {
  final c = currency;
  if (c == null) return null;

  if (keypad.isEvaluating && keypad.leftOperand != null && keypad.operator != null) {
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
```

Keep the expression line single-line with ellipsis, but the large-text tests must still prove the line remains visible on a realistic width.

- [ ] **Step 2: Run the display tests to verify they pass**

Run: `dart format . && flutter test test/widget/features/transactions/amount_display_test.dart`
Expected: ALL PASS

---

## Chunk 4: Controller And Screen Wiring

### Task 7: Add `applyOperator()` using the existing mock-based controller suite

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`
- Modify: `test/unit/controllers/transaction_form_controller_test.dart`
- Modify: `lib/features/transactions/transaction_form_state.dart`

- [ ] **Step 1: Add failing controller tests to the existing suite**

In `test/unit/controllers/transaction_form_controller_test.dart` add:

```dart
import 'package:ledgerly/features/transactions/keypad_state.dart';
```

```dart
group('calculator operators', () {
  test('TC33: applyOperator stores the left operand and enters evaluating', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(transactionFormControllerProvider.notifier);

    await controller.hydrateForAdd();
    controller.appendDigit(1);
    controller.appendDigit(2);
    controller.applyOperator(CalcOperator.add);

    expect(controller.keypadSnapshot.leftOperand, 1200);
    expect(controller.keypadSnapshot.operator, CalcOperator.add);
    expect(controller.keypadSnapshot.isEvaluating, isTrue);
    expect(controller.keypadSnapshot.amountMinorUnits, 0);
  });

  test('TC34: repeating the operator evaluates and mirrors the result to state', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(transactionFormControllerProvider.notifier);

    await controller.hydrateForAdd();
    controller.appendDigit(1);
    controller.appendDigit(2);
    controller.applyOperator(CalcOperator.add);
    controller.appendDigit(5);
    controller.applyOperator(CalcOperator.add);

    final data = c.read(transactionFormControllerProvider) as TransactionFormData;
    expect(controller.keypadSnapshot.amountMinorUnits, 1700);
    expect(controller.keypadSnapshot.showingResult, isTrue);
    expect(data.amountMinorUnits, 1700);
  });

  test('TC35: operator correction before right input replaces the pending operator', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(transactionFormControllerProvider.notifier);

    await controller.hydrateForAdd();
    controller.appendDigit(1);
    controller.applyOperator(CalcOperator.multiply);
    controller.applyOperator(CalcOperator.subtract);

    expect(controller.keypadSnapshot.leftOperand, 100);
    expect(controller.keypadSnapshot.operator, CalcOperator.subtract);
    expect(controller.keypadSnapshot.amountMinorUnits, 0);
  });

  test('TC35b: decimal-start while evaluating still increments the watched keypad revision', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(transactionFormControllerProvider.notifier);

    await controller.hydrateForAdd();
    controller.appendDigit(1);
    controller.applyOperator(CalcOperator.add);
    final before = (c.read(transactionFormControllerProvider) as TransactionFormData).keypadRevision;

    controller.appendDecimal();

    final after = (c.read(transactionFormControllerProvider) as TransactionFormData).keypadRevision;
    expect(after, greaterThan(before));
    expect(controller.keypadSnapshot.hasCurrentInput, isTrue);
  });

  test('TC35c: chaining with a different operator starts the next expression from the evaluated result', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    final controller = c.read(transactionFormControllerProvider.notifier);

    await controller.hydrateForAdd();
    controller.appendDigit(1);
    controller.appendDigit(2);
    controller.applyOperator(CalcOperator.add);
    controller.appendDigit(5);
    controller.applyOperator(CalcOperator.subtract);

    expect(controller.keypadSnapshot.leftOperand, 1700);
    expect(controller.keypadSnapshot.operator, CalcOperator.subtract);
    expect(controller.keypadSnapshot.isEvaluating, isTrue);
    expect(controller.keypadSnapshot.amountMinorUnits, 0);
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart format . && flutter test test/unit/controllers/transaction_form_controller_test.dart --name "TC33|TC34|TC35|TC35b|TC35c"`
Expected: FAIL because `applyOperator()` does not exist yet and `TransactionFormData` does not expose `keypadRevision`

- [ ] **Step 3: Implement `applyOperator()`**

First add `keypadRevision` to `TransactionFormState.data` in `lib/features/transactions/transaction_form_state.dart`, default it to `0` in all hydrations, and include it in generated equality / `copyWith`.
Update `_keypadFromAmount(...)` and any remaining direct `KeypadState(...)` call sites at the same time so the new calculator fields are initialized consistently; seeded non-zero amounts should set `hasCurrentInput = true` so edit/duplicate flows can start operators from the existing amount.

Because this changes a `@freezed` model, run codegen immediately after the field is added:

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `transaction_form_state.freezed.dart` regenerates cleanly

Then add a controller helper:

```dart
int _keypadRevision = 0;

TransactionFormData _copyWithKeypad(
  TransactionFormData s, {
  required bool isDirty,
}) {
  _keypadRevision += 1;
  return s.copyWith(
    amountMinorUnits: _keypad.amountMinorUnits,
    isDirty: isDirty,
    keypadRevision: _keypadRevision,
  );
}
```

Reset `_keypadRevision = 0` in every hydrate/reset path before returning fresh form state.
Use `_copyWithKeypad(...)` from every keypad mutation (`appendDigit`, `appendDecimal`, `backspace`, `clearAmount`, `applyOperator`) so expression-only transitions still rebuild the screen.

Representative `applyOperator()`:

```dart
void applyOperator(CalcOperator op) {
  final s = state;
  if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;

  final decimals = s.displayCurrency?.decimals ?? 2;
  _keypad = _keypad.pushOperator(op, decimals: decimals);
  state = _copyWithKeypad(s, isDirty: true);
}
```

- [ ] **Step 4: Run the tests again**

Run: `dart format . && flutter test test/unit/controllers/transaction_form_controller_test.dart --name "TC33|TC34|TC35|TC35b|TC35c"`
Expected: PASS

---

### Task 8: Treat active keypad input as destructive unsaved input when display currency would change

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`
- Modify: `test/unit/controllers/transaction_form_controller_test.dart`

- [ ] **Step 1: Add failing controller tests for destructive-expression gating**

Append to the same controller test file:

```dart
test('TC36: selectCurrency refuses without the clear flag when an expression is active and the visible amount is zero', () async {
  const eur = Currency(
    code: 'EUR',
    decimals: 2,
    symbol: '€',
    nameL10nKey: 'currency.eur',
  );

  final c = makeContainer();
  addTearDown(c.dispose);
  final controller = c.read(transactionFormControllerProvider.notifier);

  await controller.hydrateForAdd();
  controller.appendDigit(1);
  controller.applyOperator(CalcOperator.add); // amountMinorUnits == 0
  controller.selectCurrency(eur);

  final data = c.read(transactionFormControllerProvider) as TransactionFormData;
  expect(data.displayCurrency?.code, 'USD');
  expect(controller.keypadSnapshot.leftOperand, 100);
  expect(controller.keypadSnapshot.operator, CalcOperator.add);
});

test('TC37: selectCurrency with the clear flag clears the active expression', () async {
  const eur = Currency(
    code: 'EUR',
    decimals: 2,
    symbol: '€',
    nameL10nKey: 'currency.eur',
  );

  final c = makeContainer();
  addTearDown(c.dispose);
  final controller = c.read(transactionFormControllerProvider.notifier);

  await controller.hydrateForAdd();
  controller.appendDigit(1);
  controller.applyOperator(CalcOperator.add);
  controller.selectCurrency(eur, clearAmountOnChange: true);

  final data = c.read(transactionFormControllerProvider) as TransactionFormData;
  expect(data.displayCurrency?.code, 'EUR');
  expect(data.amountMinorUnits, 0);
  expect(controller.keypadSnapshot.hasExpression, isFalse);
});

test('TC38: selectAccount refuses without the clear flag when account reseeding would change displayCurrency during an active expression', () async {
  final c = makeContainer();
  addTearDown(c.dispose);
  final controller = c.read(transactionFormControllerProvider.notifier);

  await controller.hydrateForAdd();
  controller.appendDigit(1);
  controller.applyOperator(CalcOperator.add);
  controller.selectAccount(_accountJpy);

  final data = c.read(transactionFormControllerProvider) as TransactionFormData;
  expect(data.displayCurrency?.code, 'USD');
  expect(controller.keypadSnapshot.leftOperand, 100);
  expect(controller.keypadSnapshot.operator, CalcOperator.add);
});

test('TC39: selectAccount with the clear flag clears the active expression after the currency reseed', () async {
  final c = makeContainer();
  addTearDown(c.dispose);
  final controller = c.read(transactionFormControllerProvider.notifier);

  await controller.hydrateForAdd();
  controller.appendDigit(1);
  controller.applyOperator(CalcOperator.add);
  controller.selectAccount(_accountJpy, clearAmountOnCurrencyChange: true);

  final data = c.read(transactionFormControllerProvider) as TransactionFormData;
  expect(data.displayCurrency?.code, 'JPY');
  expect(data.amountMinorUnits, 0);
  expect(controller.keypadSnapshot.hasExpression, isFalse);
});
```

Add one same-currency account regression using an existing same-currency fixture so active keypad input does not trigger a destructive confirm when `displayCurrency` would stay the same.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart format . && flutter test test/unit/controllers/transaction_form_controller_test.dart --name "TC36|TC37|TC38|TC39"`
Expected: FAIL because the controller only guards on `amountMinorUnits > 0`

- [ ] **Step 3: Gate on amount or active keypad input in the controller**

In both `selectAccount(...)` and `selectCurrency(...)`, compute:

```dart
final hasDestructiveInput = s.amountMinorUnits > 0 || _keypad.hasVisibleInput;
final willChangeDisplayCurrency = ...;
```

Only require the clear flag when `willChangeDisplayCurrency && hasDestructiveInput`.
For account changes, this means same-currency switches must keep working without a destructive prompt even when the keypad has an active expression.

Leave the actual reset behavior unchanged after confirmation:
- if the successful change also changes `displayCurrency`, set `_keypad = const KeypadState.initial()`
- clear `amountMinorUnits` to `0`

- [ ] **Step 4: Run the full controller suite**

Run: `dart format . && flutter test test/unit/controllers/transaction_form_controller_test.dart`
Expected: ALL PASS

---

### Task 9: Wire the screen and expand destructive-change dialogs to cover active keypad input

**Files:**
- Modify: `lib/features/transactions/transaction_form_screen.dart`
- Modify: `test/widget/features/transactions/transaction_form_screen_test.dart`
- Modify: `l10n/app_en.arb`
- Reference: `l10n/app_zh.arb` (fallback shim must remain in the repo)
- Modify: `l10n/app_zh_CN.arb`
- Modify: `l10n/app_zh_TW.arb`
- Generated: `lib/l10n/app_localizations*.dart`
- Modify: `test/integration/transaction_mutation_flow_test.dart`

- [ ] **Step 1: Add failing screen tests**

In `test/widget/features/transactions/transaction_form_screen_test.dart` add:

```dart
import 'package:ledgerly/features/transactions/widgets/amount_display.dart';
```

Then add these widget tests:

```dart
testWidgets('WS22: operator flow shows expression history and a fixed-precision result', (tester) async {
  await tester.pumpWidget(mountAdd());
  await tester.pumpAndSettle();

  await tester.tap(find.text('1'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('2'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('5'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();

  final display = find.byType(AmountDisplay);
  expect(
    find.descendant(
      of: display,
      matching: find.textContaining('12.00 + 5.00 ='),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(of: display, matching: find.text('17.00')),
    findsOneWidget,
  );
});

testWidgets('WS23: changing currency during an active expression still shows the Change and Clear dialog even when the visible amount is zero', (tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(mountAdd());
  await tester.pumpAndSettle();

  await tester.tap(find.text('1'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(CurrencySelectorTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('JPY').first);
  await tester.pumpAndSettle();

  expect(
    find.text('Changing the currency will clear the current amount or calculation.'),
    findsOneWidget,
  );
  expect(find.text('Change and Clear'), findsOneWidget);
});

testWidgets('WS23b: changing account during an active expression shows the destructive dialog even when the visible amount is zero', (tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(mountAdd());
  await tester.pumpAndSettle();

  await tester.tap(find.text('1'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(AccountSelectorTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Yen').first);
  await tester.pumpAndSettle();

  expect(find.textContaining('amount or calculation'), findsOneWidget);
  expect(find.textContaining('Clear'), findsOneWidget);
});

testWidgets('WS24: confirming the destructive dialog clears the active expression and updates currency', (tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(mountAdd());
  await tester.pumpAndSettle();

  await tester.tap(find.text('1'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(CurrencySelectorTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('JPY').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Change and Clear'));
  await tester.pumpAndSettle();

  final tile = tester.widget<CurrencySelectorTile>(find.byType(CurrencySelectorTile));
  expect(tile.currency?.code, 'JPY');

  final display = find.byType(AmountDisplay);
  expect(
    find.descendant(of: display, matching: find.textContaining('1.00 +')),
    findsNothing,
  );
});

testWidgets('WS25: divide-by-zero leaves the form unsaveable and keeps the expression visible', (tester) async {
  await tester.pumpWidget(mountAdd());
  await tester.pumpAndSettle();

  await tester.tap(find.text('7'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('÷'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('0'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('÷'));
  await tester.pumpAndSettle();

  final saveButton = tester.widget<TextButton>(
    find.widgetWithText(TextButton, 'Save'),
  );
  expect(saveButton.onPressed, isNull);

  final display = find.byType(AmountDisplay);
  expect(
    find.descendant(
      of: display,
      matching: find.textContaining('7.00 ÷ 0.00 ='),
    ),
    findsOneWidget,
  );
});

testWidgets('WS25b: zero-valued evaluated results stay visible after a manual currency pick', (tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(mountAdd());
  await tester.pumpAndSettle();

  await tester.tap(find.byType(CurrencySelectorTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text('EUR').first);
  await tester.pumpAndSettle();

  await tester.tap(find.text('7'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('÷'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('0'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('÷'));
  await tester.pumpAndSettle();

  final display = find.byType(AmountDisplay);
  expect(
    find.descendant(
      of: display,
      matching: find.textContaining('7.00 ÷ 0.00 ='),
    ),
    findsOneWidget,
  );
  expect(find.descendant(of: display, matching: find.text('0.00')), findsOneWidget);
});

testWidgets('WS26: 2x text scale still shows the expression history and result', (tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(mountAdd(textScale: 2.0));
  await tester.pumpAndSettle();

  await tester.tap(find.text('1'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('5'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.pumpAndSettle();

  expect(find.text('+'), findsOneWidget);
  expect(find.textContaining('1.00 + 5.00 ='), findsOneWidget);
  expect(find.text('6.00'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run the screen tests to verify they fail**

Run: `dart format . && flutter test test/widget/features/transactions/transaction_form_screen_test.dart --name "WS22|WS23|WS23b|WS24|WS25|WS25b|WS26"`
Expected: FAIL because `CalculatorKeypad` is not wired to `applyOperator()`, the screen only treats non-zero amounts as destructive input, and zero-valued evaluated results can still hit the currency placeholder path

- [ ] **Step 3: Wire `onOperator` and expand the destructive-input checks**

In `lib/features/transactions/transaction_form_screen.dart`:

1. Wire the keypad:

```dart
CalculatorKeypad(
  decimals: state.displayCurrency?.decimals ?? 2,
  onDigit: controller.appendDigit,
  onDecimal: controller.appendDecimal,
  onBackspace: controller.backspace,
  onClear: controller.clearAmount,
  onOperator: controller.applyOperator,
)
```

2. In `_onTapAccountTile(...)` and `_onTapCurrencyTile(...)`, replace the local `hasAmount` check with:

```dart
final hasDestructiveInput =
    state.amountMinorUnits > 0 || controller.keypadSnapshot.hasVisibleInput;
final willChangeDisplayCurrency = ...;
```

Only show the destructive confirm when `willChangeDisplayCurrency && hasDestructiveInput`.

3. Update the dialog copy so it covers both raw amount entry and active calculations. Keep the account-triggered dialog account-specific and the manual currency dialog currency-specific; both bodies should mention that the current amount or calculation will be cleared. Change the existing l10n bodies in `app_en.arb`, `app_zh_CN.arb`, and `app_zh_TW.arb` to the equivalent of:

```json
"txCurrencyChangeConfirmBody": "Switching to this account changes the currency. The current amount or calculation will be cleared.",
"txCurrencyPickerChangeConfirmBody": "Changing the currency will clear the current amount or calculation.",
```

Do not remove `l10n/app_zh.arb`; keep the fallback shim in place even if it does not need every new key.

Then run: `flutter gen-l10n`
Expected: generated localization files update cleanly

4. Update the pre-existing `WS18` assertion in `test/widget/features/transactions/transaction_form_screen_test.dart` so it expects the new body string instead of `Changing the currency will clear the entered amount.`

5. Update `test/integration/transaction_mutation_flow_test.dart` to replace both `find.text('C')` taps with the new clear interaction. Prefer a small test helper that long-presses the backspace control so the duplicate/edit integration flow follows the shipped UI.

- [ ] **Step 4: Run the targeted screen tests again**

Run: `dart format . && flutter test test/widget/features/transactions/transaction_form_screen_test.dart --name "WS22|WS23|WS23b|WS24|WS25|WS25b|WS26"`
Expected: PASS

- [ ] **Step 5: Run the full transaction-form widget suite**

Run: `dart format . && flutter test test/widget/features/transactions/transaction_form_screen_test.dart`
Expected: ALL PASS

---

## Chunk 5: Final Verification

### Task 10: Regenerate, verify, and stop

**Files:**
- None (verification only)

Chunk-level tests above already cover the targeted feature areas. Final verification should be one end-state sweep, not a second copy of the same targeted matrix.

- [ ] **Step 1: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: generated localization files update cleanly

- [ ] **Step 2: Regenerate Freezed code after adding `keypadRevision`**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generated Freezed files update cleanly

- [ ] **Step 3: Format the repo**

Run: `dart format .`

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: no errors

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 6: Run import lint**

Run: `dart run import_lint`
Expected: PASS

- [ ] **Step 7: Optional final commit**

Create a final commit only if you want a clean handoff point after verification.
