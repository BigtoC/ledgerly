# Calculator Keypad Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add inline calculator operations (+, −, ×, ÷) to the transaction form keypad so users can compute amounts without leaving the form.

**Architecture:** Extend `KeypadState` with expression fields (leftOperand, operator, isEvaluating, showingResult). Add `pushOperator()` as the core evaluation method. Update `CalculatorKeypad` widget layout to include operator keys in the right column. Add expression line to `AmountDisplay`. Wire through `TransactionFormController`.

**Tech Stack:** Flutter, Riverpod, Freezed, Drift

**Spec:** `docs/superpowers/specs/2026-04-30-calculator-keypad-design.md`

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/features/transactions/keypad_state.dart` | Pure state machine — expression fields, `pushOperator()`, evaluation logic |
| `lib/features/transactions/widgets/calculator_keypad.dart` | Keypad widget — new 4×4 layout, operator keys, long-press ⌫ |
| `lib/features/transactions/widgets/amount_display.dart` | Display — expression line rendering for evaluating/result states |
| `lib/features/transactions/transaction_form_controller.dart` | Controller — `applyOperator()`, modified digit/backspace/clear methods |
| `test/unit/utils/keypad_decimal_math_test.dart` | Unit tests for `KeypadState` calculator operations |
| `test/widget/features/transactions/calculator_keypad_test.dart` | Widget tests for keypad layout and operator keys |

---

## Chunk 1: KeypadState — Pure State Machine

### Task 1: Add CalcOperator enum and new fields

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write failing test for new fields**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState — calculator expression fields', () {
  test('K60: initial state has no expression', () {
    const s = KeypadState.initial();
    expect(s.leftOperand, isNull);
    expect(s.operator, isNull);
    expect(s.isEvaluating, isFalse);
    expect(s.showingResult, isFalse);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K60`
Expected: FAIL — `leftOperand` not found on `KeypadState`

- [ ] **Step 3: Add CalcOperator enum and fields to KeypadState**

In `lib/features/transactions/keypad_state.dart`, add enum before `KeypadState` class:

```dart
enum CalcOperator { add, subtract, multiply, divide }
```

Add fields to `KeypadState` constructor and `initial()`:

```dart
class KeypadState {
  const KeypadState({
    required this.amountMinorUnits,
    required this.fractionalDigitsEntered,
    required this.isFractionalMode,
    this.leftOperand,
    this.operator,
    this.isEvaluating = false,
    this.showingResult = false,
  });

  const KeypadState.initial()
    : amountMinorUnits = 0,
      fractionalDigitsEntered = 0,
      isFractionalMode = false,
      leftOperand = null,
      operator = null,
      isEvaluating = false,
      showingResult = false;

  // ... existing fields ...
  final int? leftOperand;
  final CalcOperator? operator;
  final bool isEvaluating;
  final bool showingResult;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K60`
Expected: PASS

- [ ] **Step 5: Update ==, hashCode, toString**

Update `operator ==` to include new fields:

```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is KeypadState &&
      other.amountMinorUnits == amountMinorUnits &&
      other.fractionalDigitsEntered == fractionalDigitsEntered &&
      other.isFractionalMode == isFractionalMode &&
      other.leftOperand == leftOperand &&
      other.operator == operator &&
      other.isEvaluating == isEvaluating &&
      other.showingResult == showingResult;
}

@override
int get hashCode => Object.hash(
  amountMinorUnits,
  fractionalDigitsEntered,
  isFractionalMode,
  leftOperand,
  operator,
  isEvaluating,
  showingResult,
);

@override
String toString() =>
    'KeypadState(amountMinorUnits: $amountMinorUnits, '
    'fractionalDigitsEntered: $fractionalDigitsEntered, '
    'isFractionalMode: $isFractionalMode, '
    'leftOperand: $leftOperand, '
    'operator: $operator, '
    'isEvaluating: $isEvaluating, '
    'showingResult: $showingResult)';
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/transactions/keypad_state.dart test/unit/utils/keypad_decimal_math_test.dart
git commit -m "feat: add CalcOperator enum and expression fields to KeypadState"
```

---

