// DayNavigationHeader widget tests — Wave 3 §4.3.
//
// Covers: prev disabled at oldest day, next disabled when no newer
// activity day, both active in between, label tap fires onPickDay.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('DH04: today renders the localized "Today" label', (
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
          canGoNext: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
  });
}
