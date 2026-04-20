// TODO(M3): `TransactionRepository` — SSOT for transactions.
//
// Public surface:
//   - `Stream<List<Transaction>> watchAll()` (backed by Drift `.watch()`)
//   - typed command methods: `save`, `delete`, `duplicate`
//
// Business rules enforced here (not in controllers):
//   - Integer minor-unit arithmetic for every amount.
//   - Currency FK integrity — transactions must reference a known currency.
//   - Drift -> Freezed mapping. Drift types never escape this file.