### Task 2: Add pushOperator() method

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write failing tests for pushOperator**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState.pushOperator', () {
  test('K70: pushOperator(add) stores leftOperand and enters evaluating', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2); // 1200
    final result = s.pushOperator(CalcOperator.add, decimals: 2);
    expect(result.leftOperand, 1200);
    expect(result.operator, CalcOperator.add);
    expect(result.isEvaluating, isTrue);
    expect(result.amountMinorUnits, 0);
    expect(result.showingResult, isFalse);
  });

  test('K71: pushOperator(add) on evaluating state evaluates first', () {
    // 12 + 5 = 17, then push subtract
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2) // 1200
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2); // 500
    final result = s.pushOperator(CalcOperator.subtract, decimals: 2);
    expect(result.amountMinorUnits, 1700); // 12 + 5 = 17
    expect(result.leftOperand, 1700);
    expect(result.operator, CalcOperator.subtract);
    expect(result.isEvaluating, isTrue);
  });

  test('K72: pushOperator on showingResult chains from result', () {
    // After 12 + 5 = 17, tap multiply
    final s = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: null,
      operator: null,
      isEvaluating: false,
      showingResult: true,
    );
    final result = s.pushOperator(CalcOperator.multiply, decimals: 2);
    expect(result.leftOperand, 1700);
    expect(result.operator, CalcOperator.multiply);
    expect(result.isEvaluating, isTrue);
    expect(result.amountMinorUnits, 0);
    expect(result.showingResult, isFalse);
  });

  test('K73: pushOperator(add) on zero amount', () {
    final s = const KeypadState.initial();
    final result = s.pushOperator(CalcOperator.add, decimals: 2);
    expect(result.leftOperand, 0);
    expect(result.operator, CalcOperator.add);
    expect(result.isEvaluating, isTrue);
    expect(result.amountMinorUnits, 0);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K7`
Expected: FAIL — `pushOperator` not found

- [ ] **Step 3: Implement pushOperator()**

Add to `lib/features/transactions/keypad_state.dart` (after `clear()`):

```dart
/// Returns a new [KeypadState] with the operator applied.
///
/// Four paths:
/// 1. No expression active: stores current amount as leftOperand.
/// 2a. Evaluating, same operator: evaluates and shows result.
/// 2b. Evaluating, different operator: evaluates, chains result as leftOperand.
/// 3. Result showing: uses result as leftOperand, starts new expression.
KeypadState pushOperator(CalcOperator op, {required int decimals}) {
  // Path 2a/2b: evaluating — evaluate pending expression first
  if (isEvaluating && operator != null && leftOperand != null) {
    final result = _evaluate(
      leftOperand!,
      amountMinorUnits,
      operator!,
      decimals: decimals,
    );
    // Path 2a: same operator — evaluate and show result
    if (op == operator) {
      return KeypadState(
        amountMinorUnits: result,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        leftOperand: leftOperand,  // preserve for expression line
        operator: operator,        // preserve for expression line
        showingResult: true,
      );
    }
    // Path 2b: different operator — chain
    return KeypadState(
      amountMinorUnits: 0,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: result,
      operator: op,
      isEvaluating: true,
      showingResult: false,
    );
  }
  // Path 3: showing result — chain from result
  if (showingResult) {
    return KeypadState(
      amountMinorUnits: 0,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: amountMinorUnits,
      operator: op,
      isEvaluating: true,
      showingResult: false,
    );
  }
  // Path 1: no expression — store as left operand
  return KeypadState(
    amountMinorUnits: 0,
    fractionalDigitsEntered: 0,
    isFractionalMode: false,
    leftOperand: amountMinorUnits,
    operator: op,
    isEvaluating: true,
    showingResult: false,
  );
}

/// Evaluate a binary expression. Result clamps to non-negative.
/// Division rounds half-up to the currency's decimal precision.
static int _evaluate(
  int left,
  int right,
  CalcOperator op, {
  required int decimals,
}) {
  return switch (op) {
    CalcOperator.add => left + right,
    CalcOperator.subtract => (left - right).clamp(0, left),
    CalcOperator.multiply => left * right,
    CalcOperator.divide => right == 0
        ? 0
        : _roundHalfUp(left / right, decimals: decimals),
  };
}

/// Round half-up to the given decimal precision in minor units.
static int _roundHalfUp(double value, {required int decimals}) {
  final unit = _pow10(decimals);
  final shifted = value * unit;
  // Dart's round() uses half-away-from-zero, which matches half-up
  // for positive values.
  return shifted.round();
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K7`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/keypad_state.dart test/unit/utils/keypad_decimal_math_test.dart
git commit -m "feat: add pushOperator() with evaluation logic to KeypadState"
```

---

### Task 3: Add evaluation result tests

**Files:**
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write evaluation result tests**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState.pushOperator — evaluation results', () {
  test('K80: 12 + 5 = 17 (USD minor units)', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2) // 1200
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2); // 500
    // Evaluate by tapping add again
    final result = s.pushOperator(CalcOperator.add, decimals: 2);
    expect(result.amountMinorUnits, 1700);
    expect(result.leftOperand, 1200); // preserved for expression line
    expect(result.operator, CalcOperator.add); // preserved for expression line
    expect(result.isEvaluating, isFalse);
    expect(result.showingResult, isTrue);
  });

  test('K81: 150 - 50 = 100 (USD minor units)', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(5, decimals: 2) // 1500
        .pushOperator(CalcOperator.subtract, decimals: 2)
        .push(5, decimals: 0); // 50 — wait, this is wrong for decimals=2
    // Actually: 150 - 50 means leftOperand=15000, right=5000
    final s2 = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(5, decimals: 2)
        .push(0, decimals: 2) // 15000
        .pushOperator(CalcOperator.subtract, decimals: 2)
        .push(5, decimals: 2)
        .push(0, decimals: 2); // 5000
    final result = s2.pushOperator(CalcOperator.subtract, decimals: 2);
    expect(result.amountMinorUnits, 10000);
  });

  test('K82: 200 * 3 = 600 (USD minor units)', () {
    // leftOperand=20000, right=300
    final s = const KeypadState.initial()
        .push(2, decimals: 2) // 200
        .pushOperator(CalcOperator.multiply, decimals: 2)
        .push(3, decimals: 2); // 3
    final result = s.pushOperator(CalcOperator.multiply, decimals: 2);
    // 200 * 3 = 600 → 60000 minor units
    expect(result.amountMinorUnits, 60000);
  });

  test('K83: 100 / 3 = 33.33 (USD, half-up rounded) → 3333 minor units', () {
    // leftOperand=10000, right=300
    final s = const KeypadState.initial()
        .push(1, decimals: 2) // 100
        .pushOperator(CalcOperator.divide, decimals: 2)
        .push(3, decimals: 2); // 3
    final result = s.pushOperator(CalcOperator.divide, decimals: 2);
    expect(result.amountMinorUnits, 3333);
  });

  test('K84: 700 / 3 = 233.33 (USD, half-up rounded) → 23333 minor units', () {
    final s = const KeypadState.initial()
        .push(7, decimals: 2) // 700
        .pushOperator(CalcOperator.divide, decimals: 2)
        .push(3, decimals: 2); // 3
    final result = s.pushOperator(CalcOperator.divide, decimals: 2);
    expect(result.amountMinorUnits, 23333);
  });

  test('K85: negative result clamps to 0 (3 - 5)', () {
    final s = const KeypadState.initial()
        .push(3, decimals: 2) // 300
        .pushOperator(CalcOperator.subtract, decimals: 2)
        .push(5, decimals: 2); // 500
    final result = s.pushOperator(CalcOperator.subtract, decimals: 2);
    expect(result.amountMinorUnits, 0);
    expect(result.showingResult, isTrue);
  });

  test('K86: division by zero returns 0', () {
    final s = const KeypadState.initial()
        .push(7, decimals: 2) // 700
        .pushOperator(CalcOperator.divide, decimals: 2);
    // amountMinorUnits is still 0 (right operand not entered yet)
    final result = s.pushOperator(CalcOperator.divide, decimals: 2);
    expect(result.amountMinorUnits, 0);
  });

  test('K87: chain 12 + 5 - 3', () {
    // First: 12 + 5
    final s1 = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2) // 1200
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2); // 500
    // Tap subtract: evaluates 12+5=17, then stores 17 as left
    final s2 = s1.pushOperator(CalcOperator.subtract, decimals: 2);
    expect(s2.amountMinorUnits, 0); // right operand cleared
    expect(s2.leftOperand, 1700);
    expect(s2.operator, CalcOperator.subtract);
    // Enter 3 and evaluate
    final s3 = s2.push(3, decimals: 2); // 300
    final result = s3.pushOperator(CalcOperator.subtract, decimals: 2);
    expect(result.amountMinorUnits, 1400); // 17 - 3 = 14
  });
});
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K8`
Expected: PASS (logic already implemented in Task 2)

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/keypad_decimal_math_test.dart
git commit -m "test: add calculator evaluation result tests"
```

