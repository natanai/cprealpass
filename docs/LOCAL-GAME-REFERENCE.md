# Local Cyberpunk Game Reference

## Purpose

Remote GitHub agents working on this repository do not have direct filesystem access to the user's installed copy of Cyberpunk 2077. However, the user's local repository has been connected to the real game installation through a gitignored reference area, and the user is willing to run PowerShell or CMD commands when an agent needs direct evidence from the installed game.

This creates a practical bridge between branch-based GitHub work and the actual game files without committing Cyberpunk-owned content to the repository.

## Local layout

Current Windows layout:

```text
C:\Games\CyberpunkRealism
├─ game-reference\
│  ├─ live\        -> junction to installed Cyberpunk 2077
│  ├─ index\       -> generated local file/archive indexes
│  ├─ extracted\   -> safe workspace for selective vanilla extraction
│  └─ manifest.json
└─ ...tracked RealPass repository files...
```

The actual game installation is:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

The `live` directory is a junction, not a duplicate copy of the game. Any operation against it reaches the real installation, so it must be treated as read-only during investigation.

## What remote agents can do

A GitHub-hosted agent should proceed normally using repository code and documentation. When an implementation decision depends on facts that can only be established from the installed game, the agent may ask the user to run a targeted local command and return the output.

Good reasons to request a local check include:

- identifying the exact vanilla resource path for a UI element;
- confirming a class, function, event, stat, status effect, TweakDB record, or dependency exists in the installed version;
- inspecting how a vanilla consumable, inventory action, equipment rule, controller, or state machine is represented;
- checking installed framework or mod versions;
- examining logs produced by the real game;
- selectively extracting a specific resource from a REDengine archive when repository evidence is insufficient;
- confirming that a proposed hook matches the user's actual game version and installed environment.

Do **not** ask for local commands merely because local access exists. Use it when the result will materially reduce uncertainty or avoid inventing a parallel system unnecessarily.

## How to ask the user for evidence

The user prefers low-friction instructions. A request should therefore normally contain one copy/paste-ready PowerShell block with all known paths already filled in.

Prefer this style:

```powershell
# exact command(s), ready to paste
```

Avoid instructions such as "navigate to your game folder," "replace PATH with your path," or multi-step shell tutorials when the known absolute paths can be used directly.

If the command may produce substantial output, filter it locally first. Ask for the smallest useful result.

Examples of useful return data:

- relative paths;
- file names and extensions;
- hashes;
- tool/version output;
- matching symbol names;
- TweakDB record identifiers;
- class/function/event names;
- narrowly scoped textual output;
- file sizes/timestamps when relevant;
- error or game log excerpts relevant to the current issue.

## WolvenKit

Archive-level investigation may use WolvenKit CLI. Its availability should be verified before depending on it:

```powershell
wolvenkit.cli --help
```

If available, agents may give the user a selective `wolvenkit.cli` command targeting only the resource family needed for the current task and using:

```text
C:\Games\CyberpunkRealism\game-reference\extracted
```

as the output area.

Do not request extraction of the entire game by default. Large indiscriminate extraction creates noise, consumes substantial disk space, and provides less useful context to an agent than a targeted investigation.

## What belongs in Git

Appropriate repository additions derived from local inspection include:

- our own technical notes and conclusions;
- references to vanilla resource paths;
- class/function/record names needed to implement or explain integrations;
- small generated indexes or metadata that are genuinely useful and legally safe to redistribute;
- scripts that reproduce a local inspection or derive metadata;
- compatibility notes tied to a game version;
- tests or fixtures created by this project that do not reproduce proprietary game assets.

Do not commit:

- vanilla `.archive` containers;
- game executables or DLLs;
- textures, meshes, audio, videos, or other game assets;
- bulk decompiled/extracted game content;
- the `game-reference/` directory itself.

The repository should remain independently redistributable as RealPass source, documentation, tooling, and legally appropriate metadata—not as a mirror of Cyberpunk 2077.

## Design consequence for RealPass

The existence of this bridge should change how uncertain integration work is handled. If a feature appears to require a new simulation mechanism, first determine whether the vanilla game already has something close enough to extend.

For example, before building a new mechanism for a Biology feature, investigate the relevant vanilla player-state, status-effect, consumable, inventory, UI, animation, or event path. A native hook is generally preferable when it gives RealPass more coherent behavior and avoids duplicate state.

This does not mean every feature must reuse vanilla implementation. It means architectural decisions should be informed by the actual game rather than by assumptions when local evidence can be obtained cheaply.

## Safety rule

Inspection commands should be read-only by default. Commands that modify the installed game, delete files, rename files, overwrite archives, or write into `game-reference\live` require a separately justified task and explicit user awareness.

The safe working output area for vanilla investigation is:

```text
C:\Games\CyberpunkRealism\game-reference\extracted
```

Project changes themselves belong in the tracked RealPass source tree.

## Dated local snapshot

The user's setup reported the following on 2026-09-14:

```text
Cyberpunk version : 2.31
Indexed files      : 5128
Archive containers : 59
```

These values document the environment at that point in time. They should not be treated as permanent constants.
