// Splash template-substitution contract tests (plan §3.4, §5).
//
// The splash controller resolves `{date}` and `{days}` in the splash display
// text template. Substitution happens in the controller (not `build()`), is
// case-sensitive, and leaves unknown `{placeholders}` untouched. This test
// proves those invariants against a stable helper surface — delegating to
// `DateHelpers.applySplashTemplate` which is the single canonical
// implementation per `core/utils/date_helpers.dart`.
//
// Cases enumerated by plan §5 + "Controller template-substitution rule":
//   - `{date}` / `{days}` substitute literally.
//   - `{daysx}` does NOT substitute.
//   - `{DAYS}` does NOT substitute (case-sensitive).
//   - Empty string returns empty string.
//   - Future start date yields negative day count (no clamp).

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/core/utils/date_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
  });

  group('splash template substitution (plan §5)', () {
    final startDate = DateTime(2026, 1, 1);
    final now = DateTime(2026, 4, 11); // 100 days later

    test('S01: {date} and {days} substitute literally', () {
      final out = DateHelpers.applySplashTemplate(
        template: '{days} days since {date}',
        startDate: startDate,
        now: now,
        locale: 'en_US',
      );
      expect(out, '100 days since Jan 1, 2026');
    });

    test('S02: {daysx} does NOT substitute (suffix-sensitive)', () {
      final out = DateHelpers.applySplashTemplate(
        template: 'raw {daysx} keep',
        startDate: startDate,
        now: now,
        locale: 'en_US',
      );
      expect(out, 'raw {daysx} keep');
    });

    test('S03: {DAYS} does NOT substitute (case-sensitive)', () {
      final out = DateHelpers.applySplashTemplate(
        template: 'upper {DAYS} keep',
        startDate: startDate,
        now: now,
        locale: 'en_US',
      );
      expect(out, 'upper {DAYS} keep');
    });

    test('S04: {Date} does NOT substitute (case-sensitive)', () {
      final out = DateHelpers.applySplashTemplate(
        template: 'upper {Date} keep',
        startDate: startDate,
        now: now,
        locale: 'en_US',
      );
      expect(out, 'upper {Date} keep');
    });

    test('S05: empty template returns empty string', () {
      final out = DateHelpers.applySplashTemplate(
        template: '',
        startDate: startDate,
        now: now,
        locale: 'en_US',
      );
      expect(out, '');
    });

    test('S06: future start date yields negative {days} (no clamp)', () {
      final out = DateHelpers.applySplashTemplate(
        template: '{days} days since {date}',
        startDate: DateTime(2026, 4, 30),
        now: DateTime(2026, 4, 21),
        locale: 'en_US',
      );
      expect(out, '-9 days since Apr 30, 2026');
    });

    test('S07: repeated occurrences all substitute', () {
      final out = DateHelpers.applySplashTemplate(
        template: '{days}/{days} ({date})',
        startDate: startDate,
        now: now,
        locale: 'en_US',
      );
      expect(out, '100/100 (Jan 1, 2026)');
    });
  });
}
