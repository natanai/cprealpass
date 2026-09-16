# W13.1 — installed Biology runtime activation / no-effect follow-up

Status: **REPAIR COMPLETE — RETURNED TO P01.2 FOR ATTENDED VALIDATION**  
Parent: **P01.2**  
Issue: **#68**  
Branch: `agent/installed-runtime-activation-followup`

## Paste into the worker conversation

```text
[W13.1] RUNTIME — Installed Biology Activation Follow-Up

Work on repo natanai/cprealpass.

This is worker lane W13.1.

Work ONLY on the already-created branch:

agent/installed-runtime-activation-followup

Issue:
#68 — Attended follow-up — canonical candidate deploys but Biology runtime has no material in-game effect

Parent:
P01.2

Read FIRST and then follow the complete handoff:

docs/handoffs/W13-INSTALLED-RUNTIME-ACTIVATION-FOLLOWUP.md

At startup, independently resolve and report the exact current worker-branch head. Do not assume a stale handoff/base SHA.

Do NOT merge your own PR.
Do NOT ask the user to install or play the worker branch.
Do NOT ask the user to reinstall Cyberpunk.
Do NOT broaden into Biology UI redesign, E3 redesign, physiology/combat/scanner redesign, or dependency strategy before the first broken runtime boundary is proven.
```

## Read first

- `AGENTS.md`
- `AGREED-GOALS.md`
- `ROADMAP.md`
- `docs/THREAD-LEDGER.md`
- `docs/handoffs/PARENT-P01.2.md`
- `docs/INTEGRATION-ORCHESTRATOR.md`
- `docs/PARALLEL-AGENT-WORKFLOW.md`
- `docs/LOCAL-OPERATOR-COMMANDS.md`
- `docs/LOCAL-GAME-REFERENCE.md`
- `docs/BIOLOGY-REDMOD-MIGRATION.md`
- `docs/BIOLOGY-UI.md`
- `docs/SETTINGS-ARCHITECTURE.md`
- `docs/test-runs/2026-09-15-68b50ed9-runtime-no-effect.md`
- issue #68 and current comments
- existing issues #39, #40, #41, #44 for acceptance boundaries only
- package/build/install/runtime manifests and the exact scripts they deploy
- current runtime entrypoints / ScriptableSystems / controller hooks / activation-sentinel reads

## Exact attended source and artifact

Canonical source tested:

`68b50ed9e3c629ca252326918dbbb68b9bc35494`

Exact release artifact:

`biology-integrated-20260916-043147-68b50ed9e3c6.zip`

SHA-256:

`E2DD7ED91D88D9C25A3260D907F3D2F51AF2A7BC3194653D265CA90B6B291952`

Supported game/tooling:

- Cyberpunk 2077 product version 2.31
- Cyberpunk executable SHA-256 `A7DE82945C03E041FC7339FCF9066224D98DB2F5D80FEA50F7947BB350A60991`
- REDmod product version 2.31
- REDmod executable SHA-256 `144DF5A984669528CD957B40BB2126FE83B73D66BD0E041CA614C80F74E76A7F`

## What passed before launch

W12 Command 13 report `Biology-Post-Transition-Candidate-Prep-68b50ed9-20260915-233141-bdc005b7.txt` returned PASS and proved:

- W11 cleanup evidence/hash matched;
- all 42 retired Mod Settings / ArchiveXL / RED4ext paths remained absent;
- Biology-specific residue verifier passed before install;
- clean exact source checkout;
- exact REDscript offline compilation of 62 project-original sources;
- release-shaped artifact build and policy checks;
- built and installed `sourceRevision` exactly matched the tested canonical SHA;
- official REDmod recognized Biology and completed all five deployment stages;
- W09 output-directory recovery path worked on the actual supported installation.

Therefore do not reopen W09 or W11 unless new direct evidence invalidates those narrow results.

## New attended failure

The user launched with REDlauncher mods ON and reported:

> there is currently no material effect of the mod active in the game

Three screenshots from the exact session show:

