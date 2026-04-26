# M5 Wave 4 — Integration

**Source of truth:** [`PRD.md`](../../../PRD.md) → *Routing Structure*, *Testing Strategy → Integration Tests*. Contracts inherited from [`wave-0-contracts-plan.md`](wave-0-contracts-plan.md). Prior-wave outputs: [`wave-1/`](wave-1/), [`wave-2-transactions-plan.md`](wave-2-transactions-plan.md), [`wave-3-home-plan.md`](wave-3-home-plan.md).

Wave 4 is **not a slice**. It is an operator-run integration pass that verifies the six merged slices compose into a working app, reconciles shared surfaces, and confirms the full test suite is green. No new features; no controller/widget authoring.

In practice, Waves 1–3 each wired their own real screens into `lib/app/router.dart` at slice-merge time rather than landing behind M4 placeholders. Wave 4's role for §3.1 is therefore **verification** of that wiring, not active replacement; placeholder cleanup is a fallback path only invoked if a slice failed to wire its screen.

---

## 1. Goal

Turn the six independently-merged Wave 1–3 slice PRs into a shippable app:
1. Verify `lib/app/router.dart` references real slice screens for every MVP route; replace any lingering M4 placeholders that a slice failed to wire.
2. Reconcile any ARB-key conflicts that slipped through slice reviews.
3. Run the full test suite (unit + widget + integration) and resolve cross-slice integration bugs.
4. Confirm the cold-start integration test from M4 still passes end-to-end.

Entry criterion: Waves 0, 1, 2, 3 all merged to the M5 branch (`feature/m5-feature-slices` per `implementation-plan.md` → *Agent execution waves*). If any wave is still open, Wave 4 does not start.

---

## 2. Executor

**Operator (user / human), not an agent.** Router wiring and test-suite triage touch multiple slices simultaneously and require judgment calls (which slice owns a surfacing bug, whether a test needs updating or the code does). An agent would struggle without the full conversation history across slice reviews.

If the operator delegates, the agent runs in **foreground** with explicit instructions per §4 — no autonomous bug-fixing across slice boundaries.

---

## 3. Deliverables

### 3.1 Router updates

`lib/app/router.dart` — verify each MVP route resolves to a real slice screen (slices wired these during their own PRs; revert any leftover placeholder if found):
- `/splash` body → `SplashScreen` from `lib/features/splash/splash_screen.dart`.
- `/splash/preview` body → `SplashScreen(previewMode: true)` from `lib/features/splash/splash_screen.dart`. Top-level route (`parentNavigatorKey: _rootNavigatorKey`) with the same fade `CustomTransitionPage` as `/splash`; backs the Settings → Splash → "Preview splash screen" CTA. Tapping the splash Enter button in this mode pops back to settings instead of going to `/home`. Owned by the Wave 1 splash slice.
- `/home` body → `HomeScreen` from `lib/features/home/home_screen.dart`.
- `/home/add` + `/home/edit/:id` bodies → `TransactionFormScreen` from `lib/features/transactions/transaction_form_screen.dart`. Verify the root-modal presentation (`parentNavigatorKey: _rootNavigatorKey`) and that `_modalPage` / equivalent uses `fullscreenDialog: true` for Material routes, per PRD → *Routing Structure*.
- `/accounts` body → `AccountsScreen`.
- `/accounts/new` + `/accounts/:id` routes → `AccountFormScreen(accountId: ...)`, with the Accounts-plan modal push semantics (`parentNavigatorKey: _rootNavigatorKey` + modal page builder) instead of nesting them as plain in-branch screens. `/accounts/new` is Add mode (`accountId: null`); `/accounts/:id` is Edit mode (`accountId: parsedId`); invalid ids redirect to `/accounts`.
- `/settings` body → `SettingsScreen`.
- `/settings/categories` body → `CategoriesScreen`.

Keep the existing:
- Root redirect on `splash_enabled` (M4).
- `StatefulShellRoute` for Home / Accounts / Settings tabs (M4).
- Fade `CustomTransitionPage` for `/splash → /home` (M4).

