import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'transaction.freezed.dart';

/// One day's expense and income totals per currency code. Both values are
/// unsigned sums in minor units.
typedef DailyTotals = Map<String, ({int expense, int income})>;

/// User transaction. Mirrors `transactions` row (PRD.md 275-291).
///
/// `currency` stores the original transaction currency — Phase 2 price
/// conversion never overwrites it (PRD.md 291).
///
/// No `type` field: expense/income is derived from the linked
/// `Category.type` (PRD 290). A `type` on `Transaction` would double-source
/// that truth.
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required int id,

    /// Random v4 UUID, the same on every device, so CSV import can
    /// recognise a row it exported. Empty for a row not saved yet: the
    /// database sets it on insert and `save` never changes it. Only
    /// `insertImported` writes one it is given.
    @Default('') String uuid,

    /// Integer minor units. Scaling factor is `Currency.decimals`. Never
    /// a double, not even for display. See PRD.md -> Money Storage Policy.
    required int amountMinorUnits,

    /// Original-transaction currency value object on the read side. Drift
    /// column stays a `TEXT` FK to `currencies.code`.
    required Currency currency,

    /// FK -> `categories.id`. Type (expense/income) derives from the
    /// linked category.
    required int categoryId,

    /// FK -> `accounts.id`.
    required int accountId,

    /// User-supplied transaction date.
    required DateTime date,

    /// Optional free text.
    String? memo,

    /// Keypad expression that produced [amountMinorUnits] (e.g.
    /// `3.5+10.5+11+3`), or null when the amount was typed directly.
    String? amountFormula,

    /// Repository-populated at insert; immutable across updates (M3).
    required DateTime createdAt,

    /// Repository-populated at insert; refreshed on every update (M3).
    required DateTime updatedAt,
  }) = _Transaction;
}
