---
title: Moving lib/ to a new folder layout without losing the layer-boundary rules
date: 2026-11-02
category: architecture-patterns
module: lib/ tree layout and layer-boundary rules
problem_type: architecture_pattern
component: development_workflow
severity: medium
applies_when:
  - "Moving many Dart files whose imports are relative, so a find-and-replace on package: URIs cannot rewrite them"
  - "Renaming or moving a folder that a search_file_path_reg_exp in import_analysis_options.yaml names"
  - "A tree move spans many commits and each commit must pass codegen, format, analyze and the full suite on its own"
  - "Docs cite lib/ paths that the move changes"
resolution_type: workflow_improvement
related_components:
  - "import_analysis_options.yaml"
  - "test/unit/architecture/layer_boundaries_test.dart"
  - "PRD.md"
  - "docs/architecture/layers.md"
  - "docs/architecture/dependencies.md"
tags:
  - "refactor"
  - "relayout"
  - "relative-imports"
  - "layer-boundaries"
  - "import-analysis-options"
  - "codegen"
  - "docs-sync"
  - "issue-87"
---

# Moving lib/ to a new folder layout without losing the layer-boundary rules

## Context

Issue #87 moved `lib/` from the PRD tree to the Flutter team's `flutter-apply-architecture-best-practices` layout, with no behaviour change:

| Before | After |
|---|---|
| `lib/features/<f>/` (`*_controller`, `*_state`, `*_providers`, `*_screen`) plus `widgets/` | `lib/ui/features/<f>/{view_models,views}/`, `views/` flat |
| `lib/data/models/`, `lib/data/use_cases/` | `lib/domain/{models,use_cases}/` |
| `lib/core/theme/`, `lib/app/widgets/adaptive_shell.dart` | `lib/ui/core/{theme,widgets}/` |

That was 140 hand-written files plus their generated parts, over 400 import lines in `lib/` and `test/`, and about 25 docs, landed as 15 commits that each pass codegen, `dart format`, `dart analyze --fatal-infos` and the full suite.

Two things make such a move harder than it looks:

1. **`lib/` uses relative imports.** One target file is spelled differently from every importer, and an importer's spelling changes when the importer itself moves. Find-and-replace cannot get this right.
2. **The layer rules select files by path regex.** `import_analysis_options.yaml` names folders; `layer_boundaries_test.dart` pins example paths as plain strings. When a folder moves, a rule naming it matches nothing and stays green, and a test pinned to a deleted path stays green too. A careless move can delete every layer boundary without a single red test.

## Guidance

### 1. Derive the mapping from rules, print it, and check the counts first

Write the mover so it computes `old -> new` from a few rules (here: files directly in a slice go to `view_models/` unless they are `*_screen.dart` or a known view; `widgets/**` goes to a flat `views/`; the sub-slices `analysis/charts`, `analysis/search`, `settings/csv_import`, `settings/csv_export` keep their own pair of folders) and raises on any path it does not expect. Tag each target with its step (`shell`, `models`, `use_cases`, `feature:<name>`) so one script drives every commit.

Print the whole plan and compare its totals with the agreed numbers before moving anything (47 view-model files, 72 views, 15 models, 3 use cases, 3 theme/shell files). Flattening a folder can make two files collide, so also check that no target appears twice.

### 2. Resolve every directive against the old path, recompute it from the new one

```python
def rewrite_uri(old_file, new_file, uri, moves):
    target, is_pkg = resolve(old_file, uri)   # relative or package:ledgerly/ -> lib/...
    if target is None:                        # dart:, other packages
        return uri
    new_target = moves.get(target, target)
    if is_pkg:                                # keep the author's style
        return 'package:ledgerly/' + new_target[len('lib/'):]
    if new_target == target and new_file == old_file:
        return uri                            # untouched: keep the spelling
    return os.path.relpath(new_target, os.path.dirname(new_file))
```

- Cover `import`, `export`, `part` and the branches of conditional imports (`if (dart.library.io) 'x.dart'`).
- `resolve` is your own helper: it turns a relative URI or a `package:ledgerly/` URI into a `lib/...` path, and returns `None` for anything else.
- Rewrite every file while it is still at its old path, then `git mv`, then delete emptied folders.
- `test/` here reaches `lib/` only through `package:ledgerly/...` and is organised by layer, so no test moves and a plain URI substitution is enough.
- Move `*.g.dart` / `*.freezed.dart` with their source. `part of 'x.dart'` is sibling-relative, so it stays valid.

### 3. Make the rules accept both trees before the first move

Every intermediate commit has files in both trees. `package:yaml` throws on duplicate keys, so you cannot add a second rule with the same name for the new tree. Widen the existing rule with an alternation instead, and mark it transitional:

```yaml
  # TRANSITIONAL (issue #87): the lib/features/ alternative goes once the
  # last slice has moved.
  controllers_forbid_db_and_services:
    search_file_path_reg_exp: "^lib/(?:features/.*_controller|ui/features/.*/view_models/[^/]+_(controller|providers))\\.dart$"
```

