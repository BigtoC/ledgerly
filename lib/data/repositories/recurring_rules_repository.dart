// `RecurringRulesRepository` — SSOT for `recurring_rules`.
//
// Owns next-due-date computation (initial + advance), reference validation
// (currency / category / account must exist and not be archived), and the
// archive-vs-delete contract. Maps Drift rows into [RecurringRule] domain
// models so callers never see a Drift type.

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/account_dao.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/currency_dao.dart';
import '../database/daos/recurring_rule_dao.dart';
import '../models/currency.dart';
import '../models/recurring_rule.dart';
import '../models/recurring_rule_draft.dart';

class RecurringRulesRepositoryException implements Exception {
  const RecurringRulesRepositoryException(this.message);
  final String message;
  @override
  String toString() => 'RecurringRulesRepositoryException: $message';
}

class ArchivedReferenceException extends RecurringRulesRepositoryException {
  const ArchivedReferenceException(super.message);
}

class FrequencyFieldsMissingException
    extends RecurringRulesRepositoryException {
  const FrequencyFieldsMissingException(super.message);
}

abstract class RecurringRulesRepository {
  Stream<List<RecurringRule>> watchActive();

  /// One-shot query: active, non-archived rules whose next_due_date <= [today].
  Future<List<RecurringRule>> findDue(DateTime today);

  Future<RecurringRule?> getById(int id);

  /// Insert a new rule. Computes initial next_due_date from frequency + today.
  Future<int> insert(RecurringRuleDraft draft, {DateTime? today});

  /// Edit a rule. Affects future generations only — does not touch
  /// already-generated pending rows.
  Future<void> update(int id, RecurringRuleDraft draft);

  /// Pause or resume. Resume recomputes next_due_date from today.
  Future<void> setActive(int id, {required bool active, DateTime? today});

  /// Soft-delete (archive). Idempotent.
  Future<void> archive(int id);

  /// Advance next_due_date after a successful generation pass.
  Future<void> advanceAfterGeneration(int id, DateTime newNextDueDate);

  /// Record a non-recoverable failure for [id].
  Future<void> recordFailure(int id, String message, DateTime at);

  /// Clear the recorded failure for [id]. Called after a successful pass.
  Future<void> clearFailure(int id);

  /// Advance a date by one frequency interval, anchored on the rule's
  /// day_of_month / day_of_week / month_of_year. Centralized here for
  /// the use case to avoid duplication.
  DateTime advanceDateByFrequency(RecurringRule rule, DateTime current);

  /// Fast-forward to the most recent matching occurrence at or before [today].
  /// Throws [StateError] if [safetyCap] iterations are exceeded — guards
  /// against pathological inputs that would otherwise loop indefinitely.
  DateTime fastForwardToRecent(
    RecurringRule rule,
    DateTime today, {
    int safetyCap = 10000,
  });
}

final class DriftRecurringRulesRepository implements RecurringRulesRepository {
  DriftRecurringRulesRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final drift.AppDatabase _db;
  final DateTime Function() _clock;

  RecurringRuleDao get _dao => _db.recurringRuleDao;
  CurrencyDao get _currencyDao => _db.currencyDao;
  CategoryDao get _categoryDao => _db.categoryDao;
  AccountDao get _accountDao => _db.accountDao;

  // ---------- Reads ----------

  @override
  Stream<List<RecurringRule>> watchActive() {
    return _dao.watchActive().asyncMap((rows) async => _rowsToDomain(rows));
  }

