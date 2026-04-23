// Tests for `UserPreferencesRepository` (M3 Stream C §6.1).
//
// Uses the shared in-memory harness at `_harness/test_app_database.dart`.
// Every case has a direct row in the §6.1 Test Plan table.

import 'package:flutter/material.dart' show ThemeMode, Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/repositories/repository_exceptions.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';

import '_harness/test_app_database.dart';

void main() {
  late AppDatabase db;
  late UserPreferencesRepository prefs;

  setUp(() {
    db = newTestAppDatabase();
    prefs = DriftUserPreferencesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserPreferencesRepository — theme', () {
    test('theme round-trip: setThemeMode -> getThemeMode', () async {
      expect(await prefs.getThemeMode(), ThemeMode.system);
      await prefs.setThemeMode(ThemeMode.dark);
      expect(await prefs.getThemeMode(), ThemeMode.dark);
    });

    test('watchThemeMode emits default then write', () async {
      final expectation = expectLater(
        prefs.watchThemeMode(),
        emitsInOrder(<ThemeMode>[ThemeMode.system, ThemeMode.dark]),
      );
      // Defer the write so the subscription is installed first and the
      // default value has already been emitted by the time we mutate.
      await Future<void>.delayed(Duration.zero);
      await prefs.setThemeMode(ThemeMode.dark);
      await expectation;
    });

    test('theme decode failure: corrupt value throws '
        'PreferenceDecodeException with .key and .rawValue', () async {
      // Pre-seed the DAO directly to simulate a corrupt row.
      await db.userPreferencesDao.write('theme_mode', '"purple"');
      try {
        await prefs.getThemeMode();
        fail('expected PreferenceDecodeException');
      } on PreferenceDecodeException catch (e) {
        expect(e, isA<RepositoryException>());
        expect(e.key, 'theme_mode');
        expect(e.rawValue, '"purple"');
        expect(e.toString(), contains('theme_mode'));
      }
    });
  });

  group('UserPreferencesRepository — locale', () {
    test('locale default is null (follow device)', () async {
      expect(await prefs.getLocale(), isNull);
    });

    test('locale round-trip: null then zh_TW', () async {
      await prefs.setLocale(null);
      expect(await prefs.getLocale(), isNull);

      await prefs.setLocale(const Locale('zh', 'TW'));
      final stored = await prefs.getLocale();
      expect(stored, const Locale('zh', 'TW'));
    });

    test('locale round-trip: language-only code (de)', () async {
      await prefs.setLocale(const Locale('de'));
      expect(await prefs.getLocale(), const Locale('de'));
    });
  });

  group('UserPreferencesRepository — default currency', () {
    test('default currency fallback is USD when missing', () async {
      expect(await prefs.getDefaultCurrency(), 'USD');
    });

    test('default currency round-trip: TWD', () async {
      await prefs.setDefaultCurrency('TWD');
      expect(await prefs.getDefaultCurrency(), 'TWD');
    });
  });

  group('UserPreferencesRepository — default account id', () {
    test('missing key resolves to null', () async {
      expect(await prefs.getDefaultAccountId(), isNull);
    });

    test('round-trip: 42 -> null -> 7', () async {
      await prefs.setDefaultAccountId(42);
      expect(await prefs.getDefaultAccountId(), 42);

      await prefs.setDefaultAccountId(null);
      expect(await prefs.getDefaultAccountId(), isNull);

      await prefs.setDefaultAccountId(7);
      expect(await prefs.getDefaultAccountId(), 7);
    });
  });

  group('UserPreferencesRepository — first-run gate', () {
    test('default is false', () async {
      expect(await prefs.getFirstRunComplete(), isFalse);
    });

    test('markFirstRunComplete writes true; second call is a no-op', () async {
      await prefs.markFirstRunComplete();
      expect(await prefs.getFirstRunComplete(), isTrue);
      // Second call does not throw.
      await prefs.markFirstRunComplete();
      expect(await prefs.getFirstRunComplete(), isTrue);
    });
  });

  group('UserPreferencesRepository — splash defaults', () {
    test('watchSplashEnabled default-emits true', () async {
      expect(await prefs.watchSplashEnabled().first, isTrue);
      expect(await prefs.getSplashEnabled(), isTrue);
    });

    test('watchSplashStartDate default-emits null', () async {
      expect(await prefs.watchSplashStartDate().first, isNull);
      expect(await prefs.getSplashStartDate(), isNull);
    });

    test('watchSplashDisplayText default-emits "Since {date}"', () async {
      expect(await prefs.watchSplashDisplayText().first, 'Since {date}');
      expect(await prefs.getSplashDisplayText(), kDefaultSplashDisplayText);
    });

    test('watchSplashButtonLabel default-emits "Enter"', () async {
      expect(await prefs.watchSplashButtonLabel().first, 'Enter');
      expect(await prefs.getSplashButtonLabel(), kDefaultSplashButtonLabel);
    });
  });

  group('UserPreferencesRepository — splash round-trips', () {
    test('splash start date ISO-8601 round-trip (UTC)', () async {
      final date = DateTime.utc(2026, 4, 22);
      await prefs.setSplashStartDate(date);
      expect(await prefs.getSplashStartDate(), date);
    });

    test('splash start date null clears the value', () async {
      await prefs.setSplashStartDate(DateTime.utc(2026, 4, 22));
      await prefs.setSplashStartDate(null);
      expect(await prefs.getSplashStartDate(), isNull);
    });

    test('splash display text custom round-trip', () async {
      await prefs.setSplashDisplayText('Day {days}');
      expect(await prefs.getSplashDisplayText(), 'Day {days}');
    });

    test('splash button label custom round-trip', () async {
      await prefs.setSplashButtonLabel('Go');
      expect(await prefs.getSplashButtonLabel(), 'Go');
    });

    test('watchSplashEnabled emits [true, false] on write', () async {
      final expectation = expectLater(
        prefs.watchSplashEnabled(),
        emitsInOrder(<bool>[true, false]),
      );
      await Future<void>.delayed(Duration.zero);
      await prefs.setSplashEnabled(false);
      await expectation;
    });
  });

  group('UserPreferencesRepository — corruption', () {
    test('malformed JSON throws PreferenceDecodeException for '
        'splash_enabled', () async {
      await db.userPreferencesDao.write('splash_enabled', 'not-json-at-all');
      try {
        await prefs.getSplashEnabled();
        fail('expected PreferenceDecodeException');
      } on PreferenceDecodeException catch (e) {
        expect(e, isA<RepositoryException>());
        expect(e.key, 'splash_enabled');
        expect(e.rawValue, 'not-json-at-all');
      }
    });

    test('wrong-shape JSON throws PreferenceDecodeException for '
        'default_account_id', () async {
      await db.userPreferencesDao.write('default_account_id', '"not-an-int"');
      try {
        await prefs.getDefaultAccountId();
        fail('expected PreferenceDecodeException');
      } on PreferenceDecodeException catch (e) {
        expect(e, isA<RepositoryException>());
        expect(e.key, 'default_account_id');
        expect(e.rawValue, '"not-an-int"');
      }
    });
  });
}