On the import side, keep the old ban and add the new one (`^package:ledgerly/features/` and `^package:ledgerly/ui/`), and use negative lookahead for exemptions (`^package:ledgerly/domain/(?!models/)`). Land this, with tests pinning the new paths, as the first commit (`e9b3384`).

### 4. Guard tests, so a rule cannot go quiet

All four live in `layer_boundaries_test.dart`:

```dart
test('every lib/ui, lib/domain and lib/data file matches a rule', () {
  final config = _Config.load(File(_rulesFile).readAsStringSync());
  final layered = RegExp(r'^lib/(ui|domain|data)/');
  final unmatched = [
    for (final path in _libFiles())
      if (layered.hasMatch(path) &&
          !config.rules.any((r) => r.appliesTo(path)))
        path,
  ];
  expect(unmatched, isEmpty);
});

test('every rule applies to at least one lib file', () {
  final config = _Config.load(File(_rulesFile).readAsStringSync());
  final files = _libFiles();
  final dead = [
    for (final rule in config.rules)
      if (!files.any(rule.appliesTo)) rule.name,
  ];
  expect(dead, isEmpty);
});
```

- **Coverage** (above) and **exactly one rule per `lib/ui/` file** came with the transitional rules in the first commit. Coverage failed at once on `lib/data/seed/first_run_seed.dart`, which no rule had ever covered. The exactly-one test keeps the `ui/` rules (and `core_stays_pure`, which owns the theme) from overlapping.
- **Dead-rule guard** (above) and **example paths exist** came only in the cleanup commit (`571597a`), and both failed there. They could not land earlier: during the move the old-tree rules and pins are meant to point at files that are going away.
  - The dead-rule guard catches a rule whose folder has moved.
  - The example-paths test requires every path the pin tests use to be a real file. The mover never rewrites those strings, and a pin on a deleted path passes forever.

Delete a rule in the commit that empties its folder where you can: `app_widgets_forbid_repository_and_service_providers` went with the shell move. The five `lib/features/`-only rules could not go until the last slice moved, so that commit left them dead for one commit, until the cleanup commit removed them with the transitional alternations.

### 5. One slice per commit, behind a gate

Order: widen the rules, then theme and shell, models, use cases, each feature slice, rule cleanup, and docs. Before each commit, run the same checks as CI:

```zsh
dart run build_runner build --delete-conflicting-outputs  # commit any regenerated parts
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
flutter test
```

Moving files and changing imports left codegen output identical. The exception is a doc comment on a provider: `riverpod_generator` copies it into `.g.dart`, so rewording a comment that names a path changes the generated part, and it must be regenerated in the same commit.

### 6. Update docs against the mapping, then check mechanically

Doc edits can run in parallel with the code moves because they touch different files, but the half-moved tree on disk is not a reliable reference: give the editors the mapping as the authority. Afterwards:

- Check that every `lib/...` path cited in live docs exists.
- Run a repo-wide `git grep` for the old folder names. Here it found `assets/splash/README.md`, which no doc group owned.
- Leave historical plans and specs (`docs/plans/`, `docs/superpowers/`) on their old paths.

## Why This Matters

Path-regex rules fail open: without the guards, a relayout can leave every layer rule checking nothing while CI stays green.

## When to Apply

- Any folder move inside `lib/`, including splitting or merging a feature slice.
- Adding a new folder under `lib/ui/`, `lib/domain/` or `lib/data/`: the coverage test will demand a rule for it.

## Examples

`widgets_forbid_data_internals` through the three phases:

```yaml
# before: screens only; three more rules covered widgets/, states and other helpers
search_file_path_reg_exp: "^lib/features/.*_screen\\.dart$"

# transitional (both trees; deny-by-default under lib/ui/)
search_file_path_reg_exp: "^lib/(?:features/.*_screen\\.dart$|ui/(?!core/theme/)(?!features/.*/view_models/[^/]+_(controller|providers)\\.dart$).*\\.dart$)"

# final
search_file_path_reg_exp: "^lib/ui/(?!core/theme/)(?!features/.*/view_models/[^/]+_(controller|providers)\\.dart$).*\\.dart$"
```

Keying on folder plus suffix let two rules replace seven: every `lib/ui/` file except the theme and `view_models/*_controller.dart` / `*_providers.dart` gets the widget rule, so a new view or state file is covered without editing the rules.

## Related

- Issue #87 and the owner's decisions in its comments; earlier layer-rule work in #85, #92 and #95.
- [`docs/architecture/dependencies.md`](../../architecture/dependencies.md) — how the layer-boundary check works.
- [`flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md`](../performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md) — the regenerate-before-every-commit rule and a per-commit check sweep.
- [`controller-command-outcomes-and-snackbar-actions-outliving-widgets.md`](controller-command-outcomes-and-snackbar-actions-outliving-widgets.md) — explains why outcome types live in `*_state.dart`, which relies on the layer rules.
