# RealPass agent instructions

Last updated: **2026-09-14 21:00 CDT (UTC-05:00)**

RealPass is a foundational Cyberpunk 2077 realism overhaul. The project is intentionally designed so ordinary game patches should affect a small compatibility boundary rather than force broad rewrites.

## TEST HANDOFF GATE — read before telling the user a build is ready to test

Every user-facing live-test handoff MUST explicitly classify the requested test as one of these two modes:

### 1. ITERATION TEST

Use this for focused feature/UI/gameplay iteration when there has been no game patch, framework/package-layout change, or other structural reason to distrust the existing vanilla baseline.

Rules:

- The local RealPass repository/workspace is disposable. **Use a fresh clone/download of current canonical `main` for every user-facing test build.** Do not ask the user to repair, switch, stash, or carry forward an old local worktree as the normal test path.
- A Cyberpunk reinstall is **not** required for every iteration.
- Reusing the game installation is allowed only when the previous RealPass test package is accounted for by its installed `realpass/build-manifest.json` and the game can be returned to the recorded vanilla baseline without unexplained extra or modified files.
- Use the baseline/reset tooling documented in `docs/CLEAN-ROOM-TESTING.md`. If the reset cannot prove the game is back at baseline, stop and escalate to a milestone clean-room test instead of layering another build over uncertain residue.
- Build and install the same game-root-shaped package intended for players. Do not use a long-lived developer deployment as the ordinary attended-test path.

### 2. MILESTONE CLEAN-ROOM TEST

Use this for large milestones, major structural/package changes, Cyberpunk patches, bundled framework changes, dependency changes, unexplained baseline drift, or any test where stale files could plausibly invalidate the result.

Rules:

- uninstall Cyberpunk 2077 in Steam;
- delete any residual `Cyberpunk 2077` game directory after uninstall;
- reinstall through Steam;
- optionally launch vanilla once and exit;
- capture/refresh the GitHub-safe vanilla baseline before adding RealPass;
- use a fresh clone/download of current canonical `main`;
- build a game-root-shaped RealPass test ZIP and merge it into the clean game exactly as a player would.

### Mandatory wording in a test handoff

Before saying “ready to test”, “launch it”, or equivalent, the agent must state:

1. **Test mode:** `ITERATION` or `MILESTONE CLEAN-ROOM`.
2. **Source state:** the exact `main` commit/revision being tested.
3. **Game-state evidence:** either “verified against recorded vanilla baseline” or why a milestone reinstall is required.
4. **Artifact:** the release-shaped ZIP/package being tested, not an accumulated repo/game state.

Do not casually instruct the user to reinstall Cyberpunk for every small change, and do not casually reuse an unknown modded game directory. The baseline exists specifically to distinguish those cases.

See `docs/CLEAN-ROOM-TESTING.md` before giving live-test instructions.

## Read order — do this before changing scope or architecture

1. `AGREED-GOALS.md` — **what the product is now**. Locked goals outrank old implementation notes.
2. `docs/DECISION-HISTORY.md` — **when decisions changed and which misunderstandings the user already corrected**.
3. The focused current architecture document relevant to the task, for example:
   - `docs/BIOLOGY-UI.md`
   - `docs/SETTINGS-ARCHITECTURE.md`
   - `docs/E3-PRESENTATION.md`
   - `docs/PATCH-RESILIENCE.md`
   - `docs/RELEASE-ARCHITECTURE.md`
   - `docs/CLEAN-ROOM-TESTING.md`
4. Machine-readable manifests/tests for the implementation contract.

Do **not** reconstruct current intent from old commits, closed branch workplans, or historical prototypes before reading the files above. Superseded handoff/status packets are intentionally removed from the current tree; Git history remains available when historical evidence is actually needed.

## Evidence hierarchy for Cyberpunk internals

For questions about what the supported game build actually contains, exposes, names, calls, stores, or does, use this order:

1. repository-owned code/tests and `reference/cyberpunk/`;
2. targeted direct inspection of the user's installed Cyberpunk build;
3. official game/framework/tool documentation and release notes;
4. web/community examples as secondary evidence.

**Do not use internet search as a substitute for a small direct game-file inspection when the installed build can answer the question more authoritatively.**

If correctness depends on a vanilla class, method, event, record, resource path, controller, callback, state-machine path, widget ownership rule, or other game-internal fact and the tracked snapshot is insufficient, ask the user for a targeted local probe instead of guessing.

## Local game access available through the user

Known Windows paths:

