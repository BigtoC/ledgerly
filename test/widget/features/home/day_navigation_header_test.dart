// DayNavigationHeader widget tests — Wave 3 §4.3.
//
// Covers: prev disabled at oldest day, next disabled when no newer
// activity day, both active in between, label tap fires onPickDay,
// label is always the formatted date (no Today / Yesterday override).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/core/utils/date_helpers.dart';
import 'package:ledgerly/features/home/widgets/day_navigation_header.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('DH01: prev chevron disabled when canGoPrev is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DayNavigationHeader(
          selectedDay: DateTime.now(),
          locale: 'en_US',
          onPrev: () {},
          onNext: () {},
          onPickDay: () {},
          canGoPrev: false,
          canGoNext: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final prev = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    expect(prev.onPressed, isNull);
    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('DH02: next chevron disabled when canGoNext is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DayNavigationHeader(
          selectedDay: DateTime.now(),
          locale: 'en_US',
          onPrev: () {},
          onNext: () {},
          onPickDay: () {},
          canGoPrev: true,
          canGoNext: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('DH03: tapping the selected-day label fires onPickDay', (
    tester,
  ) async {
    var picked = 0;
    await tester.pumpWidget(
      _wrap(
        DayNavigationHeader(
          selectedDay: DateTime.now(),
          locale: 'en_US',
          onPrev: () {},
          onNext: () {},
          onPickDay: () => picked++,
          canGoPrev: true,
          canGoNext: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(picked, 1);
  });

  testWidgets('DH04: today renders the date, not a "Today" label', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      _wrap(
        DayNavigationHeader(
          selectedDay: now,
          locale: 'en_US',
          onPrev: () {},
          onNext: () {},
          onPickDay: () {},
          canGoPrev: false,
          canGoNext: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);
    expect(
      find.text(DateHelpers.formatDayHeader(now, 'en_US')),
      findsOneWidget,
    );
  });

  testWidgets('DH06: yesterday renders the date, not a "Yesterday" label', (
    tester,
  ) async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await tester.pumpWidget(
      _wrap(
        DayNavigationHeader(
          selectedDay: yesterday,
          locale: 'en_US',
          onPrev: () {},
          onNext: () {},
          onPickDay: () {},
          canGoPrev: true,
          canGoNext: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsNothing);
    expect(
      find.text(DateHelpers.formatDayHeader(yesterday, 'en_US')),
      findsOneWidget,
    );
  });

  testWidgets('DH05: day label sits in a pill filled with the card colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DayNavigationHeader(
          selectedDay: DateTime.now(),
          locale: 'en_US',
          onPrev: () {},
          onNext: () {},
          onPickDay: () {},
          canGoPrev: true,
          canGoNext: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<TextButton>(find.byType(TextButton));
    final colorScheme = Theme.of(tester.element(find.byType(TextButton)))
        .colorScheme;
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      colorScheme.surfaceContainer,
    );
    expect(button.style?.shape?.resolve(<WidgetState>{}), isA<StadiumBorder>());
    // The pill hugs the label instead of stretching between the chevrons.
    expect(
      tester.getSize(find.byType(TextButton)).width,
      lessThan(tester.getSize(find.byType(Row)).width / 2),
    );
  });
}
