// NewVersionBadge widget tests (app update check).
//
// Covers:
//   - Renders the localized "new version" label.
//   - Without a SHA-256, tapping launches the exact APK URL in the system
//     browser.
//   - A failed launch shows the localized SnackBar, whether the launcher
//     returns false or throws (url_launcher_android throws on failure).
//   - The label meets WCAG AA contrast on the primary fill in both app
//     themes and with a dark primary.
//   - The badge is a labeled button with a 48dp tap target.
//   - With a SHA-256, tapping asks first and then starts the in-app
//     update; the label, permission SnackBar and failure SnackBar (with
//     an Open in browser fallback) follow AppUpdateController's state.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ledgerly/core/theme/app_theme.dart';
import 'package:ledgerly/data/models/app_update.dart';
import 'package:ledgerly/features/settings/app_update_controller.dart';
import 'package:ledgerly/features/settings/app_update_state.dart';
import 'package:ledgerly/features/settings/widgets/new_version_badge.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

final _inApp = AppUpdate(
  version: 'v0.7.4',
  fileName: 'ledgerly-v0.7.4-arm64-v8a.apk',
  apkUrl: Uri.parse(
    'https://github.com/BigtoC/ledgerly/releases/download/v0.7.4/'
    'ledgerly-v0.7.4-arm64-v8a.apk',
  ),
  sha256: 'ab' * 32,
  sizeBytes: 25568852,
);

/// No SHA-256 or size, so the badge can only open the browser.
final _browserOnly = _inApp.copyWith(sha256: null, sizeBytes: null);

class _FakeController extends AppUpdateController {
  _FakeController(this.initial);
  final AppUpdateState initial;
  final started = <AppUpdate>[];
  @override
  AppUpdateState build() => initial;
  @override
  Future<void> start(AppUpdate update) async => started.add(update);
  void emit(AppUpdateState s) => state = s;
}

Widget _wrap(Widget child, {ThemeData? theme, _FakeController? controller}) {
  final container = ProviderContainer(
    overrides: [
      appUpdateControllerProvider.overrideWith(
        () => controller ?? _FakeController(const AppUpdateState.idle()),
      ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('NVB01: shows "new version"', (tester) async {
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _browserOnly)));

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
      _wrap(NewVersionBadge(update: _browserOnly, launch: fakeLaunch)),
    );
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();

    expect(calls, [(_browserOnly.apkUrl, LaunchMode.externalApplication)]);
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
      _wrap(NewVersionBadge(update: _browserOnly, launch: fakeLaunch)),
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
      _wrap(NewVersionBadge(update: _browserOnly, launch: fakeLaunch)),
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
        _wrap(NewVersionBadge(update: _browserOnly), theme: theme),
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
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _browserOnly)));

    expect(
      tester.getSemantics(find.text('new version')),
      isSemantics(label: 'new version', isButton: true, hasTapAction: true),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('NVB07: in-app update asks first, then starts on Download', (
    tester,
  ) async {
    final c = _FakeController(const AppUpdateState.idle());
    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _inApp), controller: c),
    );
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();

    expect(find.text('Update to v0.7.4?'), findsOneWidget);
    expect(find.textContaining('about 24.4 MB'), findsOneWidget);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(c.started, [_inApp]);
  });

  testWidgets('NVB08: cancelling the dialog does not start', (tester) async {
    final c = _FakeController(const AppUpdateState.idle());
    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _inApp), controller: c),
    );
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(c.started, isEmpty);
  });

  testWidgets('NVB09: labels follow the controller state', (tester) async {
    final c = _FakeController(const AppUpdateState.downloading(42));
    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _inApp), controller: c),
    );
    expect(find.text('downloading 42%'), findsOneWidget);

    c.emit(const AppUpdateState.ready('/a.apk'));
    await tester.pump();
    expect(find.text('install'), findsOneWidget);

    c.emit(const AppUpdateState.installing('/a.apk'));
    await tester.pump();
    expect(find.text('installing…'), findsOneWidget);
  });

  testWidgets('NVB10: tapping install starts without a dialog', (tester) async {
    final c = _FakeController(const AppUpdateState.ready('/a.apk'));
    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _inApp), controller: c),
    );
    await tester.tap(find.text('install'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(c.started, [_inApp]);
  });

  testWidgets('NVB11: permission prompt shows a SnackBar', (tester) async {
    final c = _FakeController(const AppUpdateState.downloading(100));
    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _inApp), controller: c),
    );
    c.emit(const AppUpdateState.ready('/a.apk', needsPermission: true));
    await tester.pump();

    expect(
      find.text('Allow Ledgerly to install apps, then tap install.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'NVB12: a failure shows its message with an Open in browser action',
    (tester) async {
      final calls = <Uri>[];
      final c = _FakeController(const AppUpdateState.downloading(3));
      await tester.pumpWidget(
        _wrap(
          NewVersionBadge(
            update: _inApp,
            launch: (url, {mode = LaunchMode.platformDefault}) async {
              calls.add(url);
              return true;
            },
          ),
          controller: c,
        ),
      );
      c.emit(const AppUpdateState.failed(UpdateFailure.signatureConflict));
      // Let the SnackBar slide in so its action is tappable.
      await tester.pumpAndSettle();

      expect(find.textContaining('signed differently'), findsOneWidget);
      await tester.tap(find.text('Open in browser'));
      await tester.pump();
      expect(calls, [_inApp.apkUrl]);
      // A failed attempt shows the idle label again, so the next tap retries.
      expect(find.text('new version'), findsOneWidget);
    },
  );

  testWidgets('NVB13: progress label survives 2x text scale', (tester) async {
    final c = _FakeController(const AppUpdateState.downloading(100));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      _wrap(NewVersionBadge(update: _inApp), controller: c),
    );

    expect(find.text('downloading 100%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
