// Widget tests for `showAccountPickerSheet`'s "Create account" path: after
// the account form returns the saved id, the sheet looks the account up
// and pops it, or stays open when the account is gone or archived.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/features/transactions/widgets/account_picker_sheet.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _created = Account(
  id: 42,
  name: 'Wallet',
  accountTypeId: 1,
  currency: _usd,
);

void main() {
  late _MockAccountRepository accountRepo;

  setUp(() {
    accountRepo = _MockAccountRepository();
    // No accounts yet, so the sheet shows the "Create account" button.
    when(() => accountRepo.watchAll())
        .thenAnswer((_) => Stream.value(const <Account>[]));
  });

  /// Opens the picker from `/`. The account form at
  /// `/settings/manage-accounts/new` is a stub that pops with id 42.
  /// [results] collects what the picker returned.
  Widget mount(List<Account?> results) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async =>
                    results.add(await showAccountPickerSheet(context)),
                child: const Text('open-picker'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/manage-accounts/new',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => GoRouter.of(context).pop(42),
                child: const Text('finish-create-account'),
              ),
            ),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [accountRepositoryProvider.overrideWithValue(accountRepo)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Future<void> createAccountFromPicker(WidgetTester tester) async {
    await tester.tap(find.text('open-picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('finish-create-account'));
    await tester.pumpAndSettle();
  }

  testWidgets('returns the account created from the picker', (tester) async {
    when(() => accountRepo.getById(42)).thenAnswer((_) async => _created);
    final results = <Account?>[];
    await tester.pumpWidget(mount(results));
    await tester.pumpAndSettle();

    await createAccountFromPicker(tester);

    expect(results, [_created]);
    expect(find.text('Create account'), findsNothing);
  });

  testWidgets('stays open when the created account is archived', (
    tester,
  ) async {
    when(() => accountRepo.getById(42))
        .thenAnswer((_) async => _created.copyWith(isArchived: true));
    final results = <Account?>[];
    await tester.pumpWidget(mount(results));
    await tester.pumpAndSettle();

    await createAccountFromPicker(tester);

    expect(results, isEmpty);
    expect(find.text('Create account'), findsOneWidget);
  });
}
