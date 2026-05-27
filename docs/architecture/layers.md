# Layers (3-Layer Architecture)

> Authoritative source: [`PRD.md` → *Architecture*](../../PRD.md#architecture).

Ledgerly uses a strict **3-layer architecture** (Data → UI), with a `domain/` use-case layer added only in Phase 2. Reviewer discipline matters more than the linter here — see [`dependencies.md`](./dependencies.md) for why `import_lint` enforcement is best-effort.

## Non-Negotiables

- **SSOT on repositories.** Only `data/repositories/*` write to Drift or `flutter_secure_storage`. Controllers and widgets never construct Drift `Insertable` rows, never call DAO `.insert()`, never touch secure storage. Layer-boundary rules are declared in `import_analysis_options.yaml` at the repo root (the pinned `import_lint ^0.1.6` only reads from that filename, not from `analysis_options.yaml`).
- **Drift stays inside repositories.** Repositories map Drift data classes into Freezed domain models in `data/models/` and return those. Controllers and widgets must never see a Drift row type — that is the seam that protects the UI from schema churn.
- **Controllers expose state + commands, not data access.** Each `*_controller.dart` owns an immutable Freezed sealed state (`loading | empty | data(...) | error`) and typed command methods. Widgets read state and call commands; no data transformation in `build()`.
- **Reactive by default.** Repositories return `Stream<T>` backed by Drift `.watch()`; controllers consume via Riverpod `StreamNotifier` / `AsyncNotifier`. Avoid manual refresh patterns.
- **Error propagation is typed.** Services throw typed exceptions, repositories re-throw or wrap, use cases translate to domain failures, controllers expose `AsyncValue`. No `try/catch` in widgets. No unhandled `Future`.

## Where things live

- **App-layer construction** lives in providers: `lib/app/providers/repository_providers.dart` builds the concrete `Drift*Repository` implementations. `appDatabaseProvider` is intentionally a required override from `bootstrap()` or `test/support/test_app.dart` — see [`bootstrap.md`](./bootstrap.md).
- **External I/O** follows the same boundary: `lib/data/services/exchange_rate_service.dart` owns Dio calls; `lib/data/repositories/exchange_rate_repository.dart` owns `exchange_rates` persistence/refresh. Widgets/controllers consume `exchangeRatesProvider` or repository commands instead of instantiating HTTP clients.
- **Feature slices co-locate read-only helper providers** for view models and hydration seeds — see `lib/features/home/home_providers.dart`, `lib/features/accounts/accounts_providers.dart`, `lib/features/settings/settings_providers.dart`, `lib/features/transactions/transactions_providers.dart`, `lib/features/analysis/search/analysis_providers.dart`, `lib/features/analysis/charts/charts_providers.dart`. Prefer slice-local providers over reaching into DB internals from widgets.
- **`domain/` exists only in Phase 2.** MVP is primarily `app/`, `core/`, `data/`, `features/`. The one MVP exception is `lib/data/use_cases/recurring_generation_use_case.dart` — the recurring-rules generation engine — and it lives in `data/` because it orchestrates a single repository pair rather than crossing layered boundaries.

## Chart slice — concrete example of the seam

The drill-down on the Analysis tab is the clearest example of how UI-layer state is kept out of the data layer:

- Selection identity lives in `lib/features/analysis/charts/selected_slice.dart` (`SelectedSlice.category | account | currency`), held by `lib/features/analysis/charts/charts_selection_controller.dart`.
- `lib/features/analysis/charts/charts_controller.dart` translates the active selection into plain `{categoryId, accountId, currencyCode}` filters before calling the repository — the data layer never sees `SelectedSlice`.
- `lib/features/analysis/charts/slice_drilldown_controller.dart` owns the selected-slice row stream plus the delete/undo lifecycle.
