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
import 'package:ledgerly/features/analysis/search/category_search_detail_screen.dart';
import 'package:ledgerly/features/analysis/search/widgets/category_search_tile.dart';
import 'package:ledgerly/features/analysis/search/widgets/transaction_search_row.dart';
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

Account _acct() => const Account(
  id: 1,
  accountTypeId: 1,
  name: 'Cash',
  currency: _usd,
  openingBalanceMinorUnits: 0,
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

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  testWidgets('renders read-only TransactionSearchRow', (tester) async {
    final tx = _MockTransactionRepository();
    final cat = _MockCategoryRepository();
    final acct = _MockAccountRepository();

    when(
      () => tx.watchByMemo('coffee'),
    ).thenAnswer((_) => Stream.value([_tx()]));
    when(
      () => cat.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([_cat()]));
    when(
      () => acct.watchAll(includeArchived: true),
    ).thenAnswer((_) => Stream.value([_acct()]));

    await tester.pumpWidget(
      ProviderScope(
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
          home: CategorySearchDetailScreen(
            categoryId: 1,
            query: 'coffee',
            currencyCode: 'USD',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(TransactionSearchRow), findsOneWidget);
    expect(find.byType(PopupMenuButton<dynamic>), findsNothing);
  });

  testWidgets(
    'back navigation preserves AnalysisController query (keepAlive)',
    (tester) async {
      final tx = _MockTransactionRepository();
      final cat = _MockCategoryRepository();
      final acct = _MockAccountRepository();

      when(
        () => tx.watchByMemo('coffee'),
      ).thenAnswer((_) => Stream.value([_tx()]));
      when(
        () => cat.watchAll(includeArchived: true),
      ).thenAnswer((_) => Stream.value([_cat()]));
      when(
        () => acct.watchAll(includeArchived: true),
      ).thenAnswer((_) => Stream.value([_acct()]));

      final router = GoRouter(
        initialLocation: '/analysis',
        routes: [
          GoRoute(
            path: '/analysis',
            builder: (_, _) => const AnalysisScreen(),
            routes: [
              GoRoute(
                path: 'search/:categoryId',
                builder: (_, state) => CategorySearchDetailScreen(
                  categoryId: int.parse(state.pathParameters['categoryId']!),
                  query: state.uri.queryParameters['q']!,
                  currencyCode: state.uri.queryParameters['c']!,
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
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
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byType(CategorySearchTile), findsOneWidget);

      await tester.tap(find.byType(CategorySearchTile));
      await tester.pumpAndSettle();
      expect(find.byType(CategorySearchDetailScreen), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AnalysisScreen), findsOneWidget);
      expect(find.byType(CategorySearchTile), findsOneWidget);
      expect(find.widgetWithText(TextField, 'coffee'), findsOneWidget);
    },
  );
}
