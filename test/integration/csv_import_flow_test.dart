// CSV import end to end: Settings → Import from CSV → choose the sample
// file → resolve Credit Card → Import → Done, on a seeded en_US database.
//
// The file picker is replaced by a fake `CsvFileService` returning the
// sample bytes, and the FX service by a no-op (the sample is HKD, the
// seeded default is USD, so the commit triggers one refresh). Results
// are asserted through the repository, not Home: Home reads
// `DateTime.now()`, so a Home assertion would only pass on 2026-10-30.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/exchange_rates_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/accounts/accounts_controller.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_controller.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_screen.dart';
import 'package:ledgerly/features/settings/settings_controller.dart';
import 'package:ledgerly/features/settings/settings_screen.dart';

import '../support/test_app.dart';

class _FakeCsvFileService implements CsvFileService {
  _FakeCsvFileService(this._bytes);

  final Uint8List _bytes;

  @override
  Future<({String name, Uint8List bytes})?> pick() async =>
      (name: 'import_fortune_city_data.csv', bytes: _bytes);

  @override
  Future<bool> save(String fileName, Uint8List bytes) =>
      throw UnimplementedError();
}

class _NoopExchangeRateService extends Mock implements ExchangeRateService {}

/// Load and commit run Drift queries that need real async time, and the
/// loading and committing spinners never settle, so pump with real
/// delays until [finder] shows up.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
}

@Dependencies([
  router,
  themeMode,
  userLocalePreference,
  exchangeRateRepository,
  CsvImportController,
  SettingsController,
  AccountsController,
  exchangeRates,
  initialDefaultCurrency,
  defaultCurrency,
])
void main() {
  testWidgets('Settings → Import from CSV imports the sample file', (
    tester,
  ) async {
    final db = newTestAppDatabase();
    addTearDown(db.close);
    await tester.runAsync(() => runTestSeed(db));
    final bytes = File('test/data/import_fortune_city_data.csv')
        .readAsBytesSync();

    final fx = _NoopExchangeRateService();
    when(() => fx.fetchRates(any())).thenAnswer((_) async => []);

    final container = makeTestContainer(
      db: db,
      extraOverrides: [
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: false, startDate: null),
        ),
        csvFileServiceProvider.overrideWithValue(_FakeCsvFileService(bytes)),
        exchangeRateServiceProvider.overrideWithValue(fx),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestApp(container: container));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Settings → Import from CSV.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    const tile = ValueKey('settingsImportCsvTile');
    await tester.scrollUntilVisible(
      find.byKey(tile),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(tile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(tile));
    await tester.pumpAndSettle();
    expect(find.byType(CsvImportScreen), findsOneWidget);

    // Choose the file: the preview asks only about Credit Card.
    await tester.tap(find.text('Choose CSV file'));
    await _pumpUntil(tester, find.text('import_fortune_city_data.csv'));
    final confirm = find.byKey(const ValueKey('csvImportConfirmButton'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.text('Choose where these go'), findsOneWidget);

    // Credit Card → create an account type and an account.
    await tester.tap(
      find.byKey(const ValueKey('csvImportAccount:Credit Card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('csvImportSheetCreateTypeAndAccount')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose where these go'), findsNothing);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(find.text('Import 105 transactions'), findsOneWidget);

    // Import → Done.
    await tester.tap(confirm);
    await _pumpUntil(tester, find.text('Import complete'));
    expect(find.text('Imported 105 transactions'), findsOneWidget);
    expect(find.text('Created 2 accounts and 3 categories'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(CsvImportScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);

    final (all, lastDay) = (await tester.runAsync(
      () async => (
        await db.select(db.transactions).get(),
        await DriftTransactionRepository(db)
            .watchByDay(DateTime(2026, 10, 30))
            .first,
      ),
    ))!;
    expect(all, hasLength(105));
    expect(lastDay, isNotEmpty);
    for (final tx in lastDay) {
      expect(tx.date, DateTime(2026, 10, 30));
      expect(tx.createdAt, DateTime(2026, 10, 30, 10, 39));
      expect(tx.currency.code, 'HKD');
    }
    verify(() => fx.fetchRates(any())).called(1);
    expect(tester.takeException(), isNull);
  });
}
