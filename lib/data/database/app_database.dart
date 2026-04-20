// TODO(M1): Drift `AppDatabase` with `schemaVersion = 1`. Opens the
// application SQLite file via `drift_flutter` + `path_provider`. Migrations
// (Phase 2 onwards) live in a `MigrationStrategy.onUpgrade` stepwise by
// version, with snapshots committed to `drift_schemas/` (see README there).
//
// SSOT rule: only repositories in `lib/data/repositories/` may talk to this
// class. Controllers and widgets never see Drift types — see import_lint
// rules in analysis_options.yaml.
