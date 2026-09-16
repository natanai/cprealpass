# W12.1 — operator bootstrap hardening and canonical candidate preparation

Status: **ACTIVE worker handoff**  
Parent: **P01.2**  
Issue: **#66**  
Branch: `agent/operator-bootstrap-hardening`

## Paste into the worker conversation

```text
[W12.1] RELEASE — Operator Bootstrap Hardening

Work on repo natanai/cprealpass.

This is worker lane W12.1.

Work ONLY on the already-created branch:

agent/operator-bootstrap-hardening

Issue:
#66 — Operator bootstrap hardening — worktree-aware local-first discovery and exact-head offline fallback

Parent:
P01.2

Branch base at creation:
<resolve current canonical main after this handoff commit>

At startup, resolve and report the exact current worker-branch head rather than assuming a stale SHA from chat text.

Do NOT merge your own PR.
Do NOT ask the user to install or play the worker branch.
Do NOT modify Biology runtime, body UI, E3 presentation, combat, physiology, scanner, or gameplay behavior.
Do NOT ask the user to reinstall Cyberpunk merely to work around operator tooling.
Do NOT assume any prior local cprealpass clone/worktree exists between user instructions.

READ FIRST:
- AGENTS.md
- AGREED-GOALS.md
- ROADMAP.md
- docs/THREAD-LEDGER.md
- docs/handoffs/PARENT-P01.2.md
- docs/handoffs/PARENT-INTEGRATION.md
- docs/INTEGRATION-ORCHESTRATOR.md
- docs/PARALLEL-AGENT-WORKFLOW.md
- docs/CLEAN-ROOM-TESTING.md
- docs/LOCAL-OPERATOR-COMMANDS.md
- docs/handoffs/W12-OPERATOR-BOOTSTRAP-HARDENING.md
- issue #66 and all current comments
- tools/Bootstrap-BiologyHardUninstallTest.ps1
- tools/Bootstrap-LegacyFrameworkTransitionProbe.ps1
- tools/Bootstrap-LegacyFrameworkTransitionCleanup.ps1
- tools/Prepare-BiologyMilestoneTest.ps1
- tools/Build-BiologyPackage.ps1
- tools/Deploy-BiologyRedmod.ps1
- tests/Test-LocalOperatorCommands.ps1

CURRENT ATTENDED STATE

The user's supported Cyberpunk 2077 / REDmod 2.31 installation has now completed the controlled pre-W10 transition:
1. W11 read-only probe proved 42 exact Mod Settings / ArchiveXL / RED4ext retirement candidates SAFE-TO-APPLY.
2. W11 cleanup then PASSed, deleting all 42 exact retired files and re-verifying all 5 protected redscript files.
3. The old Biology package was then removed through its player-facing `Uninstall Biology.exe`.
4. Canonical `Verify-BiologyRemoval.ps1` subsequently PASSed with exit code 0: no Biology-specific package/runtime residue remains.
5. Generic redscript remains intentionally preserved as shared infrastructure.
6. No new canonical W09+W10 candidate has been built or installed yet.

The parent then attempted to prepare the exact canonical candidate from main `b0b79b4adae66fb8ebf95e78768996a9d8650821` with a large ad-hoc interactive PowerShell block. It failed BEFORE build/install/deploy and did not mutate the game.

ATTENDED TOOLING FAILURE

Evidence report:
`Biology-Candidate-Prep-20260915-225136-7c702f02.txt`

Observed failures:
- `$ErrorActionPreference='Stop'` plus `2>&1` around `git clone` treated Git's ordinary `Cloning into ...` stderr as a terminating `RemoteException`; this is not a trustworthy native-process success/failure boundary.
- the large `try/catch/finally` block was pasted interactively; PowerShell accepted the `try/catch` statement before the later `finally` token, so `finally` was parsed as a command and failed.
- because `finally` did not execute, the disposable workspace was not auto-removed.

This is now explicitly tracked in issue #66. The worker must eliminate the need for another chat-authored orchestration block.

GOAL

Produce a repository-owned, zero-local-repo-safe operator path that can prepare the next canonical Biology candidate after an explicitly accounted transition state, with durable evidence and correct native-process handling.

The immediate parent use case is:
- old retired frameworks already removed by W11;
- old Biology package hard-uninstalled;
- Biology-specific residue verifier PASS;
- shared redscript intentionally remains;
- Cyberpunk itself was not freshly reinstalled for this transition;
- therefore the ordinary fresh-reinstall milestone branch in `Prepare-BiologyMilestoneTest.ps1` does not directly describe the current state, and a strict vanilla-baseline comparison would incorrectly reject intentionally preserved shared redscript.

REQUIRED DELIVERABLES

1. Add a repository-owned bootstrap/entrypoint for the post-transition candidate preparation path. It should:
   - require an exact canonical main SHA;
   - work from zero local cprealpass repo state;
   - use bounded local-first discovery when a valid checkout happens to exist;
   - never assume a previous clone/worktree survived;
   - create uniquely signed disposable workspace(s);
   - use `System.Diagnostics.ProcessStartInfo`/ArgumentList style child execution so stdout/stderr/exit code are captured without conflating normal native stderr with PowerShell exceptions;
   - exact-checkout the requested SHA and verify a clean candidate source;
   - exact-compile/build the release-shaped Biology package through `Build-BiologyPackage.ps1`;
   - place/retain the final ZIP somewhere outside the disposable repo so the user may immediately delete repo/worktree state;
   - compute/report exact artifact SHA-256 and byte size;
   - install that exact ZIP to the supported game root;
   - verify installed receipt/source revision matches the requested SHA;
   - deploy through `Deploy-BiologyRedmod.ps1` and preserve full child diagnostics;
   - stop before game launch;
   - generate one attachable `.txt` on success AND failure;
   - clearly identify what may be deleted immediately vs what must be kept for attended testing.

2. Account for the transition-state proof boundary instead of pretending this is a normal vanilla milestone reset. The tool must not claim full vanilla-baseline verification. It should require/record explicit parent-supplied transition evidence or otherwise fail closed if the state cannot be safely characterized.

3. Fold the broader issue #66 hardening into the canonical operator contract where in scope:
   - worktree-aware local-first discovery;
   - exact-head cached-origin fallback where safe;
   - no `.git/config`-only admission logic;
   - robust bootstrap-loader boundary;
   - no assumption of persistent local repos across instructions.

4. Update `docs/LOCAL-OPERATOR-COMMANDS.md` so the parent has one copy/paste-ready supported command/launcher rather than internal logic reconstructed in chat.

5. Add/adjust CI coverage in `tests/Test-LocalOperatorCommands.ps1` (and focused tests as needed) for:
   - native stderr that is nonfatal when exit code is 0;
   - success/failure report durability;
   - zero-existing-repo state;
   - disposable workspace cleanup semantics;
   - artifact retained outside disposable repo;
   - exact SHA pinning;
   - transition-state evidence classification;
   - worktree-aware discovery/offline fallback from issue #66.

6. Keep the installed game read-only in tests/fixtures. Do not ask the user to run the new operator tool until parent review/merge.

NON-GOALS

- no runtime feature changes;
- no REDmod activation redesign;
- no W09 cache/output redesign beyond invoking the existing helper;
- no W10 settings redesign;
- no weakening of hard-uninstall ownership safety;
- no full-game reinstall requirement merely to satisfy the operator harness;
- no deletion of preserved redscript;
- no broad scan outside the existing bounded `C:\Games` immediate-child discovery contract.

RETURN TO P01.2 WITH

- W12.1 identifier;
- exact final branch head;
- PR number;
- cloud CI result;
- exact files changed;
- operator command/launcher that P01.2 should give the user after merge;
- exact report filename contract;
- proof that normal Git stderr is not misclassified as failure;
- proof that the tool works without any pre-existing local repo;
- what evidence the parent must provide/approve for the current W11-transition state;
- confirmation that the game is not launched automatically and that worker branch testing is not requested.
```
