import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'pending_transaction.freezed.dart';

/// Domain model for a pending (un-approved) transaction.
///
/// `source` discriminates between 'blockchain' and 'recurring'. MVP only
/// surfaces the shared fields plus `recurringRuleId`; blockchain-specific
/// fields land with the Phase 2 Ankr integration.
@freezed
abstract class PendingTransaction with _$PendingTransaction {
  const factory PendingTransaction({
    required int id,
    required String source,
    required int amountMinorUnits,
    required Currency currency,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  }) = _PendingTransaction;
}
