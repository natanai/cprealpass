# realpass test tiers

realpass has two deliberately different test tiers. Future agents must not confuse a green cloud run with native Cyberpunk acceptance, and must not make GitHub Actions depend on local/generated/third-party files that are intentionally excluded from the public repository.

## Tier 1 — public-source / cloud-safe

`Run-CI.ps1` is the authoritative Tier 1 runner. Every test listed there must reproduce from a fresh checkout using only tracked project-original source, contracts and fixtures. It may create ignored temporary staging/report files during the job, but it must not require:

- the Cyberpunk installation or `final.redscripts`;
- user saves or deployment receipts;
- generated `manifest/*.deployment.json` files;
- `vendor/` or `ReferenceMods/` content;
- acquired Dark Future / Project E3 source that is intentionally excluded from the public tree;
- network acquisition, unattended game launch, services, watchers, recorders or scheduled jobs.

Tier 1 covers model invariants, contract integrity, runtime-policy composition, no-healthbar ownership, safe-package policy, packaging metadata, and source-level orchestration safety. A green Tier 1 run means the public source is internally coherent enough to proceed to the local gates. It is **not** evidence that redscript compiles against the installed game or that a feature renders/plays correctly.

## Tier 2 — local integration / native acceptance

Local tests are allowed to consume the user's hash-pinned acquired dependencies, generated deployment manifests, Cyberpunk 2077 2.31 script bundle and reversible deployment state. Examples include tests such as `Test-SleepClamp.ps1`, `Test-InjuryAuthority.ps1`, `Test-FieldCareConsume.ps1`, `Test-BodyAttendedProfile.ps1`, native-profile mapping tests and exact compile/deploy/rollback checks.

A local-only test stays local-only when its purpose is to validate the actual transformed/upstream integration rather than a project-original pure model. Do **not** solve a missing CI dependency by committing third-party source, game files, generated deployment manifests or machine-specific state.

The broad attended gameplay gate is documented in `../docs/ATTENDED-ACCEPTANCE.md`. `../tools/Prepare-AttendedSession.ps1` is the preferred orchestration entry point: by default it builds the generated body+combat candidate, compiles it against the installed game and runs the real upgrade planner in `-WhatIf` mode. Actual deployment requires explicit `-Deploy`, creates a verified save backup first, verifies the resulting deployment receipt, and still does not launch the game.

## Evidence rule

When recording a result, say which tier supplied the evidence. Use wording such as:

- **offline passed** — project model/contract/fixture checks passed;
- **compiled locally** — exact generated profile compiled against the installed game;
- **deployed/rollback verified** — file transaction and recovery were verified;
- **attended native passed** — the player actually observed the behavior in Cyberpunk;
- **release ready** — all required native, compatibility, licensing and packaging gates are satisfied.

Never promote `partial`/`pending` acceptance gates merely because a lower tier is green.
