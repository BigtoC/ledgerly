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

Operator keys use a distinct visual style (e.g. `colorScheme.primaryContainer`) to differentiate from digit keys. A new `_OperatorKey` widget (analogous to the existing `_DigitKey` and `_IconKey`) renders operator buttons with this style.

Long-press on `⌫` reuses the existing `onClear` callback — no new callback needed.

## 2. State Machine (`KeypadState`)

New fields on `KeypadState`:

```dart
final int? leftOperand;        // stored left side of expression (minor units)
final CalcOperator? operator;  // +, −, ×, ÷
final bool isEvaluating;       // true after first operand + operator, typing 2nd number
final bool showingResult;      // true after evaluation, before next digit/operator tap

enum CalcOperator { add, subtract, multiply, divide }
```

### `pushOperator()` Method

```dart
/// Returns a new [KeypadState] with the operator applied.
///
/// If [isEvaluating] is true and the right operand is non-zero,
/// evaluates the pending expression first, then sets the new operator.
/// If [showingResult] is true, uses the current result as [leftOperand].
KeypadState pushOperator(CalcOperator op, {required int decimals})
```

### State Transitions

| User action | Transition |
|---|---|
| Type digits (no operator active) | Same as today — accumulates `amountMinorUnits` |
| Tap `.` (no operator active) | Same as today — enters fractional mode |
| Tap `+` (amount ≥ 0) | `leftOperand = amountMinorUnits`, `operator = add`, `isEvaluating = true`, reset `amountMinorUnits = 0`, reset fractional mode |
| Type digits (while `isEvaluating`) | Accumulates into `amountMinorUnits` (the right operand) |
| Tap `.` (while `isEvaluating`) | Enters fractional mode for the right operand (same pushDecimal logic) |
| Tap `+` again (while `isEvaluating`) | Evaluate `leftOperand + amountMinorUnits` → result becomes new `amountMinorUnits`, clear `leftOperand`/`operator`, `isEvaluating = false`. Display enters "result showing" state. |
| Tap different operator (while `isEvaluating`) | Evaluate previous, store result as new `leftOperand`, set new `operator` |
| Tap digit (in "result showing" state, no operator active) | Clear expression state entirely, start fresh accumulation |
| Tap operator (in "result showing" state) | Use result as `leftOperand`, start new expression |
| `⌫` (while `isEvaluating`, amount = 0) | Cancel expression — restore `leftOperand` as `amountMinorUnits`, clear operator |
| `C` / long-press `⌫` | Full reset — clear everything including expression |
| Tap operator-again with 0 right side | Uses `leftOperand` as result (no-op effectively) |

**"Result showing" state:** After evaluation completes, the system is in a transient state where the expression line shows the full calculation and the result is displayed. A digit tap clears the expression and starts fresh. An operator tap chains from the result. This is distinct from `isEvaluating` — it's the state where `leftOperand == null` but the expression line is still visible (tracked by a separate `showingResult` flag on `KeypadState`).

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
- Expression display reads from `keypadSnapshot` which already exposes `KeypadState`. The display widget reads the new `leftOperand`, `operator`, `isEvaluating`, and `showingResult` fields from this snapshot to render the expression line.

**L10n:** Operator symbols (`÷`, `×`, `−`, `+`) render as literal Unicode characters — no l10n keys needed for MVP. If locale-specific symbols are required later, add l10n keys at that point.

## 5. Edge Cases

- **Negative results:** `3 − 5 =` → result clamps to `0`. Amounts are always non-negative (no negation key). The expression line shows `3 − 5 = 0`.
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
- `pushOperator(CalcOperator.add)` on state with `amountMinorUnits=1200` → sets `leftOperand=1200`, `operator=add`, `isEvaluating=true`, `amountMinorUnits=0`
- Add: push `5`, push `0`, push `0` → `amountMinorUnits=500`; pushOperator(add) → `amountMinorUnits=1700`, `leftOperand=null`
- Subtract: `leftOperand=150`, `amountMinorUnits=50`, evaluate → `amountMinorUnits=100`
- Multiply: `leftOperand=200`, `amountMinorUnits=3`, evaluate → `amountMinorUnits=600`
- Divide (USD, decimals=2): `leftOperand=10000` ($100.00), `amountMinorUnits=300` ($3.00), evaluate → `amountMinorUnits=3333` ($33.33, half-up rounded)
- Divide (USD, decimals=2): `leftOperand=70000` ($700.00), `amountMinorUnits=300` ($3.00), evaluate → `amountMinorUnits=23333` ($233.33, half-up rounded)
- Negative result: `leftOperand=300` ($3.00), `amountMinorUnits=500` ($5.00), subtract → `amountMinorUnits=0` (clamped)
- Division by zero: `leftOperand=700`, `amountMinorUnits=0`, divide → `amountMinorUnits=0`
- Chain: push `12`, pushOperator(add), push `5`, pushOperator(subtract) → intermediate `amountMinorUnits=17`, then `leftOperand=17`, `operator=subtract`
- Cancel expression via backspace: `leftOperand=1200`, `isEvaluating=true`, `amountMinorUnits=0`, pop → `amountMinorUnits=1200`, `leftOperand=null`
- Clear: state with expression → clear() → `amountMinorUnits=0`, `leftOperand=null`, `operator=null`, `isEvaluating=false`
- Operator on zero: `amountMinorUnits=0`, pushOperator(add) → `leftOperand=0`, `isEvaluating=true`

**Widget tests (`calculator_keypad_test.dart`):**
- Operator keys render `÷`, `×`, `−`, `+` labels and call `onOperator` callback with correct `CalcOperator` enum
- Operator keys use `colorScheme.primaryContainer` background (distinct from digit keys' `surfaceContainerHigh`)
- Long-press ⌫ triggers `onClear` (not `onBackspace`)
- Bottom row renders `. 0 ⌫ +` (no `00` key, no `C` key)
- Decimal disabled on JPY (decimals = 0) still works

**Controller tests:**
- `applyOperator(CalcOperator.add)` sets `_keypad.leftOperand` and `_keypad.isEvaluating`
- `applyOperator` on second tap evaluates and updates `state.amountMinorUnits`
- `appendDigit` during `isEvaluating` accumulates into right operand
- `backspace` during `isEvaluating` with `amountMinorUnits=0` cancels expression, restores `leftOperand`
- `clearAmount` resets `_keypad` to initial (including expression fields)
- Currency change mid-expression resets expression state

**Display tests:**
- Expression line renders `{leftOperand} {op}` when `isEvaluating == true`
- Expression line shows `{leftOperand} {op} {rightOperand} =` after evaluation
- Expression line clears when `showingResult == true` and user taps a digit

## 7. Files Modified

| File | Change |
|---|---|
| `lib/features/transactions/keypad_state.dart` | Add `leftOperand`, `operator`, `isEvaluating`, `showingResult`; add `pushOperator()` method; modify `pop()` and `clear()` |
| `lib/features/transactions/widgets/calculator_keypad.dart` | New layout; add operator keys; add `onOperator` callback; long-press ⌫ for clear |
| `lib/features/transactions/widgets/amount_display.dart` | Render expression line when operator active |
| `lib/features/transactions/transaction_form_controller.dart` | Add `applyOperator()`; modify `appendDigit()`, `backspace()`, `clearAmount()` |
| `test/unit/utils/keypad_decimal_math_test.dart` | Add calculator operation tests |
| `test/widget/features/transactions/calculator_keypad_test.dart` | Update layout tests; add operator key tests |
