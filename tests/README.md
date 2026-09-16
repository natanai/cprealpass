# Biology test tiers

Biology uses two deliberately different evidence tiers. A green cloud run is not native Cyberpunk acceptance, and local gameplay evidence must come from the current canonical `main` build rather than a stale branch or accumulated developer install.

## Tier 1 — public-source / cloud-safe

`Run-CI.ps1` is the authoritative Tier 1 runner. Every listed test must reproduce from a fresh checkout using only tracked project-original source, contracts and fixtures. It must not require the Cyberpunk installation, user saves, generated deployment state, third-party source trees, network acquisition, unattended game launch, background services, watchers, recorders or scheduled jobs.

Tier 1 covers model invariants, contracts, runtime-origin policy, native-seam confinement, package policy, operator workflow safety, and CI-suite hygiene. Passing Tier 1 means the source is internally coherent enough to proceed to local gates; it does not prove native compilation, rendering or gameplay behavior.

`Test-CiSuiteHygiene.ps1` makes the suite inventory explicit: `Run-CI.ps1` may not contain duplicate entries, every listed test must exist, and every `Test-*.ps1` that is intentionally excluded must be named below with a reason.

## Intentional non-cloud / local-only tests

These files are retained intentionally outside `Run-CI.ps1`; they are not silently orphaned:

- `Test-AttendedBuilder.ps1` — local attended-builder compatibility exercise that depends on local build/test context rather than the pure public-source cloud contract.
- `Test-BodyAttendedProfile.ps1` — attended/local body-profile helper validation, not a standalone cloud gate.
- `Test-BodyProfile.ps1` — profile-oriented local/developer check retained outside the canonical cloud suite.
- `Test-CompileGuard.ps1` — local exact-compilation guard tied to installed Cyberpunk compiler/game inputs; cloud CI cannot claim this proof.
- `Test-Deployment.ps1` — local deployment-oriented check requiring installed game/deployment state; official REDmod deployment remains a local/attended gate.

If another `Test-*.ps1` is intentionally kept outside cloud CI, add it here in the same change that creates/excludes it and state why. If it is reproducible from public source and should be a normal contract, add it to `Run-CI.ps1` instead.

## Tier 2 — local compatibility / attended acceptance

For user-facing gameplay testing, follow `../docs/CLEAN-ROOM-TESTING.md` and the rules in `../AGENTS.md`.

- Use a fresh clone/download of canonical `main` for every attended build.
- Classify the session as either an iteration test or milestone clean-room test.
- Use the recorded vanilla baseline/reset workflow when reusing the installed game.
- Build and install the same release-shaped candidate intended for players; do not treat an accumulated developer deployment as the canonical attended-test path.
- Save/reload remains an important persistence test, but Biology must not create, require or gate ordinary local deployment on an additional Biology-managed save backup. Existing external/cloud save protection is the accepted policy in `AGREED-GOALS.md`.
- Do not launch Cyberpunk unattended or create background helpers.

## Evidence rule

Use precise labels when recording results:

- **offline passed** — project model/contract/fixture checks passed;
- **compiled locally** — exact project source compiled against the installed supported game;
- **baseline verified** — the reusable installation matches the recorded vanilla baseline, or a milestone clean-room reinstall was performed;
- **attended native passed** — the player actually observed the behavior in Cyberpunk;
- **release ready** — all required native, compatibility, packaging and licensing gates are satisfied.

Never promote a lower-tier result into gameplay acceptance.
