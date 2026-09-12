# realpass worklog

This is the durable chronological ledger for repo work. It is intentionally concise enough for a new agent to scan before touching the project, while retaining the decisions that would otherwise be trapped in chat history.

For current percentages and blockers, read `docs/PROJECT-STATUS.md`. For design rules, read `REALISM-SPEC.md` and `docs/MODULAR-ARCHITECTURE.md`.

## Logging convention

Every meaningful work batch should record:

- date and branch;
- commit(s) or identifiable files changed;
- what changed and why;
- tests/evidence actually obtained;
- what was deliberately *not* claimed;
- completion percentage before/after if the change closes or reopens a release gate;
- the clearest next action.

Do not use successful compilation as shorthand for gameplay validation. Do not report a distribution package as release-ready if it contains local-only or redistribution-blocked dependencies.

---

## 2026-09-12 — local-to-GitHub handoff completed

Branch/source: `main`
Commits: `cba7659`, `938c8b9`

The local PC repository was successfully pushed to `natanai/cprealpass`. The remote now contains the local-agent fixes for scanned NPC names/toilet interaction labels and the candidate that restores the modern scanner/quickhack presentation while retaining selected E3 HUD assets.

Evidence: Git remote advanced from `2f0846b` to `938c8b9`; local worktree was clean before push.

Not claimed: the modern-scanner candidate has not thereby been proven in native gameplay. Pushing source does not upload ignored local game assets, staging outputs, dependency archives, deployment state or saves.

Next: continue remote work on a branch separate from `main` and preserve the local state for attended testing.

---

## 2026-09-12 — realism scope tightened

Branch: `chatgpt-continuation`
Commits: `f23eda2`, `e6501a2`, `4b9dbbe`
Files: `REALISM-SPEC.md`, `docs/ROADMAP.md`, `docs/MODULAR-ARCHITECTURE.md`

The project was explicitly reframed as one physical/physiological realism mod rather than a general difficulty/survival collection. Major runtime authorities were defined as body/needs, injury, ballistics/combat, armor/clothing, cyberware physiology, presentation and diagnostics. Weather/economy/scarcity/random encounters/travel restrictions and an added outfit/transmog system were declared out of scope.

Combat target was made causal rather than health-pool driven: projectile/ammunition -> region -> material/protection -> penetration -> tissue/cyberware injury -> physiological consequence -> treatment/recovery. Clothing does not gain arbitrary ballistic protection merely because it occupies an equipment slot.

Not claimed: those module boundaries are not yet a fully wired runtime settings implementation. Existing source still contains hard-coded development gates and upstream integration bridges.

Completion estimate after this scope work: **43% toward 1.0** (formal baseline recorded in `docs/PROJECT-STATUS.md`).

Next: convert the architecture into machine-readable contracts, automated tests and a release/distribution plan.

---

## 2026-09-12 — durable project ledger introduced

Branch: `chatgpt-continuation`
Commit: `90b6ac0`
Files: `docs/PROJECT-STATUS.md`

Added a weighted release-readiness model, current known-good state, blocker list, immediate priority order and future-agent rules. Overall baseline is **43%**. The percentage is deliberately conservative and measures progress toward a usable, validated, redistributable 1.0 rather than source-code volume.

Next: add runtime/distribution contracts and cloud-safe automation, then revise the percentage only if those changes materially close release gates.