---

### Task 4: Modify push() for showingResult state

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write failing test**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState.push — showingResult state', () {
  test('K90: digit during showingResult clears expression and starts fresh', () {
    // Start from showingResult state (after evaluation, leftOperand/operator preserved)
    final s = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      isEvaluating: false,
      showingResult: true,
    );
    final result = s.push(3, decimals: 2);
    expect(result.amountMinorUnits, 300); // fresh 3, not 1700 + 3
    expect(result.leftOperand, isNull);
    expect(result.operator, isNull);
    expect(result.isEvaluating, isFalse);
    expect(result.showingResult, isFalse);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K90`
Expected: FAIL — result is 17300 instead of 300

- [ ] **Step 3: Modify push() to handle showingResult**

At the top of the `push()` method in `lib/features/transactions/keypad_state.dart`, add:

```dart
KeypadState push(int digit, {required int decimals}) {
  assert(digit >= 0 && digit <= 9, 'digit out of range: $digit');
  // If showing result, clear expression and start fresh
  if (showingResult) {
    return KeypadState(
      amountMinorUnits: digit * _pow10(decimals),
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
    );
  }
  // ... rest of existing push logic unchanged ...
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K90`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/keypad_state.dart test/unit/utils/keypad_decimal_math_test.dart
git commit -m "feat: clear expression on digit input during showingResult state"
```

---

### Task 5: Modify pop() for expression cancellation

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write failing test**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState.pop — expression cancellation', () {
  test('K95: pop during evaluating with amount=0 cancels expression', () {
    // 12 + (nothing typed yet) → backspace → cancel, restore 12
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2) // 1200
        .pushOperator(CalcOperator.add, decimals: 2);
    // amountMinorUnits is 0, leftOperand is 1200
    expect(s.amountMinorUnits, 0);
    expect(s.leftOperand, 1200);
    final result = s.pop(decimals: 2);
    expect(result.amountMinorUnits, 1200);
    expect(result.leftOperand, isNull);
    expect(result.operator, isNull);
    expect(result.isEvaluating, isFalse);
  });

  test('K96: pop during evaluating with amount>0 pops right operand digit', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2) // 1200
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2); // 500
    final result = s.pop(decimals: 2);
    expect(result.amountMinorUnits, 0); // 500 → 0 (single digit popped)
    expect(result.leftOperand, 1200); // expression preserved
    expect(result.operator, CalcOperator.add);
    expect(result.isEvaluating, isTrue);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K95`
Expected: FAIL

- [ ] **Step 3: Modify pop() for expression cancellation**

At the top of the `pop()` method in `lib/features/transactions/keypad_state.dart`, add before existing logic:

```dart
KeypadState pop({required int decimals}) {
  // Cancel expression if evaluating and right operand is empty
  if (isEvaluating && amountMinorUnits == 0 && leftOperand != null) {
    return KeypadState(
      amountMinorUnits: leftOperand!,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
    );
  }
  // ... rest of existing pop logic unchanged ...
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K9`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/keypad_state.dart test/unit/utils/keypad_decimal_math_test.dart
git commit -m "feat: cancel expression on backspace when right operand is empty"
```

---

### Task 6: Modify clear() to reset expression fields

**Files:**
- Modify: `lib/features/transactions/keypad_state.dart`
- Test: `test/unit/utils/keypad_decimal_math_test.dart`

- [ ] **Step 1: Write failing test**

Add to `test/unit/utils/keypad_decimal_math_test.dart`:

```dart
group('KeypadState.clear — expression reset', () {
  test('K98: clear resets expression fields', () {
    final s = const KeypadState.initial()
        .push(1, decimals: 2)
        .push(2, decimals: 2)
        .pushOperator(CalcOperator.add, decimals: 2)
        .push(5, decimals: 2);
    final result = s.clear();
    expect(result.amountMinorUnits, 0);
    expect(result.leftOperand, isNull);
    expect(result.operator, isNull);
    expect(result.isEvaluating, isFalse);
    expect(result.showingResult, isFalse);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K98`
Expected: FAIL — expression fields not reset

- [ ] **Step 3: Update clear() to reset expression fields**

The `clear()` method already returns `const KeypadState.initial()` which now includes the new fields with their default values. The test should pass as-is since we added defaults to the `initial()` constructor.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart --name K98`
Expected: PASS

- [ ] **Step 5: Run all KeypadState tests**

Run: `flutter test test/unit/utils/keypad_decimal_math_test.dart`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/transactions/keypad_state.dart test/unit/utils/keypad_decimal_math_test.dart
git commit -m "test: verify clear() resets expression fields"
```

---

## Chunk 2: CalculatorKeypad Widget

### Task 7: Add operator keys and new layout

**Files:**
- Modify: `lib/features/transactions/widgets/calculator_keypad.dart`
- Test: `test/widget/features/transactions/calculator_keypad_test.dart`

- [ ] **Step 1: Write failing tests for new layout**

Add to `test/widget/features/transactions/calculator_keypad_test.dart`:

```dart
testWidgets('WK10: operator keys render with correct labels', (tester) async {
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
  await tester.pumpAndSettle();
  expect(find.text('÷'), findsOneWidget);
  expect(find.text('×'), findsOneWidget);
  expect(find.text('−'), findsOneWidget);
  expect(find.text('+'), findsOneWidget);
});

testWidgets('WK11: onOperator callback fires with correct CalcOperator', (
  tester,
) async {
  final operators = <CalcOperator>[];
  await tester.pumpWidget(
    _wrap(
      CalculatorKeypad(
        decimals: 2,
        onDigit: (_) {},
        onDecimal: () {},
        onBackspace: () {},
        onClear: () {},
        onOperator: operators.add,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('+'));
  await tester.tap(find.text('−'));
  await tester.tap(find.text('×'));
  await tester.tap(find.text('÷'));
  expect(operators, [
    CalcOperator.add,
    CalcOperator.subtract,
    CalcOperator.multiply,
    CalcOperator.divide,
  ]);
});

testWidgets('WK12: 00 key is removed', (tester) async {
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
  await tester.pumpAndSettle();
  expect(find.text('00'), findsNothing);
});

testWidgets('WK13: C key is removed', (tester) async {
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
  await tester.pumpAndSettle();
  expect(find.text('C'), findsNothing);
});

testWidgets('WK14: long-press ⌫ triggers onClear', (tester) async {
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
  await tester.pumpAndSettle();
  await tester.longPress(find.byTooltip(AppLocalizations.of(
    tester.element(find.byType(CalculatorKeypad)),
  ).txKeypadBackspace));
  expect(clearCount, 1);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/features/transactions/calculator_keypad_test.dart --name WK1`
Expected: FAIL — `onOperator` parameter not found

- [ ] **Step 3: Add _OperatorKey widget and onOperator callback**

In `lib/features/transactions/widgets/calculator_keypad.dart`:

Add `onOperator` callback to `CalculatorKeypad`:

```dart
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
```

Add import at top:

```dart
import '../keypad_state.dart';
```

- [ ] **Step 4: Update layout to new 4×4 grid**

Replace the `build` method body with the new layout:

```dart
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
            onTap: () => onOperator(CalcOperator.divide),
          ),
        ]),
        _row([
          _DigitKey(label: '4', onTap: () => onDigit(4)),
          _DigitKey(label: '5', onTap: () => onDigit(5)),
          _DigitKey(label: '6', onTap: () => onDigit(6)),
          _OperatorKey(
            label: '×',
            onTap: () => onOperator(CalcOperator.multiply),
          ),
        ]),
        _row([
          _DigitKey(label: '1', onTap: () => onDigit(1)),
          _DigitKey(label: '2', onTap: () => onDigit(2)),
          _DigitKey(label: '3', onTap: () => onDigit(3)),
          _OperatorKey(
            label: '−',
            onTap: () => onOperator(CalcOperator.subtract),
          ),
        ]),
        _row([
          _DigitKey(
            label: '.',
            onTap: decimalEnabled ? onDecimal : null,
          ),
          _DigitKey(label: '0', onTap: () => onDigit(0)),
          _IconKey(
            icon: Icons.backspace_outlined,
            tooltip: l10n.txKeypadBackspace,
            onTap: onBackspace,
            onLongPress: onClear,
          ),
          _OperatorKey(
            label: '+',
            onTap: () => onOperator(CalcOperator.add),
          ),
        ]),
      ],
    ),
  );
}
```

- [ ] **Step 5: Add _OperatorKey widget**

Add after `_IconKey` class:

```dart
class _OperatorKey extends StatelessWidget {
  const _OperatorKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Add onLongPress to _IconKey**

Update `_IconKey` to support long-press:

```dart
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
              onLongPress: onLongPress,
              child: Center(child: Icon(icon)),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Remove _SpacerKey class**

Delete the `_SpacerKey` class — no longer used.

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/widget/features/transactions/calculator_keypad_test.dart`
Expected: ALL PASS

- [ ] **Step 9: Update existing tests that reference old layout**

Existing tests WK01–WK04 use the old constructor without `onOperator`. Update the `_wrap` helper and constructor calls to include `onOperator: (_) {}`.

- [ ] **Step 10: Run all keypad tests**

Run: `flutter test test/widget/features/transactions/calculator_keypad_test.dart`
Expected: ALL PASS

- [ ] **Step 11: Commit**

```bash
git add lib/features/transactions/widgets/calculator_keypad.dart test/widget/features/transactions/calculator_keypad_test.dart
git commit -m "feat: add operator keys and new 4×4 keypad layout"
```

---

## Chunk 3: AmountDisplay — Expression Line

### Task 8: Add expression line to AmountDisplay

**Files:**
- Modify: `lib/features/transactions/widgets/amount_display.dart`
- Test: `test/widget/features/transactions/amount_display_test.dart` (may need to create)

- [ ] **Step 1: Write failing tests**

Create or update `test/widget/features/transactions/amount_display_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/features/transactions/keypad_state.dart';
import 'package:ledgerly/features/transactions/widgets/amount_display.dart';
import 'package:ledgerly/data/models/currency.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// Use a test currency with 2 decimals
final _usd = Currency(code: 'USD', decimals: 2);

void main() {
  testWidgets('AD01: no expression — no expression line', (tester) async {
    await tester.pumpWidget(
      _wrap(AmountDisplay(
        keypad: const KeypadState.initial(),
        currency: _usd,
      )),
    );
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('AD02: evaluating — expression line shows left + op', (
    tester,
  ) async {
    final keypad = KeypadState(
      amountMinorUnits: 500,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      isEvaluating: true,
    );
    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
    );
    // Expression line should show "12 +"
    expect(find.textContaining('12 +'), findsOneWidget);
  });

  testWidgets('AD03: showingResult — expression line shows full expression', (
    tester,
  ) async {
    final keypad = KeypadState(
      amountMinorUnits: 1700,
      fractionalDigitsEntered: 0,
      isFractionalMode: false,
      leftOperand: 1200,
      operator: CalcOperator.add,
      showingResult: true,
    );
    await tester.pumpWidget(
      _wrap(AmountDisplay(keypad: keypad, currency: _usd)),
    );
    // Expression line should show "12 + 5 ="
    expect(find.textContaining('12 + 5 ='), findsOneWidget);
  });
}
```

Note: The `Currency` model uses Freezed. Use minimal constructor: `Currency(code: 'USD', decimals: 2)`. The `symbol` and `nameL10nKey` are optional.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/features/transactions/amount_display_test.dart --name AD`
Expected: FAIL — expression line not found

- [ ] **Step 3: Add expression line rendering to AmountDisplay**

In `lib/features/transactions/widgets/amount_display.dart`, add to the `build` method. Before the main amount `Row`, add a conditional expression line:

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context);
  final code = currency?.code ?? '';
  final showPlaceholder =
      currencyTouched && keypad.amountMinorUnits == 0 && code.isNotEmpty;

  // Build expression line text
  final expressionText = _buildExpressionText();

  final text = showPlaceholder
      ? l10n.txAmountPlaceholderInCurrency(code)
      : _renderAmountText();
  final foreground = hasError
      ? theme.colorScheme.error
      : theme.colorScheme.onSurface;
  final textColor = showPlaceholder
      ? foreground.withValues(alpha: 0.5)
      : foreground;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: hasError
          ? Border.all(color: theme.colorScheme.error, width: 1.5)
          : null,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expressionText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              expressionText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.5),
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
```

Add the expression text builder method:

```dart
String? _buildExpressionText() {
  final k = keypad;
  final decimals = currency?.decimals ?? 2;
  final unit = _pow10(decimals);

  if (k.isEvaluating && k.leftOperand != null && k.operator != null) {
    final leftStr = _formatMinorUnits(k.leftOperand!, unit, decimals);
    final opStr = _operatorSymbol(k.operator!);
    return '$leftStr $opStr';
  }

  if (k.showingResult && k.leftOperand != null && k.operator != null) {
    final leftStr = _formatMinorUnits(k.leftOperand!, unit, decimals);
    final opStr = _operatorSymbol(k.operator!);
    final rightStr = _formatMinorUnits(k.amountMinorUnits, unit, decimals);
    return '$leftStr $opStr $rightStr =';
  }

  return null;
}

