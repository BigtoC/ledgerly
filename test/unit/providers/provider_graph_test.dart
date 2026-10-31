// M4 §7.1 — provider graph smoke test.
//
// Verifies that every `keepAlive` repository provider can be resolved when
// `appDatabaseProvider` is overridden with an in-memory DB. Guards against
// future providers accidentally watching `AppDatabase` in a way that leaks a
// DAO or fails construction.

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/app_database_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/service_providers.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/services/csv_file_service.dart';
import 'package:ledgerly/data/use_cases/csv_import_use_case.dart';

class _CancellingCsvFileService implements CsvFileService {
  @override
  Future<({String name, Uint8List bytes})?> pick() async => null;

  @override
  Future<bool> save(String fileName, Uint8List bytes) =>
      throw UnimplementedError();
}

@Dependencies([
  currencyRepository,
  categoryRepository,
  accountTypeRepository,
  accountRepository,
  transactionRepository,
  userPreferencesRepository,
  csvImportUseCase,
])
void main() {
  group('provider graph', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase(NativeDatabase.memory()),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('every keepAlive repository provider resolves without throwing', () {
      expect(() {
        container.read(currencyRepositoryProvider);
        container.read(categoryRepositoryProvider);
        container.read(accountTypeRepositoryProvider);
        container.read(accountRepositoryProvider);
        container.read(transactionRepositoryProvider);
        container.read(userPreferencesRepositoryProvider);
      }, returnsNormally);
    });

    test(
      'csvImportUseCase resolves and uses the csvFileService override',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final withFakePicker = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            csvFileServiceProvider.overrideWithValue(
              _CancellingCsvFileService(),
            ),
          ],
        );
        addTearDown(withFakePicker.dispose);

        final useCase = withFakePicker.read(csvImportUseCaseProvider);

        expect(useCase, isA<CsvImportUseCase>());
        expect(await useCase.pickAndLoad(), isNull);
      },
    );
  });
}
