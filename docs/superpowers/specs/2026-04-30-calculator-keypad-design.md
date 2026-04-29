# Calculator Keypad — Design Spec

**Date:** 2026-04-30
**Status:** Draft
**Scope:** Add basic calculator operations (+, −, ×, ÷) to the transaction form keypad

## Overview

The transaction form's numeric keypad currently only supports entering raw amounts. This adds inline calculator functionality so users can compute amounts without leaving the form (e.g. `12.50 + 5.00 = 17.50`).

## 1. Keypad Layout

New 4×4 grid (replaces current layout):

```
 7  8  9  ÷
 4  5  6  ×
 1  2  3  −
 .  0  ⌫  +
```

Changes from current:
- Right column: `÷`, `×`, `−`, `+` replace two `_SpacerKey`s and relocate `⌫`/`.`
- Bottom row: `.` moves from row 2 col 4 to row 4 col 1; `00` removed (user taps `0` twice)
- `C` key removed — long-press on `⌫` triggers clear
- `⌫` moves from row 1 col 4 to row 4 col 3

Operator keys use a distinct visual style (e.g. `colorScheme.primaryContainer`) to differentiate from digit keys.

## 2. State Machine (`KeypadState`)

New fields on `KeypadState`:

```dart
final int? leftOperand;        // stored left side of expression (minor units)
final CalcOperator? operator;  // +, −, ×, ÷
final bool isEvaluating;       // true after first operand + operator, typing 2nd number

enum CalcOperator { add, subtract, multiply, divide }
```

### State Transitions

| User action | Transition |
|---|---|
| Type digits (no operator active) | Same as today — accumulates `amountMinorUnits` |
| Tap `+` (amount > 0) | `leftOperand = amountMinorUnits`, `operator = add`, `isEvaluating = true`, reset `amountMinorUnits = 0` |
| Type digits (while `isEvaluating`) | Accumulates into `amountMinorUnits` (the right operand) |
| Tap `+` again (while `isEvaluating`) | Evaluate `leftOperand + amountMinorUnits` → result becomes new `amountMinorUnits`, clear `leftOperand`/`operator`, `isEvaluating = false` |
| Tap different operator (while `isEvaluating`) | Evaluate previous, store result as new `leftOperand`, set new `operator` |
| `⌫` (while `isEvaluating`, amount = 0) | Cancel expression — restore `leftOperand` as `amountMinorUnits`, clear operator |
| `C` / long-press `⌫` | Full reset — clear everything including expression |
| Tap operator-again with 0 right side | Uses `leftOperand` as result (no-op effectively) |

### Evaluation Rules

- Division rounds half-up to the active currency's decimal precision (2 for USD, 0 for JPY, etc.)
- Other operations (+, −, ×) stay exact since integer inputs produce integer results
- Division by zero → result is `0`
- Uses Dart `int` (64-bit) — sufficient for realistic amounts

## 3. Amount Display

`AmountDisplay` shows the expression inline above the current input.

**When no expression is active** (`leftOperand == null`):
- Same as today — shows the typed amount

**When expression is active** (`isEvaluating == true`):
- Small line above: `{leftOperand} {operator symbol}` in `onSurface` with reduced opacity
- Main display shows the current right operand

```
┌─────────────────────────────┐
│  12.50 +                    │  ← small, muted expression line
│  5.00                    USD│  ← main amount (current input)
└─────────────────────────────┘
```

**After evaluation** (tap operator again):
- Expression line persists showing full calculation: `{leftOperand} {op} {rightOperand} =`
- Main display shows the result

```
┌─────────────────────────────┐
│  12.50 + 5.00 =             │  ← full expression stays visible
│  17.50                    USD│  ← result
└─────────────────────────────┘
```

**Expression line clears when:**
- User starts typing a new number (digit press resets expression state)
- User taps `C` / long-press `⌫` (full reset)
- User taps an operator on the result (starts a new expression chaining from result)

## 4. Controller Changes

`TransactionFormController` changes:

