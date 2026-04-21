import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'transaction.freezed.dart';

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

    /// Repository-populated at insert; immutable across updates (M3).
    required DateTime createdAt,

    /// Repository-populated at insert; refreshed on every update (M3).
    required DateTime updatedAt,
  }) = _Transaction;
}
