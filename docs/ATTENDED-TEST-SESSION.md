# Canonical attended PC test session contract

Status: **mandatory owner workflow**  
Last updated: **2026-09-16**

This document defines what it means when the parent tells the project owner that a Biology build is **ready for PC testing**. It supersedes older attended flows that asked the owner to run several separate pre-launch probes, return evidence, wait for interpretation, launch the game, and then run separate post-launch probes.

## Core owner rule

`READY FOR PC TEST` has one operational meaning:

```text
ONE COMMAND -> QUIET LISTENER READY -> OWNER LAUNCHES GAME -> OWNER TESTS -> OWNER CLOSES GAME -> TYPE END IN SAME WINDOW -> ONE EVIDENCE HANDOFF -> CONFIRMED CLEANUP
```

The owner must not be asked to execute a chain of separate preparatory PowerShell probes before first launch merely to establish baselines that the attended-session tool itself can collect.

## 1. One user command starts the entire attended session

When the parent says a candidate is ready for PC testing, the parent supplies **one copy/paste command**.

That one command must be zero-local-repo-safe and exact-revision-pinned. It may internally:

- discover or acquire exact canonical source;
- create disposable repo/worktree state;
- build the exact release-shaped candidate when required;
- perform bounded fail-closed preflight checks;
- install/deploy the candidate when the attended scenario requires it;
- fingerprint the installed game/candidate/tooling;
- collect the pre-launch baseline needed for later comparison;
- start the attended-session listener.

Those are internal phases of one operator session, not separate commands for the owner to run and report one by one.

If internal preparation cannot safely reach the launch-ready state, the session must stop before telling the owner to launch and must already contain enough diagnostics to explain the failure.

## 2. The PowerShell window remains open as a quiet listener

After successful preparation the command remains running in the same PowerShell window and prints a clear state such as:

```text
READY TO LAUNCH CYBERPUNK
Listener active. Leave this window open.
After you have exited the game, return here and type END.
```

The listener should be quiet by default. It may print important state transitions or a concise fatal condition, but it must not continuously spam the operator with logs.

The listener owns the before/after evidence boundary. It should capture, as relevant to the candidate under test:

- candidate/build/source identity;
- installed ownership receipt state;
- process start/exit observations;
- REDscript configured-output baseline and post-launch state;
- REDscript/current-log deltas;
- REDmod deployment/runtime evidence where relevant;
- bounded framework/game logs required to diagnose startup failure;
- timestamps/hashes needed to distinguish pre-launch from post-launch state;
- explicit test-session start/end markers.

This does not require every test session to collect every possible log. The tool should collect the smallest robust diagnostic set appropriate to the integrated candidate while being capable of explaining a launch failure without sending the owner through another manual preflight sequence.

## 3. The owner launches the game normally

The listener does **not** need to launch Cyberpunk itself unless a future explicit owner decision changes this contract.

The normal flow is:

1. one command reaches `READY TO LAUNCH CYBERPUNK`;
2. owner launches through the supported player path (normally REDlauncher/Steam with the requested mods state);
3. owner performs the attended in-game checklist;
4. owner exits Cyberpunk normally;
5. owner returns to the same PowerShell window.

If Cyberpunk fails to launch, crashes during startup, or exits before reaching usable gameplay, the listener must preserve the relevant startup/process/log evidence automatically. The owner should not have to run a separate diagnostic probe just to discover what failed.

## 4. `END` is the only normal session-finalization input

After the game is closed, the owner types:

```text
END
```

into the **same PowerShell window**.

`END` tells the listener to:

- stop listening;
- collect the final post-launch/post-exit state;
- compare it with the pre-launch baseline gathered by the same session;
- finalize all PASS/FAIL/partial evidence;
- package the one obvious handoff file for ChatGPT;
- report what will be cleaned;
- begin the evidence-confirmation handshake.

There should not be a second PowerShell command for a post-launch probe.

## 5. Evidence handoff and confirmation happen inside the same session

If evidence must be returned to the parent, the listener prints one obvious instruction such as:

