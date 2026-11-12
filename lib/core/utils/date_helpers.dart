import 'package:intl/intl.dart';

/// A piece of the resolved splash display text. The splash widget renders
/// segments back-to-back in a single line, applying the rainbow gradient
/// only to spans where [isDate] is `true`. Plain `{days}` substitutions
/// and surrounding literal text live in `isDate: false` segments. Empty
/// runs are elided so an unbroken adjacent date / plain pair does not
/// produce a zero-length plain segment between them.
typedef SplashTextSegment = ({String text, bool isDate});

/// Day-boundary math + locale-aware date formatting used by the Home
/// day-grouped list and the splash day counter. No Flutter imports,
/// no state. See PRD.md 510-552 (splash) and 864-887 (i18n).
class DateHelpers {
  const DateHelpers._();

  /// Returns midnight (00:00:00.000) **in the same time zone as [dt]**.
  /// Used to bucket transactions by day in the Home list and as the
  /// anchor for the splash day counter.
  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Local-midnight of Monday for the week containing [dt].
  /// `DateTime.weekday` is 1=Mon..7=Sun, so subtracting `(weekday - 1)`
  /// days lands on the Monday. DST-safe: operates on the calendar day
  /// component, not on `Duration`-based subtraction.
  static DateTime startOfWeek(DateTime dt) {
    final base = startOfDay(dt);
    return DateTime(base.year, base.month, base.day - (base.weekday - 1));
  }

  /// Local-midnight of the first day of the month containing [dt].
  static DateTime startOfMonth(DateTime dt) => DateTime(dt.year, dt.month, 1);

  /// Local-midnight of Jan 1 of the year containing [dt].
  static DateTime startOfYear(DateTime dt) => DateTime(dt.year, 1, 1);

  /// ISO 8601 week number (1–53) of the week containing [dt]. Weeks start
  /// on Monday, and week 1 is the one holding the year's first Thursday,
  /// so Dec 29, 2025 is in week 1 and Jan 3, 2021 in week 53.
  static int isoWeekNumber(DateTime dt) {
    // The week's Thursday decides which year the week belongs to.
    final thursday = DateTime(dt.year, dt.month, dt.day + 4 - dt.weekday);
    final dayOfYear = daysBetween(DateTime(thursday.year), thursday);
    return dayOfYear ~/ 7 + 1;
  }

  /// Returns true if [a] and [b] land on the same calendar day in
  /// [a]'s time zone.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole calendar days from [from] to [to] using each argument's
  /// local midnight. Zero when [from] and [to] share a day.
  /// Positive when [to] is later. Negative when [to] is earlier, never
  /// clamped: the splash counter (PRD.md 510-552) shows a future start date
  /// as `-N`.
  /// **DST-safe:** operates on `startOfDay` differences via UTC
  /// milliseconds with rounding, so clocks that jump forward / backward
  /// do not shift the count.
  static int daysBetween(DateTime from, DateTime to) {
    // `Duration.inDays` is wrong across DST — it uses absolute hours.
    // Convert each local-midnight anchor to UTC ms and round to the
    // nearest day to absorb the ±3600000 ms DST offset delta.
    final a = startOfDay(from).toUtc().millisecondsSinceEpoch;
    final b = startOfDay(to).toUtc().millisecondsSinceEpoch;
    const msPerDay = 86400000;
    final diffMs = b - a;
    return (diffMs / msPerDay).round();
  }

  // Building a DateFormat parses the locale pattern each time, and list rows
  // call formatDisplayDate per build. One per locale; the key space is tiny,
  // so no eviction.
  static final Map<String, DateFormat> _displayDateCache = {};

  /// Locale-aware "long-ish" date for splash and settings display
  /// (e.g. `Apr 21, 2026` / `2026年4月21日`). Matches PRD.md 525 / 549
  /// "rainbow-gradient text below showing the start date".
  static String formatDisplayDate(DateTime date, String locale) =>
      _displayDateCache
          .putIfAbsent(locale, () => DateFormat.yMMMd(locale))
          .format(date);

  /// Locale-aware "day header" date for the Home day-grouped list
  /// (e.g. `Tue, Apr 21` in en_US; `4月21日 週二` in zh_TW). No year —
  /// Home already implies "recent".
  static String formatDayHeader(DateTime date, String locale) =>
      DateFormat.MMMEd(locale).format(date);

  /// Substitutes `{date}` (→ `formatDisplayDate(startDate, locale)`) and
  /// `{days}` (→ `daysBetween(startDate, now)` with locale-aware grouping via
  /// `NumberFormat.decimalPattern(locale)`) in the splash display template;
  /// unknown `{placeholder}` tokens pass through unchanged. Returns the
  /// resolved text split into segments so the widget can style `{date}`
  /// substitutions independently (rainbow gradient) from the surrounding
  /// plain run. `{days}` is substituted inline into its enclosing plain
  /// segment. Empty plain runs at segment boundaries are dropped.
  static List<SplashTextSegment> applySplashTemplateSegments({
    required String template,
    required DateTime startDate,
    required DateTime now,
    required String locale,
  }) {
    if (template.isEmpty) return const <SplashTextSegment>[];
    final days = daysBetween(startDate, now);
    final daysStr = NumberFormat.decimalPattern(locale).format(days);
    final dateStr = formatDisplayDate(startDate, locale);

    final segments = <SplashTextSegment>[];
    var i = 0;
    final buffer = StringBuffer();
    void flushPlain() {
      if (buffer.isEmpty) return;
      segments.add((text: buffer.toString(), isDate: false));
      buffer.clear();
    }

    while (i < template.length) {
      if (template.startsWith('{date}', i)) {
        flushPlain();
        segments.add((text: dateStr, isDate: true));
        i += '{date}'.length;
      } else if (template.startsWith('{days}', i)) {
        buffer.write(daysStr);
        i += '{days}'.length;
      } else {
        buffer.write(template[i]);
        i += 1;
      }
    }
    flushPlain();
    return segments;
  }
}