  @override
  Future<RecurringRule?> getById(int id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<RecurringRule>> findDue(DateTime today) async {
    final rows = await _dao.findDue(today);
    return _rowsToDomain(rows);
  }

  // ---------- Writes ----------

  @override
  Future<int> insert(RecurringRuleDraft draft, {DateTime? today}) async {
    _validateFrequencyFields(draft);
    await _validateActiveReferences(
      draft.categoryId,
      draft.accountId,
      draft.currency.code,
    );

    final now = _clock();
    final effectiveToday = today ?? DateTime(now.year, now.month, now.day);
    final nextDue = _computeInitialNextDue(draft, effectiveToday);

    return _dao.insert(
      drift.RecurringRulesCompanion(
        name: Value(draft.name),
        amountMinorUnits: Value(draft.amountMinorUnits),
        currency: Value(draft.currency.code),
        categoryId: Value(draft.categoryId),
        accountId: Value(draft.accountId),
        memo: draft.memo != null ? Value(draft.memo) : const Value.absent(),
        frequency: Value(draft.frequency),
        dayOfWeek: draft.dayOfWeek != null
            ? Value(draft.dayOfWeek)
            : const Value.absent(),
        dayOfMonth: draft.dayOfMonth != null
            ? Value(draft.dayOfMonth)
            : const Value.absent(),
        monthOfYear: draft.monthOfYear != null
            ? Value(draft.monthOfYear)
            : const Value.absent(),
        isActive: const Value(true),
        isArchived: const Value(false),
        nextDueDate: Value(nextDue),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> update(int id, RecurringRuleDraft draft) async {
    _validateFrequencyFields(draft);
    await _validateActiveReferences(
      draft.categoryId,
      draft.accountId,
      draft.currency.code,
    );

    final stored = await _dao.findById(id);
    if (stored == null) {
      throw RecurringRulesRepositoryException('Recurring rule $id not found');
    }

    final now = _clock();
    final effectiveToday = DateTime(now.year, now.month, now.day);
    final scheduleChanged =
        stored.frequency != draft.frequency ||
        stored.dayOfWeek != draft.dayOfWeek ||
        stored.dayOfMonth != draft.dayOfMonth ||
        stored.monthOfYear != draft.monthOfYear;
    final nextDueDate = scheduleChanged
        ? _computeInitialNextDue(draft, effectiveToday)
        : stored.nextDueDate;
    await _dao.updateRow(
      drift.RecurringRulesCompanion(
        id: Value(id),
        name: Value(draft.name),
        amountMinorUnits: Value(draft.amountMinorUnits),
        currency: Value(draft.currency.code),
        categoryId: Value(draft.categoryId),
        accountId: Value(draft.accountId),
        memo: draft.memo != null ? Value(draft.memo) : const Value.absent(),
        frequency: Value(draft.frequency),
        dayOfWeek: draft.dayOfWeek != null
            ? Value(draft.dayOfWeek)
            : const Value.absent(),
        dayOfMonth: draft.dayOfMonth != null
            ? Value(draft.dayOfMonth)
            : const Value.absent(),
        monthOfYear: draft.monthOfYear != null
            ? Value(draft.monthOfYear)
            : const Value.absent(),
        isActive: Value(stored.isActive),
        isArchived: Value(stored.isArchived),
        nextDueDate: Value(nextDueDate),
        createdAt: Value(stored.createdAt),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> setActive(
    int id, {
    required bool active,
    DateTime? today,
  }) async {
    final stored = await _dao.findById(id);
    if (stored == null) {
      throw RecurringRulesRepositoryException('Recurring rule $id not found');
    }

    if (!active) {
      await _dao.setActive(id, active: false);
      return;
    }

    // Resume: recompute next_due_date from today, then update both fields.
    final now = _clock();
    final effectiveToday = today ?? DateTime(now.year, now.month, now.day);
    final draft = await _storedToDraft(stored);
    final nextDue = _computeInitialNextDue(draft, effectiveToday);

    await _dao.setActive(id, active: true);
    await _dao.updateNextDueDate(id, nextDue, now);
  }

  @override
  Future<void> archive(int id) async {
    final stored = await _dao.findById(id);
    if (stored == null) {
      throw RecurringRulesRepositoryException('Recurring rule $id not found');
    }
    if (stored.isArchived) return;
    await _dao.archiveById(id);
  }

  @override
  Future<void> advanceAfterGeneration(int id, DateTime newNextDueDate) async {
    await _dao.updateNextDueDate(id, newNextDueDate, _clock());
  }

  @override
  Future<void> recordFailure(int id, String message, DateTime at) {
    return _dao.recordFailure(id, message, at, _clock());
  }

  @override
  Future<void> clearFailure(int id) {
    return _dao.clearFailure(id, _clock());
  }

  // ---------- Date math ----------

  @override
  DateTime advanceDateByFrequency(RecurringRule rule, DateTime current) {
    switch (rule.frequency) {
      case 'daily':
        return DateTime(current.year, current.month, current.day + 1);
      case 'weekly':
        return DateTime(current.year, current.month, current.day + 7);
      case 'monthly':
        final nextMonth = current.month == 12 ? 1 : current.month + 1;
        final nextYear = current.month == 12 ? current.year + 1 : current.year;
        return _clampDay(nextYear, nextMonth, rule.dayOfMonth!);
      case 'yearly':
        final nextYear = current.year + 1;
        return _clampDay(nextYear, rule.monthOfYear!, rule.dayOfMonth!);
      default:
        throw RecurringRulesRepositoryException(
          'Unknown frequency: ${rule.frequency}',
        );
    }
  }

  @override
  DateTime fastForwardToRecent(
    RecurringRule rule,
    DateTime today, {
    int safetyCap = 10000,
  }) {
    final todayMidnight = DateTime(today.year, today.month, today.day);
    var candidate = rule.nextDueDate;
    var next = advanceDateByFrequency(rule, candidate);
    var iterations = 0;
    while (!next.isAfter(todayMidnight)) {
      if (++iterations > safetyCap) {
        throw StateError(
          'fastForwardToRecent exceeded safetyCap=$safetyCap '
          'for rule ${rule.id}',
        );
      }
      candidate = next;
      next = advanceDateByFrequency(rule, candidate);
    }
    return candidate;
  }

  // ---------- Validation ----------

  void _validateFrequencyFields(RecurringRuleDraft draft) {
    switch (draft.frequency) {
      case 'weekly':
        if (draft.dayOfWeek == null) {
          throw const FrequencyFieldsMissingException(
            'day_of_week is required for weekly frequency',
          );
        }
      case 'monthly':
        if (draft.dayOfMonth == null) {
          throw const FrequencyFieldsMissingException(
            'day_of_month is required for monthly frequency',
          );
        }
      case 'yearly':
        if (draft.monthOfYear == null || draft.dayOfMonth == null) {
          throw const FrequencyFieldsMissingException(
            'month_of_year and day_of_month are required for yearly frequency',
          );
        }
      case 'daily':
        break;
      default:
        throw RecurringRulesRepositoryException(
          'Unknown frequency: ${draft.frequency}',
        );
    }
  }

  Future<void> _validateActiveReferences(
    int categoryId,
    int accountId,
    String currencyCode,
  ) async {
    final cat = await _categoryDao.findById(categoryId);
    if (cat == null || cat.isArchived) {
      throw ArchivedReferenceException(
        'Category $categoryId is archived or missing',
      );
    }
    final acc = await _accountDao.findById(accountId);
    if (acc == null || acc.isArchived) {
      throw ArchivedReferenceException(
        'Account $accountId is archived or missing',
      );
    }
    final cur = await _currencyDao.findByCode(currencyCode);
    if (cur == null) {
      throw ArchivedReferenceException('Currency $currencyCode not found');
    }
  }

  // ---------- Next-due-date computation ----------

  DateTime _computeInitialNextDue(RecurringRuleDraft draft, DateTime today) {
    switch (draft.frequency) {
      case 'daily':
        return today;
      case 'weekly':
        return _nextWeeklyDate(today, draft.dayOfWeek!);
      case 'monthly':
        return _nextMonthlyDate(today, draft.dayOfMonth!);
      case 'yearly':
        return _nextYearlyDate(today, draft.monthOfYear!, draft.dayOfMonth!);
      default:
        throw RecurringRulesRepositoryException(
          'Unknown frequency: ${draft.frequency}',
        );
    }
  }

  /// Find the next date on or after [from] whose weekday matches [dayOfWeek]
  /// (0=Sun..6=Sat).
  DateTime _nextWeeklyDate(DateTime from, int dayOfWeek) {
    // Dart weekday: 1=Mon..7=Sun. Spec: 0=Sun..6=Sat.
    final dartWeekday = dayOfWeek == 0 ? 7 : dayOfWeek;
    final diff = (dartWeekday - from.weekday + 7) % 7;
    return DateTime(from.year, from.month, from.day + diff);
  }

  /// Find the next date on or after [from] whose day matches [dayOfMonth],
  /// clamping to the last day of shorter months.
  DateTime _nextMonthlyDate(DateTime from, int dayOfMonth) {
    final clampedThisMonth = _clampDay(from.year, from.month, dayOfMonth);
    if (!from.isAfter(clampedThisMonth)) {
      return clampedThisMonth;
    }
    final nextMonth = from.month == 12 ? 1 : from.month + 1;
    final nextYear = from.month == 12 ? from.year + 1 : from.year;
    return _clampDay(nextYear, nextMonth, dayOfMonth);
  }

  /// Find the next date on or after [from] whose (month, day) match,
  /// clamping for leap years.
  DateTime _nextYearlyDate(DateTime from, int month, int day) {
    final candidate = _clampDay(from.year, month, day);
    if (!candidate.isBefore(DateTime(from.year, from.month, from.day))) {
      return candidate;
    }
    return _clampDay(from.year + 1, month, day);
  }

  /// Clamp [day] to the last day of [year]-[month] and return as a
  /// midnight DateTime.
  DateTime _clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final clamped = day > lastDay ? lastDay : day;
    return DateTime(year, month, clamped);
  }

  // ---------- Mapping ----------

  Future<List<RecurringRule>> _rowsToDomain(
    List<drift.RecurringRuleRow> rows,
  ) async {
    if (rows.isEmpty) return const <RecurringRule>[];
    final codes = rows.map((r) => r.currency).toSet();
    final currenciesByCode = <String, Currency>{};
    for (final code in codes) {
      final row = (await _currencyDao.findByCode(code))!;
      currenciesByCode[code] = _currencyFromRow(row);
    }
    return rows
        .map(
          (row) => RecurringRule(
            id: row.id,
            name: row.name,
            amountMinorUnits: row.amountMinorUnits,
            currency: currenciesByCode[row.currency]!,
            categoryId: row.categoryId,
            accountId: row.accountId,
            memo: row.memo,
            frequency: row.frequency,
            dayOfWeek: row.dayOfWeek,
            dayOfMonth: row.dayOfMonth,
            monthOfYear: row.monthOfYear,
            isActive: row.isActive,
            isArchived: row.isArchived,
            nextDueDate: row.nextDueDate,
            lastError: row.lastError,
            lastErrorAt: row.lastErrorAt,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<RecurringRule> _toDomain(drift.RecurringRuleRow row) async {
    final currencyRow = (await _currencyDao.findByCode(row.currency))!;
    return RecurringRule(
      id: row.id,
      name: row.name,
      amountMinorUnits: row.amountMinorUnits,
      currency: _currencyFromRow(currencyRow),
      categoryId: row.categoryId,
      accountId: row.accountId,
      memo: row.memo,
      frequency: row.frequency,
      dayOfWeek: row.dayOfWeek,
      dayOfMonth: row.dayOfMonth,
      monthOfYear: row.monthOfYear,
      isActive: row.isActive,
      isArchived: row.isArchived,
      nextDueDate: row.nextDueDate,
      lastError: row.lastError,
      lastErrorAt: row.lastErrorAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<RecurringRuleDraft> _storedToDraft(drift.RecurringRuleRow row) async {
    // Always load the real currency. A stub `decimals: 0` would silently
    // corrupt downstream money formatting if the draft escapes this scope —
    // CLAUDE.md is explicit that decimals come from `currencies.decimals`.
    final currencyRow = (await _currencyDao.findByCode(row.currency))!;
    return RecurringRuleDraft(
      name: row.name,
      amountMinorUnits: row.amountMinorUnits,
      currency: _currencyFromRow(currencyRow),
      categoryId: row.categoryId,
      accountId: row.accountId,
      memo: row.memo,
      frequency: row.frequency,
      dayOfWeek: row.dayOfWeek,
      dayOfMonth: row.dayOfMonth,
      monthOfYear: row.monthOfYear,
    );
  }

  Currency _currencyFromRow(drift.Currency row) => Currency(
    code: row.code,
    decimals: row.decimals,
    symbol: row.symbol,
    nameL10nKey: row.nameL10nKey,
    customName: row.customName,
    isToken: row.isToken,
    sortOrder: row.sortOrder,
  );
}
