import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

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

  testWidgets('tapping a row pushes /home/edit/:id on the root navigator', (
    tester,
  ) async {
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

    String? pushedLocation;
    final router = GoRouter(
      initialLocation: '/analysis/search/1?q=coffee&c=USD',
      routes: [
        GoRoute(
          path: '/analysis/search/:categoryId',
          builder: (_, state) => CategorySearchDetailScreen(
            categoryId: int.parse(state.pathParameters['categoryId']!),
            query: state.uri.queryParameters['q']!,
            currencyCode: state.uri.queryParameters['c']!,
          ),
        ),
        GoRoute(
          path: '/home/edit/:id',
          builder: (_, state) {
            pushedLocation = '/home/edit/${state.pathParameters['id']}';
            return const Scaffold(body: Center(child: Text('edit-stub')));
          },
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
    await tester.pump();

    await tester.tap(find.byType(TransactionSearchRow));
    await tester.pumpAndSettle();

    expect(pushedLocation, '/home/edit/1');
    expect(find.text('edit-stub'), findsOneWidget);
  });

  testWidgets(
    'swipe-to-delete shows undo snackbar; UNDO restores row before any repo write',
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
      when(() => tx.delete(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(tx),
            categoryRepositoryProvider.overrideWithValue(cat),
            accountRepositoryProvider.overrideWithValue(acct),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
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

      // Drag-open the slidable, then tap the Delete action. Mirrors the
      // pattern used in `home_screen_test.dart` — relying on
      // DismissiblePane via a single large drag is flaky in widget
      // tests because the dismissal animation interacts with the row's
      // own re-emission timing.
      await tester.drag(
        find.byKey(const ValueKey<int>(1)),
        const Offset(-900, 0),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CategorySearchDetailScreen)),
      );
      await tester.tap(find.text(l10n.commonDelete).last);
      // Drive the snackbar in: the controller emits, ref.listen fires
      // post-build, and the SnackBar runs its open animation. Avoid
      // `pumpAndSettle` because the 4-second undo timer would block
      // forever — pump a bounded amount of time instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // Row hidden, snackbar visible with UNDO action.
      expect(find.byType(TransactionSearchRow), findsNothing);
      expect(find.text(l10n.homeDeleteUndoSnackbar), findsOneWidget);
      expect(find.text(l10n.commonUndo), findsOneWidget);
      verifyNever(() => tx.delete(any()));

      // Tap UNDO before the timer fires.
      await tester.tap(find.text(l10n.commonUndo));
      await tester.pump();
      await tester.pump();

      // Row restored, repo.delete never called.
      expect(find.byType(TransactionSearchRow), findsOneWidget);
      verifyNever(() => tx.delete(any()));
    },
  );

  testWidgets(
    'swipe-to-delete commits via repo.delete after the undo window expires',
    (tester) async {
      final tx = _MockTransactionRepository();
      final cat = _MockCategoryRepository();
      final acct = _MockAccountRepository();
      final txStream = StreamController<List<Transaction>>.broadcast();
      addTearDown(txStream.close);

      when(() => tx.watchByMemo('coffee')).thenAnswer((_) => txStream.stream);
      when(
        () => cat.watchAll(includeArchived: true),
      ).thenAnswer((_) => Stream.value([_cat()]));
      when(
        () => acct.watchAll(includeArchived: true),
      ).thenAnswer((_) => Stream.value([_acct()]));
      when(() => tx.delete(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(tx),
            categoryRepositoryProvider.overrideWithValue(cat),
            accountRepositoryProvider.overrideWithValue(acct),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
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

      txStream.add([_tx()]);
      await tester.pump();
      await tester.pump();
      expect(find.byType(TransactionSearchRow), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey<int>(1)),
        const Offset(-900, 0),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CategorySearchDetailScreen)),
      );
      await tester.tap(find.text(l10n.commonDelete).last);
      await tester.pump();
      await tester.pump();

      verifyNever(() => tx.delete(any()));

      // Past the 4-second undo window → repo.delete commits.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      verify(() => tx.delete(1)).called(1);
    },
  );

  testWidgets(
    'renders TransactionSearchRow without a PopupMenu (no duplicate affordance)',
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
    },
  );

  testWidgets(
    'income totals wait for category metadata before rendering sign',
    (tester) async {
      final tx = _MockTransactionRepository();
      final cat = _MockCategoryRepository();
      final acct = _MockAccountRepository();
      final categories = StreamController<List<Category>>.broadcast();
      addTearDown(categories.close);

      when(() => tx.watchByMemo('coffee')).thenAnswer(
        (_) => Stream.value([
          Transaction(
            id: 1,
            amountMinorUnits: 1000,
            currency: _usd,
            categoryId: 1,
            accountId: 1,
            date: DateTime.utc(2026, 5, 1),
            memo: 'coffee',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ]),
      );
      when(
        () => cat.watchAll(includeArchived: true),
      ).thenAnswer((_) => categories.stream);
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
            locale: Locale('en'),
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
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('-\$10.00'), findsNothing);

      categories.add([
        const Category(
          id: 1,
          type: CategoryType.income,
          l10nKey: 'cat.salary',
          customName: 'Salary',
          icon: 'attach_money',
          color: 1,
          sortOrder: 1,
          isArchived: false,
        ),
      ]);
      await tester.pump();
      await tester.pump();

      expect(find.text('+\$10.00'), findsWidgets);
    },
  );

  testWidgets(
    'detail page pre-fills from cache and opens its own live subscription',
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
      verify(() => tx.watchByMemo('coffee')).called(1);

      await tester.tap(find.byType(CategorySearchTile));
      await tester.pumpAndSettle();

      // Detail page MUST open its own watchByMemo subscription so live
      // updates from the edit screen propagate after pop. The cache is a
      // synchronous pre-fill, not a substitute for the subscription.
      verify(() => tx.watchByMemo('coffee')).called(1);
      expect(find.byType(CategorySearchDetailScreen), findsOneWidget);
      expect(find.byType(TransactionSearchRow), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CategorySearchDetailScreen)),
      );
      expect(find.text(l10n.analysisErrorMessage), findsNothing);
    },
  );

  testWidgets(
    'detail page reflects edits made after navigating in (live stream)',
    (tester) async {
      final tx = _MockTransactionRepository();
      final cat = _MockCategoryRepository();
      final acct = _MockAccountRepository();
      final txStream = StreamController<List<Transaction>>.broadcast();
      addTearDown(txStream.close);

      Transaction snap({required int amount, String memo = 'coffee'}) =>
          Transaction(
            id: 1,
            amountMinorUnits: amount,
            currency: _usd,
            categoryId: 1,
            accountId: 1,
            date: DateTime.utc(2026, 5, 1),
            memo: memo,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          );

      when(() => tx.watchByMemo('coffee')).thenAnswer((_) => txStream.stream);
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
            locale: Locale('en'),
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

      txStream.add([snap(amount: 1000)]);
      await tester.pump();
      await tester.pump();
      expect(find.text(r'-$10.00'), findsWidgets);

      // Simulate the edit screen popping: the underlying memo stream
      // re-emits with the updated row. The detail page must reflect it
      // without the user navigating again.
      txStream.add([snap(amount: 2500)]);
      await tester.pump();
      await tester.pump();

      expect(find.text(r'-$25.00'), findsWidgets);
      expect(find.text(r'-$10.00'), findsNothing);
    },
  );

  testWidgets(
    'detail page drops a row when its memo is edited to no longer match',
    (tester) async {
      final tx = _MockTransactionRepository();
      final cat = _MockCategoryRepository();
      final acct = _MockAccountRepository();
      final txStream = StreamController<List<Transaction>>.broadcast();
      addTearDown(txStream.close);

      when(() => tx.watchByMemo('coffee')).thenAnswer((_) => txStream.stream);
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
            locale: Locale('en'),
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

      txStream.add([_tx()]);
      await tester.pump();
      await tester.pump();
      expect(find.byType(TransactionSearchRow), findsOneWidget);

      // After the user edits the row's memo to no longer match the
      // active query, Drift's `watchByMemo('coffee')` re-emits with the
      // row dropped. The detail page reflects the empty state.
      txStream.add(const <Transaction>[]);
      await tester.pump();
      await tester.pump();

      expect(find.byType(TransactionSearchRow), findsNothing);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CategorySearchDetailScreen)),
      );
      expect(find.text(l10n.analysisNoResults), findsOneWidget);
    },
  );

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
