# Biology parent/worker thread ledger

Status: **canonical active conversation/lane registry**  
Last updated: **2026-09-15**

> **MANDATORY:** Read this file before creating a new worker thread, reusing an old thread, replacing a thread that has become too long, or handing parent/orchestrator responsibility to a new conversation.

The repository is the durable source of truth. Git issues/branches/PRs track code state; ChatGPT conversations carry temporary working context attached to a lane.

## Core rule

**A clear new goal should normally get a new lane/thread, even when an older usable conversation exists.**

An older `USABLE` thread is a context reserve, not the default destination for new work. Reuse it only when its existing context is directly useful to a true continuation of the same goal.

When the user reports that a thread is becoming too long, treat that as an orchestration event: update this ledger, stop treating that conversation as the active working surface, and create a replacement thread/handoff before continuing substantial work there.

## Lane IDs vs thread instances

A **lane** is the durable workstream/goal. A **thread instance** is one ChatGPT conversation carrying that lane at a particular time.

```text
P01.1   parent/orchestrator lane P01, first conversation instance
P01.2   same parent/orchestrator lane after the first parent thread becomes too long
W06.1   worker lane W06, first conversation instance
W06.2   same worker goal moved to a replacement conversation
W07.1   a genuinely new worker goal/lane
```

Rules:
- `P##` = parent/orchestrator lane.
- `W##` = worker lane.
- `.1`, `.2`, `.3`, ... = conversation generation for the same goal.
- A thread becoming too long increments only the generation when the same lane continues.
- A materially new goal gets a new base lane ID.
- Branch and issue numbers remain the implementation identifiers; thread IDs track conversation continuity.

## Recommended ChatGPT thread title

```text
[P01.2] PARENT — Integration Orchestrator
[W06.1] INTEGRATION — Exact-Compile Repair
[W05.1] RELEASE — Player Disable / Uninstall
```

Existing conversations do not need retroactive renaming; this ledger maps their visible title/alias to the official ID.

## Thread-state vocabulary

`ACTIVE`
: The conversation is currently receiving ongoing work.

`USABLE`
: The conversation is not actively assigned work, but its existing context may help with a direct continuation. **Do not prefer it over a fresh lane for a new goal.**

`TOO-LONG`
: The user has reported the conversation has become too long or unwieldy. Do not continue substantial work there.

`RETIRED`
: Do not route new work into this conversation.

## Lane-work-state vocabulary

`IN-PROGRESS`
: Work is actively underway.

`WAITING`
: Temporarily waiting on another lane, user evidence, or an integration decision.

`READY-PARENT`
: Worker implementation is complete enough to return to the parent for review/integration; remaining attended/integration acceptance may still be pending.

`BLOCKED`
: A concrete blocker prevents safe progress.

`MERGED`
: The lane's implementation is represented on canonical `main`.

`SUPERSEDED`
: Another lane now owns the work.

`CLOSED`
: The lane's assigned goal is complete without further implementation.

## Current ledger

