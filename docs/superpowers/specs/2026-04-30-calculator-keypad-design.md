# Calculator Keypad — Design Spec

**Date:** 2026-04-30  
**Status:** Draft  
**Scope:** Add basic calculator operations (`+`, `−`, `×`, `÷`) to the transaction form keypad

## Overview

The transaction form's numeric keypad currently only supports entering raw amounts. This adds inline calculator functionality so users can compute amounts without leaving the form (for example `12.50 + 5.00 = 17.50`).

## 1. Keypad Layout

New 4x4 grid:

```
 7  8  9  ÷
 4  5  6  ×
 1  2  3  −
 .  0  ⌫  +
```

Changes from current:
- Right column: `÷`, `×`, `−`, `+` replace the old spacer/backspace placement
- Bottom row: `.` moves to row 4 col 1; `00` is removed
- Visible `C` key is removed; long-press `⌫` performs full clear
- For zero-decimal currencies, the `.` key keeps its slot but is disabled or a no-op
- Operator keys use a distinct visual style (for example `colorScheme.primaryContainer`)

Accessibility:
- Visible operator glyphs stay literal Unicode (`÷`, `×`, `−`, `+`)
- Operator buttons expose localized semantics labels (`Add`, `Subtract`, `Multiply`, `Divide`)
- Backspace exposes the existing tooltip and a long-press clear hint
- Full clear must also be reachable through a non-gesture accessibility path (for example a `CustomSemanticsAction` on the backspace control)

Large text:
- Key labels clamp to the repo's existing fixed-height pattern: `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5)`
- The transaction form as a whole must still survive 2x text scale without overflow

## 2. State Machine (`KeypadState`)

New fields on `KeypadState`:

```dart
final int? leftOperand;        // stored left side in minor units
final CalcOperator? operator;  // +, −, ×, ÷
final bool isEvaluating;       // true after first operand + operator
final bool showingResult;      // true after evaluation, before next digit/operator tap
final int? rightOperand;       // preserved after evaluation for expression history
final bool hasCurrentInput;    // distinguishes empty right operand from explicit 0

enum CalcOperator { add, subtract, multiply, divide }
```

Derived helpers:

```dart
bool get hasExpression =>
    leftOperand != null ||
    operator != null ||
    isEvaluating ||
    showingResult ||
    rightOperand != null;

bool get hasVisibleInput => hasExpression || hasCurrentInput;
```

### Why `hasCurrentInput` exists

`amountMinorUnits == 0` is ambiguous:
- empty right operand after tapping an operator
- explicit integer `0`
- explicit fractional zero like `.0`

The reducer must distinguish those states so that:
- `12 ×` then `−` corrects the operator without evaluating `12 × 0`
- `12 ÷` then `÷` is a no-op
- `12 ÷ 0` really evaluates as divide-by-zero

### `pushOperator()` rules

1. Truly untouched keypad (`!hasCurrentInput` and no prior result):
   operator tap is a no-op
2. No expression active:
   store the current amount as `leftOperand`, set `operator`, enter `isEvaluating`, clear the current input
3. Evaluating with **no** current right operand:
   - same operator: no-op
   - different operator: replace the pending operator, do not evaluate
4. Evaluating with a current right operand:
   evaluate the pending expression
   - same operator: enter `showingResult`
   - different operator: chain from the result into a new pending operator
5. Showing a result:
   tapping an operator uses the result as `leftOperand` and starts a new pending expression

### Digit / decimal / backspace rules

- Typing a digit while `isEvaluating == true` fills the right operand and preserves `leftOperand` / `operator`
- Tapping decimal while `isEvaluating == true` marks the right operand as started even before a numeric digit is entered (`hasCurrentInput = true`)
- Tapping decimal when `decimals == 0` is disabled or a no-op so zero-decimal currencies do not expose meaningless fractional input
- Typing a digit while `showingResult == true` clears the old expression and starts a fresh amount
- Backspace while `isEvaluating == true` and `hasCurrentInput == false` cancels the expression and restores `leftOperand`
- Backspace while editing the right operand preserves the expression; if the current operand becomes empty again, set `hasCurrentInput = false`
- Long-press `⌫` resets everything (`KeypadState.initial()`)

## 3. Arithmetic Rules

Amounts remain stored in integer minor units, but operators act on the displayed decimal values.

Let `unit = 10^currency.decimals`.

- Add: `left + right`
- Subtract: `max(left - right, 0)`
- Multiply: half-up round `(left * right) / unit`
- Divide: half-up round `(left * unit) / right`

Implementation rules:
- Use integer / `BigInt` helpers only inside `KeypadState`
- Do not use `double` in the calculator state machine

Product rules:
- Division by zero evaluates to `0`
- Subtraction underflow clamps to `0`
- These zero results remain visible in calculator history and in the main result line
- Save remains blocked because `canSave` still requires `amountMinorUnits > 0`

Examples:
- `2.00 × 3.00 = 6.00`
- `100.00 ÷ 3.00 = 33.33`
- `1.00 ÷ 8.00 = 0.13` (half-up tie)
- `0.05 × 0.10 = 0.01` (half-up tie)
- `3.00 − 5.00 = 0.00`
- `7.00 ÷ 0.00 = 0.00`

## 4. Amount Display

`AmountDisplay` shows two layers:

### While typing a current operand

- Main amount uses the existing live-entry preview behavior
- Expression line is hidden unless an expression is active

### While evaluating

- Expression line shows `{leftOperand} {operator}` using `MoneyFormatter.formatBare(...)`
- Main amount shows the current right operand using the existing live-entry preview

Example:

```
┌─────────────────────────────┐
│ 12.00 +                     │
│ 5.00                    USD │
└─────────────────────────────┘
```

### After evaluation (`showingResult == true`)

