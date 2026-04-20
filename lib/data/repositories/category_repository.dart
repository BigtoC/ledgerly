// TODO(M3): `CategoryRepository` — SSOT for categories.
//
// Business rules enforced here:
//   - Category `type` is immutable after the first transaction references
//     it (guardrail G5). `update()` rejects type changes with a typed
//     exception once referenced.
//   - Archive-instead-of-delete when referenced (guardrail G6).
//   - Rename writes `custom_name` only; `l10n_key` is never modified so
//     locale switches do not duplicate or orphan rows (guardrail G7).
