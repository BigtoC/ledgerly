# M4 — App shell: bootstrap, routing, theme wiring

> **For agentic workers.** Drive this plan through `superpowers:subagent-driven-development`
> and resume with `superpowers:executing-plans` if interrupted. Every task in §6 is
> bite-sized; run the §7 tests alongside, not at the end.

**Owner:** Single developer / single PR (`docs/plans/implementation-plan.md` §5 M4: *"Parallel? Better as a single PR — shell concerns couple tightly"*).
**Milestone:** M4 — App shell (`docs/plans/implementation-plan.md` §5 M4 deliverables + exit criteria; §7 M4 testing row).
**Streams:** None. M4 is deliberately unsharded; the bootstrap ordering, router redirect, and provider overrides must land together or nothing runs.

**Upstream dependencies (must be merged to `main` before this plan starts red/green):**
- **M0** — folder skeleton, `pubspec.yaml`, `analysis_options.yaml`, `import_analysis_options.yaml`, CI. **Merged.**
- **M1 Stream A** — Drift tables + DAOs + `AppDatabase(QueryExecutor)` constructor + `schemaVersion = 2` (note: MVP bumped to 2 to add `currencies.custom_name`). **Merged.**
- **M1 Stream B** — Freezed domain models + `LocaleService` stub (`Platform.localeName`, fallback `en_US`). **Merged.**
- **M2 Stream A** — `money_formatter.dart`, `date_helpers.dart` (indirectly consumed by splash placeholder). **Merged.**
- **M2 Stream B** — `icon_registry.dart`, `color_palette.dart` (not touched by M4). **Merged.**
- **M2 Stream C** — `lightTheme` / `darkTheme` in `core/theme/app_theme.dart`; `l10n/app_{en,zh,zh_CN,zh_TW}.arb` populated with `appTitle`, `navHome`, `navAccounts`, `navSettings`, and common labels. **Merged.**
- **M3 Stream A** — `DriftTransactionRepository`, `DriftCategoryRepository`. **Merged.**
- **M3 Stream B** — `DriftAccountTypeRepository`, `DriftAccountRepository`, `DriftCurrencyRepository`. **Merged.**
- **M3 Stream C** — `DriftUserPreferencesRepository` (with `watchSplashEnabled()`, `watchSplashStartDate()`, `watchThemeMode()`, `watchLocale()`, `getFirstRunComplete()`), `runFirstRunSeed(...)` in `lib/data/seed/first_run_seed.dart`, migration harness. **Merged.**

**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- Architecture → Folder Structure — lines **104–222** (lib/app/ layout).
- Bootstrap Sequence — lines **225–236** (the 8 steps this plan implements verbatim).
- Technology Stack — lines **238–250** (Riverpod + `riverpod_generator`, `go_router` `StatefulShellRoute`, `flutter_localizations`).
- Routing Structure — lines **630–653** (every route + root `redirect:` on `splash_enabled`).
- MVP Screens & User Flow → First-run Defaults — lines **666–673** (splash enabled by default, seeded default account auto-selected).
- Adaptive Layouts — lines **759–774** (600dp breakpoint → `BottomNavigationBar` ↔ `NavigationRail`).
- Internationalization → locale fallback policy — lines **894–900** (Chinese resolution; `zh` bare fallback; runtime English fallback when script is ambiguous).
- Theme — lines **904–912** (`core/theme/app_theme.dart`, `Riverpod provider watches preference and rebuilds MaterialApp`).
- Splash Screen (MVP) → Two-Stage Launch + Launch Flow — lines **521–545** (native splash → Flutter splash or Home; date-prompt branch).

**Guardrails from `docs/plans/implementation-plan.md` §6:**
- **G9** — all `await` lives inside `bootstrap.dart`; `main.dart` stays `await bootstrap()`.
- **G10** — router `redirect:` reads `splash_enabled`; the SplashScreen is **never** rendered when disabled (no flash).
- **G11** — layout primitives match PRD; the adaptive breakpoint is wired **at the shell level**, not inside individual screens.
- **G12** — tests organized by layer; M4 lands `test/widget/smoke/` + `test/integration/bootstrap_to_home_test.dart`.

**Tech stack (already in `pubspec.yaml`, no new dependencies):** `flutter_riverpod ^2.6.1`, `riverpod_annotation ^2.6.1`, `riverpod_generator ^2.6.3`, `go_router ^17.2.1`, `intl ^0.20.2`, `flutter_localizations`. No `dio`, no `flutter_secure_storage`.

**One-sentence goal.** Wire the 8-step bootstrap sequence, the provider graph, the go_router tree with the splash redirect, and the adaptive shell so cold launch on a clean device opens (first-run date prompt → splash → Home) and on a subsequent launch with `splash_enabled=false` opens Home directly — with a smoke-test and integration-test template that becomes the harness every M5 slice reuses.

