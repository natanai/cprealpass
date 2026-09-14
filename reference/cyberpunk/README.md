# Local Cyberpunk installation snapshot

This directory contains a machine-generated, GitHub-safe description of the
Cyberpunk 2077 installation used to develop Cyberpunk Realism / RealPass.

Generated: 2026-09-14 18:50:53 -05:00

Cyberpunk version: 2.31

## Purpose

Remote GitHub agents cannot directly access the user's Windows installation.

Use these files to understand the current local environment. If information
inside the actual game archives is required, ask the user to run a targeted
PowerShell, CMD, or WolvenKit command and return its output.

Agents SHOULD ask for local evidence rather than guess when implementation
depends on vanilla Cyberpunk internals.

## Files

- environment.json — game version and high-level counts
- filesystem-index.csv — files visible in the installed game, relative paths only
- archives.csv — installed REDengine archive containers
- frameworks.json — presence of major Cyberpunk modding frameworks
- red4ext-plugins.json — installed RED4ext plugin names and available versions
- installed-scripts.csv — loose REDscript files currently installed
- installed-archive-mods.csv — archive mods currently installed

## Important boundary

This repository does NOT contain the actual vanilla Cyberpunk archives,
textures, audio, meshes, or other copyrighted game assets.

The user's local machine also has a private read-only game reference at:

    game-reference\live

and a safe temporary extraction location at:

    game-reference\extracted

Those paths do not exist for remote GitHub agents.

## Remote-agent procedure

If you need to know something about the installed game that is not represented
here:

1. Identify exactly what evidence would resolve the question.
2. Give the user ONE copy/paste-ready PowerShell or CMD command.
3. Use the known local paths documented in AGENTS.md; do not make the user
   substitute placeholder paths.
4. Prefer read-only inspection.
5. Ask for the resulting output.
6. Record durable conclusions in tracked project documentation when useful.

Do not invent a parallel RealPass mechanism merely because vanilla internals
are not visible from GitHub.
