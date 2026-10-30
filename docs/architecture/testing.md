# Testing

> Authoritative source: [`PRD.md` → *Testing Strategy*](../../PRD.md#testing-strategy).

Tests are organized **by architectural layer, not by feature**.

```
test/
├── unit/{app,controllers,l10n,providers,repositories,seed,services,use_cases,utils}/
├── widget/{app,features,smoke,theme}/
└── integration/
```

## Patterns

- **Repository tests** use Drift's **in-memory database**; assert rules like category type locking, archive-instead-of-delete, FK integrity, and reactive stream emissions.
- **Controller tests** use Riverpod `ProviderContainer` overrides with `mocktail`.
- **Splash screen** has **golden tests** because its visual design is a product requirement. Widget coverage lives in `test/widget/features/splash/splash_screen_test.dart`; route-level redirect coverage lives in `test/unit/app/router_test.dart`; controller/template coverage for the inline-date behavior lives in `test/unit/controllers/splash_controller_test.dart` and `test/unit/utils/splash_template_substitution_test.dart`.
- **Migration tests** run `onUpgrade` against every committed snapshot in `drift_schemas/` on both empty and seeded DBs. The live tests are in `test/unit/repositories/migration_test.dart` and validate the v1–v7 generated schema helpers (`test/unit/repositories/_harness/generated/schema_v{1..7}.dart`), seeded and empty DB opens, and `PRAGMA foreign_keys` after upgrade. **Never rewrite a merged migration in place** — add a new schema version instead.
- **Drift-backed setup and direct repository writes that happen before the first `pump`** must run inside `tester.runAsync(...)`; see `test/widget/smoke_test.dart` and `test/integration/bootstrap_to_home_test.dart`.
- **Riverpod 3 specifics.** Retry is disabled app-wide via `noProviderRetry` (`lib/app/bootstrap.dart`); `makeTestContainer` / `buildBootstrappedTestApp` pass it too, so prefer them when a test asserts on an error state. A stream or notifier provider with no listener is paused, so in unit tests add `container.listen(provider, (_, __) {})` before awaiting `container.read(provider.future)`.
- **Scoped providers need `@Dependencies` in tests too.** `riverpod_lint`'s `provider_dependencies` rule (enforced in CI by `dart analyze --fatal-infos`) does not see `ProviderContainer` / `UncontrolledProviderScope` overrides. So a test `main()` or helper that reads a scoped provider, or pumps a widget annotated with `@Dependencies`, must declare those providers with `@Dependencies([...])` from `package:riverpod_annotation/experimental/scope.dart`. The annotation is lint metadata only. Copy the names from the lint's "Missing dependencies" message, without the duplicates it repeats.
- **Ankr API calls are mocked in every test**; no live network calls in the suite. For exchange rates, stub `ExchangeRateService` or override `exchangeRatesProvider` / `exchangeRateRepositoryProvider`.

## Canonical harness

`test/support/test_app.dart` is the canonical app-shell harness: `newTestAppDatabase()`, `runTestSeed(db)`, `makeTestContainer(...)`, `buildTestApp(...)`, `buildBootstrappedTestApp(...)` cover the standard in-memory DB + ProviderScope setup patterns.

## Where slice coverage lives

- **Conversion** — `test/unit/services/exchange_rate_service_test.dart`, `test/widget/features/home/summary_strip_conversion_test.dart`, `test/widget/features/home/transaction_tile_conversion_test.dart`, `test/widget/features/accounts/account_tile_conversion_test.dart`, `test/integration/currency_conversion_flow_test.dart`.
- **Charts** — `test/widget/features/analysis/charts_section_test.dart`, `test/widget/features/analysis/chart_slice_selection_interaction_test.dart`, `test/widget/features/analysis/chart_slice_stale_selfheal_test.dart`, `test/widget/features/analysis/chart_legend_view_all_pop_test.dart`, `test/integration/chart_display_flow_test.dart`, `test/integration/analysis_drilldown_test.dart`, `test/widget/features/analysis/selected_slice_items_list_test.dart` (drill-down row cap), `test/widget/features/analysis/widgets/daily_bar_chart_test.dart`. Controller/data coverage for the drill-down path lives in `test/unit/controllers/charts_selection_controller_slice_test.dart`, `test/unit/controllers/charts_controller_slice_test.dart`, `test/unit/controllers/slice_drilldown_controller_test.dart`, `test/unit/controllers/slice_drilldown_data_test.dart`. Override `chartsFxStatusProvider`, `chartsCurrenciesByCodeProvider`, and the analysis lookup providers (`analysisCategoriesByIdProvider`, `analysisAccountsByIdProvider`) when a chart test only needs the projection layer.
- **App update** — `test/unit/services/app_release_service_test.dart` (asset `digest` / `size` parsing and `download`), `test/unit/services/apk_installer_service_test.dart` (the `ledgerly/apk_installer` channel), `test/unit/repositories/app_update_repository_test.dart` (download, SHA-256 verify, reuse of a verified file, install outcomes, clean-up), `test/unit/providers/available_app_update_provider_test.dart`, `test/unit/controllers/app_update_controller_test.dart`, `test/unit/app/android_in_app_update_manifest_test.dart` (permissions, receiver and channel name), `test/widget/features/settings/new_version_badge_test.dart` (NVB01–NVB06 browser fallback and accessibility, NVB07–NVB13 in-app flow), `test/widget/features/settings/settings_screen_test.dart`, `test/widget/app/app_update_check_test.dart`. The Kotlin `PackageInstaller` side has no test harness; it is verified by hand on a device.
- **CSV import** — `test/unit/utils/decimal_rounding_test.dart`, `test/unit/utils/fortune_city_csv_parser_test.dart`, `test/unit/utils/csv_import_matcher_test.dart` (the matcher lives in `lib/features/settings/csv_import/` but its tests sit with the other pure-logic tests), `test/unit/services/csv_file_service_test.dart`, `test/unit/use_cases/csv_import_use_case_test.dart`, `test/unit/controllers/csv_import_controller_test.dart`, `test/widget/features/settings/csv_import_screen_test.dart`, `test/integration/csv_import_flow_test.dart`. The import write path (`insertImported`, `getImportSignatures`) is covered in `test/unit/repositories/transaction_repository_test.dart`. Fixtures are `test/data/import_fortune_city_data.csv` (the 105-row sample) and `test/data/import_fortune_city_unterminated_quote.csv`.

## Schema-version handoff

When adding schema v8: dump a new `drift_schema_v8.json` snapshot into `drift_schemas/`, regenerate the helpers with `dart run drift_dev schema generate drift_schemas/ test/unit/repositories/_harness/generated/`, and extend `test/unit/repositories/migration_test.dart`. The v4 upgrade adds `recurring_rules`, `pending_transactions`, and the partial UNIQUE index `idx_pending_recurring_unique_partial` (declared imperatively because Drift cannot express the partial WHERE clause); the v5 upgrade adds `exchange_rates` plus the unique pair index `idx_exchange_rates_pair`; the v6 upgrade adds the nullable `transactions.amount_formula` column, so existing rows read back with no formula; the v7 upgrade is data-only: it inserts the seeded `category.investment` row unless one already exists, and deletes `category.personal` when nothing references it, otherwise archives it.
