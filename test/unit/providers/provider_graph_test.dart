// M4 §7.1 — provider graph smoke test.
//
// Verifies that every `keepAlive` repository provider can be resolved when
// `appDatabaseProvider` is overridden with an in-memory DB. Guards against
// future providers accidentally watching `AppDatabase` in a way that leaks a
// DAO or fails construction.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/providers/app_database_provider.dart';
import 'package:ledgerly/app/providers/locale_service_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart';

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
        container.read(localeServiceProvider);
      }, returnsNormally);
    });
  });
}
