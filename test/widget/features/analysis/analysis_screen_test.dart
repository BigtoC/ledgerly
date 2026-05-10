import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/features/analysis/search/widgets/analysis_search_placeholder.dart';
import 'package:ledgerly/features/analysis/search/widgets/category_search_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

Category _cat() => const Category(
  id: 1,
  type: CategoryType.expense,
  l10nKey: 'cat.coffee',
  customName: 'Coffee',
  icon: 'coffee',
  color: 1,
  sortOrder: 1,
  isArchived: false,
);

Transaction _tx() => Transaction(
  id: 1,
  amountMinorUnits: 1000,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  date: DateTime.utc(2026, 5, 1),
  memo: 'coffee',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Widget _harness({
  required TransactionRepository tx,
  required CategoryRepository cat,
  required AccountRepository acct,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(tx),
      categoryRepositoryProvider.overrideWithValue(cat),
      accountRepositoryProvider.overrideWithValue(acct),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AnalysisScreen(),
    ),
  );
}

GoRouter _detailRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/analysis',
        builder: (_, _) => const AnalysisScreen(),
        routes: [
          GoRoute(
            path: 'search/:categoryId',
            builder: (_, _) => const Scaffold(body: Text('detail')),
          ),
        ],
      ),
    ],
  );
}

Widget _routerHarness({
  required TransactionRepository tx,
  required CategoryRepository cat,
  required AccountRepository acct,
  required String initialLocation,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(tx),
      categoryRepositoryProvider.overrideWithValue(cat),
      accountRepositoryProvider.overrideWithValue(acct),
    ],
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _detailRouter(initialLocation),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  late _MockTransactionRepository tx;
  late _MockCategoryRepository cat;
  late _MockAccountRepository acct;

  setUp(() {
    tx = _MockTransactionRepository();
    cat = _MockCategoryRepository();
    acct = _MockAccountRepository();
    when(
      () => cat.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value(const <Category>[]));
    when(
      () => acct.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value(const <Account>[]));
  });

  testWidgets('renders idle placeholder by default', (tester) async {
    await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
    await tester.pump();

    expect(find.byType(AnalysisSearchPlaceholder), findsOneWidget);
  });

  testWidgets('shows no-results copy when query has no matches', (
    tester,
  ) async {
    when(() => tx.watchByMemo(any())).thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('No transactions found'), findsOneWidget);
  });

  testWidgets('stale loading results are not tappable', (tester) async {
    final coffeeCtrl = StreamController<List<Transaction>>.broadcast();
    final teaCtrl = StreamController<List<Transaction>>.broadcast();
    addTearDown(coffeeCtrl.close);
    addTearDown(teaCtrl.close);
    when(() => tx.watchByMemo('coffee')).thenAnswer((_) => coffeeCtrl.stream);
    when(() => tx.watchByMemo('tea')).thenAnswer((_) => teaCtrl.stream);

    when(
      () => cat.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([_cat()]));

    await tester.pumpWidget(
      _routerHarness(
        tx: tx,
        cat: cat,
        acct: acct,
        initialLocation: '/analysis',
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 350));
    coffeeCtrl.add([_tx()]);
    await tester.pump();

    expect(find.byType(CategorySearchTile), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tea');
    await tester.pump();

    await tester.tap(find.byType(CategorySearchTile), warnIfMissed: false);
    await tester.pump();

    expect(find.text('detail'), findsNothing);
  });

  testWidgets('router harness can still navigate on settled results', (
    tester,
  ) async {
    when(() => tx.watchByMemo(any())).thenAnswer((_) => Stream.value([_tx()]));
    when(
      () => cat.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([_cat()]));

    await tester.pumpWidget(
      _routerHarness(
        tx: tx,
        cat: cat,
        acct: acct,
        initialLocation: '/analysis',
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.byType(CategorySearchTile));
    await tester.pumpAndSettle();

    expect(find.text('detail'), findsOneWidget);
  });
}
