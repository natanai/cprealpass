# Biology — CURRENT ROADMAP

Current work is **#152: autonomous final product completion** on `autonomous/final-product-completion`. The owner explicitly authorized one local agent, local release lifecycle testing, safe startup/main-menu smoke, one final PR and merge after gates pass. Do not create workers, wait for a parent, or ask the owner to run the tests for this run. The exact directive is `docs/handoffs/AUTONOMOUS-FINAL-PRODUCT-COMPLETION.md`.

Current GitHub issues/PRs and `docs/THREAD-LEDGER.md` retain coordination state. The product scope is `AGREED-GOALS.md`; implementation/evidence is tracked in `docs/PRODUCT-COMPLETION-MATRIX.md` and `docs/evidence/AUTONOMOUS-COMPLETION-2026-09-20.md`.

## Current gates

- T007 source repairs: player gameplay eligibility, native-loss injury route, E3 save-backed preference and native scanner/nameplate ownership.
- Whole-product source audit: single body, bounded callbacks, care/protection/combat authority, all native activation entry points, save compatibility and explicit failure behavior.
- Player package: one native installer, one native uninstaller, pinned redscript/cybercmd, notices, receipt and checksums; no external mod runtime.
- Release gates still to record at final HEAD: complete CI and exact compile, final ZIP inventory, install/upgrade/reinstall/uninstall/reinstall, REDmod deployment and startup smoke, exact final installed receipt, final PR/CI/merge.
- Native gameplay/render/save observations that cannot be established without playing a save remain explicitly LIVE-ONLY. They must not be represented as static proof or turned into a request that blocks this owner-authorized run.

The source does not retain the old reported body-system-missing or T007 E3 defects as unresolved implementation tasks. The final evidence must distinguish their source repairs from unperformed native observations. #39 (body shell), #40 (E3), #41 (runtime), and #44 (disable/uninstall), plus #35/#78/#101/#102/#148/#151, are reconciled through #152 with evidence rather than revived as obsolete worker assignments.

## Historical provenance

Parent integration/orchestration thread policy and its prior handoff remain in `docs/INTEGRATION-ORCHESTRATOR.md` and `docs/handoffs/PARENT-INTEGRATION.md`; the explicit solo owner override above governs #152. The official REDmod recognition milestone remains accepted historical evidence.

The first integrated attended artifact was `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5`. Pre-W10 transition provenance is `7e61724071b8c95ba5c334ab9e8d11c43381c94e`. W11.1 / issue #64 / PR #65 recorded the SAFE-TO-APPLY read-only decision for 42 retired framework files while protecting redscript. The failed W14 install source was `04d4c1584df4b0823e093422b98cf4c5575c7b19`; W15 provided bounded repository-backed recovery evidence when its old ZIP was absent. These are historical states, not the current installed-state description.

Dated evidence remains under `docs/test-runs/` and `docs/operator-evidence/`. Never overwrite it with claims about a new revision. Routine Biology removal does not require a Steam reinstall. The final state for #152 must be the tested final Biology release installed, with shared dependencies and saves preserved, and no external public distribution.