String _operatorSymbol(CalcOperator op) {
  return switch (op) {
    CalcOperator.add => '+',
    CalcOperator.subtract => '−',
    CalcOperator.multiply => '×',
    CalcOperator.divide => '÷',
  };
}

String _formatMinorUnits(int minorUnits, int unit, int decimals) {
  if (decimals == 0) return minorUnits.toString();
  final whole = minorUnits ~/ unit;
  final frac = (minorUnits % unit).toString().padLeft(decimals, '0');
  return '$whole.$frac';
}
```

Add the import for `keypad_state.dart` at the top of the file if not already present.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widget/features/transactions/amount_display_test.dart`
Expected: PASS

- [ ] **Step 5: Run all existing tests to verify no regressions**

Run: `flutter test test/widget/features/transactions/`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/transactions/widgets/amount_display.dart test/widget/features/transactions/amount_display_test.dart
git commit -m "feat: add expression line to AmountDisplay"
```

---

## Chunk 4: TransactionFormController — Wiring

### Task 9: Add applyOperator() to controller

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`

- [ ] **Step 1: Add applyOperator() method**

In `lib/features/transactions/transaction_form_controller.dart`, add after `clearAmount()`:

```dart
void applyOperator(CalcOperator op) {
  final s = state;
  if (s is! TransactionFormData || s.isSaving || s.isDeleting) return;
  final decimals = s.displayCurrency?.decimals ?? 2;
  _keypad = _keypad.pushOperator(op, decimals: decimals);
  state = s.copyWith(
    amountMinorUnits: _keypad.amountMinorUnits,
    isDirty: true,
  );
}
```

