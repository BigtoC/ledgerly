// `UserPreferencesRepository` — SSOT for the `user_preferences` key/value
// table. Typed getters + setters + watchers over the JSON-encoded `value`
// column.
//
// The first-run seed lives in `lib/data/seed/first_run_seed.dart` and uses
// this repository's `getFirstRunComplete` / `markFirstRunComplete` as its
// idempotency gate. The seed is intentionally NOT a method on this class
// so the KV-table concern and the cross-table orchestration stay separate
// (Stream C plan §2.1).
//
// Contract rules (Stream C plan §1):
//   - Every `user_preferences.value` is JSON-encoded, scalars included
//     (`true` → `"true"`, `'light'` → `'"light"'`, `42` → `'42'`). The
//     DAO stays agnostic; this repository owns `jsonEncode` / `jsonDecode`.
//   - Missing keys resolve to the caller-supplied `defaultValue`. Only
//     actively corrupted JSON surfaces as [PreferenceDecodeException].
//   - `watchX()` streams share the DAO's `.watchSingleOrNull()` and do not
//     write a default on first subscribe.
//   - No business-rule validation (e.g. "default_currency must exist in
//     `currencies`") — that is a cross-table FK concern owned by the
//     account / transaction repositories.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode, Locale;

import '../database/app_database.dart';
import '../database/daos/user_preferences_dao.dart';
import 'repository_exceptions.dart';

/// Shared seed-default + repository-default constant. Stream C plan §9.8 —
/// the seed writes this literal, and `_watchJson` falls back to it when the
/// key is absent. A drift between the two values would cause "first launch
/// shows one string, wipe-and-reseed shows another". Keep in sync.
const String kDefaultSplashDisplayText = 'Since {date}';

/// Shared seed-default + repository-default for the splash CTA label.
/// Stream C plan §2.3 Step 6.
const String kDefaultSplashButtonLabel = 'Enter';

/// Failure surface for a corrupted `user_preferences.value` cell. Thrown
/// when `jsonDecode` succeeds but the resulting value cannot be coerced
/// into the typed return shape (e.g. `'"purple"'` for `theme_mode`), or
/// when `jsonDecode` itself throws (malformed JSON).
///
/// Extends the shared [RepositoryException] base so callers can handle
/// corrupted preference state alongside other typed repository failures.
class PreferenceDecodeException extends RepositoryException {
  PreferenceDecodeException(this.key, this.rawValue, this.cause)
    : super('user_preferences[$key] corrupted: $cause');

  /// The key whose stored value failed to decode.
  final String key;

  /// The raw (undecoded) string stored at [key].
  final String rawValue;

  /// Underlying decode failure (JSON parse error or type mismatch).
  final Object cause;

  @override
  String toString() => 'PreferenceDecodeException: $message';
}

/// SSOT for `user_preferences`. Owns every write path to the Drift KV
/// table and every JSON-decoded read. Consumers import this interface —
/// the DAO is never exposed to controllers, widgets, or the router.
abstract class UserPreferencesRepository {
  // ---------- Theme (PRD 902) ----------

  /// Watches the stored theme mode. Defaults to [ThemeMode.system].
  Stream<ThemeMode> watchThemeMode();

  /// One-shot read. Defaults to [ThemeMode.system] when missing.
  Future<ThemeMode> getThemeMode();

  Future<void> setThemeMode(ThemeMode mode);

  // ---------- Locale (PRD 887–892) ----------

  /// `null` means "follow device locale" (PRD 887).
  Stream<Locale?> watchLocale();
  Future<Locale?> getLocale();
  Future<void> setLocale(Locale? locale);

  // ---------- Default currency (PRD 665, 687) ----------

  /// ISO 4217 code. The seed guarantees this is present post-first-run.
  /// The repository does NOT validate that `code` exists in `currencies` —
  /// it is a display hint, not a relational row.
  Stream<String> watchDefaultCurrency();
  Future<String> getDefaultCurrency();
  Future<void> setDefaultCurrency(String code);

  // ---------- Default account (PRD 686) ----------

  /// `null` means "use last-used active account" per PRD 686.
  Stream<int?> watchDefaultAccountId();
  Future<int?> getDefaultAccountId();
  Future<void> setDefaultAccountId(int? id);

  // ---------- First-run gate (bootstrap step 6) ----------

  /// Returns `false` when the key is missing. The seed uses this as its
  /// idempotency gate (Stream C plan §2.3 Step 0).
  Future<bool> getFirstRunComplete();

  /// Writes `true`. Idempotent — second call is a no-op from the caller's
  /// perspective.
  Future<void> markFirstRunComplete();

  // ---------- Splash (PRD 439–442, 544–547) ----------

