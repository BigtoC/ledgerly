import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/accounts/account_form_screen.dart';
import '../features/analysis/analysis_screen.dart';
import '../features/analysis/search/category_search_detail_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/home/home_screen.dart';
import '../features/recurring/recurring_rule_form_screen.dart';
import '../features/recurring/recurring_rules_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shopping_list/shopping_list_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/transactions/transaction_form_screen.dart';
import '../features/transactions/transaction_form_state.dart';
import 'providers/splash_redirect_provider.dart';
import 'widgets/adaptive_shell.dart';

part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@Riverpod(keepAlive: true, dependencies: [splashGateSnapshot])
GoRouter router(Ref ref) {
  final gate = ref.watch(splashGateSnapshotProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: gate,
    redirect: (context, state) {
      if (!gate.splashEnabled) {
        if (state.matchedLocation == '/' ||
            state.matchedLocation == '/splash') {
          return '/home';
        }
        return null;
      }
      if (state.matchedLocation == '/') return '/splash';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, state) =>
            _materialPage(state, const SizedBox.shrink()),
      ),
      GoRoute(
        path: '/splash',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        // Preview entry from Settings → Splash. Top-level so the splash
        // covers the bottom navigation, with a fade transition that
        // matches the production splash. Tapping the splash Enter
        // button pops back to settings (see `SplashEnterButton`).
        path: '/splash/preview',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(previewMode: true),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (ctx, state, shell) => _materialPage(
          state,
          AdaptiveShell(
            currentIndex: shell.currentIndex,
            onDestinationSelected: shell.goBranch,
            child: shell,
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, state) =>
                    _materialPage(state, const HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      const _AdaptiveTransactionFormRoute(),
                    ),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    redirect: (_, state) =>
                        int.tryParse(state.pathParameters['id'] ?? '') == null
                        ? '/home'
                        : null,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      _AdaptiveTransactionFormRoute(
                        transactionId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'shopping-list',
                    pageBuilder: (_, state) =>
                        _materialPage(state, const ShoppingListScreen()),
                    routes: [
                      GoRoute(
                        path: ':itemId',
                        redirect: (_, state) =>
                            int.tryParse(
                                  state.pathParameters['itemId'] ?? '',
                                ) ==
                                null
                            ? '/home/shopping-list'
                            : null,
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (ctx, state) => _modalPage(
                          state,
                          _AdaptiveTransactionFormRoute(
                            shoppingListItemId: int.parse(
                              state.pathParameters['itemId']!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analysis',
                pageBuilder: (_, state) =>
                    _materialPage(state, const AnalysisScreen()),
                routes: [
                  GoRoute(
                    path: 'search/:categoryId',
                    redirect: (_, state) {
                      final categoryId = int.tryParse(
                        state.pathParameters['categoryId'] ?? '',
                      );
                      final query =
                          state.uri.queryParameters['q']?.trim() ?? '';
                      final currencyCode =
                          state.uri.queryParameters['c']?.trim() ?? '';
                      if (categoryId == null ||
                          query.isEmpty ||
                          currencyCode.isEmpty) {
                        return '/analysis';
                      }
                      return null;
                    },
                    pageBuilder: (context, state) {
                      final categoryId = int.parse(
                        state.pathParameters['categoryId']!,
                      );
                      final query =
                          state.uri.queryParameters['q']?.trim() ?? '';
                      final currencyCode = state.uri.queryParameters['c']!
                          .trim();
                      return _materialPage(
                        state,
                        CategorySearchDetailScreen(
                          categoryId: categoryId,
                          query: query,
                          currencyCode: currencyCode,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (_, state) =>
                    _materialPage(state, const SettingsScreen()),
                routes: [
                  GoRoute(
                    path: 'categories',
                    pageBuilder: (_, state) =>
                        _materialPage(state, const CategoriesScreen()),
                  ),
                  GoRoute(
                    path: 'about',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (_, state) =>
                        _materialPage(state, const AboutScreen()),
                  ),
                  GoRoute(
                    path: 'manage-accounts/new',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) =>
                        _modalPage(state, const AccountFormScreen()),
                  ),
                  GoRoute(
                    path: 'manage-accounts/:id',
                    redirect: (_, state) =>
                        int.tryParse(state.pathParameters['id'] ?? '') == null
                        ? '/settings'
                        : null,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      AccountFormScreen(
                        accountId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'recurring',
                    pageBuilder: (_, state) =>
                        _materialPage(state, const RecurringRulesScreen()),
                  ),
                  GoRoute(
                    path: 'recurring/new',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      const _AdaptiveFormRoute(
                        child: RecurringRuleFormScreen(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'recurring/:id',
                    redirect: (_, state) =>
                        int.tryParse(state.pathParameters['id'] ?? '') == null
                        ? '/settings'
                        : null,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      _AdaptiveFormRoute(
                        child: RecurringRuleFormScreen(
                          ruleId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _AdaptiveTransactionFormRoute extends StatelessWidget {
  const _AdaptiveTransactionFormRoute({
    this.transactionId,
    this.shoppingListItemId,
  });

  final int? transactionId;
  final int? shoppingListItemId;

  @override
  Widget build(BuildContext context) {
    final TransactionFormMode? mode = shoppingListItemId != null
        ? EditShoppingListDraftMode(shoppingListItemId: shoppingListItemId!)
        : null;
    return _AdaptiveFormRoute(
      child: TransactionFormScreen(transactionId: transactionId, mode: mode),
    );
  }
}

/// Adaptive layout for full-screen form routes (transactions, recurring
/// rules, etc.). On <600dp the child renders edge-to-edge; on >=600dp it
/// renders inside a centered, max-560-wide constrained `Dialog` with a
/// dimmed scrim. Single source of truth for the breakpoint constants —
/// every form route uses this wrapper.
class _AdaptiveFormRoute extends StatelessWidget {
  const _AdaptiveFormRoute({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return child;
        }
        return Scaffold(
          backgroundColor: Colors.black54,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Dialog(
                  insetPadding: const EdgeInsets.all(24),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox.expand(child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Flutter SDK `MaterialPage` for non-modal routes, matching what go_router
/// built for plain `builder:` routes before 18.x. go_router 18 detects the
/// app type via `package:material_ui`'s `MaterialApp`, which is a different
/// class from the `package:flutter/material.dart` one this app uses, so plain
/// `builder:` routes would silently fall back to `NoTransitionPage` (no push
/// animation, no iOS back-swipe). Building the page explicitly keeps the
/// platform-default Material transitions.
Page<void> _materialPage(GoRouterState state, Widget child) {
  return MaterialPage(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: <String, String>{
      ...state.pathParameters,
      ...state.uri.queryParameters,
    },
    restorationId: state.pageKey.value,
    child: child,
  );
}

Page<void> _modalPage(GoRouterState state, Widget child) {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => CupertinoPage(
      key: state.pageKey,
      fullscreenDialog: true,
      child: child,
    ),
    _ => MaterialPage(key: state.pageKey, fullscreenDialog: true, child: child),
  };
}