| Thread ID | Current visible title / alias | Role / goal | Thread state | Lane work state | GitHub / branch | Parent routing note |
|---|---|---|---|---|---|---|
| **P01.2** | `[P01.2] PARENT — Integration Orchestrator` | Parent / integration orchestrator | **ACTIVE** | **IN-PROGRESS** | Issue #35; read `docs/handoffs/PARENT-P01.2.md` first | Successor to P01.1. W09-W12 are merged; W09 official REDmod recovery has now attended-PASSed. Exact canonical candidate `68b50ed9...` built/installed/deployed successfully, but attended launcher-ON play showed no material Biology effect. P01.2 routed that cross-cutting runtime activation/load failure to W13.1 and is waiting for worker evidence/repair before resuming #39/#40/#41 acceptance. |
| **W13.1** | `[W13.1] RUNTIME — Installed Biology Activation Follow-Up` | Find and repair the first installed runtime load/register/attach boundary causing an exact deployed candidate to have no material Biology live effect | **ACTIVE** | **IN-PROGRESS** | Issue #68; `agent/installed-runtime-activation-followup`; handoff `docs/handoffs/W13-INSTALLED-RUNTIME-ACTIVATION-FOLLOWUP.md` | Exact candidate from `68b50ed9e3c629ca252326918dbbb68b9bc35494` built, installed and REDmod-deployed successfully, yet screenshots show ordinary CYBERWARE hub/screen and vanilla/current gameplay. Worker must prove the earliest broken runtime boundary before any downstream UI/E3 redesign. |
| **P01.1** | `PARENT 1` | Parent / integration orchestrator | **TOO-LONG** | **CLOSED** | Issue #35 | Predecessor parent. User reported this conversation was becoming too long on 2026-09-15. Do not continue substantial orchestration here; use P01.2 and the durable handoff. |
| **W12.1** | `[W12.1] RELEASE — Operator Bootstrap Hardening` | Worktree-aware/local-first operator bootstrap hardening plus repository-owned post-W11 canonical candidate preparation | **USABLE** | **MERGED** | Issue #66 closed completed; PR #67 merged; `agent/operator-bootstrap-hardening`; worker head `bc1ba45b9ca4625f32b91de3caee8157f9531d3d` | Command 13 is now the supported post-transition candidate path. It pins exact main + reviewed W11 cleanup evidence, handles native stderr by exit/acceptance semantics, supports linked worktrees and exact cached-origin fallback, retains artifact/evidence outside disposable repo state, and stops before game launch. Parent owns attended execution. |
| **W11.1** | `[W11.1] RELEASE — Legacy Framework Transition Cleanup` | Safely retire pre-W10 Mod Settings / ArchiveXL / RED4ext residue before the next attended candidate | **USABLE** | **MERGED** | Issue #64 closed; PR #65 merged; `agent/pre-w10-framework-transition-cleanup`; worker head `052888059bb2f1e75a64804494d302ced6b51e9f` | Attended cleanup PASSed: all 42 approved retired framework files were deleted, all five protected redscript files were reverified, shared roots were preserved, and the legacy preference file was intentionally untouched. The old Biology package was then hard-uninstalled and `Verify-BiologyRemoval.ps1` PASSed. |
| **W10.1** | `[W10.1] SETTINGS — Self-Contained Provider` | Remove Biology's Mod Settings reliance and replace the public preference surface with Biology-owned persistence; remove unused settings-stack dependencies | **USABLE** | **MERGED** | Issue #61; PR #63 merged; `agent/self-contained-settings-provider`; worker head `134ae11a20d8ae432686a7711cbb72f70e006fa6` | Mod Settings, ArchiveXL and RED4ext are removed from production package/acquisition/install architecture; redscript is the only retained generic runtime dependency. REDlauncher/REDmod is sole whole-mod activation. One save-backed E3 preference is edited from Biology-owned body UI. Attended persistence/launcher-off acceptance remains parent-owned. |
| **W09.1** | `[W09.1] REDMOD — Post-Uninstall Deploy Recovery` | Repair official REDmod 2.31 post-uninstall/reinstall output/cache-state failure | **USABLE** | **MERGED** | Issue #59 closed completed; PR #62 merged; `agent/redmod-post-uninstall-deploy-recovery`; worker head `096cbf5d3a1e4f2b19ffc0509e1afcb70d76abaa` | Attended exact candidate at `68b50ed9...` proved the helper-created missing `r6/cache/modded` path allows official REDmod 2.31 to recognize Biology and complete all five deployment stages. Narrow W09 acceptance is complete. |
| **W08.1** | `[W08.1] REDMOD — Standalone Tweak Grammar Repair` | Determine and implement official REDmod 2.31 standalone tweak/package grammar for launcher activation authority | **USABLE** | **MERGED** | Issue #55 closed completed; PR #56 merged; `agent/redmod-standalone-tweak-grammar-repair`; worker head `f5e675586e4cbf46027a71bf530186ba13591956` | Attended official REDmod no longer reported the prior `using` parser error and progressed to generated TweakDB output writing. Narrow grammar issue accepted. |
| **W07.1** | `[W07.1] REDMOD — Activation Sentinel Repair` | Repair REDmod-owned launcher activation sentinel after attended TweakDB compile failure | **USABLE** | **MERGED** | Issue #53 closed as superseded by #55; PR #54 merged; `agent/redmod-activation-sentinel-repair`; worker head `b0f98c4d6df006395aaf7b5e98ab2aac2c4a1210` | Worker repair and generalized operator-probe hardening are on main. Reuse only as context if this exact topic returns. |
| **W06.1** | `Lane - INTEGRATION EXACT-COMPILE REPAIR` | Cross-lane exact-compile repair for integrated attended follow-ups | **USABLE** | **MERGED** | Issue #50 closed; PR #52; `agent/integration-exact-compile-repair`; repaired head `8f533d8451d2a894fe3ead0eed05ac0adefb69a0` | Parent exact compile passed on integrated runtime head `1a97607332bb6237fb7516b35d1a292403fb2740`; repair is on main through PR #49. |
| **W05.1** | `Lane - PLAYER DISABLE / UNINSTALL ARCHITECTURE` | Launcher-off vanilla behavior + self-contained Biology uninstaller | **USABLE** | **MERGED** | Issue #44; PR #45 closed as superseded by integration; `agent/player-uninstall-vanilla-toggle` | Player-facing hard uninstall and Biology-specific residue verifier attended-passed. Launcher-OFF final acceptance remains open, but meaningful ON/OFF comparison is blocked until W13 restores material launcher-ON Biology runtime activity. |
| **W03.1** | `Thread 3 — E3 HUD, NPC nameplates, presentation settings` | E3-inspired neutral HUD + ambient NPC nameplates | **USABLE** | **MERGED** | Issue #40; PR #46 closed as superseded by integration; `agent/presentation-attended-followup` | Implementation is on main through PR #49. Issue #40 stays open for attended E3/nameplate/scanner acceptance after W13 restores live Biology runtime activation. |
| **W04.1** | `ATTENDED RUNTIME-AUTHORITY FOLLOW-UP` | Authoritative live Biology body runtime/session ownership | **USABLE** | **MERGED** | Issue #41; PR #47 closed as superseded by integration; `agent/body-runtime-attended-followup` | Implementation plus W06 compile repair are on main. Issue #41 stays open for attended live-runtime acceptance after W13 restores load/register/attach. |
| **W02.1** | `Thread 2 — Biology UI and body runtime` | Biology native Cyberware shell/drill-down/back/mode-state follow-up | **USABLE** | **MERGED** | Issue #39; PR #43 closed as superseded by integration; `agent/biology-ui-attended-followup` | Implementation is on main through PR #49. Issue #39 stays open for attended shell/navigation acceptance after W13 restores live Biology runtime activation. |
| **W01.1** | `Thread 1 — REDmod foundation` | Original REDmod package/deployment foundation | **USABLE** | **MERGED** | Issue #28; PR #31; historical branch `agent/redmod-foundation` | Foundation work is already on main. A new distinct REDmod goal should normally receive a new W## lane. |

