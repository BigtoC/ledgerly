import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'recurring_rule_draft.freezed.dart';

/// Form-input value object for creating/updating a recurring rule.
///
/// Excludes id, next_due_date, is_active, is_archived, and timestamps —
/// those are repository-managed.
@freezed
abstract class RecurringRuleDraft with _$RecurringRuleDraft {
  const factory RecurringRuleDraft({
    required String name,
    required int amountMinorUnits,
    required Currency currency,
    required int categoryId,
    required int accountId,
    String? memo,
    required String frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
  }) = _RecurringRuleDraft;
}
