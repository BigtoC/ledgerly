// Shared in-memory Drift harness for repository-layer tests.
//
// Ownership: M3 Stream C (`docs/plans/m3-repositories-seed/
// stream-c-preferences-seed-migration.md` §4). Streams A and B consume this
// helper from their own repository tests; no test file may fork a local
// in-memory DB helper (see Stream B plan §6.4).
//
// Phase 1 ships only `newTestAppDatabase()`. `TestRepoBundle` (which wires
// concrete `Drift*Repository` implementations over the shared DB) and
// `seedMinimalRepositoryFixtures()` land as their sibling repositories
// merge in later phases — see Stream C §4.2 / §5 Task C2.

import 'package:drift/native.dart';
import 'package:ledgerly/data/database/app_database.dart';

/// Returns a fresh in-memory `AppDatabase` for tests.
///
/// `NativeDatabase.memory()` gives each test an isolated DB with no disk
/// footprint. The caller MUST `await db.close()` in a `tearDown` /
/// `addTearDown` block.
///
/// The returned database applies `PRAGMA foreign_keys = ON` via
/// `AppDatabase.migration.beforeOpen` — repository FK pre-check tests rely
/// on this being active.
AppDatabase newTestAppDatabase() => AppDatabase(NativeDatabase.memory());