## Current integration relationship

```text
P01.2 parent
  |
  +-- canonical main contains integrated shell/runtime/presentation/uninstaller work
  +-- W07/W08 activation grammar MERGED; W08 parser acceptance observed
  +-- W09 / PR #62 MERGED; issue #59 CLOSED after attended exact-candidate deploy PASS
  |     `-- deploy helper prepares only missing r6/cache/modded before official REDmod deploy
  +-- W10 / PR #63 MERGED
  |     `-- Mod Settings + ArchiveXL + RED4ext removed from production; redscript-only supplemental runtime
  |     `-- sole in-game public preference is save-backed E3 HUD/nameplates Boolean in Biology-owned UI
  +-- W11 / PR #65 MERGED; issue #64 CLOSED; attended cleanup PASS
  |     `-- 42 exact retired framework files deleted; five redscript paths preserved/reverified
  |     `-- shared roots preserved; old Biology subsequently hard-uninstalled
  |     `-- canonical Biology-specific residue verifier PASS
  +-- W12 / PR #67 MERGED; issue #66 CLOSED
  |     `-- Command 13 produced exact release artifact from canonical 68b50ed9...
  |     `-- exact install receipt matched source and official REDmod deployment PASSed
  +-- W13 / issue #68 ACTIVE
  |     `-- attended launcher-ON screenshots show ordinary CYBERWARE hub/screen and current/vanilla gameplay
  |     `-- no material Biology runtime/UI/presentation effect despite successful build/install/deploy
  |     `-- worker owns first broken installed load/register/attach boundary only
  |
  +-- next parent gate: review W13 evidence/repair and merge if sound; then build/install/deploy one new exact canonical candidate and prove Biology is materially active before resuming downstream acceptance
  +-- issue #44 remains open for launcher OFF + reinstall-after-uninstall reliability
  +-- issues #39/#40/#41 remain open for attended UI/runtime/presentation acceptance after W13
