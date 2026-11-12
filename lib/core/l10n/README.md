# `lib/core/l10n/`

l10n *utilities*. Source ARB files live in `/l10n/` at the repo root;
gen-l10n writes the Dart classes to `lib/l10n/`, imported as
`package:ledgerly/l10n/app_localizations.dart`.

- `app_localizations_delegates.dart` — `appLocalizationsDelegates`, the
  `localizationsDelegates` for every `MaterialApp` (see
  `docs/architecture/dependencies.md` → *Material and Cupertino packages*).
