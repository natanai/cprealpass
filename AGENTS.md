# Agent Instructions

This repository is developed against a real local Cyberpunk 2077 installation, but GitHub-hosted agents **cannot access that installation directly**. Do not assume that missing vanilla game files in Git means they are unavailable for investigation.

RealPass is intended to be a foundational, long-lived realism layer. Ordinary Cyberpunk patches should not break it unless CDPR changes a genuinely relevant underlying contract. That goal affects how evidence is gathered and how integrations are designed.

## Evidence hierarchy for Cyberpunk internals

For questions about **what the supported game build actually contains, exposes, names, calls, or does**, use this order of evidence:

1. repository-owned code, tests, generated reference metadata, and already-recorded local evidence;
2. direct inspection of the user's installed Cyberpunk build through a targeted local PowerShell/CMD/WolvenKit request;
3. official tool/framework documentation and game release notes;
4. web/community guides, examples, forum posts, and other secondary material.

**Do not use an internet search as a substitute for direct game evidence when a small local inspection can answer the question more authoritatively.** Web research is still appropriate for tooling documentation, release history, known framework behavior, broader context, and cross-checking.

If implementation correctness depends on a vanilla class, event, record, resource path, controller, callback, script signature, state-machine path, or other game-internal fact and the repository snapshot is insufficient, ask the user for local evidence before guessing or copying a web example.

## Local game access available through the user

The user's current Windows paths are:

- Repository / mod workspace: `C:\Games\CyberpunkRealism`
- Cyberpunk 2077 installation: `C:\Games\Steam\steamapps\common\Cyberpunk 2077`
- Local read-only game junction: `C:\Games\CyberpunkRealism\game-reference\live`
- Local safe extraction workspace: `C:\Games\CyberpunkRealism\game-reference\extracted`
- Local generated indexes: `C:\Games\CyberpunkRealism\game-reference\index`

`game-reference/live` is a Windows directory junction to the actual installed game. Treat it as **read-only**. Never instruct the user to edit, delete, rename, overwrite, or repack files there unless a task explicitly requires a carefully justified game-install modification.

`game-reference/extracted` is the preferred local output location for selectively extracted vanilla resources used for investigation.

The entire `game-reference/` tree is intentionally excluded from Git and is not visible to remote agents.

A GitHub-safe snapshot of the local environment is tracked under `reference/cyberpunk/`. Read that snapshot before assuming which frameworks, deployed scripts, archive payloads, or game files are present.

For a broad environment refresh after a Cyberpunk patch or major local install change, ask the user to run this tracked read-only scanner:

```powershell
& "C:\Games\CyberpunkRealism\tools\Refresh-LocalGameReference.ps1"
```

That command reads the game installation and rewrites only the GitHub-safe metadata under `reference/cyberpunk/`; it does not modify game files or commit/push anything. For a narrow implementation question, prefer a smaller targeted probe instead of refreshing or extracting everything.

## Remote-agent protocol

GitHub/branch agents are explicitly allowed—and expected when useful—to ask the user to run PowerShell or CMD commands when direct evidence from the installed game would materially improve the work.

When requesting a local command:

1. Prefer a single copy/paste-ready PowerShell block.
2. Use the known absolute paths above so the user does not need to navigate folders or substitute placeholders.
3. Make the command read-only whenever possible.
4. State exactly what output is needed and why it resolves the current uncertainty.
5. Keep requests targeted; do not ask the user to bulk-export or unpack the whole game.
6. If output is large, filter it before asking the user to paste it back.
7. Prefer derived evidence such as file paths, hashes, record names, class/function names, tool output, metadata, or narrow text extracts over copying proprietary game assets into Git.
8. Never ask the user to commit vanilla archives, textures, audio, meshes, executables, DLLs, or other proprietary game files.
9. When the result establishes a durable architectural fact, record that conclusion in tracked docs/code/tests so future agents do not need to rediscover it from the web.

If archive-level inspection is needed, WolvenKit CLI may be available on the user's machine. Do not assume it is installed; if necessary, first ask the user to run:

```powershell
wolvenkit.cli --help
```

Then provide the exact selective inspection/extraction command needed for the task. Avoid bulk extraction unless there is a strong technical reason.

## Patch-resilience design rule

Treat patch resilience as an architectural requirement, not a cleanup task.

Prefer, in roughly this order:

- semantic game systems and native/script APIs over implementation accidents;
- named classes, events, records, stats, and stable relationships over magic values;
- existing vanilla state and lifecycle ownership over duplicated RealPass shadow state;
- narrow adapters around game-facing seams over spreading game-version assumptions through the simulation core;
- runtime discovery/validation where practical over hard-coded assumptions;
- fail-closed or loudly detectable incompatibility over silent incorrect behavior.

Avoid unnecessary reliance on:

- hard-coded memory offsets or addresses;
- copied/decompiled vanilla implementation bodies;
- exact line numbers or incidental file ordering;
- brittle widget-tree positions or incidental UI hierarchy when a semantic controller/event exists;
- patch-specific timing assumptions without a stable lifecycle reason;
- duplicated state that can drift from a vanilla authority;
- third-party mod behavior when RealPass can integrate directly with the underlying game contract.

If a version-sensitive seam is unavoidable, isolate it behind the smallest practical adapter, document the evidence used to select it, add a validation/probe where feasible, and keep the rest of RealPass independent of that detail.

The desired failure mode after a future Cyberpunk patch is: a small compatibility seam detects a meaningful upstream contract change and can be repaired locally. The undesired failure mode is: patch-specific assumptions are scattered throughout the mod and silently produce incorrect simulation.

See `docs/PATCH-RESILIENCE.md` for the durable architecture policy.

## Investigation principle

Before creating a parallel RealPass system, investigate whether Cyberpunk already exposes an appropriate native mechanism: player state, stat, status effect, TweakDB record, event, controller, inventory/equipment behavior, UI component, animation/state machine, interaction, consumable behavior, cyberware hook, or other existing game system.

Prefer extending or integrating with native systems when that produces a more faithful and maintainable result. The local game installation is available as an evidence source through the user even when the remote agent cannot read it directly.

This does not mean RealPass should tightly couple itself to every vanilla implementation detail. The goal is the opposite: understand the actual game well enough to choose the **smallest, most semantic, most stable integration seam**.

## Current local snapshot

As reported from the user's installed game on 2026-09-14:

- Cyberpunk 2077 version: `2.31`
- Installed files indexed locally: `5,128`
- REDengine `.archive` containers found: `59`

Treat these counts as a dated snapshot, not permanent assumptions. Ask for a fresh local check if a task depends on current installation state.

For the detailed local-evidence workflow, see `docs/LOCAL-GAME-REFERENCE.md`.
