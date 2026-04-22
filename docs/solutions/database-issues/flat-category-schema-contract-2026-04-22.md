---
title: Flat category schema contract for M1
date: 2026-04-22
category: database-issues
module: categories data model
problem_type: database_issue
component: database
symptoms:
  - M1 docs and product decisions removed subcategories, but the schema and model still exposed `parent_id` and `parentId`
  - Generated Drift and Freezed output still included hierarchy fields and index metadata
  - Normal `flutter test` verification was blocked by an `objective_c` native-asset hook failure in this environment
root_cause: logic_error
resolution_type: code_fix
severity: medium
tags: [drift, freezed, categories, schema, flat-model]
---

# Flat category schema contract for M1

## Problem

The category contract had diverged from the updated product decision. Documentation had already moved to a flat category model, but the M1 Drift table, DAO, Freezed model, and generated artifacts still described category hierarchy through `parent_id` / `parentId`.

## Symptoms

- `lib/data/database/tables/categories_table.dart` still declared `parentId` and `categories_parent_idx`
- `lib/data/database/daos/category_dao.dart` still exposed `watchChildren(...)`
- `lib/data/models/category.dart` and generated output still carried `parentId`
- `drift_schemas/drift_schema_v1.json` still serialized the old hierarchy column and index

## What Didn't Work

- Running `flutter test` as the primary regression path was not viable in this environment because Flutter startup spent its time in an `objective_c` native-asset hook and never reached the actual test body.
- Running code generation through `dart run build_runner ...` also failed because it went back through package resolution and native-asset plumbing instead of using the already-resolved worktree package config.

## Solution

Flatten the M1 category contract end-to-end:

- Remove `@TableIndex(name: 'categories_parent_idx', columns: {#parentId})` and the `parentId` column from `lib/data/database/tables/categories_table.dart`
- Remove `watchChildren(int parentId)` from `lib/data/database/daos/category_dao.dart`
- Remove `parentId` from `lib/data/models/category.dart`
- Regenerate `lib/data/database/app_database.g.dart` and `lib/data/models/category.freezed.dart`
- Regenerate `drift_schemas/drift_schema_v1.json`
- Add a narrow repository test that asserts a fresh `categories` table no longer contains `parent_id` or `categories_parent_idx`

Because `flutter pub run` / `dart run` were unreliable for generators in this environment, `build_runner` was executed directly against the resolved package config:

```bash
dart --packages=.dart_tool/package_config.json \
  "$HOME/.pub-cache/hosted/pub.dev/build_runner-2.5.4/bin/build_runner.dart" \
  build --delete-conflicting-outputs
```

And the schema snapshot was refreshed with Drift, then reformatted back into the repo's multi-line JSON style.

## Why This Works

The bug was a contract mismatch, not a repository-rule bug. The app still described a hierarchical category shape in M1 artifacts even though the source-of-truth docs had already removed that concept. Deleting the hierarchy field from the handwritten M1 sources and regenerating dependent artifacts restores a single consistent flat model across the table, DAO, domain model, generated code, and schema snapshot.

## Prevention

- When a Drift getter or Freezed field is removed, update the handwritten source and regenerate both Drift and Freezed output in the same change.
- Re-run a targeted grep for removed identifiers like `parentId`, `parent_id`, and obsolete indexes after regeneration.
- If Flutter test startup is blocked by environment-level native-asset issues, verify the schema contract with a direct in-memory `AppDatabase` execution path instead of claiming test coverage that never actually ran.

## Related Issues

- `docs/plans/m1-data-foundations/stream-c-field-name-contract.md` allows rewriting `drift_schema_v1.json` before merge to `main`
- `docs/plans/m1-data-foundations/stream-a-drift-schema.md`
- `docs/plans/m1-data-foundations/stream-b-freezed-models.md`
