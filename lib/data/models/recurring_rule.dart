import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'recurring_rule.freezed.dart';

/// Domain model for a recurring transaction rule.
///
/// `frequency` is the raw string ('daily' | 'weekly' | 'monthly' | 'yearly')
/// that the table stores. The repository treats unknown values as a
/// programming error (throws). Per-frequency fields:
///   - 'daily':  no extra fields.
///   - 'weekly': `dayOfWeek` (0=Sun..6=Sat) required.
///   - 'monthly': `dayOfMonth` (1-31) required; clamped to last day of
///     shorter months at compute time.
///   - 'yearly': both `monthOfYear` (1-12) and `dayOfMonth` required.
@freezed
abstract class RecurringRule with _$RecurringRule {
  const factory RecurringRule({
    required int id,
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
    required bool isActive,
    required bool isArchived,
    required DateTime nextDueDate,
    String? lastError,
    DateTime? lastErrorAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RecurringRule;
}