- [ ] **Step 2: Write controller tests**

Add controller tests in `test/unit/controllers/transaction_form_controller_test.dart` (or the existing controller test file):

```dart
group('TransactionFormController — calculator operators', () {
  test('applyOperator sets leftOperand and isEvaluating on keypad', () async {
    // Setup: hydrate controller with a valid form state
    // ... (use existing test setup pattern)
    // Enter amount 12 via keypad
    controller.appendDigit(1);
    controller.appendDigit(2);
    expect(controller.keypadSnapshot.amountMinorUnits, 1200);
    // Apply operator
    controller.applyOperator(CalcOperator.add);
    expect(controller.keypadSnapshot.leftOperand, 1200);
    expect(controller.keypadSnapshot.operator, CalcOperator.add);
    expect(controller.keypadSnapshot.isEvaluating, isTrue);
    expect(controller.keypadSnapshot.amountMinorUnits, 0);
  });

  test('applyOperator on second tap evaluates and updates state', () async {
    // Setup controller, enter 12, tap +, enter 5, tap +
    controller.appendDigit(1);
    controller.appendDigit(2);
    controller.applyOperator(CalcOperator.add);
    controller.appendDigit(5);
    controller.applyOperator(CalcOperator.add);
    expect(controller.keypadSnapshot.amountMinorUnits, 1700);
    expect(controller.keypadSnapshot.showingResult, isTrue);
  });

  test('appendDigit during evaluating accumulates into right operand', () async {
    controller.appendDigit(1);
    controller.applyOperator(CalcOperator.add);
    controller.appendDigit(5);
    expect(controller.keypadSnapshot.amountMinorUnits, 500);
    expect(controller.keypadSnapshot.isEvaluating, isTrue);
  });

  test('backspace during evaluating with amount=0 cancels expression', () async {
    controller.appendDigit(1);
    controller.appendDigit(2);
    controller.applyOperator(CalcOperator.add);
    // amountMinorUnits is 0, leftOperand is 1200
    controller.backspace();
    expect(controller.keypadSnapshot.amountMinorUnits, 1200);
    expect(controller.keypadSnapshot.leftOperand, isNull);
  });

  test('clearAmount resets expression state', () async {
    controller.appendDigit(1);
    controller.applyOperator(CalcOperator.add);
    controller.appendDigit(5);
    controller.clearAmount();
    expect(controller.keypadSnapshot.amountMinorUnits, 0);
    expect(controller.keypadSnapshot.leftOperand, isNull);
    expect(controller.keypadSnapshot.operator, isNull);
    expect(controller.keypadSnapshot.isEvaluating, isFalse);
  });
});
```

