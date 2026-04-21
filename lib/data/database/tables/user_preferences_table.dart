import 'package:drift/drift.dart';

/// Drift table for `user_preferences`.
///
/// See `PRD.md` lines 401–414 (Database Schema → user_preferences) and
/// `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.6.
///
/// Key/value store. `value` is **always JSON-encoded**, including
/// scalars: `bool true` as `"true"`, `String "light"` as `"\"light\""`,
/// `int 7` as `"7"`. `UserPreferencesRepository` (M3) uses one
/// `jsonDecode` path for every key. This DAO stays agnostic.
///
/// Known keys (populated by M3 / M4): `theme_mode`, `default_account_id`,
/// `default_currency`, `locale`, `first_run_completed`, `splash_enabled`,
/// `splash_start_date`, `splash_display_text`, `splash_button_label`.
/// Stream A declares no enum or key registry — that is repository
/// territory.
@DataClassName('UserPreferenceRow')
class UserPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
