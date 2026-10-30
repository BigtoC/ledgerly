// NewVersionBadge widget tests (app update check).
//
// Covers:
//   - Renders the localized "new version" label.
//   - Tapping launches the exact APK URL in the system browser.
//   - A failed launch shows the localized SnackBar, whether the launcher
//     returns false or throws (url_launcher_android throws on failure).
//   - The label meets WCAG AA contrast on the primary fill in both app
//     themes and with a dark primary.
//   - The badge is a labeled button with a 48dp tap target.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ledgerly/core/theme/app_theme.dart';
import 'package:ledgerly/data/models/app_update.dart';
import 'package:ledgerly/features/settings/widgets/new_version_badge.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

final _update = AppUpdate(
  version: 'v0.7.2',
  fileName: 'ledgerly-v0.7.2-arm64-v8a.apk',
  apkUrl: Uri.parse(
    'https://github.com/BigtoC/ledgerly/releases/download/v0.7.2/'
    'ledgerly-v0.7.2-arm64-v8a.apk',
  ),
);

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('NVB01: shows "new version"', (tester) async {
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _update)));

    expect(find.text('new version'), findsOneWidget);
  });

  testWidgets('NVB02: tap opens the APK URL in the external browser', (
    tester,
  ) async {
    final calls = <(Uri, LaunchMode)>[];
    Future<bool> fakeLaunch(
      Uri url, {
      LaunchMode mode = LaunchMode.platformDefault,
    }) {
      calls.add((url, mode));
      return Future.value(true);
    }

    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _update, launch: fakeLaunch)),
    );
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();

    expect(calls, [(_update.apkUrl, LaunchMode.externalApplication)]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('NVB03: failed launch shows the localized SnackBar', (
    tester,
  ) async {
    Future<bool> fakeLaunch(
      Uri url, {
      LaunchMode mode = LaunchMode.platformDefault,
    }) => Future.value(false);

    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _update, launch: fakeLaunch)),
    );
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the download link'), findsOneWidget);
  });

  testWidgets('NVB04: launcher that throws shows the localized SnackBar', (
    tester,
  ) async {
    Future<bool> fakeLaunch(
      Uri url, {
      LaunchMode mode = LaunchMode.platformDefault,
    }) => Future.error(PlatformException(code: 'ACTIVITY_NOT_FOUND'));

    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _update, launch: fakeLaunch)),
    );
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the download link'), findsOneWidget);
  });

  for (final (name, theme) in [
    ('light', lightTheme),
    ('dark', darkTheme),
    // Guards against hardcoding the label color to suit pinkAccent.
    (
      'dark-primary',
      ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: const Color(0xFF1A237E),
        ),
      ),
    ),
  ]) {
    testWidgets('NVB05: label meets WCAG AA contrast in $name theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(NewVersionBadge(update: _update), theme: theme),
      );

      // Effective colors as painted, independent of how the badge is built.
      final fill = tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('settingsNewVersionBadge')),
                  matching: find.byType(Material),
                  matchRoot: true,
                )
                .first,
          )
          .color!;
      final text = tester
          .renderObject<RenderParagraph>(find.text('new version'))
          .text
          .style!
          .color!;
      final l1 = fill.computeLuminance(), l2 = text.computeLuminance();
      final ratio = (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);

      expect(fill, theme.colorScheme.primary);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  }

  testWidgets('NVB06: badge is a labeled button with a 48dp tap target', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _update)));

    expect(
      tester.getSemantics(find.text('new version')),
      isSemantics(label: 'new version', isButton: true, hasTapAction: true),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
