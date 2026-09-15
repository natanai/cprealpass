# RealPass agent operating rules

This file is the first operational read for ChatGPT/Codex/other development agents working in this repository.

## Authority and precedence

1. Explicit newer user instructions override older repository text.
2. `AGREED-GOALS.md` is the canonical product-intent ledger.
3. `docs/PROJECT-STATUS.md` and `docs/ATTENDED-ACCEPTANCE.md` describe the current implementation/test path.
4. `docs/WORKLOG.md` is historical chronology. Older entries may describe superseded workflows and must not be treated as current policy when a later entry or current canonical document replaces them.

If an old tool, test, package note or worklog entry conflicts with the current owned-runtime path, fix or retire the stale artifact instead of reviving it.

## Nat's local Windows paths

- Repository checkout: `C:\Games\CyberpunkRealism`
- Cyberpunk 2077 game root: `C:\Games\Steam\steamapps\common\Cyberpunk 2077`

Do not assume the repository is `C:\Games\Cyberpunk`.

## Current local build/deploy path

Use `tools/Prepare-OwnedSession.ps1` for the current owned-runtime candidate.

- Without `-Deploy`: run checks, build/exact-compile, and preflight without modifying the game.
- With `-Deploy`: install the current owned payload and verify it.
- Do not use legacy source-mod-integrated attended/deployment workflows as the current operator path.
- Do not launch Cyberpunk unattended. The player launches the game normally through Steam after the tool reports ready.

## No RealPass-managed save backups

RealPass development/testing must **not create, require, recommend, or gate deployment on an extra save backup**.

Do not reintroduce `Backup-Saves.ps1`, save-backup directories, save-copy steps, or tests/contracts that require them. Save/reload remains an important gameplay-persistence test; that is separate from making filesystem backups of saves.

The current development recovery model is the flat RealPass-owned file record plus `Remove-OwnedRuntime.ps1`; Steam Verify Files or reinstall is the stock-game repair authority when needed.

## Local game knowledge

Agents working remotely on GitHub may ask Nat to run a focused PowerShell or Command Prompt command against the installed game when direct local file knowledge would be more reliable and durable than guessing or searching the web. Record useful stable findings in the repository so future agents can reuse them.

Keep patch-sensitive Cyberpunk hooks narrow and prefer direct installed-game evidence when a question depends on exact local game files or the supported game version.
