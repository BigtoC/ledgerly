// CSV export → import round trip (#70) through the real exporter, import
// controller and Drift: a Ledgerly export imports into a fresh install
// with every field intact, and importing it again, into either database,
// finds every row a duplicate.
//
// The file service is a fake that hands the saved bytes back to the
// picker; the FX service is a no-op.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/service_providers.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/features/categories/views/category_display.dart';
import 'package:ledgerly/ui/features/settings/csv_import/view_models/csv_import_controller.dart';
import 'package:ledgerly/ui/features/settings/csv_import/view_models/csv_import_state.dart';

import '../support/test_app.dart';

class _FakeCsvFileService implements CsvFileService {
  Uint8List? saved;

  @override
  Future<PickedFile?> pick() async => (name: 'ledgerly.csv', bytes: saved!);

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    saved = bytes;
    return true;
  }
}

class _NoopExchangeRateService extends Mock implements ExchangeRateService {}

@Dependencies([CsvImportController, csvExportUseCase])
void main() {
  test('a Ledgerly export imports into a fresh install and is all '
      'duplicates when imported again', () async {
    final files = _FakeCsvFileService();
    final fx = _NoopExchangeRateService();
    when(() => fx.fetchRates(any())).thenAnswer((_) async => []);

    @Dependencies([CsvImportController])
    ProviderContainer open(AppDatabase db) {
      final c = makeTestContainer(
        db: db,
        extraOverrides: [
          csvFileServiceProvider.overrideWithValue(files),
          exchangeRateServiceProvider.overrideWithValue(fx),
        ],
      );
      addTearDown(c.dispose);
      c.listen(csvImportControllerProvider, (_, _) {});
      return c;
    }

    @Dependencies([CsvImportController])
    Future<CsvImportPreview> pick(ProviderContainer c) async {
      final controller = c.read(csvImportControllerProvider.notifier)..reset();
      await controller.pickFile();
      return c.read(csvImportControllerProvider) as CsvImportPreview;
    }

    // Source: one value in both types, a custom income category, a
    // formula-like account name and memo, and a backdated JPY row.
    final source = newTestAppDatabase();
    addTearDown(source.close);
    await runTestSeed(source);
    final cash = await getDefaultAccount(source);
    final wallet = await createTestAccount(
      source,
      name: '@Wallet',
      currencyCode: 'JPY',
      accountTypeId: await getAccountTypeId(source, 'accountType.cash'),
    );
    final bonus = await DriftCategoryRepository(source).save(
      const Category(
        id: 0,
        icon: 'category',
        color: 0,
        type: CategoryType.income,
        customName: 'Bonus',
      ),
    );
    await insertTestTransaction(
      source,
      accountId: cash.id,
      categoryId: await getSeededCategoryId(source, 'category.investment'),
      currencyCode: 'USD',
      amountMinorUnits: 1234,
      date: DateTime(2026, 10, 29),
      memo: '=1+1, "hi"\nthere',
    );
    await insertTestTransaction(
      source,
      accountId: cash.id,
      categoryId: await getSeededCategoryId(
        source,
        'category.income.investment',
      ),
      currencyCode: 'USD',
      amountMinorUnits: 700,
      date: DateTime(2026, 10, 30),
    );
    await insertTestTransaction(
      source,
      accountId: wallet.id,
      categoryId: bonus.id,
      currencyCode: 'JPY',
      amountMinorUnits: 1000,
      date: DateTime(2026, 1, 2),
    );

    final en = lookupAppLocalizations(const Locale('en'));
    final sourceContainer = open(source);
    await sourceContainer
        .read(csvExportUseCaseProvider)
        .export(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          categoryName: (c) => categoryDisplayName(c, en),
        );

    // Target: a fresh install. Only @Wallet needs a decision.
    final target = newTestAppDatabase();
    addTearDown(target.close);
    await runTestSeed(target);
    final targetContainer = open(target);
    final preview = await pick(targetContainer);
    expect(preview.importCount, 3);
    expect(preview.errors, isEmpty);
    final undecided = preview.accounts.where((a) => a.resolution == null);
    expect(undecided.map((a) => a.csvValue), ['@Wallet']);
    final controller =
        targetContainer.read(csvImportControllerProvider.notifier)
          ..setAccountResolution(
            '@Wallet',
            undecided.single.createTypeAndAccountOption,
          );
    await controller.commit();
    expect(
      targetContainer.read(csvImportControllerProvider),
      isA<CsvImportDone>(),
    );

    expect(await _describe(target), await _describe(source));

    for (final c in [targetContainer, sourceContainer]) {
      final again = await pick(c);
      expect(again.importCount, 0);
      expect(again.duplicateCount, 3);
    }
  });
}

/// Every transaction in [db] by the fields an export carries, with the
/// category by identity and type and the account by name, sorted.
Future<List<String>> _describe(AppDatabase db) async {
  final categories = {
    for (final c in await DriftCategoryRepository(
      db,
    ).watchAll(includeArchived: true).first)
      c.id: c,
  };
  final accounts = {
    for (final a in await DriftAccountRepository(
      db,
      DriftCurrencyRepository(db),
    ).watchAll(includeArchived: true).first)
      a.id: a.name,
  };
  return [
    for (final r in await db.select(db.transactions).get())
      [
        r.amountMinorUnits,
        r.currency,
        categories[r.categoryId]!.l10nKey ??
            categories[r.categoryId]!.customName,
        categories[r.categoryId]!.type.name,
        accounts[r.accountId],
        r.date,
        r.createdAt,
        r.memo,
      ].join('|'),
  ]..sort();
}
