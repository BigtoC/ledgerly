# Layers (3-Layer Architecture)

> Authoritative source: [`PRD.md` → *Architecture*](../../PRD.md#architecture).

Ledgerly uses the Flutter team's layered architecture with three layers: **UI** (`lib/ui/`), **domain** (`lib/domain/`) and **data** (`lib/data/`). Two folders sit beside them: `lib/app/` wires the layers together, and `lib/core/` holds helpers any layer may import.

Import-level layer boundaries are enforced by `test/unit/architecture/layer_boundaries_test.dart` (see [`dependencies.md`](./dependencies.md#layer-boundary-check)), which also checks that every `lib/` file except `main.dart`, `app/providers/service_providers.dart` and the generated `l10n/` matches at least one rule, and every `lib/ui/` file exactly one. UI files are covered by folder and suffix: `view_models/*_controller.dart` and `view_models/*_providers.dart` follow the controller rule, the theme follows `theme_stays_pure`, and every other `lib/ui/` file follows the deny-by-default widget rule. That includes views, `*_state.dart` and pure helpers such as `selected_slice.dart` and `amount_formula.dart`, so a new UI file is covered without editing the rules. `lib/core/` follows `core_stays_pure`. `lib/app/` is covered only by `app_forbids_platform_plugins`, which keeps `package_info_plus`, `path_provider`, `file_picker` and `file_selector` out of every `lib/app/` file except `lib/app/providers/service_providers.dart`. `lib/main.dart`, `lib/app/providers/service_providers.dart` and the generated `lib/l10n/` are not covered, and the rules below that are not about imports still rely on review.

## Folder layout

```
lib/
├── main.dart
├── app/            # bootstrap.dart, router.dart, app.dart, providers/
├── core/           # non-widget helpers: formatters, icon/colour registries, CSV codecs, constants, date helpers, system_browser.dart
├── data/
│   ├── database/   # Drift tables, DAOs, AppDatabase
│   ├── repositories/
│   ├── seed/
│   └── services/   # return Dart records / SDK types; no data/models/
├── domain/
│   ├── models/     # Freezed models
│   └── use_cases/
├── ui/
│   ├── core/       # theme/, widgets/ (adaptive_shell.dart, adaptive_sheet.dart, confirm_dialog.dart, undo_snack_bar.dart)
│   └── features/<feature>/{view_models,views}/
└── l10n/           # generated
```

- **`view_models/`** holds `*_controller.dart`, `*_state.dart`, `*_providers.dart` and pure helpers (for example `amount_formula.dart`, `keypad_state.dart`, `selected_slice.dart`, `csv_import_matcher.dart`).
- **`views/`** is flat, with no `widgets/` subfolder: routed `*_screen.dart` files and every other widget or label helper of the slice (for example `charts_section.dart`, `shopping_list_item_labels.dart`).
- **Sub-slices** stay under their parent with their own folders: `ui/features/analysis/charts/`, `ui/features/analysis/search/`, `ui/features/settings/csv_import/` and `ui/features/settings/csv_export/`, each with `view_models/` and `views/`. `ui/features/analysis/` itself has only `views/analysis_screen.dart`.
- **Display helpers stay with their slice.** `category_display.dart` lives in `ui/features/categories/views/`, and `account_type_display.dart` and `currency_display.dart` in `ui/features/accounts/views/`. They are l10n string functions, not shared widgets, so they do not belong in `ui/core/`.
- **`lib/core/` holds no widgets.** Only the theme and the adaptive shell live in `ui/core/`.

## Non-Negotiables

- **SSOT on repositories.** Only `data/repositories/*` write to Drift or `flutter_secure_storage`. Controllers and widgets never construct Drift `Insertable` rows, never call DAO `.insert()`, never touch secure storage. Layer-boundary rules are declared in `import_analysis_options.yaml` at the repo root and checked by `test/unit/architecture/layer_boundaries_test.dart`.
- **Drift stays inside repositories.** Repositories map Drift data classes into Freezed domain models in `domain/models/` and return those. Controllers and widgets must never see a Drift row type — that is the seam that protects the UI from schema churn.
- **Controllers expose state + commands, not data access.** Each `view_models/*_controller.dart` owns an immutable Freezed state (sealed when it has more than one shape) and typed command methods. A controller read through `AsyncValue` gets loading and error from it, so it doesn't repeat them as variants; `HomeState` keeps PRD's `loading | empty | data | error` shape. Widgets read state and call commands; no data transformation in `build()`.
- **Reactive by default.** Repositories return `Stream<T>` backed by Drift `.watch()`; controllers consume via Riverpod `StreamNotifier` / `AsyncNotifier`. Avoid manual refresh patterns.
- **Error propagation is typed.** Services throw typed exceptions, repositories re-throw or wrap, use cases translate to domain failures. Controllers expose reads as `AsyncValue`, return a Freezed sealed outcome (declared in the slice's `*_state.dart`) from each command that can fail in a way the user must see, and keep effect listeners for failures that arrive after a command has returned ([`PRD.md` → *Error Handling Pattern*](../../PRD.md#error-handling-pattern)). No `try/catch` in widgets: they `switch` on outcomes. No unhandled `Future`: a widget awaits a command and handles its outcome, or uses `unawaited(...)` only on a command that cannot throw, and checks `mounted` after every `await`.

## Where things live

- **App-layer construction** lives in providers: `lib/app/providers/repository_providers.dart` builds the concrete `Drift*Repository` implementations, `AppUpdateRepository` and the use cases, and `lib/app/providers/service_providers.dart` builds the services (`dio`, `exchangeRateService`, `csvFileService`, `packageInfoService`). Under `lib/ui/`, only `view_models/*_controller.dart` and `view_models/*_providers.dart` may import `repository_providers.dart`, and no file may import `service_providers.dart` or `app_database_provider.dart`, so a widget cannot reach a repository, nor a controller a service or `AppDatabase`, through those files. App-level values that widgets read get their own file instead: `exchange_rates_provider.dart` (`exchangeRatesProvider`) and `app_version_provider.dart` (`appVersionProvider`). `appDatabaseProvider` is intentionally a required override from `bootstrap()` or `test/support/test_app.dart` — see [`bootstrap.md`](./bootstrap.md).
- **External I/O** follows the same boundary: services own the calls and repositories own what is done with the results. `lib/data/services/exchange_rate_service.dart` owns the FX Dio calls and `lib/data/repositories/exchange_rate_repository.dart` owns `exchange_rates` persistence/refresh. For app updates, `lib/data/services/app_release_service.dart` owns the Dio calls (GitHub latest-release lookup and APK download) and the `<cache>/updates/` directory the APKs land in, and `lib/data/services/apk_installer_service.dart` owns the `ledgerly/apk_installer` platform channel to Android's `PackageInstaller`; `lib/data/repositories/app_update_repository.dart` orchestrates them (update lookup, SHA-256 verification of the download, install, clean-up). Platform plugins are wrapped too: `lib/data/services/package_info_service.dart` wraps `package_info_plus` and `lib/core/utils/system_browser.dart` wraps `url_launcher`, no `lib/ui/` file outside the theme may import `package_info_plus`, `dio`, `file_picker`, `file_selector`, `path_provider` or `url_launcher`, and `lib/app/` files other than `service_providers.dart` may not import `package_info_plus`, `path_provider`, `file_picker` or `file_selector`. Widgets/controllers consume `exchangeRatesProvider`, `appVersionProvider`, `availableAppUpdateProvider`, `appUpdateControllerProvider` or repository commands instead of instantiating HTTP clients or calling services.
- **Feature slices co-locate read-only helper providers** for view models and hydration seeds in every `lib/ui/features/**/view_models/*_providers.dart` (e.g. `lib/ui/features/home/view_models/home_providers.dart`, `lib/ui/features/accounts/view_models/accounts_providers.dart`). Like controllers, they may read repositories, domain models and `app/providers/` (except `service_providers.dart`), never `AppDatabase`/DAOs, services or Drift. Prefer slice-local providers over reaching into DB internals from widgets: when a widget needs a one-off repository call, expose it from the slice's `*_providers.dart`, as `txAccountLookupProvider` in `lib/ui/features/transactions/view_models/transactions_providers.dart` does for the account picker.
- **`core/` may use domain models, and nothing else from the layers.** It may import Flutter/SDK packages and the plain models in `domain/models/` (for example `lib/core/utils/money_formatter.dart` takes `Currency` for its `decimals`), but never anything under `data/`, use cases, `ui/` (the theme included) or `app/`. The theme in `lib/ui/core/theme/` gets the same bans from its own rule, `theme_stays_pure`, which lets it import its own files ([`PRD.md` → *Layer Boundaries*](../../PRD.md#layer-boundaries-forbidden-imports)).
- **Use cases live in `lib/domain/use_cases/`**: `recurring_generation_use_case.dart` (the recurring-rules generation engine), `csv_import_use_case.dart` (Fortune City CSV import) and `csv_export_use_case.dart` (date-range CSV export). Add one only when the work coordinates several repositories. A use case may import `data/database/app_database.dart`, and nothing else under `data/database/`, to take `AppDatabase` and run one atomic `db.transaction` across repositories; it never touches a DAO, a table or Drift. `csv_export_use_case.dart` needs no `AppDatabase` and runs no transaction. A future wallet-sync use case would be `lib/domain/use_cases/wallet_sync_use_case.dart`. Repositories may not import use cases.

## Chart slice — concrete example of the seam

The drill-down on the Analysis tab is the clearest example of how UI-layer state is kept out of the data layer:

- Selection identity lives in `lib/ui/features/analysis/charts/view_models/selected_slice.dart` (`SelectedSlice.category | account | currency`), held by `lib/ui/features/analysis/charts/view_models/charts_selection_controller.dart`.
- `lib/ui/features/analysis/charts/view_models/charts_controller.dart` translates the active selection into plain `{categoryId, accountId, currencyCode}` filters before calling the repository — the data layer never sees `SelectedSlice`.
- `lib/ui/features/analysis/charts/view_models/slice_drilldown_controller.dart` owns the selected-slice row stream plus the delete/undo lifecycle.
