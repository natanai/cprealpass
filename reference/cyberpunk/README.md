# Local Cyberpunk installation snapshots

This directory contains machine-generated, GitHub-safe descriptions of the Cyberpunk 2077 installation used to develop RealPass. It never contains the actual game archives, executables, DLLs, textures, audio, meshes or other proprietary assets.

## Two snapshot roles

### Current observed installation

The files at this directory root describe the installation observed when `tools/Refresh-LocalGameReference.ps1` last ran:

- `environment.json` — game version, generation timestamp, and high-level counts
- `filesystem-index.csv` — relative paths, extensions and sizes
- `archives.csv` — installed REDengine archive containers
- `frameworks.json` — presence of major modding frameworks
- `red4ext-plugins.json` — installed RED4ext plugin names/versions
- `installed-scripts.csv` — loose script files
- `archive-payloads.csv` — loose payloads under `archive\pc\mod`

This snapshot may describe vanilla or a RealPass-installed test environment. Git history is the running archive of these observations.

Refresh it with:

```powershell
pwsh ./tools/Refresh-LocalGameReference.ps1
```

### Known-clean vanilla baseline

`vanilla-baseline/` is different. It is captured only from a deliberately clean vanilla installation and contains a strict path/size/SHA-256 inventory used to detect leftover or modified game files before another attended iteration.

Capture and publish a clean baseline with:

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 -Publish
```

That command pushes a dedicated `local-vanilla-baseline-*` branch containing only this GitHub-safe metadata. Give the branch name to a remote agent for review/merge.

Compare a reused installation against the baseline with:

```powershell
pwsh ./tools/Compare-GameToVanillaBaseline.ps1
```

For the full iteration-vs-milestone test policy, see `docs/CLEAN-ROOM-TESTING.md`.

## Remote-agent procedure

If repository metadata does not answer an important game-internal question:

1. identify the smallest evidence needed;
2. prefer direct installed-game evidence over an old web example when practical;
3. give the user one copy/paste-ready read-only command using the known paths in `AGENTS.md`;
4. request only the narrow output needed;
5. preserve durable conclusions in code/docs/tests/metadata.

The local machine also has a gitignored read-only bridge at `game-reference\live` and a safe temporary extraction area at `game-reference\extracted`. Those are not mirrored to GitHub.

## Stability rule

Prefer semantic native contracts, named APIs/events/records and small compatibility adapters over copied implementation bodies, hard-coded offsets, incidental widget indexes or other patch-local details. If a version-sensitive seam is unavoidable, isolate and validate it.
