# Bootstrap & First-Run

> Authoritative source: [`PRD.md` → *Bootstrap Sequence*](../../PRD.md#bootstrap-sequence).

`lib/main.dart` awaits `bootstrap()`. `lib/app/bootstrap.dart` runs the ordered async init **before** `runApp`:

1. **Open DB** (Drift)
2. **Initialize locale** (`intl` date data)
3. **Read prefs** (theme, locale, splash preferences — eagerly)
4. **Seed if empty** — first-run seed (currencies, default categories, one `Cash` account, `default_currency` from device locale) runs only when the DB is empty
5. **Build `ProviderScope`** with `appDatabaseProvider` overridden (the provider is injected via override rather than constructed inside the provider)
6. `runApp`

After the first frame, `App` schedules `RecurringGenerationUseCase.execute()` from the first-frame callback; failures are swallowed so startup is not blocked. `lib/app/app.dart` also eagerly reads `exchangeRateRepositoryProvider` so DAO / default-currency listeners start on first build. The same first-frame callback then calls `availableAppUpdateProvider.notifier.checkAfter(exchangeRateRepository.startupRefresh)`: once the startup FX refresh settles it makes one GitHub `releases/latest` GET per launch, only on Android ABIs, without blocking the frame, and logs only the exception type on failure. After a successful check, `checkAfter` deletes stale files under `<cacheDir>/updates/`, keeping only the found release's verified APK; a failed check deletes nothing, because it cannot tell which downloaded APK is still current. The download and install happen only on a badge tap (`AppUpdateController`): dio downloads the APK in the foreground, `AppUpdateRepository` checks it against the release asset's SHA-256 `digest`, and the `ledgerly/apk_installer` MethodChannel copies it into a `PackageInstaller` session on a background thread and commits it (prompt-free on Android 12+, otherwise the system confirm dialog). A release without a digest, and every failure, falls back to opening the APK URL in the system browser.

## Splash redirect

Root route uses a `go_router` `redirect:` that reads `splash_enabled` from `user_preferences` — there is no splash route visited when it is disabled. `SplashGateSnapshot` in `lib/app/providers/splash_redirect_provider.dart` bridges the preference stream into the synchronous `redirect:`, so splash-disabled launches redirect straight to `/home` without constructing `SplashScreen`.

## Splash display text

The default template is `'On {date} start using Ledgerly'`. `lib/features/splash/splash_controller.dart` enforces the "date is always shown" rule by prepending `'{date} '` to any non-empty custom template that lacks it. `lib/core/utils/date_helpers.dart` returns `List<SplashTextSegment>` from `applySplashTemplateSegments()` so `lib/features/splash/splash_screen.dart` can render the `{date}` span with `SplashRainbowGradientText` **inline** instead of using a separate date widget.

## Route table

Routes are wired in `lib/app/router.dart`:

`/splash`, `/splash/preview`, `/home`, `/home/add`, `/home/edit/:id`, `/home/shopping-list`, `/home/shopping-list/:itemId`, `/analysis`, `/analysis/search/:categoryId`, `/settings`, `/settings/about`, `/settings/categories`, `/settings/recurring`, `/settings/recurring/new`, `/settings/recurring/:id`, `/settings/import`, `/settings/export`, `/settings/manage-accounts/new`, `/settings/manage-accounts/:id`.

Tapping the version label at the bottom of `settings_screen.dart` opens `lib/features/settings/about_screen.dart` at `/settings/about`.
