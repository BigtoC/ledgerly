import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule_draft.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';

import '_harness/test_app_database.dart';

Future<void> _seedCurrencyUsd(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO currencies '
    '(code, decimals, symbol, name_l10n_key, is_token, sort_order) '
    'VALUES (?, ?, ?, ?, 0, ?)',
    <Object?>['USD', 2, r'$', 'currency.usd', 1],
  );
}

int _categoryCounter = 0;

Future<int> _insertCategoryRaw(
  AppDatabase db, {
  String type = 'expense',
  bool archived = false,
}) async {
  _categoryCounter++;
  await db.customStatement(
    'INSERT INTO categories (l10n_key, icon, color, type, sort_order, '
    'is_archived) VALUES (?, ?, ?, ?, ?, ?)',
    <Object?>[
      'cat.test.$_categoryCounter',
      'tag',
      0,
      type,
      1,
      archived ? 1 : 0,
    ],
  );
  final rows = await db
      .customSelect('SELECT id FROM categories ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

Future<int> _insertAccountRaw(
  AppDatabase db, {
  String currency = 'USD',
  bool archived = false,
}) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO account_types '
    '(l10n_key, icon, color, sort_order, is_archived) '
    'VALUES (?, ?, ?, ?, ?)',
    <Object?>['at.test', 'wallet', 0, 1, 0],
  );
  final typeRows = await db
      .customSelect('SELECT id FROM account_types ORDER BY id ASC LIMIT 1')
      .get();
  final typeId = typeRows.first.read<int>('id');
  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, '
    'opening_balance_minor_units, is_archived) '
    "VALUES ('Cash', ?, ?, 0, ?)",
    <Object?>[typeId, currency, archived ? 1 : 0],
  );
  final rows = await db
      .customSelect('SELECT id FROM accounts ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

void main() {
  group('RecurringRulesRepository', () {
    late AppDatabase db;
    late DriftRecurringRulesRepository repo;
    late int categoryId;
    late int accountId;

    setUp(() async {
      db = newTestAppDatabase();
      await _seedCurrencyUsd(db);
      categoryId = await _insertCategoryRaw(db);
      accountId = await _insertAccountRaw(db);
      repo = DriftRecurringRulesRepository(
        db,
        clock: () => DateTime(2026, 5, 7),
      );
    });

    tearDown(() async => db.close());

    RecurringRuleDraft draft({
      String name = 'Netflix',
      int amount = 1599,
      String frequency = 'monthly',
      int? dayOfWeek,
      int? dayOfMonth,
      int? monthOfYear,
    }) => RecurringRuleDraft(
      name: name,
      amountMinorUnits: amount,
      currency: _usd,
      categoryId: categoryId,
      accountId: accountId,
      frequency: frequency,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
    );

    group('initial next_due_date', () {
      test('daily rule sets next_due_date to today', () async {
        final today = DateTime(2026, 5, 7);
        final id = await repo.insert(draft(frequency: 'daily'), today: today);
        final rule = await repo.getById(id);
        expect(rule!.nextDueDate, DateTime(2026, 5, 7));
      });

      test('weekly rule finds next matching weekday', () async {
        // May 7, 2026 is Thursday (Dart weekday=4). dayOfWeek=5 → Friday.
        final today = DateTime(2026, 5, 7);
        final id = await repo.insert(
          draft(frequency: 'weekly', dayOfWeek: 5),
          today: today,
        );
        final rule = await repo.getById(id);
        expect(rule!.nextDueDate, DateTime(2026, 5, 8));
      });

      test('weekly rule when today matches', () async {
        // May 7 is Thursday (Dart weekday=4) → spec dayOfWeek=4 = today.
        final today = DateTime(2026, 5, 7);
        final id = await repo.insert(
          draft(frequency: 'weekly', dayOfWeek: 4),
          today: today,
        );
        final rule = await repo.getById(id);
        expect(rule!.nextDueDate, DateTime(2026, 5, 7));
      });

      test('monthly clamps day_of_month to shorter month', () async {
        final today = DateTime(2026, 2, 5);
        final id = await repo.insert(
          draft(frequency: 'monthly', dayOfMonth: 31),
          today: today,
        );
        final rule = await repo.getById(id);
        expect(rule!.nextDueDate, DateTime(2026, 2, 28));
      });

      test('monthly when day already passed this month', () async {
        final today = DateTime(2026, 5, 20);
        final id = await repo.insert(
          draft(frequency: 'monthly', dayOfMonth: 15),
          today: today,
        );
        final rule = await repo.getById(id);
        expect(rule!.nextDueDate, DateTime(2026, 6, 15));
      });

      test('yearly with leap-year clamping', () async {
        final today = DateTime(2026, 1, 1);
        final id = await repo.insert(
          draft(frequency: 'yearly', monthOfYear: 2, dayOfMonth: 29),
          today: today,
        );
        final rule = await repo.getById(id);
        expect(rule!.nextDueDate, DateTime(2026, 2, 28));
      });
    });

    group('validation', () {
      test('throws FrequencyFieldsMissingException when '
          'weekly day_of_week null', () async {
        expect(
          () => repo.insert(draft(frequency: 'weekly')),
          throwsA(isA<FrequencyFieldsMissingException>()),
        );
      });

      test('throws ArchivedReferenceException for archived category', () async {
        final archivedCat = await _insertCategoryRaw(db, archived: true);
        final d = RecurringRuleDraft(
          name: 'X',
          amountMinorUnits: 100,
          currency: _usd,
          categoryId: archivedCat,
          accountId: accountId,
          frequency: 'daily',
        );
        expect(
          () => repo.insert(d),
          throwsA(isA<ArchivedReferenceException>()),
        );
      });
    });

    group('lifecycle', () {
      test('update recomputes next_due_date when schedule changes', () async {
        final id = await repo.insert(
          draft(frequency: 'monthly', dayOfMonth: 15),
          today: DateTime(2026, 5, 10),
        );

        await repo.update(id, draft(frequency: 'monthly', dayOfMonth: 20));

        final rule = await repo.getById(id);
        expect(rule!.dayOfMonth, 20);
        expect(rule.nextDueDate, DateTime(2026, 5, 20));
      });

      test('archive sets is_archived and is_active false', () async {
        final id = await repo.insert(
          draft(frequency: 'daily'),
          today: DateTime(2026, 5, 7),
        );
        await repo.archive(id);
        final rule = await repo.getById(id);
        expect(rule!.isArchived, isTrue);
        expect(rule.isActive, isFalse);
      });

      test('archive is idempotent', () async {
        final id = await repo.insert(
          draft(frequency: 'daily'),
          today: DateTime(2026, 5, 7),
        );
        await repo.archive(id);
        await repo.archive(id);
        final rule = await repo.getById(id);
        expect(rule!.isArchived, isTrue);
      });

      test('pause flips is_active false', () async {
        final id = await repo.insert(
          draft(frequency: 'daily'),
          today: DateTime(2026, 5, 7),
        );
        await repo.setActive(id, active: false);
        final rule = await repo.getById(id);
        expect(rule!.isActive, isFalse);
      });

      test('resume recomputes next_due_date from today', () async {
        final id = await repo.insert(
          draft(frequency: 'monthly', dayOfMonth: 15),
          today: DateTime(2026, 5, 14),
        );
        // After insert: next_due is May 15.
        await repo.setActive(id, active: false);
        // Resume on June 20 → next_due should be July 15.
        await repo.setActive(id, active: true, today: DateTime(2026, 6, 20));
        final rule = await repo.getById(id);
        expect(rule!.isActive, isTrue);
        expect(rule.nextDueDate, DateTime(2026, 7, 15));
      });
    });

    group('date math', () {
      test('advanceDateByFrequency monthly', () async {
        final id = await repo.insert(
          draft(frequency: 'monthly', dayOfMonth: 31),
          today: DateTime(2026, 3, 31),
        );
        final rule = (await repo.getById(id))!;
        final next = repo.advanceDateByFrequency(rule, DateTime(2026, 3, 31));
        expect(next, DateTime(2026, 4, 30)); // Clamped.
        final next2 = repo.advanceDateByFrequency(rule, next);
        expect(next2, DateTime(2026, 5, 31));
      });

      test('fastForwardToRecent advances past today', () async {
        final id = await repo.insert(
          draft(frequency: 'daily'),
          today: DateTime(2026, 1, 1),
        );
        final rule = (await repo.getById(id))!;
        final today = DateTime(2026, 5, 7);
        final result = repo.fastForwardToRecent(rule, today);
        expect(result, today);
      });
    });

    group('streams', () {
      test('watchActive emits inserted rules', () async {
        await repo.insert(
          draft(name: 'B', frequency: 'daily'),
          today: DateTime(2026, 5, 7),
        );
        await repo.insert(
          draft(name: 'A', frequency: 'daily'),
          today: DateTime(2026, 5, 7),
        );

        final list = await repo.watchActive().first;
        expect(list, hasLength(2));
      });
    });

    group('findDue', () {
      test('returns only rules with next_due_date <= today, '
          'active and non-archived', () async {
        final dueId = await repo.insert(
          draft(frequency: 'daily'),
          today: DateTime(2026, 5, 7),
        );
        await repo.insert(
          draft(name: 'Future', frequency: 'monthly', dayOfMonth: 1),
          today: DateTime(2026, 5, 10),
        );
        final pausedId = await repo.insert(
          draft(name: 'Paused', frequency: 'daily'),
          today: DateTime(2026, 5, 7),
        );
        await repo.setActive(pausedId, active: false);

        final due = await repo.findDue(DateTime(2026, 5, 7));
        expect(due.map((r) => r.id), [dueId]);
      });
    });
  });
}
