# Attended test — canonical candidate deploys but Biology has no material live effect

Date: 2026-09-15
Cyberpunk version: 2.31
Test mode: controlled post-W11 transition candidate / parent-attended
Canonical main SHA: `68b50ed9e3c629ca252326918dbbb68b9bc35494`
Artifact/package: `biology-integrated-20260916-043147-68b50ed9e3c6.zip`
Artifact SHA-256: `E2DD7ED91D88D9C25A3260D907F3D2F51AF2A7BC3194653D265CA90B6B291952`
Candidate-prep report: `Biology-Post-Transition-Candidate-Prep-68b50ed9-20260915-233141-bdc005b7.txt`

## Included work

- W09 / PR #62 — post-uninstall official REDmod output-directory recovery
- W10 / PR #63 — self-contained settings/provider and retired framework removal
- W11 / PR #65 — controlled retirement of pre-W10 Mod Settings / ArchiveXL / RED4ext residue
- W12 / PR #67 — hardened zero-local-repo operator bootstrap and canonical post-transition candidate preparation
- previously merged Biology shell/runtime/presentation follow-ups for issues #39/#40/#41

## Pre-launch evidence

The W12 candidate-prep report returned `RESULT: PASS` and established:

- exact W11 cleanup report hash accepted;
- all 42 retired framework paths remained absent;
- Biology-specific residue verifier PASS before install;
- exact clean candidate source at canonical SHA;
- exact REDscript compilation of 62 project-original sources;
- release-shaped artifact built and retained outside disposable repository state;
- built and installed `sourceRevision` exactly matched canonical SHA;
- official REDmod 2.31 recognized `Biology` and completed all five deploy stages;
- W09 repaired `r6/cache/modded` recovery path attended-PASSed;
- game was not launched by the preparation tool.

## Expected acceptance

- [ ] Pause/hub exposes the Biology-owned outer `BIOLOGY` identity rather than ordinary top-level `CYBERWARE`.
- [ ] Biology overview/runtime is materially present in the live session.
- [ ] Biology/Cyberware internal submode UI is visible and functional.
- [ ] Ordinary gameplay shows at least the expected Biology/E3-owned presentation when enabled.
- [ ] Existing #39/#40/#41 acceptance can proceed meaningfully.

## Observed results

### PASS

- Exact artifact installation and official REDmod deployment were already proven before launch by the W12 report.
- No pre-W10 framework warning/menu-gap symptom was reported in this launch before the broader runtime failure became obvious.

### FAIL

The user reported: **“there is currently no material effect of the mod active in the game.”**

Three screenshots from the exact attended session show:

1. Pause/hub still presents the ordinary `CYBERWARE` tile instead of `BIOLOGY`.
2. Opening Cyberware shows the ordinary native Cyberware anatomy/equipment screen, with no visible Biology overview, no `BIOLOGY | CYBERWARE` selector, and no Biology runtime/status surface.
3. Ordinary first-person gameplay reads as current/vanilla presentation with no material Biology/E3 effect visible.

This is broader than an isolated #39 shell defect, #41 body-runtime defect, or #40 E3 presentation defect. The current exact release candidate appears not to have its Biology runtime/controller hook surface executing or attaching materially in the live game at all.

## Evidence boundary

Do not infer the cause from deployment success. Official REDmod deployment proves package/TweakDB recognition and output, while the live screenshots show that the expected Biology REDscript/runtime behavior is not materially active. Offline REDscript compile success likewise does not prove live loader registration/hook attachment.

## Findings and routing

| ID | Finding | Expected | Observed | Owner / route | Follow-up issue/branch |
|---|---|---|---|---|---|
| LIVE-ACT-01 | Exact deployed candidate has no material Biology live effect | Outer Biology identity + runtime/UI/presentation materially active | Vanilla/current Cyberware hub/screen and gameplay remain | New cross-cutting runtime activation/load lane | #68 / `agent/installed-runtime-activation-followup` |

## KEEP / FIX / REMOVE

- KEEP — W09 official REDmod output-path repair; the exact candidate completed real deployment.
- KEEP — W11/W12 controlled transition and evidence path.
- FIX — determine the first broken installed runtime load/register/attach boundary before resuming UI/presentation acceptance.
- DO NOT REMOVE/REDESIGN — #39/#40/#41 implementations merely because they are not currently visible; first prove whether they are loading/executing at all.

## Milestone disposition

**Rejected for live Biology acceptance.**

Reason: deployment/build preparation succeeded, but the exact attended runtime shows no material Biology-owned live surface.

## Next integration step

- Route #68 to fresh worker lane W13.1.
- Worker must use installed-game/runtime evidence to locate the first broken load/register/attach boundary and open a PR without asking the user to install/play the worker branch.
- Parent will retest one exact integrated release-shaped artifact after W13.1 returns and is reviewed/merged.