**New method:**
- `void applyOperator(CalcOperator op)` — handles operator tap. If `isEvaluating` and right operand is non-zero, evaluates first; then sets the new operator and left operand.

**Modified behavior:**
- `appendDigit()` — when `isEvaluating`, accumulates into the right operand (same push logic)
- `backspace()` — when `isEvaluating` and `amountMinorUnits == 0`, cancels the expression and restores `leftOperand`
- `clearAmount()` — full reset including expression state

**Wiring in `CalculatorKeypad`:**
- New callback: `ValueChanged<CalcOperator> onOperator`
- Keypad widget renders 4 operator keys and calls `onOperator` on tap

**State mirroring:**
- `TransactionFormData.amountMinorUnits` updated on every evaluation result (same field, no Freezed model change)
- Expression display reads from `keypadSnapshot` which already exposes `KeypadState`

## 5. Edge Cases

- **Division by zero:** `7 ÷ 0 =` → result is `0`. Expression line shows `7 ÷ 0 = 0`.
- **Division rounding:** Half-up to currency decimals. `100 / 3 = 33.33` (USD) = 3333 minor units. `700 / 3 = 233.33` (USD) = 23333 minor units.
- **Currency change mid-expression:** Full reset of expression state (leftOperand, operator, isEvaluating cleared).
- **Account change mid-expression:** Same as currency change — full reset.
- **Operator on zero:** `0 + 5` → leftOperand = 0, operator = add. Valid entry path.
- **Chaining:** `12 + 5 − 3` — tapping `−` evaluates `12 + 5 = 17`, then starts `17 −`.
- **Save validation:** `canSave` still checks `amountMinorUnits > 0`. In-progress expression (leftOperand set, right side is 0) is not saveable.
- **Edit/Duplicate hydration:** Expression state starts clean. Calculator only activates on operator tap.

## 6. Testing

**Unit tests (`keypad_decimal_math_test.dart`):**
- `pushOperator` sets leftOperand and operator correctly
- Evaluation: `1200 + 500 = 1700` (USD minor units)
- Evaluation: `150 - 50 = 100`
- Evaluation: `200 * 3 = 600`
- Evaluation: `100 / 3 = 33` (USD, half-up rounding to cents → 3333 minor units)
- Evaluation: `700 / 3 = 233` (USD, half-up rounding → 23333 minor units)
- Division by zero → 0
- Chain: `12 + 5 - 3` evaluates progressively
- Cancel expression via backspace (restore leftOperand)
- Clear resets everything including expression state
- Operator on zero: `0 + 5 = 5`

**Widget tests (`calculator_keypad_test.dart`):**
- Operator keys render and call `onOperator` callback
- Operator keys have distinct visual style from digit keys
- Long-press ⌫ triggers `onClear`
- 00 key removed, bottom row is `. 0 ⌫ +`
- Decimal disabled on JPY (decimals = 0) still works

**Controller tests:**
- `applyOperator` sets expression state
- `applyOperator` evaluates on second tap
- `appendDigit` accumulates right operand during expression
- `backspace` cancels expression when right side is empty
- `clearAmount` resets expression state
- Currency change mid-expression resets expression

**Display tests:**
- Expression line renders when operator active
- Expression line shows full calculation after evaluation
- Expression line clears on new digit input

## 7. Files Modified

| File | Change |
|---|---|
| `lib/features/transactions/keypad_state.dart` | Add `leftOperand`, `operator`, `isEvaluating`; add `pushOperator()` method; modify `pop()` and `clear()` |
| `lib/features/transactions/widgets/calculator_keypad.dart` | New layout; add operator keys; add `onOperator` callback; long-press ⌫ for clear |
| `lib/features/transactions/widgets/amount_display.dart` | Render expression line when operator active |
| `lib/features/transactions/transaction_form_controller.dart` | Add `applyOperator()`; modify `appendDigit()`, `backspace()`, `clearAmount()` |
| `test/unit/utils/keypad_decimal_math_test.dart` | Add calculator operation tests |
| `test/widget/features/transactions/calculator_keypad_test.dart` | Update layout tests; add operator key tests |