1. Pause/hub still exposes ordinary top-level `CYBERWARE`, not `BIOLOGY`.
2. Cyberware opens the ordinary native anatomy/equipment screen, with no visible Biology overview, no `BIOLOGY | CYBERWARE` selector, and no Biology runtime/status surface.
3. Ordinary first-person gameplay looks current/vanilla, with no material Biology/E3 presentation visible.

This is broader than the already-known individual acceptance defects in #39/#40/#41. Treat the first task as **locating the earliest live runtime load/register/attach failure**, not fixing downstream visuals blindly.

## Primary investigation goal

Establish which of these boundaries first fails in the live installed game:

1. **artifact/install placement** — are the exact Biology runtime files physically installed where Cyberpunk/redscript actually loads them?
2. **redscript loader/compile-at-game-launch** — does the live game loader compile/load the installed Biology scripts, and if not, what exact error prevents it?
3. **class/hook attachment** — if scripts load, are the replacements/wraps/hooks targeting valid CP2077 2.31 classes/signatures?
4. **system registration/session creation** — are Biology ScriptableSystems or equivalent authority registered and retrievable in a live session?
5. **activation gating** — is the W10 launcher/REDmod sentinel incorrectly evaluating Biology as disabled despite REDlauncher mods ON?
6. **UI/runtime entrypoint execution** — do the outer hub/menu and presentation entrypoints ever execute after load?

Do not skip directly to redesigning the visible UI. The screenshots currently support a cross-cutting activation/load failure hypothesis, not a proven UI defect.

## Required source audit

Trace the release-shaped runtime path end-to-end:

`source files -> deployment manifest/profile -> Build-BiologyPackage.ps1 -> ZIP layout -> installed paths -> redscript live loader -> Biology runtime registration -> menu/presentation hooks -> activation gate`

Compare the exact release artifact contract against the local supported game reference and known redscript 0.5.31 loader behavior already documented in the repo.

Pay particular attention to any difference between:

- offline compiler acceptance vs live game loader acceptance;
- project source layout vs staged deployment layout;
- package receipt ownership vs files actually consumed by the loader;
- REDmod TWEAKS activation sentinel success vs REDscript runtime visibility of that sentinel;
- compile-time valid class names/signatures vs runtime hook targets that may no longer attach on 2.31.

## Local evidence requirement

If source inspection cannot prove the first broken boundary, add a **repository-owned read-only probe/bootstrap** rather than asking the user to hunt logs manually.

It must:

- work with zero persistent local repo assumption;
- use bounded local-first worktree-aware discovery or the canonical exact-revision loader boundary;
- require exact branch + 40-character worker head;
- fingerprint Cyberpunk/REDmod;
- keep installed game read-only;
- collect only bounded evidence needed for this failure, such as exact installed Biology paths/hashes, relevant redscript/runtime loader logs/errors, receipt revision, sentinel state evidence, and any loader/runtime registration evidence available without game mutation;
- use `ProcessStartInfo`/ArgumentList for native children;
- preserve stdout/stderr/exit/exception evidence;
- emit one attachable `.txt` on success and failure;
- print `ATTACH THIS FILE TO CHATGPT:`;
- never depend on a previous local repo/worktree surviving.

Do not ask the user to reinstall Cyberpunk or to install/play your worker branch.

## Scope boundaries

### You own

- installed Biology REDscript/runtime activation and loader boundary;
- release packaging/install path defects if they directly explain the no-effect launch;
- activation-sentinel read/gating defects if direct evidence proves them;
- CP2077 2.31 hook/class/signature repair if that is the first broken boundary;
- minimal diagnostic tooling/tests/docs needed to prove the repair.

### You do not own

- #39 downstream Biology shell UX redesign;
- #40 downstream E3 visual/nameplate redesign;
- #41 downstream body-state semantics beyond ensuring the runtime can actually load/register;
- #44 launcher-OFF final acceptance;
- W09 REDmod output recovery redesign;
- W11 transition cleanup redesign;
- broad dependency replacement.

