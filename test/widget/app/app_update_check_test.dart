// Pins the app-level ordering of the update check: first frame, then the
// startup FX refresh, then exactly one GitHub release check. If something
// starts `defaultCurrencyProvider` before `App` builds, the repository
// misses the first default-currency value, `startupRefresh` never
// completes, and this test fails instead of the check silently stopping.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/app_update_provider.dart';
import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/data/repositories/app_update_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';

import '../../support/test_app.dart';

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

class _MockAppUpdateRepository extends Mock implements AppUpdateRepository {}

final _apkUrl = Uri.parse('https://example.com/ledgerly-v0.7.2-arm64-v8a.apk');

@Dependencies([router, themeMode, userLocalePreference, exchangeRateRepository])
void main() {
  testWidgets('checks for an update once, after the startup FX fetch', (
    tester,
  ) async {
    final db = newTestAppDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await runTestSeed(db);
      // A foreign-currency account so the startup refresh has a pair to
      // fetch instead of short-circuiting.
      await createTestAccount(
        db,
        name: 'Euro cash',
        currencyCode: 'EUR',
        accountTypeId: await getAccountTypeId(db, 'accountType.cash'),
      );
    });

    final fxGate =
        Completer<
          List<({String from, String to, double rate, DateTime fetchedAt})>
        >();
    final fx = _MockExchangeRateService();
    when(() => fx.fetchRates(any())).thenAnswer((_) => fxGate.future);
    final updates = _MockAppUpdateRepository();
    when(() => updates.findUpdate()).thenAnswer((_) async => _apkUrl);

    final container = makeTestContainer(
      db: db,
      extraOverrides: [
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: false, startDate: null),
        ),
        exchangeRateServiceProvider.overrideWithValue(fx),
        appUpdateRepositoryProvider.overrideWithValue(updates),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestApp(container: container));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => fx.fetchRates(any())).called(1);
    verifyNever(() => updates.findUpdate());

    fxGate.complete(const []);
    await tester.pumpAndSettle();

    verify(() => updates.findUpdate()).called(1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    verifyNever(() => updates.findUpdate());

    final dot = tester.widget<Badge>(
      find.byKey(const ValueKey('settingsUpdateDot')),
    );
    expect(dot.isLabelVisible, isTrue);
  });
}