```

One worker lane is currently active: **W13.1**. Merged worker conversations remain context reserves only. Do not route new downstream UI/presentation work until W13 establishes whether the Biology runtime is loading and attaching at all.

## Creating a new lane/thread

Before giving the user a new worker handoff:
1. Check this ledger for a truly matching active lane.
2. Decide whether the task is a continuation or a new goal.
3. Prefer a **new W## lane** when the goal is materially new, an old branch is merged/closed, or the old conversation has stale/overgrown context.
4. Assign the next unused base ID.
5. Add the new row here with `ACTIVE / IN-PROGRESS` before or alongside the handoff.
6. Put the official ID in the handoff and recommended chat title.
7. Record branch, issue, base/head state and merge dependency.

## Reusing a `USABLE` thread

Reuse is appropriate only when all of the following are true:
- the goal is genuinely the same/substantially continuous;
- existing conversation knowledge materially reduces rediscovery;
- existing branch/issue ownership still fits;
- the conversation has not been marked `TOO-LONG`;
- the parent explicitly routes work back there or the user specifically chooses it.

Otherwise create a new lane.

## When the user says a thread is too long

1. Change that row's thread state to `TOO-LONG`.
2. Keep the old row as the continuity record.
3. For the **same ongoing lane**, create the **next generation** (`W06.2`, `P01.2`, etc.).
4. Add the successor row with `ACTIVE` and record the predecessor.
5. Provide a self-contained handoff with current branch/head, issue/PR, completed work, blockers, evidence and next action.
6. If the work goal itself changed, assign a fresh `W##` instead of `.2`.
7. Mark the predecessor `RETIRED` later if its context is no longer useful.

The parent follows the same rule: `P01.1 -> P01.2` is a routine continuity event, not an emergency reconstruction from chat memory.

## Parent maintenance requirement

The parent owns this ledger. Update it whenever:
- a worker thread is created;
- a thread becomes active/inactive;
- a worker returns `READY-PARENT`;
- a lane is blocked, closed, superseded or merged;
- the user reports a thread is too long;
- a replacement conversation is created;
- work is deliberately routed back to a `USABLE` thread;
- a new parent thread takes over.

A parent handoff is incomplete if this ledger does not accurately identify the active parent and active workers.

## Worker responsibility

Workers read this ledger through `docs/PARALLEL-AGENT-WORKFLOW.md` and their handoff. A worker should not self-reactivate an old lane or absorb a new goal merely because related context exists in its conversation.

When reporting completion, include the official thread ID so the parent can update `READY-PARENT`, `CLOSED`, `MERGED`, `SUPERSEDED`, etc.

## Relationship to GitHub state

This ledger does not replace issues, PRs, branches, `ROADMAP.md`, or test records.

Use:
- this file for conversation/lane continuity and thread usability;
- GitHub issues for scope/acceptance;
- branches/PRs for implementation state;
- `ROADMAP.md` / active roadmap for product work state;
- `docs/test-runs/` for attended evidence.

If the ledger and GitHub disagree about code state, GitHub is authoritative for the code and the parent must repair this ledger.