import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_preferences_table.dart';

part 'user_preferences_dao.g.dart';

/// Thin SQL wrapper for `user_preferences`.
///
/// JSON encoding/decoding of `value` lives in
/// `UserPreferencesRepository` (M3). This DAO stays agnostic: every
/// value is a raw `String`.
@DriftAccessor(tables: [UserPreferences])
class UserPreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$UserPreferencesDaoMixin {
  UserPreferencesDao(super.db);

  /// Watch a single key's value. Emits `null` when the key is missing.
  Stream<String?> watch(String key) {
    return (select(userPreferences)..where((p) => p.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  /// Watch every row. Debug / settings bulk read.
  Stream<List<UserPreferenceRow>> watchAll() {
    return select(userPreferences).watch();
  }

  /// One-shot read. Returns `null` when the key is missing.
  Future<String?> read(String key) async {
    final row = await (select(userPreferences)
          ..where((p) => p.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Upsert on the primary key (`key`).
  Future<void> write(String key, String value) async {
    await into(userPreferences).insertOnConflictUpdate(
      UserPreferencesCompanion.insert(key: key, value: value),
    );
  }

  /// Delete a row by key.
  ///
  /// Named `deleteByKey` rather than `delete` because `DatabaseAccessor`
  /// (via `DatabaseConnectionUser`) already defines a
  /// `delete<Table>(TableInfo)` method used to build delete statements;
  /// declaring an instance method named `delete` would collide with
  /// that signature. Stream A §3.6 lists this as `delete(String)`;
  /// renaming preserves the semantics without shadowing Drift's own
  /// builder.
  Future<int> deleteByKey(String key) {
    return (delete(userPreferences)..where((p) => p.key.equals(key))).go();
  }
}