  /// **The router `redirect:` consumes this stream** (Stream C plan
  /// guardrail G10). Widget-level code never subscribes — the `splash`
  /// route is gated from above.
  Stream<bool> watchSplashEnabled();
  Future<bool> getSplashEnabled();
  Future<void> setSplashEnabled(bool enabled);

  Stream<DateTime?> watchSplashStartDate();
  Future<DateTime?> getSplashStartDate();
  Future<void> setSplashStartDate(DateTime? date);

  Stream<String> watchSplashDisplayText();
  Future<String> getSplashDisplayText();
  Future<void> setSplashDisplayText(String text);

  Stream<String> watchSplashButtonLabel();
  Future<String> getSplashButtonLabel();
  Future<void> setSplashButtonLabel(String label);
}

/// Concrete Drift-backed implementation of [UserPreferencesRepository].
final class DriftUserPreferencesRepository
    implements UserPreferencesRepository {
  DriftUserPreferencesRepository(this._db) : _dao = _db.userPreferencesDao;

  // `_db` is retained (not just the DAO) so the first-run seed can call
  // `_db.transaction(...)` on the same instance. The DAO-facing path is
  // `_dao` for succinctness.
  // ignore: unused_field
  final AppDatabase _db;
  final UserPreferencesDao _dao;

  // ---------- Key registry ----------
  //
  // The Dart identifier prefix `_k` is cosmetic — the DB column stores the
  // string literal (e.g. `theme_mode`). Renames after M3 are a schema
  // migration (G7 spirit).

  static const String _kThemeMode = 'theme_mode';
  static const String _kLocale = 'locale';
  static const String _kDefaultCurrency = 'default_currency';
  static const String _kDefaultAccountId = 'default_account_id';
  static const String _kFirstRunCompleted = 'first_run_completed';
  static const String _kSplashEnabled = 'splash_enabled';
  static const String _kSplashStartDate = 'splash_start_date';
  static const String _kSplashDisplayText = 'splash_display_text';
  static const String _kSplashButtonLabel = 'splash_button_label';

  // ---------- JSON codec ----------

  Future<T> _readJson<T>(
    String key, {
    required T defaultValue,
    required T Function(dynamic decoded) decode,
  }) async {
    final raw = await _dao.read(key);
    if (raw == null) return defaultValue;
    return _decodeRaw<T>(key, raw, decode);
  }

  Future<void> _writeJson(String key, Object? encoded) async {
    await _dao.write(key, jsonEncode(encoded));
  }

  Stream<T> _watchJson<T>(
    String key, {
    required T defaultValue,
    required T Function(dynamic decoded) decode,
  }) {
    return _dao.watch(key).map((raw) {
      if (raw == null) return defaultValue;
      return _decodeRaw<T>(key, raw, decode);
    });
  }

  T _decodeRaw<T>(String key, String raw, T Function(dynamic) decode) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      throw PreferenceDecodeException(key, raw, e);
    }
    try {
      return decode(decoded);
    } catch (e) {
      throw PreferenceDecodeException(key, raw, e);
    }
  }

  // ---------- Theme ----------

  @override
  Stream<ThemeMode> watchThemeMode() => _watchJson<ThemeMode>(
    _kThemeMode,
    defaultValue: ThemeMode.light,
    decode: _decodeThemeMode,
  );

  @override
  Future<ThemeMode> getThemeMode() => _readJson<ThemeMode>(
    _kThemeMode,
    defaultValue: ThemeMode.light,
    decode: _decodeThemeMode,
  );

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      _writeJson(_kThemeMode, mode.name);

  static ThemeMode _decodeThemeMode(dynamic v) {
    if (v is! String) {
      throw FormatException(
        'Expected String for theme_mode, got ${v.runtimeType}',
      );
    }
    // "system" was removed from the UI; treat any stored "system" as "light".
    if (v == 'system') return ThemeMode.light;
    return ThemeMode.values.byName(v);
  }

  // ---------- Locale ----------

  @override
  Stream<Locale?> watchLocale() =>
      _watchJson<Locale?>(_kLocale, defaultValue: null, decode: _decodeLocale);

  @override
  Future<Locale?> getLocale() =>
      _readJson<Locale?>(_kLocale, defaultValue: null, decode: _decodeLocale);

  @override
  Future<void> setLocale(Locale? locale) =>
      _writeJson(_kLocale, locale == null ? null : _encodeLocale(locale));

  static String _encodeLocale(Locale locale) {
    final cc = locale.countryCode;
    if (cc == null || cc.isEmpty) return locale.languageCode;
    return '${locale.languageCode}_$cc';
  }

  static Locale? _decodeLocale(dynamic v) {
    if (v == null) return null;
    if (v is! String) {
      throw FormatException('Expected String for locale, got ${v.runtimeType}');
    }
    final parts = v.split('_');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  // ---------- Default currency ----------

  @override
  Stream<String> watchDefaultCurrency() => _watchJson<String>(
    _kDefaultCurrency,
    defaultValue: 'USD',
    decode: _decodeString('default_currency'),
  );

  @override
  Future<String> getDefaultCurrency() => _readJson<String>(
    _kDefaultCurrency,
    defaultValue: 'USD',
    decode: _decodeString('default_currency'),
  );

  @override
  Future<void> setDefaultCurrency(String code) =>
      _writeJson(_kDefaultCurrency, code);

  // ---------- Default account ----------

  @override
  Stream<int?> watchDefaultAccountId() => _watchJson<int?>(
    _kDefaultAccountId,
    defaultValue: null,
    decode: _decodeNullableInt('default_account_id'),
  );

  @override
  Future<int?> getDefaultAccountId() => _readJson<int?>(
    _kDefaultAccountId,
    defaultValue: null,
    decode: _decodeNullableInt('default_account_id'),
  );

  @override
  Future<void> setDefaultAccountId(int? id) =>
      _writeJson(_kDefaultAccountId, id);

  // ---------- First-run gate ----------

  @override
  Future<bool> getFirstRunComplete() => _readJson<bool>(
    _kFirstRunCompleted,
    defaultValue: false,
    decode: _decodeBool('first_run_completed'),
  );

  @override
  Future<void> markFirstRunComplete() => _writeJson(_kFirstRunCompleted, true);

  // ---------- Splash ----------

  @override
  Stream<bool> watchSplashEnabled() => _watchJson<bool>(
    _kSplashEnabled,
    defaultValue: true,
    decode: _decodeBool('splash_enabled'),
  );

  @override
  Future<bool> getSplashEnabled() => _readJson<bool>(
    _kSplashEnabled,
    defaultValue: true,
    decode: _decodeBool('splash_enabled'),
  );

  @override
  Future<void> setSplashEnabled(bool enabled) =>
      _writeJson(_kSplashEnabled, enabled);

  @override
  Stream<DateTime?> watchSplashStartDate() => _watchJson<DateTime?>(
    _kSplashStartDate,
    defaultValue: null,
    decode: _decodeNullableDate('splash_start_date'),
  );

  @override
  Future<DateTime?> getSplashStartDate() => _readJson<DateTime?>(
    _kSplashStartDate,
    defaultValue: null,
    decode: _decodeNullableDate('splash_start_date'),
  );

  @override
  Future<void> setSplashStartDate(DateTime? date) =>
      _writeJson(_kSplashStartDate, date?.toIso8601String());

  @override
  Stream<String> watchSplashDisplayText() => _watchJson<String>(
    _kSplashDisplayText,
    defaultValue: kDefaultSplashDisplayText,
    decode: _decodeString('splash_display_text'),
  );

  @override
  Future<String> getSplashDisplayText() => _readJson<String>(
    _kSplashDisplayText,
    defaultValue: kDefaultSplashDisplayText,
    decode: _decodeString('splash_display_text'),
  );

  @override
  Future<void> setSplashDisplayText(String text) =>
      _writeJson(_kSplashDisplayText, text);

  @override
  Stream<String> watchSplashButtonLabel() => _watchJson<String>(
    _kSplashButtonLabel,
    defaultValue: kDefaultSplashButtonLabel,
    decode: _decodeString('splash_button_label'),
  );

  @override
  Future<String> getSplashButtonLabel() => _readJson<String>(
    _kSplashButtonLabel,
    defaultValue: kDefaultSplashButtonLabel,
    decode: _decodeString('splash_button_label'),
  );

  @override
  Future<void> setSplashButtonLabel(String label) =>
      _writeJson(_kSplashButtonLabel, label);

  // ---------- Decode helpers ----------

  static String Function(dynamic) _decodeString(String key) => (dynamic v) {
    if (v is! String) {
      throw FormatException('Expected String for $key, got ${v.runtimeType}');
    }
    return v;
  };

  static bool Function(dynamic) _decodeBool(String key) => (dynamic v) {
    if (v is! bool) {
      throw FormatException('Expected bool for $key, got ${v.runtimeType}');
    }
    return v;
  };

  static int? Function(dynamic) _decodeNullableInt(String key) => (dynamic v) {
    if (v == null) return null;
    if (v is! int) {
      throw FormatException('Expected int? for $key, got ${v.runtimeType}');
    }
    return v;
  };

  static DateTime? Function(dynamic) _decodeNullableDate(String key) =>
      (dynamic v) {
        if (v == null) return null;
        if (v is! String) {
          throw FormatException(
            'Expected ISO-8601 String for $key, got ${v.runtimeType}',
          );
        }
        return DateTime.parse(v);
      };
}
