# `drift_schemas/`

Committed snapshots of every `AppDatabase` schema version, generated via
`drift_dev schema dump`. Each snapshot backs migration tests that exercise
`MigrationStrategy.onUpgrade` on both an empty database and a seeded one
(see PRD -> Migration Strategy and Testing Strategy -> Repository Tests).

## Generating a snapshot

```bash
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
```

Run this after every `schemaVersion` bump. The file name convention is
`drift_schema_v<N>.json`.

## Rules

- **Never rewrite an existing snapshot in place.** Breaking schema changes
  require a new `schemaVersion` plus a documented data-transform step.
- `drift_schema_v1.json` lands in M1 once the MVP tables compile.
- Phase 2 (`pending_transactions`, `wallet_addresses`, `exchange_rates`, +
  seeded token rows) bumps to `schemaVersion = 2` and adds a second
  snapshot here.