- [ ] **Step 3: Verify existing tests still pass**

Run: `flutter test test/widget/features/transactions/transaction_form_screen_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add lib/features/transactions/transaction_form_controller.dart
git commit -m "feat: add applyOperator() to TransactionFormController"
```

---

### Task 10: Wire onOperator to CalculatorKeypad in screen

**Files:**
- Modify: `lib/features/transactions/transaction_form_screen.dart`

- [ ] **Step 1: Add onOperator to CalculatorKeypad call**

In `lib/features/transactions/transaction_form_screen.dart`, update the `CalculatorKeypad` construction in `_buildForm`:

```dart
CalculatorKeypad(
  decimals: state.displayCurrency?.decimals ?? 2,
  onDigit: controller.appendDigit,
  onDecimal: controller.appendDecimal,
  onBackspace: controller.backspace,
  onClear: controller.clearAmount,
  onOperator: controller.applyOperator,
),
```

- [ ] **Step 2: Run integration tests**

Run: `flutter test test/integration/bootstrap_to_home_test.dart`
Expected: PASS

- [ ] **Step 3: Run all transaction tests**

Run: `flutter test test/widget/features/transactions/`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/transactions/transaction_form_screen.dart
git commit -m "feat: wire operator keys to controller in TransactionFormScreen"
```

---

### Task 11: Handle currency/account change mid-expression

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`
- Modify: `lib/features/transactions/keypad_state.dart`

