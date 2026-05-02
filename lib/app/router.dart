import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/accounts/account_form_screen.dart';
import '../features/accounts/accounts_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/home/home_screen.dart';
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
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
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
        builder: (ctx, state, shell) => AdaptiveShell(
          currentIndex: shell.currentIndex,
          onDestinationSelected: shell.goBranch,
          child: shell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      const _AdaptiveTransactionFormRoute(),
                      fullscreenDialog: true,
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
                      fullscreenDialog: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accounts',
                builder: (_, _) => const AccountsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      const AccountFormScreen(),
                      fullscreenDialog: true,
                    ),
                  ),
                  GoRoute(
                    path: 'shopping-list',
                    builder: (_, _) => const ShoppingListScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        redirect: (_, state) =>
                            int.tryParse(state.pathParameters['id'] ?? '') ==
                                null
                            ? '/accounts/shopping-list'
                            : null,
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (ctx, state) => _modalPage(
                          state,
                          _AdaptiveTransactionFormRoute(
                            shoppingListItemId: int.parse(
                              state.pathParameters['id']!,
                            ),
                          ),
                          fullscreenDialog: true,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':id',
                    redirect: (_, state) =>
                        int.tryParse(state.pathParameters['id'] ?? '') == null
                        ? '/accounts'
                        : null,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (ctx, state) => _modalPage(
                      state,
                      AccountFormScreen(
                        accountId: int.parse(state.pathParameters['id']!),
                      ),
                      fullscreenDialog: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'categories',
                    builder: (_, _) => const CategoriesScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const AboutScreen(),
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
    final form = TransactionFormScreen(
      transactionId: transactionId,
      mode: mode,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return form;
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
                  child: SizedBox.expand(child: form),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Page<void> _modalPage(
  GoRouterState state,
  Widget child, {
  bool fullscreenDialog = false,
}) {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => CupertinoPage(
      key: state.pageKey,
      fullscreenDialog: fullscreenDialog,
      child: child,
    ),
    _ => MaterialPage(
      key: state.pageKey,
      fullscreenDialog: fullscreenDialog,
      child: child,
    ),
  };
}
