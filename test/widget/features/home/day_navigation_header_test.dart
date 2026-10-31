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
    await tester.tap(find.byKey(const ValueKey('homeDayHeader.pickDay')));
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
    // The jump button on the right reads "Today"; the pill never does.
    final pill = find.byKey(const ValueKey('homeDayHeader.pickDay'));
    expect(
      find.descendant(of: pill, matching: find.text('Today')),
      findsNothing,
    );
    expect(
      find.text(DateHelpers.formatDayHeader(now, 'en_US')),
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
    final pill = find.byKey(const ValueKey('homeDayHeader.pickDay'));
    final button = tester.widget<TextButton>(pill);
    final colorScheme = Theme.of(tester.element(pill)).colorScheme;
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      colorScheme.surfaceContainer,
    );
    expect(button.style?.shape?.resolve(<WidgetState>{}), isA<StadiumBorder>());
    // The pill hugs the label instead of stretching between the chevrons.
    expect(
      tester.getSize(pill).width,
      lessThan(tester.getSize(find.byType(DayNavigationHeader)).width / 2),
    );
  });

  testWidgets('DH07: jump-to-today button fires onJumpToToday', (tester) async {
    var jumped = false;
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
          showJumpToToday: true,
          onJumpToToday: () => jumped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jump to today'));
    await tester.pumpAndSettle();
    expect(jumped, isTrue);
  });

  testWidgets('DH08: on today the button reads "Today" and is disabled', (
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
          onJumpToToday: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jump to today'), findsNothing);
    final button = tester.widget<TextButton>(
      find.ancestor(of: find.text('Today'), matching: find.byType(TextButton)),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('DH09: chevrons hug the pill on the left; jump button sits '
      'at the right edge', (tester) async {
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
          showJumpToToday: true,
          onJumpToToday: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    final pill = tester.getRect(
      find.byKey(const ValueKey('homeDayHeader.pickDay')),
    );
    final next = tester.getRect(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    final jump = tester.getRect(
      find.byKey(const ValueKey('homeDayHeader.jumpToToday')),
    );
    expect(next.left - pill.right, lessThan(8));
    expect(next.right, lessThan(screenWidth / 2 + 40));
    expect(jump.left, greaterThan(next.right));
    expect(screenWidth - jump.right, lessThan(24));
  });

  testWidgets('DH10: at 2x text scale on a 360dp phone the date pill keeps '
      'the row and the jump button moves below it', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      _wrap(
        DayNavigationHeader(
          selectedDay: DateTime(2026, 9, 30),
          locale: 'en_US',
          onPrev: () {},
          onNext: () {},
          onPickDay: () {},
          canGoPrev: true,
          canGoNext: true,
          showJumpToToday: true,
          onJumpToToday: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final pill = tester.getRect(
      find.byKey(const ValueKey('homeDayHeader.pickDay')),
    );
    final jump = tester.getRect(
      find.byKey(const ValueKey('homeDayHeader.jumpToToday')),
    );
    final prev = tester.getRect(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    final next = tester.getRect(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    // The long label fills everything between the chevrons instead of
    // ceding space to the jump button.
    expect(
      pill.width,
      greaterThanOrEqualTo(360 - 16 - prev.width - next.width),
    );
    expect(jump.top, greaterThanOrEqualTo(pill.bottom));
  });
}
