import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recurring_rules_table.dart';

part 'recurring_rule_dao.g.dart';

/// Thin SQL wrapper for `recurring_rules`.
///
/// Business rules (next_due_date computation, archive-vs-delete,
/// reference validation) live in `RecurringRulesRepository`. This DAO
/// returns Drift rows only.
@DriftAccessor(tables: [RecurringRules])
class RecurringRuleDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRuleDaoMixin {
  RecurringRuleDao(super.db);

  /// All non-archived rules: active first, then ordered by next_due_date
  /// ascending; paused rules sort to the end by name.
  Stream<List<RecurringRuleRow>> watchActive() {
    return (select(recurringRules)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isActive, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.nextDueDate, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Active, non-archived rules whose next_due_date <= [today].
  Future<List<RecurringRuleRow>> findDue(DateTime today) {
    return (select(recurringRules)..where(
          (t) =>
              t.isActive.equals(true) &
              t.isArchived.equals(false) &
              t.nextDueDate.isSmallerOrEqualValue(today),
        ))
        .get();
  }

  /// One-shot read by id.
  Future<RecurringRuleRow?> findById(int id) {
    return (select(
      recurringRules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new row. Returns the new id.
  Future<int> insert(RecurringRulesCompanion row) {
    return into(recurringRules).insert(row);
  }

  /// Replace row by PK.
  Future<bool> updateRow(RecurringRulesCompanion row) {
    return update(recurringRules).replace(row);
  }

  /// Archive by id: sets is_archived=true, is_active=false.
  Future<void> archiveById(int id) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      const RecurringRulesCompanion(
        isArchived: Value(true),
        isActive: Value(false),
      ),
    );
  }

  /// Set active flag.
  Future<void> setActive(int id, {required bool active}) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(isActive: Value(active)),
    );
  }

  /// Advance next_due_date after generation.
  Future<void> updateNextDueDate(
    int id,
    DateTime newDate,
    DateTime updatedAt,
  ) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(
        nextDueDate: Value(newDate),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Record a generation failure on the rule.
  Future<void> recordFailure(
    int id,
    String message,
    DateTime at,
    DateTime updatedAt,
  ) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(
        lastError: Value(message),
        lastErrorAt: Value(at),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Clear a previously-recorded failure.
  Future<void> clearFailure(int id, DateTime updatedAt) async {
    await (update(recurringRules)..where((t) => t.id.equals(id))).write(
      RecurringRulesCompanion(
        lastError: const Value(null),
        lastErrorAt: const Value(null),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Hard-delete by id.
  Future<int> deleteById(int id) {
    return (delete(recurringRules)..where((t) => t.id.equals(id))).go();
  }
}