**Do not** add new routes beyond the inventory above. Phase 2 routes (`/settings/wallets`, `/settings/ankr-key`, `/home/pending`) stay out of MVP per PRD. `/splash/preview` is the only MVP-scope route added past M4 and is owned by Wave 1, not Wave 4.

### 3.2 ARB reconciliation

- Update `test/unit/l10n/arb_audit_test.dart` from its M4 fixed-key inventory so it validates the intended merged-M5 invariants (locale parity, fallback-only `app_zh.arb`, no unexpected drift), then run it against the reconciled ARBs.
- Resolve any duplicate-key collisions: two slices that accidentally claimed the same key — rename the lesser-used one under its proper slice prefix.
- Check that every key under `common*` is genuinely shared by ≥2 slices. Move singletons back to their slice prefix.
- Verify every key added during Wave 1–3 landed in the shipped locale files (`app_en`, `app_zh_TW`, `app_zh_CN`) and that `app_zh.arb` remained fallback-only.

### 3.3 Integration harness preservation

Wave 4 keeps the existing M4 integration harness green against the merged M5 app; it does **not** pull the full PRD integration-flow authoring work forward from M6.

- Keep `test/integration/bootstrap_to_home_test.dart` green against the merged router + real slice screens.
- Update that harness only where real slice screens intentionally replace M4 placeholders or where router wiring changes the expected launch timing / route transitions.
- If Wave 4's router swap exposes a regression that cannot be covered by the existing harness, add the smallest additional integration smoke needed for the wiring change. Do not expand `test/integration/` into the full PRD end-to-end suite here.
- The full PRD integration-flow set (first-launch, splash-on/off launches, duplicate, edit, multi-currency, archive) remains M6 work per `implementation-plan.md`.

Phase 2 integration tests (wallet add/sync, pending approve/reject) remain out of scope.

### 3.4 Test suite sweep

