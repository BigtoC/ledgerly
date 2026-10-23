---
title: Persisting the keypad formula as a replay-verified record next to the authoritative amount
date: 2026-10-23
category: design-patterns
module: transactions
problem_type: design_pattern
component: frontend_stimulus
severity: medium
applies_when:
  - "Storing a derived or human-readable expression next to an authoritative stored value"
  - "Persisting calculator-keypad input that is evaluated strictly left to right rather than by operator precedence"
  - "A state machine caches values that can also be derived from its recorded input lists"
  - "Refactoring a state machine where behaviour must stay identical and only one known bug may change"
  - "Adding a nullable column whose value must be cleared when an edit no longer produces it"
symptoms:
  - "Formula unrecoverable after save because the keypad kept only a running total"
  - "Flat formula 1+2*2 stored next to 6.00 reads as 5 under usual precedence"
  - "Formula 5-10+20 shown next to 20.00 because each subtraction step clamped at zero"
  - "After = on a dangling operator (1+2+=) the formula lists kept 1+2 but the cached operands were nulled"
root_cause: logic_error
resolution_type: code_fix
related_components:
  - database
  - testing_framework
tags:
  - keypad
  - amount-formula
  - left-to-right-evaluation
  - round-trip-validation
  - single-source-of-truth
  - differential-fuzzing
  - drift-migration
  - minor-units
---

# Persisting the keypad formula as a replay-verified record next to the authoritative amount

## Context

The add/edit transaction keypad accepts expressions such as `3.5 + 10.5 + 11 + 3` (= 28.00). Until #51 only the result was saved, so the calculation behind an amount was gone the moment the transaction was saved. It could not be checked or edited later.

#48 had just made the keypad chain operators (`1 + 2 +` shows `3 +`) and evaluate **strictly left to right with no operator precedence** (`2 + 3 × 4` = 20). That choice was made so a stored formula would replay to the same result, and so the form's amount always equals what `=` produces: the screen never shows a number other than the one Save stores (session history).

#51 then added a nullable `transactions.amount_formula` TEXT column (Drift v5 → v6) and replays the formula on Edit and Duplicate. Review rounds and fuzzing turned up several bugs before merge, and #53 removed a duplicated state that had already drifted apart. The rules below are what survived.

Code: `lib/features/transactions/keypad_state.dart` (state machine and arithmetic), `amount_formula.dart` (codec and shared renderer), `widgets/amount_display.dart` (history line), `transaction_form_controller.dart` (`_keypadForStored`), `lib/data/repositories/transaction_repository.dart` (`_toCompanion`). The authoritative format spec is `PRD.md` → *transactions* notes on `amount_formula`.

## Guidance

### 1. Record the expression as typed; make that record the single source of truth

A keypad that keeps only a running total (`leftOperand`, `operator`, current operand) cannot give the formula back. `KeypadState` records every operand as typed (`FormulaOperand`: minor units, fractional digits typed, fractional mode) plus the operators between them. Everything else is derived. The running total is a fold, and it takes `decimals` because × and ÷ steps round to the currency's minor unit:

```dart
int? leftOperand({required int decimals}) {
  if (isEvaluating) {
    return _fold(formulaOperands, _withoutLast(formulaOperators), decimals: decimals);
  }
  ...
}
```

A constructor assert ties the list shapes to the mode. With that in place, `pop`, `formula()` and the display don't need to repeat length guards:

```dart
}) : assert(
       isEvaluating
           ? !showingResult &&
                 formulaOperators.isNotEmpty &&
                 formulaOperands.length == formulaOperators.length
           : showingResult && formulaOperators.isNotEmpty
           ? formulaOperands.length == formulaOperators.length + 1
           : formulaOperands.isEmpty && formulaOperators.isEmpty,
       'formula lists do not match the keypad mode',
     );
```

The assert reads list lengths, so the constructor cannot be `const`. `KeypadState.initial()` still is.

### 2. Store canonical, locale-independent text

The stored form uses `.` as the decimal separator, `+ - * /` as operators, no spaces, and drops trailing fractional zeros. A full-precision reload (`3.50`) therefore encodes the same as a short typed `3.5`. A plain amount stores `null`, never a lone operand. Locale formatting (digit grouping, the local decimal separator) is applied only on screen, in `AmountDisplay._localizedOperand`.

### 3. If evaluation ignores precedence, store the bracketed form and share one renderer

A flat `1+2*2` saved next to 6.00 reads as 5 to anyone who applies normal precedence. `renderFormula` brackets the expression so far whenever × or ÷ follows + or −, so the keys give `(1+2)*2`. Storage and the on-screen history line call the same function with different operand and operator renderers:

