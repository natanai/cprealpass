# Agent Instructions

This repository is developed against a real local Cyberpunk 2077 installation, but GitHub-hosted agents **cannot access that installation directly**. Do not assume that missing vanilla game files in Git means they are unavailable for investigation.

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

## Remote-agent protocol

GitHub/branch agents are explicitly allowed to ask the user to run PowerShell or CMD commands when direct evidence from the installed game would materially improve the work.

When requesting a local command:

1. Prefer a single copy/paste-ready PowerShell block.
2. Use the known absolute paths above so the user does not need to navigate folders or substitute placeholders.
3. Make the command read-only whenever possible.
4. State exactly what output is needed and why it resolves the current uncertainty.
5. Keep requests targeted; do not ask the user to bulk-export or unpack the whole game.
6. If output is large, filter it before asking the user to paste it back.
7. Prefer derived evidence such as file paths, hashes, record names, class/function names, tool output, metadata, or narrow text extracts over copying proprietary game assets into Git.
8. Never ask the user to commit vanilla archives, textures, audio, meshes, executables, DLLs, or other proprietary game files.

If archive-level inspection is needed, WolvenKit CLI may be available on the user's machine. Do not assume it is installed; if necessary, first ask the user to run:

```powershell
wolvenkit.cli --help
```

Then provide the exact selective inspection/extraction command needed for the task. Avoid bulk extraction unless there is a strong technical reason.

## Investigation principle

Before creating a parallel RealPass system, investigate whether Cyberpunk already exposes an appropriate native mechanism: player state, stat, status effect, TweakDB record, event, controller, inventory/equipment behavior, UI component, animation/state machine, interaction, consumable behavior, cyberware hook, or other existing game system.

Prefer extending or integrating with native systems when that produces a more faithful and maintainable result. The local game installation is available as an evidence source through the user even when the remote agent cannot read it directly.

## Current local snapshot

As reported from the user's installed game on 2026-09-14:

- Cyberpunk 2077 version: `2.31`
- Installed files indexed locally: `5,128`
- REDengine `.archive` containers found: `59`

Treat these counts as a dated snapshot, not permanent assumptions. Ask for a fresh local check if a task depends on current installation state.

For the detailed workflow and rationale, see `docs/LOCAL-GAME-REFERENCE.md`.