Run `flutter test` (unit + widget + integration). Triage:
- **Cross-slice bug** (Wave 2 form expects something Wave 1 doesn't provide) → decide which slice owns the fix; file a follow-up PR against the owning slice's owner. Do **not** patch across slice boundaries inside Wave 4.
- **M4 test broken by slice work** (e.g. smoke test still references placeholder screens) → update the test to reference the real screens. This is Wave 4's responsibility.
- **Golden test drift** — rerun `flutter test --update-goldens` on the CI runner image; do not accept locally.

### 3.5 Manual smoke on device matrix

Per `implementation-plan.md` → M6 → *Deliverables*, the full device matrix (Android phone + tablet + iOS phone + tablet) is M6's responsibility. Wave 4 runs a minimal smoke on the operator's primary device, plus one lightweight local `>=600dp` spot-check (simulator/emulator acceptable):
- Cold launch with splash enabled and a configured start date → splash appears → Enter → Home.
- Add a transaction → returns to Home with the day pinned.
- Edit an existing transaction → save → verify the updated row remains visible on the pinned day.
- Duplicate → adjust → save → verify.
- Archive a used category/account → confirm it disappears from the relevant picker but remains visible in management/history.
- Toggle theme (Settings) → app recolors without restart.
- Toggle locale (Settings) → strings change without restart.
- `>=600dp` spot-check: shell switches to `NavigationRail`, Home renders its two-pane layout, and Add/Edit Transaction opens with constrained-dialog presentation instead of the phone full-screen modal.

Deeper a11y / 2× text scale / screen reader verification stays in M6.

---

## 4. Executor notes — if delegated to an agent

If the operator delegates Wave 4 to a Claude agent:

- The agent runs **foreground only** (not background) — cross-slice triage needs real-time judgment.
- The agent's prompt must include:
  - This plan doc path.
  - The list of merged slice PRs (so the agent can read their diffs).
  - An explicit rule: "You may edit `lib/app/router.dart` and `test/` files. You may NOT edit files under `lib/features/<slice>/` — those stay owned by their slice owner. If a feature bug surfaces, stop and report back."
- The agent should not start new slices, refactor shared widgets, or "improve" slice code it notices while passing through.

---

## 5. Cross-slice contract adherence (Wave 0)

- §2.3 — Cross-slice ownership is already enforced at slice-PR review time. Wave 4 only verifies the wiring, not the ownership.
- §2.4 — Wave 4 is the **only** wave allowed to edit `lib/app/router.dart` (replacing placeholders with real screens). Router edits inside a slice PR should have been rejected in review; if any slipped through, revert them here.
- §2.5 — No widget promotion to `core/widgets/` in MVP. If a widget was duplicated across three slices during Waves 1–3, flag for post-MVP extraction — do not refactor in Wave 4.
- Wave 4 integration work itself stays in one PR, but any blocking per-slice regressions discovered here are fixed in separate follow-up PRs owned by the relevant slice before the Wave 4 PR merges.

---

## 6. Exit criteria

- `lib/app/router.dart` references real slice screens for every MVP route. No placeholder imports remain.
- `test/unit/l10n/arb_audit_test.dart` passes against the reconciled ARBs.
- `flutter test` passes the full unit + widget + integration suite, including the preserved M4 integration harness and any minimal Wave 4 router-smoke additions from §3.3.
- Manual smoke (§3.5) on the operator's primary device passes each step, and one lightweight local `>=600dp` spot-check verifies adaptive shell/home/form wiring.
- `flutter analyze` clean across the whole tree.
- M5 branch is ready for merge to `main`, or for M6 polish work to begin on top of it.

Wave 4 intentionally does **not** gate on:
- M6 accessibility audit (that is M6's scope).
- Full device matrix testing (M6).
- Native splash regeneration (M6).
- Release-build signing / store listing (M6).

---

## 7. Sequencing

Single Wave 4 integration PR, plus any required per-slice follow-up PRs discovered during triage:

1. Pull the merged M5 branch with all Wave 0–3 PRs included.
2. Edit `lib/app/router.dart` to wire real slice screens (§3.1).
3. Run `flutter analyze` — resolve any compile errors introduced by the switch.
4. Run `flutter test` — resolve M4 test regressions (Wave 4's job); triage slice regressions to the owning slice and pause Wave 4 merge until the required follow-up PRs land.
5. Preserve / minimally update the integration harness per §3.3.
6. Run `test/unit/l10n/arb_audit_test.dart`; reconcile ARB collisions per §3.2.
7. Manual device smoke (§3.5).
8. Commit + open PR titled `chore(m5): wave 4 integration`.

PR size expectation: `router.dart` diff, ARB reconciliation, new integration tests, M4-test updates. Should **not** include edits to feature code. If the PR grows to touch feature code, stop and refile as separate per-slice follow-ups.

---

## 8. Risks

1. **A slice PR accidentally edited `router.dart`.** Revert the edit in Wave 4; file a follow-up against the slice to clean up its git history if needed. Reviewer discipline in Waves 1–3 should prevent this.
2. **Cross-slice integration bug surfacing late.** E.g., Home's duplicate route extra doesn't unpack the way Transactions expected. Wave 4 doesn't fix it inside itself — it files a Wave 2 or Wave 3 follow-up PR and blocks on that landing. Better to delay Wave 4 than patch blindly.
3. **ARB key leaked into `common*` unjustly.** A slice owner put `commonAccountName` or similar — should be `accountsFormName`. §3.2 catches via audit test + review.
4. **Golden tests drift on CI runner.** Regenerate on CI, not locally. Document the regen command in the PR description.
5. **Integration harness gap.** Prefer extending the existing M4 harness or using test-local setup for Wave 4 router-smoke needs. Only add a reusable helper here if a concrete Wave 4 integration update cannot be written cleanly without it.
6. **Router transition regression.** The fade transition for `/splash → /home` may break when the real `SplashScreen` replaces the placeholder. Visual regression not caught by any existing test — verify manually in §3.5.
7. **Delegation to an agent going wrong.** If delegated and the agent starts patching slice code, stop and take over. Re-emphasize the operator-run framing in §2.