```dart
if (isMultiplicative && hasUnbracketedAddition) {
  text = '($text)';
  hasUnbracketedAddition = false;
} else if (!isMultiplicative) {
  hasUnbracketedAddition = true;
}
text += '$separator${operator(op)}';
```

Parse strictly by **re-encoding and comparing**. Strip the brackets, parse the flat text, re-encode, and accept the result only if it matches the input byte for byte. That rejects `1+2*2`, `1+(2*2)` and `3.50+1` without writing a grammar; `_parseOperand` separately rejects too many fractional digits and int overflow:

```dart
final flat = formula.replaceAll(RegExp(r'[()]'), '');
// ... parse operands/operators from `flat` ...
final canonical = encodeAmountFormula(operands: operands, operators: operators, decimals: decimals);
if (canonical != formula) return null;
```

### 4. Replay the stored formula; keep the stored amount authoritative

Never display stored text as if it were the result. `KeypadState.fromFormula` folds it with the same `_fold`/`_evaluate` the keys use. The controller drops the formula if it doesn't parse or doesn't replay to the stored amount:

```dart
final parsed = formula == null ? null : parseAmountFormula(formula, decimals: decimals);
if (parsed != null) {
  final keypad = KeypadState.fromFormula(parsed, decimals: decimals);
  if (keypad.amountMinorUnits == amountMinorUnits) return keypad;
}
return KeypadState.fromAmount(amountMinorUnits, decimals: decimals);
```

The replayed state is the "just pressed `=`" state. Backspace reopens the last operand and an operator continues the formula, so the user can edit the calculation.

### 5. Clamp only the finished result

Amounts can't be negative, but the subtotals inside a formula can. Clamping every subtraction step made `5 - 10 + 20` show 20.00 next to a formula that reads as 15, and then the replay check silently dropped the formula. Subtotals now stay signed, `_nonNegative` applies only in `equals` and `fromFormula`, and `_roundHalfUp` takes the sign into account. An operator pressed after a formula result appends to the lists. It does not restart from the clamped number, so `3 - 5 = + 2` gives the same 0 as replaying `3-5+2`.

### 6. Always write a clearable nullable column on update

`_toCompanion` writes `memo` only when it is non-null (`Value.absent()` otherwise), and copying that pattern would leave a stale formula behind after an edit to a plain amount. `amount_formula` is always written:

```dart
memo: tx.memo == null ? const Value.absent() : Value(tx.memo),
// Always written so an edit that drops the expression clears it.
amountFormula: Value(tx.amountFormula),
```

Every other path that creates a transaction from the keypad has to pass the formula through too. Shopping-list `convertToTransaction` takes `amountFormula`.

### 7. Verify with fuzzing; keep the harnesses as scratch

Example-based tests didn't catch the clamp or cache bugs. Two throwaway harnesses did. They were deleted after use, and the committed unit tests pin each case they found.

- **Invariant property fuzz** (~382k formula states at 0, 2 and 18 decimals). After every random key, for any `f = state.formula(decimals: d)`:
  - `parseAmountFormula(f)` succeeds;
  - `fromFormula(...).amountMinorUnits == state.equals(decimals: d).amountMinorUnits`;
  - re-encoding gives `f`;
  - pressing `+ 1 =` after a reload gives the same result as pressing it after the live keys.
- **Differential fuzz for behaviour-preserving refactors** (~975k steps). Before committing the refactor, copy the previous class next to the test (`git show <pre-refactor-commit>:lib/features/transactions/keypad_state.dart > test/unit/utils/zz_old_keypad_state.dart`). Rename it `OldKeypadState`, delete its `CalcOperator` enum, and switch its imports to `package:` imports (`amount_formula.dart`, plus `keypad_state.dart` `show CalcOperator`, so both classes share the enum). Run both on identical random keys and compare every observable field, before and after `equals`:

  ```dart
  n = press(n, key, d);
  o = pressOld(o, key, d);
  expect(n.formulaOperands, o.formulaOperands);
  expect(n.leftOperand(decimals: d), o.leftOperand);
  expect(n.formula(decimals: d), o.formula(decimals: d));
  ```

  Every difference is either a bug in the refactor or a bug in the old class. Here it found exactly one, the old desync in *Why This Matters*.
- **Bound the inputs.** Typing very large amounts at 18 decimals overflows int64 inside `push`/`_evaluate`. That bug predates this work and is out of scope. Unbounded fuzzing reports it over and over and hides real findings. Keep 18-decimal operands fractional and avoid ÷/× there.

## Why This Matters

Each rule closes a failure that actually shipped to review:

