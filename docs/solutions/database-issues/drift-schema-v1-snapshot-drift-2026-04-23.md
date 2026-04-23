---
title: Drift v1 snapshot history repair
date: 2026-04-23
category: database-issues
module: data layer
problem_type: database_issue
component: database
symptoms:
  - `drift_schema_v1.json` described `currencies.custom_name` even though real schema v1 never had that column
  - Migration tests could not prove a real v1 database upgraded cleanly to the live schema
  - The generated v1 migration harness helpers reflected the wrong historical shape
  - Existing databases had no explicit, trustworthy `v1 -> v2` path for `currencies.custom_name`
root_cause: missing_workflow_step
resolution_type: migration
severity: high
tags: [drift, schema-history, migrations, snapshot-integrity, schema-versioning]
---

# Drift v1 snapshot history repair

## Problem

The historical Drift snapshot chain had been corrupted. `drift_schemas/drift_schema_v1.json` was rewritten in place to include `currencies.custom_name`, so the repo no longer had an honest record of what a real schema-v1 database looked like. That broke the migration contract for existing databases because the checked-in v1 snapshot no longer matched any real on-disk v1 database.

## Symptoms

- `drift_schema_v1.json` and the generated migration helpers treated `currencies.custom_name` as part of v1 even though the live app had no real `v1 -> v2` upgrade step for it.
- Snapshot-based migration tests could not prove that a real v1 database upgraded cleanly while preserving rows.
- The repo had no append-only snapshot trail showing that `custom_name` belonged to schema v2 instead of v1.

## What Didn't Work

- Treating the rewritten v1 snapshot as the new truth only hid the regression by redefining history instead of preserving it.
- Bumping `schemaVersion` alone would not fix the contract; existing v1 databases still needed an explicit upgrade path for `currencies.custom_name`.
- Regenerating the migration harness before restoring the true v1 snapshot produced a bad `schema_v1.dart` helper and duplicate-column failures in the new migration tests.

## Solution

Restore history first, then layer the new schema on top of it:

- Restore `drift_schemas/drift_schema_v1.json` to the real v1 shape.
- Add `drift_schemas/drift_schema_v2.json` for the nullable `currencies.custom_name` column.
- Change `lib/data/database/app_database.dart` to `schemaVersion => 2` and add a real `v1 -> v2` migration.
- Regenerate `test/unit/repositories/_harness/generated/schema.dart`, `schema_v1.dart`, and `schema_v2.dart` from the repaired snapshot chain.
- Expand `test/unit/repositories/migration_test.dart` so it exercises real v1 upgrades, seeded DB validation, `foreign_keys` restoration, and v1-shaped inserts.

This migration is intentionally small and safe: `currencies.custom_name` is a nullable column, so upgrading from v1 to v2 requires no backfill, no data rewrite, and no table rebuild. A straight `addColumn(...)` is sufficient.

`lib/data/database/app_database.dart` now makes the upgrade explicit:

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(currencies, currencies.customName);
    }
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

Verification for the repaired migration contract passed with:

```bash
flutter analyze
flutter test
```

## Why This Works

Drift snapshots are append-only migration evidence. Restoring the real v1 snapshot and moving `custom_name` into a genuine schema-v2 migration reestablishes the rule that old snapshots describe old databases and `onUpgrade` describes how to reach the current one. Because `custom_name` is nullable, the upgrade is additive: existing v1 rows stay valid and SQLite can apply the change without rewriting stored currency data. Once that history was honest again, the migration harness could validate a real v1 upgrade path instead of validating a rewritten fiction.

## Prevention

- Never rewrite an existing Drift snapshot in place. Add a new schema version, a new snapshot file, and an explicit `onUpgrade` step instead.
- After any schema-history repair, regenerate both live Drift output and migration harness helpers from the repaired snapshot chain before trusting migration tests.
- For additive nullable columns like `currencies.custom_name`, prefer a real version bump plus `addColumn(...)` over rewriting older snapshots or rebuilding tables unnecessarily.
- Keep one migration test that opens a real historical snapshot, upgrades it, and checks both schema shape and row preservation.
- Run `flutter analyze` and `flutter test` after schema or migration changes.

## Related Issues

- `docs/plans/m3-repositories-seed/stream-c-preferences-seed-migration.md`
- `docs/solutions/database-issues/flat-category-schema-contract-2026-04-22.md`
- `test/unit/repositories/migration_test.dart`
