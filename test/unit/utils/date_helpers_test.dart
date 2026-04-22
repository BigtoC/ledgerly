import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/core/utils/date_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('zh_TW', null);
    await initializeDateFormatting('zh_CN', null);
  });

  group('DateHelpers.startOfDay / isSameDay', () {
    test('D01: startOfDay strips time', () {
      final dt = DateTime(2026, 4, 21, 14, 37, 58, 123);
      expect(DateHelpers.startOfDay(dt), DateTime(2026, 4, 21));
    });
    test('D02: same calendar day = true', () {
      expect(
        DateHelpers.isSameDay(
          DateTime(2026, 4, 21, 0, 0),
          DateTime(2026, 4, 21, 23, 59),
        ),
        isTrue,
      );
    });
    test('D03: crossing midnight = false', () {
      expect(
        DateHelpers.isSameDay(
          DateTime(2026, 4, 21, 23, 59),
          DateTime(2026, 4, 22, 0, 1),
        ),
        isFalse,
      );
    });
  });

  group('DateHelpers.daysBetween', () {
    test('D04: forward 5 days', () {
      expect(
        DateHelpers.daysBetween(DateTime(2026, 4, 21), DateTime(2026, 4, 26)),
        5,
      );
    });
    test('D05: backward -5 days', () {
      expect(
        DateHelpers.daysBetween(DateTime(2026, 4, 26), DateTime(2026, 4, 21)),
        -5,
      );
    });
    test('D06: same day, different times → 0', () {
      expect(
        DateHelpers.daysBetween(
          DateTime(2026, 4, 21, 9, 0),
          DateTime(2026, 4, 21, 23, 30),
        ),
        0,
      );
    });
    test('D07: DST-spanning 2 days is 2, not 1 or 3 (PRD 510-552)', () {
      // 2026-03-08 is US DST start. Using noon on either side avoids any
      // accidental nearness to the 02:00 → 03:00 skip.
      expect(
        DateHelpers.daysBetween(
          DateTime(2026, 3, 7, 12, 0),
          DateTime(2026, 3, 9, 12, 0),
        ),
        2,
      );
    });
  });

  group('DateHelpers.daysSince — splash counter (PRD 510-552)', () {
    test('D08: startDate == today → 0', () {
      expect(
        DateHelpers.daysSince(
          startDate: DateTime(2026, 4, 21),
          now: DateTime(2026, 4, 21, 23, 59),
        ),
        0,
      );
    });
    test('D09: start 10 days ago → 10', () {
      expect(
        DateHelpers.daysSince(
          startDate: DateTime(2026, 4, 11),
          now: DateTime(2026, 4, 21),
        ),
        10,
      );
    });
    test('D10: start 9 days in the future → -9 (no clamp)', () {
      expect(
        DateHelpers.daysSince(
          startDate: DateTime(2026, 4, 30),
          now: DateTime(2026, 4, 21),
        ),
        -9,
      );
    });
  });

  group('DateHelpers.formatDisplayDate — splash date (PRD 525, 549)', () {
    final d = DateTime(2026, 4, 21);
    test('D11: en_US → "Apr 21, 2026"', () {
      expect(DateHelpers.formatDisplayDate(d, 'en_US'), 'Apr 21, 2026');
    });
    test('D12: zh_TW → "2026年4月21日"', () {
      expect(DateHelpers.formatDisplayDate(d, 'zh_TW'), '2026年4月21日');
    });
    test('D13: zh_CN → "2026年4月21日"', () {
      expect(DateHelpers.formatDisplayDate(d, 'zh_CN'), '2026年4月21日');
    });
  });

  group('DateHelpers.formatDayHeader — Home list (PRD 881-882)', () {
    final d = DateTime(2026, 4, 21); // Tuesday
    test('D14: en_US → "Tue, Apr 21"', () {
      expect(DateHelpers.formatDayHeader(d, 'en_US'), 'Tue, Apr 21');
    });
    test('D15: zh_TW contains 4月21日', () {
      expect(DateHelpers.formatDayHeader(d, 'zh_TW'), contains('4月21日'));
    });
  });

  group('DateHelpers.formatShortDate', () {
    final d = DateTime(2026, 4, 21);
    test('D16: en_US → 4/21/2026', () {
      expect(DateHelpers.formatShortDate(d, 'en_US'), '4/21/2026');
    });
    test('D17: zh_CN → 2026/4/21', () {
      expect(DateHelpers.formatShortDate(d, 'zh_CN'), '2026/4/21');
    });
  });

  group('DateHelpers.applySplashTemplate — PRD 526/549-551', () {
    test('D18: default "Since {date}" template', () {
      expect(
        DateHelpers.applySplashTemplate(
          template: 'Since {date}',
          startDate: DateTime(2026, 4, 11),
          now: DateTime(2026, 4, 21),
          locale: 'en_US',
        ),
        'Since Apr 11, 2026',
      );
    });
    test('D19: {days} + {date}', () {
      expect(
        DateHelpers.applySplashTemplate(
          template: '{days} days since {date}',
          startDate: DateTime(2026, 4, 11),
          now: DateTime(2026, 4, 21),
          locale: 'en_US',
        ),
        '10 days since Apr 11, 2026',
      );
    });
    test('D20: {days} at zero', () {
      expect(
        DateHelpers.applySplashTemplate(
          template: '{days} days since {date}',
          startDate: DateTime(2026, 4, 21),
          now: DateTime(2026, 4, 21),
          locale: 'en_US',
        ),
        '0 days since Apr 21, 2026',
      );
    });
  });

  group('DateHelpers.applySplashTemplate — edges', () {
    test('D21: negative {days} passes through as "-9"', () {
      expect(
        DateHelpers.applySplashTemplate(
          template: '{days} days since {date}',
          startDate: DateTime(2026, 4, 30),
          now: DateTime(2026, 4, 21),
          locale: 'en_US',
        ),
        '-9 days since Apr 30, 2026',
      );
    });
    test('D22: unknown placeholder passes through unchanged', () {
      expect(
        DateHelpers.applySplashTemplate(
          template: '{foo} is kept and {days} {date}',
          startDate: DateTime(2026, 4, 11),
          now: DateTime(2026, 4, 21),
          locale: 'en_US',
        ),
        '{foo} is kept and 10 Apr 11, 2026',
      );
    });
    test('D23: large {days} uses locale grouping', () {
      // 2000-04-21 → 2026-04-21 computed via DateHelpers for reference.
      // Expect locale-grouped 4-digit+ integer.
      final days = DateHelpers.daysSince(
        startDate: DateTime(2000, 4, 21),
        now: DateTime(2026, 4, 21),
      );
      // Sanity: at least 9,000 days (26 years).
      expect(days > 9000, isTrue);
      final expected = days >= 1000
          ? '${days ~/ 1000},${(days % 1000).toString().padLeft(3, '0')}'
          : '$days';
      expect(
        DateHelpers.applySplashTemplate(
          template: '{days}',
          startDate: DateTime(2000, 4, 21),
          now: DateTime(2026, 4, 21),
          locale: 'en_US',
        ),
        expected,
      );
    });
  });
}