If restoring runtime activation exposes the old #39/#40/#41 symptoms, stop at the W13 boundary and return those findings to the parent rather than absorbing them.

## Validation

Before returning to P01.2:

- run full cloud CI;
- add regression coverage that would have caught the proven root cause;
- open a PR to `main` but do not merge it;
- report exact final worker head;
- identify exact files changed;
- distinguish source/CI proof from what still requires attended game acceptance;
- if a local probe is needed, provide the single parent-ready command/report contract rather than asking the user to install the branch;
- confirm no game launch is automated.

## Return to parent with

- `W13.1` identifier;
- exact startup head and final head;
- issue #68 / PR number;
- exact proven root cause;
- evidence that establishes the first broken boundary;
- exact repair;
- CI result;
- whether a parent-attended read-only probe is needed before merge;
- after merge, the smallest parent retest needed to prove Biology is materially active again.

## W13.1 completion / return to P01.2

Startup worker head independently resolved at assignment:

`6361bbe2448a9d06566d6ca9d859f0bb196f4118`

The attended read-only W13 probe against installed canonical candidate `68b50ed9e3c629ca252326918dbbb68b9bc35494` established the first broken boundary as **BOUNDARY 2 — REDSCRIPT STARTUP / CONFIGURED COMPILE OUTPUT**:

- the Biology ownership receipt was exact: 75/75 files verified, 0 missing, 0 mismatched;
- all 62 current Biology REDscript source files were installed;
- REDmod reported Biology enabled and deployed;
- installed `r6/config/cybercmd/scc.toml` configured `InvokeScc` and directed gameplay to `r6/cache/modded/final.redscripts`;
- that compiled blob was stale relative to the installed candidate;
- neither `bin/x64/plugins/cybercmd.asi` nor RED4ext was installed to execute the configured startup compile task.

The narrow repair is to bundle standalone cybercmd `0.0.13` only as redscript startup plumbing. The official `cybercmd-standalone.zip` is pinned at SHA-256 `87E235026D0693D7974A908E65F8C93F6503652FB781F0647B115572BBDD6103` and contributes exactly:

- `bin/x64/global.ini`
- `bin/x64/plugins/cybercmd.asi`
- `bin/x64/version.dll`

The production runtime profile now retains exactly `redscript` + `cybercmd`. redscript remains the SCC/compiler/configuration provider; cybercmd exists solely to execute redscript's already-shipped `scc.toml` startup task. Generated `final.redscripts` remains forbidden from Biology artifacts. Mod Settings, ArchiveXL and RED4ext remain retired, and the REDmod-owned `Items.BiologyLauncherActivationMarker.stackable` sentinel remains the sole whole-mod activation authority.

Regression coverage includes `tests/Test-RedscriptStartupRuntime.ps1`, specifically preventing recurrence of the observed failure where `scc.toml` ships without a compatible startup executor. Relevant package, settings, runtime-origin, install, distribution, launcher-disable, artifact-policy and uninstaller contracts were updated only where they encoded the disproven `redscript-only` plumbing assumption.

Cloud-safe validation on repair implementation head `02f33bf436e3611c5bb4941eaf045000de07aaea` passed all W13/runtime/package checks, including PowerShell syntax for 155 repository scripts and 42 uninstaller planner/executor safety checks. The overall workflow remains red only because of the inherited parent bookkeeping assertion in `Test-ActiveRoadmap.ps1`: `Thread ledger must explicitly record the current no-worker state.` That failure predates W13 and is not owned by this lane.

PR #69 remains draft and unmerged. Subsequent commits on this worker branch are bookkeeping-only parent-return/handoff updates; parent integration must independently resolve the exact current PR head rather than treating the implementation-validation SHA above as the final branch SHA.

Static/source/package work is exhausted. The smallest parent-owned attended validation is to build/install the exact release-shaped W13 repair candidate and prove, on supported launch, that `r6/cache/modded/final.redscripts` is regenerated at or after the installed candidate payload before evaluating downstream Biology UI/body/presentation behavior. W13 does not ask the user to install/play the worker branch and does not automate game launch.