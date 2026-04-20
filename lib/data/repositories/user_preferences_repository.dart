// TODO(M3): `UserPreferencesRepository` — SSOT for the `user_preferences`
// key/value table. Typed getters and setters for theme, locale, default
// account, default currency, first-run state, and splash settings.
//
// Also owns the first-run seed routine invoked from bootstrap when the DB
// is empty (currencies, default categories, one Cash account,
// `default_currency` resolved via LocaleService).