- repository/workspace: `C:\Games\CyberpunkRealism`
- Cyberpunk 2077: `C:\Games\Steam\steamapps\common\Cyberpunk 2077`
- read-only game junction: `C:\Games\CyberpunkRealism\game-reference\live`
- safe selective extraction area: `C:\Games\CyberpunkRealism\game-reference\extracted`
- local generated indexes: `C:\Games\CyberpunkRealism\game-reference\index`
- GitHub-safe derived snapshot: `reference\cyberpunk\`
- GitHub-safe vanilla baseline: `reference\cyberpunk\vanilla-baseline\`

`game-reference\live` points at the real game installation. Treat it as **read-only** during investigation. Never ask the user to edit/delete/rename/repack through that junction merely to inspect something.

The `game-reference/` tree is intentionally excluded from Git. Commit only redistribution-safe derived metadata, RealPass conclusions, compatibility probes, tests, and our own code/docs — never proprietary Cyberpunk archives, executables, DLLs, textures, audio, meshes, or bulk extracted content.

The tracked vanilla baseline contains only relative paths, sizes, hashes, version/timestamp metadata, and similar derived information. It must never contain the game files themselves.

## Preferred proactive compatibility audit

After a Cyberpunk patch, after a major local framework/install change, or before basing new foundational code on native seams, ask the user to run:

```powershell
Set-Location 'C:\Games\CyberpunkRealism'
pwsh ./tools/Audit-GameContracts.ps1
```

That audit is designed to be read-only against the game. It refreshes the GitHub-safe environment snapshot, fingerprints the important vanilla script/cache contracts, inventories every RealPass hook boundary, runs the native-seam policy check, and exact-compiles the project-owned REDscript candidate against the installed `final.redscripts`. It writes only repository-side metadata/reports.

A successful audit does **not** prove runtime semantics or UI rendering, but it gets ahead of signature/type/linkage breakage and gives future patches a concrete before/after fingerprint.

For a narrow implementation question, prefer a smaller targeted probe rather than repeatedly running a broad audit or unpacking large archives.

## How to ask the user for local evidence

When a local probe would materially improve the work:

1. give one copy/paste-ready PowerShell block;
2. use the known absolute paths above — no placeholders if they are unnecessary;
3. make it read-only whenever possible;
4. explain exactly what uncertainty it resolves;
5. filter large output locally before asking the user to paste it;
6. prefer paths, hashes, symbol names, record IDs, metadata, narrow text extracts, and tool output over proprietary file contents;
7. record durable conclusions in tracked code/docs/tests so another agent does not have to rediscover them.

If archive-level inspection is needed, WolvenKit CLI may be available. Do not assume it is installed. First request:

```powershell
wolvenkit.cli --help
```

Then ask for only the selective resource family needed. Avoid bulk extraction unless there is a concrete technical reason.

## Patch-resilience design rules

Prefer:

- semantic game systems and named APIs over implementation accidents;
- native lifecycle/state ownership over duplicated RealPass shadow state;
- named classes/events/records/stats over magic indexes or values;
- thin game-facing adapters around stable RealPass models;
- runtime discovery + validation when it is deterministic enough;
- exact compilation and explicit compatibility probes;
- fail-obvious/fail-closed behavior over silent incorrect simulation.

Avoid unless unavoidable:

- hard-coded memory offsets/addresses;
- copied/decompiled vanilla implementation bodies;
- exact line numbers or file ordering;
- brittle widget-child positions when a semantic controller/property exists;
- fixed delays standing in for lifecycle events;
- patch-specific assumptions scattered through the simulation core;
- another gameplay/presentation mod as an intermediary when the native game exposes the underlying contract.

If a version-sensitive seam is unavoidable, isolate it in the smallest adapter, document the evidence that justified it, and add a validation/probe where practical. A future patch should ideally break one compatibility seam loudly rather than alter body/combat logic silently.

See `docs/PATCH-RESILIENCE.md` and `manifest/native-seams.json`.

## Native-first investigation principle

Before creating a parallel RealPass mechanism, investigate whether Cyberpunk already exposes an appropriate native authority or lifecycle: inventory/equipment behavior, player state, stat, status effect, TweakDB record, event, controller, animation/state machine, interaction, consumable action, cyberware hook, UI shell, etc.

The goal is not to tightly couple the whole simulation to vanilla internals. The preferred shape is:

```text
stable RealPass simulation core
        |
        v
small semantic compatibility adapter
        |
        v
native Cyberpunk contract
```

## Attended testing uses fresh source and an explicit game-state tier

For **every user-facing attended build test**, use a fresh clone/download of canonical `main` and a generated game-root-shaped package.

The game itself has two valid tiers:

- **Iteration tier:** reuse the installed game only after removing the prior package by its installed manifest and proving the remaining files match the recorded vanilla baseline.
- **Milestone clean-room tier:** uninstall, delete residual game directory, reinstall, refresh/capture baseline, then apply the generated package.

Narrow read-only probes, exact compile checks, and focused debugging are not user-facing build tests and do not require a fresh repo or game reset when local residue cannot affect the answer.

Do not present `Prepare-OwnedSession.ps1 -Deploy` as the canonical user-facing acceptance path. It may remain useful for narrow developer investigation.

See `docs/CLEAN-ROOM-TESTING.md`.

## Current product rules agents most often get wrong

- Executing gameplay/presentation behavior must be RealPass-owned; Dark Future/Project E3 are reference only.
- RealPass is one authored simulation. Internal modules are not a public buffet of gameplay toggles.
- Mod Settings has exactly **two** editable booleans: global **Enable RealPass** and **E3 first-person HUD visuals**.
- With RealPass enabled, traditional actor HP bars/numbers are suppressed; master-off may restore native behavior.
- E3 visual language remains an explicit target even though the external Project E3 runtime is forbidden.
- The modern scanner/quickhack experience remains native.
- Backpack = possessions; Biology = embodied state; Cyberware = installed equipment.
- Biology stays inspectable while healthy. `STABLE`/quiet overview does not mean hidden nodes or no drill-down.
- User-facing test builds always come from fresh canonical source; milestone clean-room reinstall is periodic/structural, not required for every small iteration.
- The user does not want an extra RealPass-managed save-backup chain for ordinary development testing.

If any of those sound surprising, read `docs/DECISION-HISTORY.md` before changing them.

## Instruction hygiene

When the user corrects or changes a requirement:

- update `AGREED-GOALS.md` if the current product requirement changed;
- append the correction with a timestamp to `docs/DECISION-HISTORY.md`;
- update the focused architecture doc and contract/test that enforce it;
- remove obsolete active handoff/workplan/status instructions instead of leaving conflicting packets beside the canonical files;
- preserve history through Git, not by keeping misleading current-tree instructions.

Current supported local snapshot is dated, not permanent. As of the last tracked refresh on 2026-09-14 the installed game reported Cyberpunk 2077 `2.31`. Refresh/audit again whenever compatibility depends on a later local state.
