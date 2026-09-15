# Local Cyberpunk installation snapshot

This directory contains a machine-generated, GitHub-safe description of the Cyberpunk 2077 installation used to develop Cyberpunk Realism / RealPass.

Generated: 2026-09-14 18:50:53 -05:00

Cyberpunk version: 2.31

## Purpose

Remote GitHub agents cannot directly access the user's Windows installation.

Use these files to understand the current local environment. If a question depends on vanilla Cyberpunk internals and this snapshot does not contain enough evidence, ask the user to run a targeted PowerShell, CMD, or WolvenKit command and return its output.

For questions about what the installed game actually contains, exposes, names, or does, **direct local evidence is preferred over web search**. Online documentation and community material are useful for tooling, release notes, background, and cross-checking, but they are not a substitute for inspecting the supported game build when a local check can answer the question more directly.

This is intentional: RealPass is meant to be a foundational, patch-resilient mod. Integration decisions should be based on stable native contracts and the actual supported game files rather than fragile assumptions copied from a particular guide, patch, or community implementation.

## Files

- `environment.json` — game version and high-level counts
- `filesystem-index.csv` — files visible in the installed game, relative paths only
- `archives.csv` — installed REDengine archive containers
- `frameworks.json` — presence of major Cyberpunk modding frameworks
- `red4ext-plugins.json` — installed RED4ext plugin names and available versions
- `installed-scripts.csv` — loose REDscript files currently installed
- `archive-payloads.csv` — loose `.archive` payloads currently present under `archive\pc\mod`; an empty file means no such payloads were found, **not** that no mods are installed

Cyberpunk mods can live in several game-root locations. `archive\pc\mod` is only the location for packed archive payloads; RealPass itself currently has deployed REDscript under `r6\scripts\CyberpunkRealism`.

## Important boundary

This repository does NOT contain the actual vanilla Cyberpunk archives, textures, audio, meshes, or other copyrighted game assets.

The user's local machine also has a private read-only game reference at:

    game-reference\live

and a safe temporary extraction location at:

    game-reference\extracted

Those paths do not exist for remote GitHub agents.

## Remote-agent procedure

If you need to know something about the installed game that is not represented here:

1. Identify exactly what evidence would resolve the question.
2. Before substituting an internet search for that evidence, ask whether the installed game can answer it more directly.
3. Give the user ONE copy/paste-ready PowerShell or CMD command.
4. Use the known local paths documented in `AGENTS.md`; do not make the user substitute placeholder paths.
5. Prefer read-only inspection.
6. Ask for the resulting output.
7. Record durable conclusions, stable symbols/contracts, and any reproducible probe in tracked project documentation or tooling when useful.

Do not invent a parallel RealPass mechanism merely because vanilla internals are not visible from GitHub.

## Stability rule

Prefer integration points that are likely to survive ordinary game patches: public/native script contracts, semantic classes and systems, stable record relationships, named events, and narrow adapters around unavoidable version-sensitive details.

Avoid unnecessary dependence on hard-coded offsets, memory addresses, copied implementation bodies, incidental UI hierarchy, exact file ordering, or other patch-local details. If a brittle seam is unavoidable, isolate it, document why it exists, and make failure obvious rather than silently falling back to incorrect behavior.