- Expression line shows `{leftOperand} {operator} {rightOperand} =`
- Main amount shows the computed result using `MoneyFormatter.formatBare(...)`

Example:

```
┌─────────────────────────────┐
│ 12.00 + 5.00 =              │
│ 17.00                   USD │
└─────────────────────────────┘
```

Formatting rules:
- Expression line and evaluated results use `MoneyFormatter.formatBare(...)`
- Locale comes from `AppLocalizations.localeName`
- Zero-decimal currencies stay zero-decimal (`12 ÷ 2 =` then `6`)
- The currency-change placeholder is suppressed whenever `keypad.hasVisibleInput` is true so zero-valued results and decimal-start input remain visible after a manual currency pick

Large text:
- Expression line may be single-line + ellipsis, but at 2x scale it must still remain visible on a realistic phone width during tests

## 5. Controller And Screen Rules

### `TransactionFormController`

Add:
- `void applyOperator(CalcOperator op)`
- a lightweight observed field such as `keypadRevision` on `TransactionFormState.data`, incremented on every keypad mutation, so expression-only transitions repaint the screen even when `amountMinorUnits` does not change

Behavior:
- Mirrors `_keypad.amountMinorUnits` into `TransactionFormData.amountMinorUnits` after every operator action
- Keeps `canSave` semantics unchanged (`amountMinorUnits > 0`)

### Currency / account changes during active keypad input

Active keypad input is destructive unsaved input, even when the visible amount is `0`.
This includes active expressions and zero-valued in-progress input such as decimal-start states.

That means the confirm-and-clear flow is required only when the attempted change would actually change `displayCurrency` and either is true:
- `state.amountMinorUnits > 0`
- `_keypad.hasVisibleInput == true`

After confirmation, if the successful account/currency change changes `displayCurrency`:
- `_keypad = const KeypadState.initial()`
- `amountMinorUnits = 0`

This applies to:
- direct currency changes
- account changes that would reseed `displayCurrency`

Same-currency account switches do not require a destructive confirm.

Dialog copy must reflect both cases, not just raw amount entry. The manual currency dialog should describe the currency change; the account-triggered dialog should describe the account switch while making the currency reseed clear. Both should say the current amount or calculation will be cleared.

### Invalid math + save behavior

`÷ 0` and subtraction underflow intentionally resolve to `0`, but zero-value results are still unsaveable. The user can backspace, clear, or continue calculating from the result.

## 6. Testing Expectations

### Unit tests (`test/unit/utils/keypad_decimal_math_test.dart`)

Must cover:
- initial expression fields + `hasCurrentInput`
- untouched-keypad operator no-op
- operator correction before any right input
- same-operator no-op with empty right operand
- explicit integer `0` and explicit fractional zero
- add / subtract / multiply / divide
- half-up tie cases for multiply and divide
- chain evaluation
- showing-result reset on digit input
- cancel expression via backspace
- clear resets all fields

### Widget tests (`test/widget/features/transactions/calculator_keypad_test.dart`)

Must cover:
- operator glyphs render and callbacks fire with the correct enum
- `00` / `C` removed
- long-press backspace triggers clear
- non-touch clear path remains exposed through semantics
- operator keys expose localized semantics labels
- zero-decimal decimal-key behavior
- 1.5x label clamp under requested 2x text scale

### Display tests (`test/widget/features/transactions/amount_display_test.dart`)

Must cover:
- no-expression state
- evaluating expression line
- showing-result expression line
- fixed-precision evaluated main result
- zero-valued decimal-start input suppresses the currency placeholder
- zero-decimal currencies
- 2x text scale with expression history visible

### Controller tests (`test/unit/controllers/transaction_form_controller_test.dart`)

Must cover:
- `applyOperator()`
- operator correction before right input
- destructive gating on active keypad input for account/currency changes
- same-currency account change does not prompt
- confirmed reset path clears expression state

### Screen tests (`test/widget/features/transactions/transaction_form_screen_test.dart`)

Must cover:
- end-to-end operator flow in the form
- active-expression currency change still shows the destructive dialog when amount display is zero
- confirmed destructive change clears expression history
- divide-by-zero remains unsaveable and visible
- 2x text scale with expression history + result visible

## 7. Files Modified

| File | Change |
|---|---|
| `lib/features/transactions/keypad_state.dart` | Add calculator fields, `hasCurrentInput`, operator evaluation, editing rules |
| `lib/features/transactions/widgets/calculator_keypad.dart` | New 4x4 layout, operator semantics labels, long-press clear, text-scale clamp |
| `lib/features/transactions/widgets/amount_display.dart` | Render expression history and fixed-precision evaluated results |
| `lib/features/transactions/transaction_form_controller.dart` | Add `applyOperator()` and expression-aware destructive gating |
| `lib/features/transactions/transaction_form_screen.dart` | Wire operator taps and expression-aware destructive dialogs |
| `test/unit/utils/keypad_decimal_math_test.dart` | Add state-machine and arithmetic coverage |
| `test/widget/features/transactions/calculator_keypad_test.dart` | Add keypad layout/semantics/text-scale coverage |
| `test/widget/features/transactions/amount_display_test.dart` | Add expression-line/result-format coverage |
| `test/unit/controllers/transaction_form_controller_test.dart` | Add controller command + destructive gating coverage |
| `test/widget/features/transactions/transaction_form_screen_test.dart` | Add end-to-end calculator flow coverage |
| `test/integration/transaction_mutation_flow_test.dart` | Replace removed `C` interactions with the shipped clear behavior |
| `l10n/app_en.arb` / `app_zh.arb` / `app_zh_CN.arb` / `app_zh_TW.arb` | Add localized operator semantics labels and destructive-dialog copy while preserving the fallback shim |
