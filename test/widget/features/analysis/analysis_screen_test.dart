import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/features/analysis/search/category_search_detail_screen.dart';
import 'package:ledgerly/features/analysis/search/widgets/analysis_search_placeholder.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

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

GoRouter _guardRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/analysis',
        builder: (_, _) => const AnalysisScreen(),
        routes: [
          GoRoute(
            path: 'search/:categoryId',
            builder: (context, state) {
              final categoryId = int.tryParse(
                state.pathParameters['categoryId'] ?? '',
              );
              final query = state.uri.queryParameters['q']?.trim() ?? '';
              final currencyCode = state.uri.queryParameters['c'] ?? '';
              if (categoryId == null || query.isEmpty || currencyCode.isEmpty) {
                return const AnalysisScreen();
              }
              return CategorySearchDetailScreen(
                categoryId: categoryId,
                query: query,
                currencyCode: currencyCode,
              );
            },
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
      routerConfig: _guardRouter(initialLocation),
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

  group('router guards', () {
    setUp(() {
      when(() => tx.watchByMemo(any())).thenAnswer((_) => const Stream.empty());
    });

    Future<void> expectFallback(WidgetTester tester, String path) async {
      await tester.pumpWidget(
        _routerHarness(tx: tx, cat: cat, acct: acct, initialLocation: path),
      );
      await tester.pump();
      expect(find.byType(AnalysisScreen), findsOneWidget);
      expect(find.byType(CategorySearchDetailScreen), findsNothing);
    }

    testWidgets('non-int categoryId falls back to AnalysisScreen', (
      tester,
    ) async {
      await expectFallback(tester, '/analysis/search/abc?q=coffee&c=USD');
    });

    testWidgets('empty q falls back to AnalysisScreen', (tester) async {
      await expectFallback(tester, '/analysis/search/5?q=&c=USD');
    });

    testWidgets('empty c falls back to AnalysisScreen', (tester) async {
      await expectFallback(tester, '/analysis/search/5?q=coffee&c=');
    });

    testWidgets('whitespace-only q (after trim) falls back', (tester) async {
      await expectFallback(tester, '/analysis/search/5?q=%20%20&c=USD');
    });
  });
}
