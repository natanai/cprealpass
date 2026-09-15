# realpass test tiers

RealPass has two deliberately different test tiers. Future agents must not confuse a green cloud run with native Cyberpunk acceptance, and must not make GitHub Actions depend on local/generated/third-party files that are intentionally excluded from the public repository.

## Tier 1 — public-source / cloud-safe

`Run-CI.ps1` is the authoritative Tier 1 runner. Every test listed there must reproduce from a fresh checkout using only tracked project-original source, contracts and fixtures. It may create ignored temporary staging/report files during the job, but it must not require:

- the Cyberpunk installation or `final.redscripts`;
- user saves, save backups or legacy deployment receipts;
- generated `manifest/*.deployment.json` files;
- `vendor/` or `ReferenceMods/` content;
- acquired Dark Future / Project E3 source that is intentionally excluded from the public tree;
- network acquisition, unattended game launch, services, watchers, recorders or scheduled jobs.

Tier 1 covers model invariants, contract integrity, runtime-origin/vanilla-identity policy, native-seam confinement, health-presentation ownership, safe-package policy, packaging metadata and source-level orchestration safety. A green Tier 1 run means the public source is internally coherent enough to proceed to local gates. It is **not** evidence that redscript compiles against the installed game or that a feature renders/plays correctly.

## Tier 2 — local integration / native acceptance

Local tests may consume the user's hash-pinned generic runtime dependencies, generated deployment manifests and Cyberpunk 2077 2.31 script bundle. Historical source-mod integration tests may remain useful as reference evidence, but they are not the current production path and must never make Dark Future or Project E3 runtime prerequisites of an owned candidate.

The broad attended gameplay gate is documented in `../docs/ATTENDED-ACCEPTANCE.md`. `../tools/Prepare-OwnedSession.ps1` is the current orchestration entry point.

Without `-Deploy`, it runs the public/offline checks, builds the complete current project-original candidate, opens only immutable test gates, exact-compiles against the installed game and plans the flat owned install without modifying Cyberpunk.

With `-Deploy`, it installs the exact current owned payload, verifies hashes, records the flat owned-file state, removes known retired/source-mod runtime residue and stops. It does **not** create or require a RealPass-managed save backup and it does **not** launch the game.

Save/reload remains a native gameplay-persistence acceptance case. That is distinct from copying/backing up save files as part of deployment.

The owned builder deliberately compiles the complete current production REDscript tree. Superseded bridge/popup/localization sources are removed from production rather than silently excluded from the candidate. `manifest/native-seams.json` and `Test-NativeSeamPolicy.ps1` additionally keep Cyberpunk-version-sensitive hook annotations confined to explicit boundary adapters so pure simulation models do not gradually become patch-coupled.

## Evidence rule

When recording a result, say which tier supplied the evidence. Useful wording includes:

- **offline passed** — project model/contract/fixture checks passed;
- **compiled locally** — exact generated profile compiled against the installed game;
- **installed/verified** — the current owned payload and hashes were verified;
- **attended native passed** — the player actually observed the behavior in Cyberpunk;
- **release ready** — all required native, compatibility, licensing and packaging gates are satisfied.

Never promote `partial`/`pending` acceptance gates merely because a lower tier is green.