**Architecture paragraph.** Bootstrap is a single async function that owns every `await`: it opens `AppDatabase`, initializes `LocaleService` and `intl` locale data (for `en_US` + `zh_TW` + `zh_CN` so `DateFormat` is ready before first paint), eagerly reads `user_preferences` once (so the router's sync `redirect:` has real values on the first frame), constructs the six repositories, invokes `runFirstRunSeed(...)` on an empty DB, and then builds a `ProviderScope` whose only override is `appDatabaseProvider`. Every repository provider (including `userPreferencesRepositoryProvider`) is derived from `appDatabaseProvider` so a single override makes the entire data layer testable. `MaterialApp.router` consumes a `routerProvider` whose `refreshListenable` is a `ChangeNotifier` fed by the `splash_enabled` / `splash_start_date` streams — that bridges Drift's reactive updates to go_router's synchronous redirect. Theme and locale providers watch the same repository streams and rebuild `MaterialApp` on change. The three placeholder feature screens (`SplashScreen`, `HomeScreen`, `SettingsScreen`) render bare `Scaffold`s plus the minimal affordances the integration test needs; M5 replaces them in place.

---

## 0. Current state of the files being replaced / created

### 0.1 `lib/main.dart` (frozen, no change)

```dart
Future<void> main() async {
  await bootstrap();
}
```

G9 is already satisfied. Leave alone.

### 0.2 `lib/app/bootstrap.dart` (current M0 stub)

```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
```

This plan replaces it with the 8-step PRD sequence (§4 below).

### 0.3 `lib/app/app.dart` (current M0 stub)

```dart
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'Ledgerly',
    home: Scaffold(body: Center(child: Text('Ledgerly'))),
  );
}
```

This plan replaces the body with `MaterialApp.router` + theme/locale provider watching (§5 below). The `title: 'Ledgerly'` literal goes away — `MaterialApp.onGenerateTitle` reads `AppLocalizations.of(context).appTitle`.

### 0.4 `lib/app/router.dart` (current M0 TODO file, no code)

Currently a comment-only file. This plan fills it with the `routerProvider` (§5 below).

### 0.5 `lib/data/seed/first_run_seed.dart` (M3 Stream C, frozen)

Entry point: `runFirstRunSeed({required db, required currencies, …, required localeService})`. Idempotent — short-circuits when `preferences.getFirstRunComplete()` returns `true`. Bootstrap calls this after opening the DB and constructing repositories.

### 0.6 `lib/data/repositories/user_preferences_repository.dart` (M3 Stream C, frozen)

Relevant watchers consumed by M4:
- `Stream<ThemeMode> watchThemeMode()` — `themeModeProvider` subscribes.
- `Stream<Locale?> watchLocale()` — `localePreferenceProvider` subscribes.
- `Stream<bool> watchSplashEnabled()` — router `refreshListenable` + redirect.
- `Stream<DateTime?> watchSplashStartDate()` — router `refreshListenable` + redirect (for the first-launch date-prompt branch).
- `Future<bool> getFirstRunComplete()` — already used by the seed; bootstrap never calls it directly.

### 0.7 `lib/data/services/locale_service.dart` (M1 Stream B, frozen)

`LocaleService.deviceLocale` returns the BCP-47-ish string (`en_US`, `zh_TW`, `ja_JP`) or `'en_US'` on `Platform` failures. Consumed by bootstrap step 3 and the seed's locale→currency mapping.

### 0.8 `lib/core/theme/app_theme.dart` (M2 Stream C, frozen)

Exports `lightTheme` and `darkTheme` (`ColorScheme.fromSeed(...)`). M4 wires them to `MaterialApp.theme` / `darkTheme`.

### 0.9 Feature placeholders (to be modified in place)

All six `features/<slice>/<slice>_screen.dart` are currently `// TODO(M5): ...` comment-only files. M4 converts three of them — `splash`, `home`, `settings` — into **minimal runnable `Scaffold`s with the exact affordances the integration test exercises**. The remaining three — `transactions`, `categories`, `accounts` — stay as one-liner `Scaffold(body: Center(child: Text(...)))` placeholders so the router has valid widget builders. M5 replaces all six.

### 0.10 `test/widget/smoke_test.dart` (M0)

Currently calls `app.main()` and expects the `'Ledgerly'` placeholder text. M4 replaces it with the `ProviderScope`-override template and asserts `AppLocalizations`-driven title instead.

### 0.11 `test/integration/` (currently empty)

M4 lands the first integration test: `test/integration/bootstrap_to_home_test.dart`.

---

## 1. Exit criteria

All conditions must hold on `main` before M5 starts.

1. **Cold launch, first run.** Clean device / wiped data → native splash → Flutter first-run path: splash route renders → tap the placeholder "Enter" button → `/home` renders with placeholder empty state. Confirmed by the integration test in §7.
2. **Cold launch, splash disabled.** With `splash_enabled = false` persisted → native splash → `/home` renders directly; `SplashScreen` is never constructed (verify via `find.byType(SplashScreen) → findsNothing`). Confirmed by the integration test variant. **Guardrail G10.**
3. **Theme reactivity.** Toggling `UserPreferencesRepository.setThemeMode(ThemeMode.dark)` while the app is running rebuilds `MaterialApp` with the dark theme (observed via `Theme.of(context).brightness`). Confirmed by a widget test.
4. **Chinese locale resolution.** `localeResolutionCallback` maps `zh_HK` → `zh_TW`, `zh_SG` → `zh_CN`, `zh` with no script → `en` (PRD 894–900). Unit-tested pure function.
5. **Smoke-test template.** `test/widget/smoke_test.dart` builds `App` wrapped in `ProviderScope` with `appDatabaseProvider` overridden to an in-memory Drift DB, passes without flutter errors, and asserts `AppLocalizations.of(context).appTitle` renders. Becomes the copy-paste base for every M5 widget test.
6. **Bootstrap ordering proof.** A unit test on `bootstrap()` (via a test-friendly `bootstrapFor(...)` helper — see §4.3) asserts the ordering: DB opens before seed, seed before `runApp`, locale data initialized before first `DateFormat` call. **Risk #8 in `implementation-plan.md` §9.**
7. **`main.dart` stays tiny.** Static check: `grep -E '^\s*await' lib/main.dart` returns only the `await bootstrap()` line. **Guardrail G9.**
8. **`flutter analyze` clean.** No warnings. Generated files (`*.g.dart`, `*.freezed.dart`) for new providers build under `build_runner build --delete-conflicting-outputs`.
9. **Adaptive breakpoint in place.** Shell swaps `BottomNavigationBar` ↔ `NavigationRail` at 600dp via `LayoutBuilder`; verified by a widget test that pumps two widths (400dp, 900dp) and finds the correct widget type. **Guardrail G11.**

---

## 2. Deliverables (file-by-file)

### 2.1 `lib/app/providers/app_database_provider.dart` (new)

Minimal `@Riverpod(keepAlive: true)` declaration of `AppDatabase`. Implementation throws `UnimplementedError` — the value is **always** supplied via `overrideWithValue` (bootstrap in production, `newTestAppDatabase()` in tests). Rationale: the DB is opened asynchronously, has platform-specific executor selection (`driftDatabase(name: 'ledgerly')` uses path_provider), and requires post-open seeding. Letting Riverpod construct it would hide the init order from the bootstrap step list.

```dart
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => throw UnimplementedError(
  'appDatabaseProvider must be overridden by bootstrap() or a test harness',
);
```

### 2.2 `lib/app/providers/repository_providers.dart` (new)

Six `@Riverpod(keepAlive: true)` providers — one per repository. Each reads `appDatabaseProvider` and constructs the Drift-backed implementation:

```dart
@Riverpod(keepAlive: true)
CurrencyRepository currencyRepository(Ref ref) =>
    DriftCurrencyRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) =>
    DriftCategoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
AccountTypeRepository accountTypeRepository(Ref ref) =>
    DriftAccountTypeRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    DriftAccountRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) =>
    DriftTransactionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
UserPreferencesRepository userPreferencesRepository(Ref ref) =>
    DriftUserPreferencesRepository(ref.watch(appDatabaseProvider));
```

**Why `keepAlive: true`:** repositories hold no state but their downstream Drift `.watch()` streams are long-lived; letting Riverpod auto-dispose the repository tears down stream listeners unnecessarily when the last consumer leaves (e.g., during a route transition). Matches PRD 100–102 *Reactive Data Flow*.

### 2.3 `lib/app/providers/locale_service_provider.dart` (new)

```dart
@Riverpod(keepAlive: true)
LocaleService localeService(Ref ref) => const LocaleService();
```

Override target for tests that need to simulate a non-`en_US` device locale.

### 2.4 `lib/app/providers/theme_provider.dart` (new)

```dart
@riverpod
ThemeMode themeMode(Ref ref) =>
    ref.watch(_themeModeStreamProvider).value ?? ThemeMode.system;

@Riverpod(keepAlive: true)
Stream<ThemeMode> _themeModeStream(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchThemeMode();
```

`MaterialApp.themeMode` consumes `themeModeProvider`. The intermediate stream provider exists so unit tests can override the stream directly with a `StreamController`. PRD 908–910.

### 2.5 `lib/app/providers/locale_provider.dart` (new)

Two providers plus a pure helper:

```dart
@Riverpod(keepAlive: true)
Stream<Locale?> _userLocalePreferenceStream(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchLocale();

@riverpod
Locale? userLocalePreference(Ref ref) =>
    ref.watch(_userLocalePreferenceStreamProvider).value;

/// PRD 894–900. Pure. Unit-tested in §7.
Locale? resolveChineseLocale(
  Locale? preferred,
  Iterable<Locale> supported,
  Locale deviceLocale,
) { … }
```

`resolveChineseLocale` handles the PRD rules:
- `null` preferred → fall through to `deviceLocale`.
- `zh_TW`, `zh_HK`, `zh_MO`, `zh_Hant*` → `const Locale('zh', 'TW')`.
- `zh_CN`, `zh_SG`, `zh_Hans*` → `const Locale('zh', 'CN')`.
- `zh` with no script/region → `const Locale('en')` (documented English fallback, PRD 898).
- Non-Chinese → return preferred if `supported` contains it, else `null` (let Flutter default to the first supported locale, which is `en`).

`MaterialApp.localeResolutionCallback` wraps this helper.

### 2.6 `lib/app/providers/splash_redirect_provider.dart` (new)

The bridge between `user_preferences` streams and go_router's `refreshListenable`. Exposes a single `Listenable` plus a sync snapshot the `redirect:` reads.

```dart
/// Two-field snapshot consumed synchronously by the router's redirect
/// callback. Updated from two long-lived stream subscriptions; notifies
/// listeners on any change.
class SplashGateSnapshot extends ChangeNotifier {
  bool splashEnabled = true;           // PRD default
  DateTime? splashStartDate;
  …
}

@Riverpod(keepAlive: true)
SplashGateSnapshot splashGateSnapshot(Ref ref) {
  final notifier = SplashGateSnapshot._();
  final repo = ref.watch(userPreferencesRepositoryProvider);

  final enabledSub = repo.watchSplashEnabled().listen((v) {
    notifier._setEnabled(v);
  });
  final dateSub = repo.watchSplashStartDate().listen((v) {
    notifier._setStartDate(v);
  });

  ref.onDispose(() {
    enabledSub.cancel();
    dateSub.cancel();
    notifier.dispose();
  });

  return notifier;
}
```

The router's `redirect:` reads `notifier.splashEnabled` and `notifier.splashStartDate` on each invocation, and the router re-evaluates because `refreshListenable: notifier` is set. No `async` inside `redirect:`.

**Initial value correctness.** Stream subscriptions are asynchronous; the first frame could land before either stream has emitted. To avoid a frame flash to the wrong route, bootstrap eagerly reads `getSplashEnabled()` / `getSplashStartDate()` once before `runApp` and uses the results to seed the `SplashGateSnapshot` via a second override (see §4.3). That makes the very first `redirect:` call see the real values.

### 2.7 `lib/app/router.dart` (replace TODO file)

```dart
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final gate = ref.watch(splashGateSnapshotProvider);
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: gate,
    redirect: (context, state) {
      if (!gate.splashEnabled) {
        return state.matchedLocation == '/' ? '/home' : null;
      }
      if (state.matchedLocation == '/') return '/splash';
      return null;
    },
    routes: [ … see §5 … ],
  );
}
```

### 2.8 `lib/app/app.dart` (replace M0 stub)

```dart
class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final preferredLocale = ref.watch(userLocalePreferenceProvider);
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: preferredLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (device, supported) =>
          resolveChineseLocale(preferredLocale, supported,
              device ?? const Locale('en', 'US')),
      routerConfig: router,
    );
  }
}
```

### 2.9 `lib/app/bootstrap.dart` (replace M0 stub)

See §4 for the step-by-step body.

### 2.10 `lib/app/widgets/adaptive_shell.dart` (new)

The wrapper widget passed to `StatefulShellRoute.indexedStack`'s `builder:` callback. Renders the stateful navigation shell with the 600dp adaptive switch:

```dart
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        return Scaffold(
          body: Row(children: [
            if (wide) NavigationRail(…destinations…, selectedIndex: shell.currentIndex,
                onDestinationSelected: shell.goBranch),
            Expanded(child: shell),
          ]),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(…destinations…,
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: shell.goBranch),
        );
      },
    );
  }
}
```

Destinations are: Home (`Symbols.home`), Accounts (`Symbols.account_balance_wallet`), Settings (`Symbols.settings`). Labels via `AppLocalizations.navHome` / `navAccounts` / `navSettings`.

### 2.11 Feature placeholders (modify, do not add features)

Three placeholders gain minimal logic so the integration test can walk the first-run flow:

- `lib/features/splash/splash_screen.dart` — `ConsumerWidget`. Reads `userPreferencesRepositoryProvider.watchSplashStartDate()`. Two UI states, both rendered as bare `Scaffold`s with `Semantics` labels:
  - start date `null` → `TextButton(onPressed: () => ref.read(userPreferencesRepositoryProvider).setSplashStartDate(DateTime.now()), child: Text('Set start date'))`.
  - start date set → `TextButton(onPressed: () => context.go('/home'), child: Text(AppLocalizations.of(ctx).splashEnter))`.

  `// TODO(M5): replace entire file with day-counter hnotes-style UI per PRD → Splash Screen.`

- `lib/features/home/home_screen.dart` — `ConsumerWidget`, `Scaffold(appBar: AppBar(title: …appTitle), body: Center(child: Text('Home')))`. M5 replaces with the `CustomScrollView` tree from PRD → Layout Primitives.

- `lib/features/settings/settings_screen.dart` — `ConsumerWidget`, `Scaffold` with one `SwitchListTile` bound to `userPreferencesRepositoryProvider.setSplashEnabled(...)`. Enables the integration-test variant without poking the repo directly; also demonstrates the controller/widget pattern M5 will extend. **Does NOT introduce a `SettingsController` — that's M5's job.**

The remaining three — `transactions/transaction_form_screen.dart`, `accounts/accounts_screen.dart`, `categories/categories_screen.dart` — stay one-liner placeholders:

```dart
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Accounts')));
}
```

### 2.12 `test/support/test_app.dart` (new — smoke/integration template)

```dart
Future<AppDatabase> newTestAppDatabase() async =>
    AppDatabase(NativeDatabase.memory());

/// Overrides the DB, skips first-run seed by default, skips splash gate
/// updates. Tests that need seeded data call `runFirstRunSeed(...)`
/// explicitly before `pumpWidget`.
Widget buildTestApp({
  required AppDatabase db,
  LocaleService? localeService,
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (localeService != null)
        localeServiceProvider.overrideWithValue(localeService),
      ...extraOverrides,
    ],
    child: const App(),
  );
}
```

Every M5 widget test starts from `buildTestApp`.

### 2.13 `test/widget/smoke_test.dart` (rewrite)

Uses the template above. Asserts:
- `find.byType(MaterialApp)` → 1.
- Localized `appTitle` reaches the root (via `AppLocalizations.of`).
- `tester.takeException()` is `null`.
- The splash route is reached (first-run path, DB freshly seeded).

Replaces the M0 body but keeps the file path so the existing CI entry keeps passing.

### 2.14 `test/integration/bootstrap_to_home_test.dart` (new)

Two `testWidgets` variants in one file — see §7.

### 2.15 `l10n/app_{en,zh,zh_TW,zh_CN}.arb` — add two keys only

Most labels exist from M2 Stream C. M4 only needs:
- `splashEnter` — "Enter" placeholder CTA. *Reuses seeded preference default `kDefaultSplashButtonLabel`, but the `AppLocalizations.splashEnter` key is needed so the placeholder renders the translated string on subsequent languages.*
- `splashSetStartDate` — "Set start date" for the placeholder prompt.

---

## 3. Provider graph and wiring

The graph is deliberately shallow. No provider observes more than one upstream:

```text
appDatabaseProvider (overridden)
  │
  ├─▶ currencyRepositoryProvider
  ├─▶ categoryRepositoryProvider
  ├─▶ accountTypeRepositoryProvider
  ├─▶ accountRepositoryProvider
  ├─▶ transactionRepositoryProvider
  └─▶ userPreferencesRepositoryProvider
        │
        ├─▶ _themeModeStreamProvider ─▶ themeModeProvider ─▶ MaterialApp.themeMode
        │
        ├─▶ _userLocalePreferenceStreamProvider ─▶ userLocalePreferenceProvider
        │                                            └─▶ MaterialApp.locale
        │
        └─▶ splashGateSnapshotProvider (ChangeNotifier) ─▶ routerProvider
                                                            └─▶ MaterialApp.router

localeServiceProvider (default: const LocaleService())   # bootstrap step 3 + seed
```

**No cycles.** `routerProvider` does not watch any feature controller — slices wire their own `ref.watch(...)` inside their screens.

**Keep-alive policy.** Everything above is `keepAlive: true` because the `ProviderScope` lives as long as the app does.

---

## 4. Bootstrap sequence (implements PRD 225–236 verbatim)

### 4.1 The 8 steps

```dart
Future<void> bootstrap() async {
  // Step 1 — Framework binding.
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2 — Open AppDatabase.
  //   In production, `drift_flutter`'s `driftDatabase(name: 'ledgerly')`
  //   resolves a path via `path_provider` and opens with migrations.
  final db = AppDatabase(driftDatabase(name: 'ledgerly'));

  // Step 3 — LocaleService.
  //   The stub is `const`; no async init needed. Kept as a dedicated step
  //   so the PRD ordering is visible.
  const localeService = LocaleService();

  // Step 4 — intl locale data.
  //   `initializeDateFormatting(null)` primes the default locale.
  //   Explicit calls for the three MVP locales so DateFormat in any
  //   screen rendered on the first frame has its data loaded.
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('zh_TW');
  await initializeDateFormatting('zh_CN');

  // Step 5 — Eager preference read. Seeds the SplashGateSnapshot so the
  //   router's first redirect sees real values, not defaults. Also
  //   doubles as a DB-reachable probe; if the DB read throws, bootstrap
  //   fails loud before `runApp` (rather than after a blank frame).
  final preferencesRepo = DriftUserPreferencesRepository(db);
  final splashEnabled = await preferencesRepo.getSplashEnabled();
  final splashStartDate = await preferencesRepo.getSplashStartDate();

  // Step 6 — First-run seed (idempotent).
  await runFirstRunSeed(
    db: db,
    currencies: DriftCurrencyRepository(db),
    categories: DriftCategoryRepository(db),
    accountTypes: DriftAccountTypeRepository(db),
    accounts: DriftAccountRepository(db),
    preferences: preferencesRepo,
    localeService: localeService,
  );

  // Step 7 — ProviderScope with the DB override + pre-seeded splash gate.
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        splashGateSnapshotProvider.overrideWith((ref) {
          final notifier = SplashGateSnapshot.withInitial(
            enabled: splashEnabled,
            startDate: splashStartDate,
          );
          // ...subscription setup identical to the default factory,
          // calling _setEnabled/_setStartDate as streams emit.
          return notifier;
        }),
      ],
      child: const App(),
    ),
  );
}
```

### 4.2 Ordering rationale (for reviewers)

1. Binding before DB — Drift's `NativeDatabase` uses platform channels.
2. DB before seed — seed writes rows; needs a live executor.
3. LocaleService before seed — seed resolves `default_currency` from `LocaleService.deviceLocale`.
4. `initializeDateFormatting` before `runApp` — otherwise `DateFormat` throws on the first paint in non-English locales.
5. Eager preference read before `runApp` — avoids a frame flash to the wrong route.
6. Seed before `runApp` — the first frame must see a non-empty DB so `Stream<List<Transaction>>` subscribers don't briefly emit empty lists that screens render as empty states.
7. Override only `appDatabaseProvider` + `splashGateSnapshotProvider` — every other provider derives cleanly.

### 4.3 Testable variant

Bootstrap needs a testable split so the ordering unit test can assert each step without touching `path_provider`. Factor the body as:

```dart
Future<void> bootstrap() => bootstrapFor(
  openDatabase: () async => AppDatabase(driftDatabase(name: 'ledgerly')),
  localeService: const LocaleService(),
);

@visibleForTesting
Future<void> bootstrapFor({
  required Future<AppDatabase> Function() openDatabase,
  required LocaleService localeService,
  List<Override> extraOverrides = const [],
}) async { …8 steps… }
```

The unit test asserts that the `openDatabase` callback is awaited before any seed DAO write (via a spy `AppDatabase` that records call order). PRD risk #8: *"Locale resolution at the wrong time"*.

---

## 5. Router structure (implements PRD 630–653)

### 5.1 Route tree

```dart
routes: [
  GoRoute(
    path: '/',
    redirect: (_, __) => null,     // handled by top-level redirect
  ),
  GoRoute(
    path: '/splash',
    pageBuilder: (ctx, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const SplashScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  ),
  StatefulShellRoute.indexedStack(
    builder: (ctx, state, shell) => AdaptiveShell(shell: shell),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'add',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (ctx, state) => _modalPage(
                state,
                const TransactionFormScreen(),
              ),
            ),
            GoRoute(
              path: 'edit/:id',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (ctx, state) => _modalPage(
                state,
                TransactionFormScreen(
                  transactionId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ),
          ],
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/accounts',
          builder: (_, __) => const AccountsScreen(),
          routes: [
            GoRoute(path: 'new', builder: (_, __) => const AccountsScreen()),
            GoRoute(path: ':id',  builder: (_, __) => const AccountsScreen()),
          ],
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'categories',
              builder: (_, __) => const CategoriesScreen(),
            ),
          ],
        ),
      ]),
    ],
  ),
],
```

**Notes.**
- `/home/pending`, `/settings/wallets`, `/settings/ankr-key` are **Phase 2** per PRD 639/645/646. **Do not declare them in M4.** Adding dead routes now creates drift the Phase 2 PR would have to unpick. Guardrail: plan §9 risk #10.
- `_rootNavigatorKey` is the root `GlobalKey<NavigatorState>`; using it for the Add/Edit Transaction modal makes it render above the `AdaptiveShell` (full-screen), matching the keypad-has-full-vertical-space requirement in PRD 650.
- `_modalPage` adapts `MaterialPage` on Android / `CupertinoPage` on iOS — matches PRD 650.

### 5.2 Redirect state machine

```text
path == '/'               splash_enabled == true  → '/splash'
                          splash_enabled == false → '/home'

any other path            no redirect (including '/splash' when disabled,
                          which returns null here; the only way to reach
                          '/splash' with disabled=true is deep-link, and
                          the state is still a valid render)
```

The redirect does **not** branch on `splash_start_date`. The "date-missing → date prompt" step lives inside `SplashScreen` (PRD 541: *"yes + no date → Date Picker → save → Day Counter"*). Keeping it inside the widget avoids an extra route and keeps `redirect:` a one-liner.

### 5.3 Refresh listenable wiring

`splashGateSnapshotProvider` is a `ChangeNotifier`; go_router consumes it directly via `refreshListenable: gate`. When `setSplashEnabled(false)` fires elsewhere in the app, the stream emits, the notifier calls `notifyListeners()`, go_router re-evaluates the current location, and the redirect pushes `/home`. This is the path the "toggle splash in Settings" integration test exercises.

---

## 6. Tasks (bite-sized)

Each task lands alongside its tests from §7. Prefer `riverpod_generator` codegen; rerun `dart run build_runner build --delete-conflicting-outputs` after every provider change.

1. **T1 — Provider skeleton.** Add `lib/app/providers/*.dart` (app_database, repository, locale_service, theme, locale, splash_redirect). Every provider file < 40 lines. No router or widget dependencies. *Test:* `test/unit/providers/provider_graph_test.dart` instantiates a `ProviderContainer` with an in-memory DB override and calls each provider; nothing throws.
2. **T2 — Pure locale resolver.** Implement `resolveChineseLocale(...)` in `locale_provider.dart`. *Test:* `test/unit/utils/resolve_chinese_locale_test.dart` — 8 cases (zh_TW, zh_HK, zh_MO, zh_CN, zh_SG, zh alone, zh_Hant_HK, en_US non-Chinese passthrough).
3. **T3 — Splash gate notifier.** Implement `SplashGateSnapshot` + `splashGateSnapshotProvider`. Cover `_setEnabled`, `_setStartDate`, initial-value constructor. *Test:* `test/unit/providers/splash_gate_snapshot_test.dart` — feed it a fake `UserPreferencesRepository` with `StreamController`s; assert `notifyListeners` fires exactly once per change and zero times on duplicate values.
4. **T4 — Router provider.** Implement `routerProvider` with the full §5.1 tree. Use `_rootNavigatorKey` + `_modalPage` helpers. *Test:* `test/unit/app/router_test.dart` — build a `GoRouter` against an overridden `splashGateSnapshotProvider`; assert `router.routerDelegate.currentConfiguration.matches` for (a) `/` with enabled=true → redirects to `/splash`, (b) `/` with enabled=false → redirects to `/home`, (c) `/home/add` → top page is a modal with `parentNavigatorKey` = root.
5. **T5 — Feature placeholders.** Replace the three M5-bound screens (`splash`, `home`, `settings`) with the bare affordances from §2.11. Add one-line placeholders for `accounts`, `categories`, `transactions`. **No controllers.**
6. **T6 — Adaptive shell.** Implement `lib/app/widgets/adaptive_shell.dart`. *Test:* `test/widget/app/adaptive_shell_test.dart` pumps two `MediaQueryData(size: Size(400, 800))` / `Size(900, 800)` wrappers; asserts `find.byType(NavigationBar)` vs `find.byType(NavigationRail)`.
7. **T7 — App widget.** Replace `lib/app/app.dart` body with the `ConsumerWidget` from §2.8. Wire `onGenerateTitle`, `localeResolutionCallback`, `theme`, `darkTheme`, `themeMode`. *Test:* smoke test (T10).
8. **T8 — Bootstrap body.** Replace `lib/app/bootstrap.dart` body with §4.1; factor `bootstrapFor(...)` per §4.3. Keep `main.dart` untouched. *Test:* `test/unit/app/bootstrap_order_test.dart` — spy `AppDatabase` records call order; assert "open → intl init → preferences read → seed → runApp" sequence.
9. **T9 — Test template.** Add `test/support/test_app.dart` with `buildTestApp` + `newTestAppDatabase`. Re-export from the M5 slices via `export 'package:ledgerly_test/test_app.dart'` — if that's too much plumbing, inline-import is fine; the contract is "one function call, no copy-paste".
10. **T10 — Smoke test rewrite.** Rewrite `test/widget/smoke_test.dart` per §2.13. Keep the old `main boots without errors` assertion but swap the UI expectation to `AppLocalizations.of(ctx).appTitle`.
11. **T11 — Integration test.** `test/integration/bootstrap_to_home_test.dart` — two cases (see §7.5).
12. **T12 — Clean up TODOs.** Remove the `TODO(M4)` comments from `bootstrap.dart`, `app.dart`, `router.dart`. Leave `TODO(M5)` comments in feature placeholders intact.
13. **T13 — Native splash verify.** Manual: run `flutter run` on a fresh Android + iOS simulator; capture a short screen recording showing native splash → Flutter splash → Home. Upload to the PR description. No code change.
14. **T14 — `flutter analyze` + `dart run build_runner build --delete-conflicting-outputs`** are clean. `dart run import_lint` returns zero violations. Rebase once against `main` (M3 just merged).

---

## 7. Tests

Test files and their invariants.

### 7.1 `test/unit/providers/provider_graph_test.dart`

```dart
test('every keepAlive provider resolves with appDatabaseProvider overridden', () async {
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
  ]);
  container.read(currencyRepositoryProvider);
  container.read(categoryRepositoryProvider);
  container.read(accountTypeRepositoryProvider);
  container.read(accountRepositoryProvider);
  container.read(transactionRepositoryProvider);
  container.read(userPreferencesRepositoryProvider);
  container.read(localeServiceProvider);
});
```

Guards against a future provider accidentally watching `AppDatabase` in its factory in a way that leaks a DAO.

### 7.2 `test/unit/utils/resolve_chinese_locale_test.dart`

8 cases per §2.5.

### 7.3 `test/unit/providers/splash_gate_snapshot_test.dart`

Fake repo with two `StreamController<bool>` / `StreamController<DateTime?>`. Asserts notifier emissions.

### 7.4 `test/widget/app/adaptive_shell_test.dart`

Pump `AdaptiveShell(shell: _FakeShell(index: 0))` under two `MediaQuery`s. Assert widget types.

### 7.5 `test/integration/bootstrap_to_home_test.dart`

```dart
testWidgets('first run: splash_enabled=true, no date → splash → home', (tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  await runFirstRunSeed(db: db, …);   // via buildTestApp helper that allows explicit seed
  await tester.pumpWidget(buildTestApp(db: db));
  await tester.pumpAndSettle();

  // Splash route reached; date prompt visible.
  expect(find.byType(SplashScreen), findsOneWidget);
  expect(find.text('Set start date'), findsOneWidget);

  // User taps — placeholder writes DateTime.now(); UI rebuilds with Enter CTA.
  await tester.tap(find.text('Set start date'));
  await tester.pumpAndSettle();
  expect(find.text('Enter'), findsOneWidget);

  // Tap Enter → /home.
  await tester.tap(find.text('Enter'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.byType(SplashScreen), findsNothing);
});

testWidgets('subsequent run: splash_enabled=false → home directly (G10)', (tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  final prefs = DriftUserPreferencesRepository(db);
  await runFirstRunSeed(db: db, …);
  await prefs.setSplashEnabled(false);
  await tester.pumpWidget(buildTestApp(db: db));
  await tester.pumpAndSettle();

  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.byType(SplashScreen), findsNothing);
});
```

### 7.6 `test/widget/smoke_test.dart`

See §2.13. Replaces M0 body.

### 7.7 `test/unit/app/router_test.dart`

Redirect cases + modal page depth assertion.

### 7.8 `test/unit/app/bootstrap_order_test.dart`

Spy `AppDatabase` that logs `.transaction`, `.customStatement`, `.close` calls; assert the sequence. Keep this test under 80 lines.

### 7.9 Coverage floor

Layer-level test count:
- `test/unit/providers/` — 3 files (provider graph, splash gate, future expansions).
- `test/unit/app/` — 2 files (router, bootstrap order).
- `test/unit/utils/` — 1 file (resolve_chinese_locale).
- `test/widget/` — 2 files (smoke, adaptive shell).
- `test/integration/` — 1 file (bootstrap → home, 2 variants).

---

## 8. Risks and decisions

### 8.1 Covered by guardrails / tests

- **G9 violation (`await` in main).** `grep` guardrail + code review.
- **G10 violation (splash flashes when disabled).** §7.5 variant 2.
- **G11 violation (nested ListView in Column, adaptive not at shell).** §7.4 asserts shell-level breakpoint; M5 slices inherit the constraint.
- **Risk #6 (`resizeToAvoidBottomInset` default).** Deferred — transaction form is M5. M4 does not set `resizeToAvoidBottomInset` on any screen.
- **Risk #7 (router redirect leaks splash).** §5.2 keeps the gate at root redirect, not inside `SplashScreen`. §7.5 proves it.
- **Risk #8 (locale resolution at wrong time).** §4.1 steps 3 + 4 + 6 ordered explicitly; §7.8 asserts it.

### 8.2 Design decisions worth flagging

1. **Router redirect state is a `ChangeNotifier`, not a Riverpod listenable.** go_router's `refreshListenable` is `Listenable`-typed. A `ChangeNotifier` is the simplest adapter; wrapping it in a `ProviderSubscription` adds indirection for no gain.
2. **Eager preference read in bootstrap (step 5).** Doubles as a DB-reachability probe. A future "preferences schema corrupted" recovery path would bail here rather than in `App.build`, which keeps the recovery UX out of widget code.
3. **Three overrides only.** `appDatabaseProvider` in production, plus `splashGateSnapshotProvider` pre-seeded with eager-read values. Tests can add `localeServiceProvider` when they want to simulate a non-`en_US` device. Every other provider derives lazily — changing a repository constructor signature does not touch this plan.
4. **Repository providers are `keepAlive: true`.** Downstream Drift streams are long-lived; auto-disposing the repository on route transitions would tear down subscriptions unnecessarily.
5. **No Phase 2 routes declared.** `/home/pending`, `/settings/wallets`, `/settings/ankr-key` land in Phase 2 PRs. Adding them now creates dead code and drift — the "resist Phase 2 shapes" risk (`implementation-plan.md` §9 #10).
6. **No `domain/` folder.** MVP has no use cases; `domain/` is Phase 2 only. M4 does not create it.
7. **Splash first-launch date prompt lives inside `SplashScreen`, not as a separate route.** PRD 535–544 describes it as a **stage** of the splash, not a distinct destination. Keeping it intra-widget aligns with M5's owner splitting the placeholder into a full screen.

### 8.3 Deliberately NOT done in M4

- No `core/utils/*` additions. Pagination primitives, error-state widgets, and snackbar helpers belong to M5.
- No `flutter_native_splash` asset regeneration (M6).
- No accessibility audit (M6).
- No golden tests (splash goldens are M5's Splash slice; there is no visual surface here worth snapshotting).
- No Settings toggle UI beyond the single `SwitchListTile` — M5 Settings replaces the placeholder wholesale.

---

## 9. Open questions (none blocking — defer if raised)

1. **Should `AdaptiveShell` use `NavigationBar` (M3) or `BottomNavigationBar`?** PRD 765 says `BottomNavigationBar`. Material 3 guidance prefers `NavigationBar`. Default to `NavigationBar` to match `useMaterial3: true` in `app_theme.dart`; flag for review if the design mocks in Figma explicitly call out Material 2 chrome.
2. **Should the integration test also cover the theme-toggle path?** Arguably a separate widget test; §7 does not require it for exit criteria, but the M5 Settings slice should own it when it replaces the placeholder.
3. **Does `splashGateSnapshotProvider` need debouncing?** `user_preferences.value` writes are coarse-grained (user tapping a toggle), so no. Flag if a Phase 2 automated writer (recurring rule scheduler) emits burst updates.

---

## 10. Exit checklist (copy into the PR body)

- [ ] `flutter run` on a clean Android + iOS simulator reaches Home via the first-run flow (T13 recording attached).
- [ ] With `splash_enabled=false` persisted, cold launch lands on Home; `SplashScreen` never builds (verified by §7.5 variant 2).
- [ ] Theme toggle rebuilds `MaterialApp` (verified by a widget test added in T7 or deferred to M5 per §9 Q2).
- [ ] `resolveChineseLocale` covers all 8 §7.2 cases.
- [ ] `test/unit/app/bootstrap_order_test.dart` asserts the PRD step order.
- [ ] `test/widget/smoke_test.dart` uses `buildTestApp`; passes.
- [ ] `test/integration/bootstrap_to_home_test.dart` (2 variants) passes.
- [ ] `flutter analyze` + `dart run import_lint` clean.
- [ ] `dart run build_runner build --delete-conflicting-outputs` exits 0.
- [ ] `main.dart` `grep -E '^\s*await' → await bootstrap();` only (G9).
- [ ] No Phase 2 routes / providers / folders introduced.
- [ ] All `TODO(M4)` comments removed.

---

*When this plan conflicts with `PRD.md`, `PRD.md` wins. When this plan conflicts with `docs/plans/implementation-plan.md`, the implementation plan wins. When both are silent, raise the question in the PR description rather than deciding unilaterally — the platform-ownership table in `implementation-plan.md` §8 names the right reviewer.*
