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

  group('DateHelpers.startOfWeek', () {
    test('Monday returns the same midnight', () {
      // 2026-05-18 is a Monday.
      final monday = DateTime(2026, 5, 18, 14, 30, 22, 500);
      expect(DateHelpers.startOfWeek(monday), DateTime(2026, 5, 18));
    });

    test('mid-week returns the previous Monday midnight', () {
      // 2026-05-21 is a Thursday.
      final thursday = DateTime(2026, 5, 21, 9);
      expect(DateHelpers.startOfWeek(thursday), DateTime(2026, 5, 18));
    });

    test('Sunday returns the previous Monday (six days back)', () {
      // 2026-05-24 is a Sunday.
      final sunday = DateTime(2026, 5, 24, 23, 59);
      expect(DateHelpers.startOfWeek(sunday), DateTime(2026, 5, 18));
    });

    test('crosses a month boundary correctly', () {
      // 2026-06-03 is a Wednesday → Monday is 2026-06-01.
      expect(
        DateHelpers.startOfWeek(DateTime(2026, 6, 3, 12)),
        DateTime(2026, 6, 1),
      );
      expect(
        DateHelpers.startOfWeek(DateTime(2026, 6, 1)),
        DateTime(2026, 6, 1),
      );
    });
  });

  group('DateHelpers.startOfMonth', () {
    test('first-of-month returns same midnight', () {
      expect(
        DateHelpers.startOfMonth(DateTime(2026, 5, 1, 10)),
        DateTime(2026, 5, 1),
      );
    });

    test('mid-month returns first-of-month midnight', () {
      expect(
        DateHelpers.startOfMonth(DateTime(2026, 5, 18, 14, 30)),
        DateTime(2026, 5, 1),
      );
    });
  });

  group('DateHelpers.startOfYear', () {
    test('Jan 1 returns same midnight', () {
      expect(
        DateHelpers.startOfYear(DateTime(2026, 1, 1, 10)),
        DateTime(2026, 1, 1),
      );
    });

    test('arbitrary day returns Jan 1 midnight of that year', () {
      expect(
        DateHelpers.startOfYear(DateTime(2026, 7, 4, 23, 59)),
        DateTime(2026, 1, 1),
      );
    });
  });

  // ISO 8601: weeks start on Monday and week 1 holds the year's first
  // Thursday, so the first and last days of a year can belong to the
  // neighbouring year's week.
  group('DateHelpers.isoWeekNumber', () {
    test('a late-December Monday can be week 1 of the next year', () {
      expect(DateHelpers.isoWeekNumber(DateTime(2025, 12, 29)), 1);
    });

    test('a late-December Monday can be week 53', () {
      expect(DateHelpers.isoWeekNumber(DateTime(2020, 12, 28)), 53);
    });

    test('early-January days can belong to the previous year\'s week', () {
      expect(DateHelpers.isoWeekNumber(DateTime(2021, 1, 3)), 53);
      expect(DateHelpers.isoWeekNumber(DateTime(2023, 1, 1)), 52);
    });

    test('week 1 starts on the Monday nearest Jan 4', () {
      expect(DateHelpers.isoWeekNumber(DateTime(2021, 1, 4)), 1);
      expect(DateHelpers.isoWeekNumber(DateTime(2026, 1, 1)), 1);
    });

    test('mid-year days and every day of a week share the number', () {
      // Oct 19-25, 2026 is week 43.
      for (var d = 19; d <= 25; d++) {
        expect(DateHelpers.isoWeekNumber(DateTime(2026, 10, d)), 43);
      }
      expect(DateHelpers.isoWeekNumber(DateTime(2025, 9, 15)), 38);
    });

    test('ignores the time of day', () {
      expect(DateHelpers.isoWeekNumber(DateTime(2025, 12, 28, 23, 59)), 52);
    });
  });
}