- [ ] **Step 1: Add resetExpression() helper to KeypadState**

In `lib/features/transactions/keypad_state.dart`:

```dart
/// Returns a new state with expression fields cleared but amount preserved.
KeypadState resetExpression() {
  return KeypadState(
    amountMinorUnits: amountMinorUnits,
    fractionalDigitsEntered: fractionalDigitsEntered,
    isFractionalMode: isFractionalMode,
  );
}
```

- [ ] **Step 2: Use resetExpression() in selectAccount() and selectCurrency()**

In `transaction_form_controller.dart`, in `selectAccount()` where the currency changes and amount is cleared, also reset the expression:

```dart
if (currencyChanged) {
  _keypad = const KeypadState.initial(); // already resets everything
  // ...
}
```

This already works because `KeypadState.initial()` resets all fields. No change needed — the existing code handles this correctly.

- [ ] **Step 3: Verify currency change resets expression**

The existing `selectAccount()` and `selectCurrency()` methods already call `_keypad = const KeypadState.initial()` when the currency changes and amount is cleared. Since `KeypadState.initial()` now includes the expression fields with default null/false values, this correctly resets expression state. No additional test needed — the existing controller tests for currency change cover this path.

- [ ] **Step 4: Commit**

```bash
git add lib/features/transactions/keypad_state.dart
git commit -m "feat: add resetExpression() helper to KeypadState"
```

---

### Task 12: Update _keypadFromAmount for edit hydration

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`

- [ ] **Step 1: Verify _keypadFromAmount returns clean expression state**

The existing `_keypadFromAmount` creates a `KeypadState` with only the 3 original fields (`amountMinorUnits`, `fractionalDigitsEntered`, `isFractionalMode`). Since the new fields have defaults (`null` / `false`), this already produces a clean expression state. No changes needed.

- [ ] **Step 2: Verify edit/duplicate tests pass**

Run: `flutter test test/widget/features/transactions/transaction_form_screen_test.dart`
Expected: ALL PASS

No commit needed — no code changes.

---

## Chunk 5: Final Verification

### Task 13: Run full test suite and format

**Files:**
- None (verification only)

- [ ] **Step 1: Format code**

Run: `dart format .`

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 3: Run all tests**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 4: Run import lint**

Run: `dart run import_lint`
Expected: PASS

- [ ] **Step 5: Final commit if any formatting changes**

```bash
git add -A
git commit -m "chore: format and lint calculator keypad changes"
```