```text
ATTACH THIS ONE EVIDENCE BUNDLE TO CHATGPT:
C:\Games\Biology-Operator-Evidence-<session-id>.zip
```

The session may then ask the owner to confirm that the bundle was successfully attached before it performs final deletion of the local handoff file. A simple prompt such as `TYPE SENT AFTER THE FILE HAS BEEN ATTACHED` is acceptable.

The owner should not have to remember a KEEP/delete list. The tool owns that lifecycle.

If evidence transfer has not been confirmed, the tool must not delete the only local copy of the handoff bundle.

## 6. Full END cleanup is tool-owned

After the owner confirms the required handoff was sent, the same running session performs its final cleanup and then prints a clear final state such as:

```text
SESSION ENDED CLEANLY
```

Final cleanup must remove the session's temporary/disposable material, including as applicable:

- temporary repo clone/worktree created for the session;
- temporary bootstrap/loader files;
- session-only staging/build directories;
- session-only local reports once their handoff has been confirmed;
- managed candidate artifact roots that are no longer required and whose identity is proven;
- other exact, tool-owned test residue created by the session.

Cleanup remains fail-closed and exact-path/identity bounded. It must never recursively guess at shared roots or delete foreign/ambiguous content.

The installed Biology candidate itself is **not automatically classified as disposable residue merely because the test session created/installed it**. Candidate removal/rollback is a separate explicit test-policy decision and must use the repository's ownership-safe uninstall/reset semantics. A session may perform such a rollback only when its attended contract explicitly says that the installed test candidate should be removed at END.

## 7. Launch failure is part of the same evidence path

The session listener must be designed so a failed launch is not followed by "now run this diagnostic command."

At minimum it should be able to correlate the launch attempt with the bounded evidence the project currently relies on, such as:

- whether the Cyberpunk process appeared and how/when it exited;
- current REDscript log and configured compiled-output state;
- new error/failure lines since session start;
- current REDmod/package identity;
- relevant loader/task-runner presence and state when part of the accepted runtime architecture;
- any repository-owned startup sentinel/probe state that can be gathered read-only.

If that evidence is insufficient to classify a new failure, the returned bundle should say exactly what remains unknown. The next diagnostic improvement belongs in repository tooling, not in a growing manual chain for the owner.

## 8. What `ready for PC testing` must not mean

The parent must not say a candidate is ready for the owner's PC and then provide a sequence like:

```text
run preflight command
attach report
wait for parent
run another probe
attach report
wait for parent
launch game
exit game
run post-launch command
attach another report
```

That pattern is retired for ordinary attended testing.

Repository/CI/static/exact-compile work should happen before the parent declares the candidate ready. Any local baselines still required for the actual attended launch belong inside the single listener session.

## 9. Exceptional diagnostic operations are still allowed, but are not the ready-to-test path

A dedicated read-only audit may still be requested when the project is **investigating why a candidate is not yet ready for testing**, or when maintaining game/reference contracts after a Cyberpunk patch.

That is different from a PC test handoff.

Language matters:

- `I need one diagnostic from your installation before I can make a candidate ready` = investigation, not ready-to-test.
- `This is ready for you to test` = one-command attended session under this document.

Do not blur those states.

## 10. Tooling requirement

The repository should expose a canonical attended-session bootstrap/entrypoint implementing this contract. Specialized test plans may configure what it watches and what attended checklist the parent asks the owner to perform, but they should reuse one session engine rather than inventing separate pre/post listener implementations per feature.

The session engine should be modular:

```text
exact source / candidate preparation
        +
pre-launch snapshot collectors
        +
quiet process/log listener
        +
post-exit collectors/comparators
        +
evidence bundle finalizer
        +
confirmed cleanup
```

There must be one source of truth for common session lifecycle behavior.

## 11. Relationship to older documentation

Where older command catalogs, historical handoffs, or test records describe multiple manual pre-launch/post-launch probes, preserve them as historical evidence only.

For future owner-facing attended tests, this document is the canonical interaction contract. `docs/LOCAL-OPERATOR-COMMANDS.md`, `docs/CLEAN-ROOM-TESTING.md`, parent handoffs, and CI contracts should be kept aligned with it.
