// TODO(M3): `AccountRepository` — SSOT for accounts.
//
// Business rules enforced here:
//   - Archive-instead-of-delete for accounts referenced by any transaction
//     (guardrail G6).
//   - New accounts default to `user_preferences.default_currency`, but the
//     creator may override on insert.
//   - Integer minor-unit arithmetic on `opening_balance_minor_units`.
