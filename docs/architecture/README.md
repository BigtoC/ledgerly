# Architecture Reference

These docs are an agent-facing extract of the architecture rules in [`PRD.md`](../../PRD.md). **`PRD.md` is the authoritative source of truth** — when these summaries conflict with it, follow `PRD.md`.

Each doc captures the rules that are easy to get wrong by defaulting to a generic Flutter shape, with pointers to the live reference files under `lib/`.

## Index

- [`layers.md`](./layers.md) — 3-layer architecture: SSOT on repositories, Drift inside repos, controller pattern, reactive defaults, typed error propagation.
- [`data-model.md`](./data-model.md) — Money in minor units, immutable category `type`, `l10n_key` identity, archive-instead-of-delete, indirect icons/colors, `pending_transactions` staging, pagination cap.
- [`ui-and-layout.md`](./ui-and-layout.md) — Required layout primitives for Home, Add/Edit Transaction, and Category picker; the 600dp adaptive breakpoint; 2× text scale.
- [`bootstrap.md`](./bootstrap.md) — First-run + bootstrap sequence, splash redirect, route table.
- [`testing.md`](./testing.md) — Test organization by architectural layer; in-memory Drift, `ProviderContainer` overrides, splash goldens, migration tests.
- [`dependencies.md`](./dependencies.md) — Pinned versions and the non-obvious reasons behind them (base `app_zh.arb`), and the layer-boundary check that replaced `import_lint`.

## Source precedence

1. [`PRD.md`](../../PRD.md) — authoritative spec.
2. These `docs/architecture/*` files — agent-facing summaries of the above.
3. [`AGENTS.md`](../../AGENTS.md) — quick reference that links here ([`CLAUDE.md`](../../CLAUDE.md) just imports it).
4. `docs/superpowers/specs/2026-04-14-ledgerly-design.md` — historical context only; if it conflicts with `PRD.md`, follow `PRD.md`.
