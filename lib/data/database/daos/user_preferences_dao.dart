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

  /// One-shot read. Returns `null` when the key is missing.
  Future<String?> read(String key) async {
    final row = await (select(
      userPreferences,
    )..where((p) => p.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Upsert on the primary key (`key`).
  Future<void> write(String key, String value) async {
    await into(userPreferences).insertOnConflictUpdate(
      UserPreferencesCompanion.insert(key: key, value: value),
    );
  }
}