| Without | What happened |
|---|---|
| Rule 1 | The calculation was lost on save. Edit/Duplicate could only show the result. |
| Rule 1 (single source) | After `1 + 2 + =` the lists kept `1+2` but the cached `leftOperand`/`operator`/`rightOperand` were null: two different answers about the same expression. |
| Rule 3 | `1+2*2` was saved next to 6.00. Any reader, export or future feature that applies normal precedence gets 5. |
| Rule 4 | A trusted-but-wrong formula would display a result that disagrees with the balance-affecting amount. |
| Rule 5 | `5 - 10 + 20` showed 20.00, the saved formula read 15, and replay quietly discarded it. |
| Rule 6 | Editing `3+4` to a plain `9` would keep `3+4` in the row. The replay check hides it, but the data is wrong. |

The stored amount is the money; the formula is an explanation that has to prove itself every time it is loaded. That keeps balances safe even if the codec or the arithmetic changes later. The worst case is that an old formula is ignored.

## When to Apply

- Persisting any derived value next to the inputs that produced it: store the inputs canonically, replay them, keep the derived value authoritative.
- Expression or calculator state where evaluation order differs from what a reader assumes.
- Text that is both stored and displayed: one renderer with pluggable operand/operator formatting; locale only on screen.
- Parsing a format you also write: re-encode-and-compare gives a strict parser for free.
- Nullable columns updated through a companion: decide explicitly between "absent" and "write null".
- Refactors that remove cached or duplicated state: derive, assert the shape, and prove equivalence with a differential fuzz against `git show <pre-refactor-commit>:<file>`.

## Examples

**Per-step clamp → clamp the result** (`_evaluate`, `equals`, `fromFormula`):

```dart
// Before
CalcOperator.subtract => (leftOperand - rightOperand).clamp(0, leftOperand),
// After
CalcOperator.subtract => leftOperand - rightOperand,
// ...and only where a result is produced:
amountMinorUnits: _nonNegative(_fold(operands, operators, decimals: decimals)),
```

**Flat → bracketed storage:**

| Keys | Stored before | Stored after | Result |
|---|---|---|---|
| `1 + 2 × 2 =` | `1+2*2` | `(1+2)*2` | 6.00 |
| `1 + 2 × 2 + 3 × 4 =` | `1+2*2+3*4` | `((1+2)*2+3)*4` | 36.00 |
| `2 × 3 + 4 =` | `2*3+4` | `2*3+4` | 10.00 |

**Cached fields → derived getters:**

```dart
// Before: stored, kept in sync by hand in every mutator
final int? leftOperand;
final CalcOperator? operator;
final int? rightOperand;

// After: derived from the formula lists
CalcOperator? get operator => formulaOperators.isEmpty ? null : formulaOperators.last;
int? get rightOperand => showingResult && formulaOperators.isNotEmpty
    ? formulaOperands.last.amountMinorUnits : null;
// leftOperand({required int decimals}) folds the lists; see rule 1.
```

**Committed tests:**
- `test/unit/utils/amount_formula_test.dart`: codec, brackets, canonical rejection.
- `test/unit/utils/keypad_formula_test.dart`: recording, replay, backspace into a formula, result-only clamp, `1 + 2 + =` getters.
- `test/unit/utils/keypad_decimal_math_test.dart`: arithmetic and backspace.
- `test/unit/controllers/transaction_form_formula_test.dart`: save, reload, and fallbacks.
- `test/widget/features/transactions/amount_display_formula_test.dart`: the history line.
- `test/integration/amount_formula_flow_test.dart`: Add → save → Edit → recalculate → edit → save on a real Drift DB.

## Related

- PRs: #48 (chained operators, `=`, left-to-right evaluation), #51 (formula storage, schema v6), #53 (single source of truth).
- `PRD.md` → *Database Schema → transactions* (`amount_formula` notes): the authoritative format spec.
- [`../logic-errors/transaction-form-workflow-integrity-2026-04-25.md`](../logic-errors/transaction-form-workflow-integrity-2026-04-25.md): Duplicate never reuses minor units across a currency change; `_keypadForStored` sits behind that same guard.
- [`../database-issues/drift-schema-v1-snapshot-drift-2026-04-23.md`](../database-issues/drift-schema-v1-snapshot-drift-2026-04-23.md): the version-bump, snapshot and `addColumn` pattern the v6 migration follows.
- [`../logic-errors/account-transaction-currency-invariant-2026-04-25.md`](../logic-errors/account-transaction-currency-invariant-2026-04-25.md): money invariants owned by the repository; derived or display data never overrides `amount_minor_units`.
