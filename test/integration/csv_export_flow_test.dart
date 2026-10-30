// CSV export end to end: Settings → Export data → Export to CSV, on a
// seeded en_US database with two transactions.
//
// The save dialog is replaced by a fake `CsvFileService` that keeps the
// bytes, so the test asserts the file the user would have saved.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/locale_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/app/providers/theme_provider.dart';
import 'package:ledgerly/app/router.dart';
import 'package:ledgerly/core/utils/transactions_csv.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';
import 'package:ledgerly/features/settings/csv_export/csv_export_controller.dart';
import 'package:ledgerly/features/settings/csv_export/csv_export_screen.dart';

import '../support/test_app.dart';

class _SavingCsvFileService implements CsvFileService {
  final saves = <({String fileName, Uint8List bytes})>[];

  @override
  Future<({String name, Uint8List bytes})?> pick() =>
      throw UnimplementedError();

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    saves.add((fileName: fileName, bytes: bytes));
    return true;
  }
}

/// Loading and exporting run Drift queries and an isolate that need real
/// async time, so pump with real delays until [finder] shows up.
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
  CsvExportController,
])
void main() {
  testWidgets('Settings → Export data saves every transaction', (tester) async {
    final db = newTestAppDatabase();
    addTearDown(db.close);
    final (lunch, salary) = (await tester.runAsync(() async {
      await runTestSeed(db);
      final account = await getDefaultAccount(db);
      final food = await getSeededCategoryId(db, 'category.food');
      final salaryCategory = await getSeededCategoryId(
        db,
        'category.income.salary',
      );
      return (
        await insertTestTransaction(
          db,
          accountId: account.id,
          categoryId: food,
          currencyCode: 'USD',
          amountMinorUnits: 1250,
          date: DateTime(2025, 1, 2, 12, 30),
          memo: 'lunch, with "friends"',
        ),
        await insertTestTransaction(
          db,
          accountId: account.id,
          categoryId: salaryCategory,
          currencyCode: 'JPY',
          amountMinorUnits: 300000,
          date: DateTime(2026, 3, 4, 9),
        ),
      );
    }))!;
    final files = _SavingCsvFileService();

    final container = makeTestContainer(
      db: db,
      extraOverrides: [
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: false, startDate: null),
        ),
        csvFileServiceProvider.overrideWithValue(files),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestApp(container: container));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Settings → Export data.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    const tile = ValueKey('settingsExportDataTile');
    await tester.scrollUntilVisible(
      find.byKey(tile),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(tile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(tile));
    await tester.pumpAndSettle();
    expect(find.byType(CsvExportScreen), findsOneWidget);

    // The full range is the default.
    await _pumpUntil(tester, find.text('Jan 2, 2025 – Mar 4, 2026'));

    await tester.tap(find.byKey(const ValueKey('csvExportButton')));
    await _pumpUntil(tester, find.text('Exported 2 transactions'));

    final saved = files.saves.single;
    expect(saved.fileName, 'ledgerly_transactions_2025-01-02_2026-03-04.csv');
    final lines = utf8.decode(saved.bytes.sublist(3)).split('\r\n');
    expect(lines, [
      'id,date,type,amount,currency,category,account,memo,'
          'created_at,updated_at',
      '${lunch.id},${formatLocalIso8601(lunch.date)},expense,12.50,USD,Food,'
          'Cash,"lunch, with ""friends""",'
          '${formatLocalIso8601(lunch.createdAt)},'
          '${formatLocalIso8601(lunch.updatedAt)}',
      '${salary.id},${formatLocalIso8601(salary.date)},income,300000,JPY,'
          'Salary,Cash,,'
          '${formatLocalIso8601(salary.createdAt)},'
          '${formatLocalIso8601(salary.updatedAt)}',
    ]);
    expect(tester.takeException(), isNull);
  });
}
