# Pre-W10 legacy framework transition

Status: **W11.1 transition contract**  
Issue: **#64**  
Target installed source: `7e61724071b8c95ba5c334ab9e8d11c43381c94e`

## Purpose

The preserved attended installation predates W10 and was built with Mod Settings 0.2.21, ArchiveXL 1.27.3, RED4ext 1.30.0, and redscript 0.5.31. Current production no longer ships or consumes Mod Settings, ArchiveXL, or RED4ext; current production still requires redscript.

This is a one-time transition path. It does **not** change the normal player uninstaller. `Uninstall Biology.exe` continues to preserve generic/shared dependencies because it cannot generally prove that another mod does not need them.

## Ownership rule

W11 never treats a framework directory as Biology-owned. The exact installed `biology/build-manifest.json` receipt is the file/hash authority.

A retired file is eligible for automatic deletion only when all of the following are true:

- the installed receipt is schema 2, product `Biology`, and names the exact attended pre-W10 source revision;
- the receipt records the file under owner `upstream:<component>` with `generic-dependency-shared` policy;
- the current file is a normal file, not a directory/reparse path;
- its current SHA-256 exactly matches the receipt;
- the tracked Cyberpunk 2077 2.31 vanilla baseline proves the path did not exist before Biology;
- current production metadata proves the component is retired and the `biology-runtime` profile is redscript-only;
- the bounded consumer scan finds no unreceipted, non-vanilla payload on the relevant mod/framework surfaces.

Changed retired files block the entire automatic cleanup. Missing retired files are reported as already absent and are not recreated or deleted. Any vanilla overlap blocks deletion.

## Consumer-safety rule

The probe compares files under the relevant mod/framework surfaces against both the tracked vanilla path set and the installed Biology receipt. An added file not accounted for by either is evidence that another mod/framework consumer may be present and therefore blocks automatic retirement.

The old Mod Settings preference file is a special case. The pre-W10 receipt intentionally identified `red4ext/plugins/mod_settings/user.ini` as preference state rather than package payload. W11 never deletes that file. If it contains a non-Biology INI section, that is treated as direct competing-consumer evidence and blocks cleanup. A Biology-only preference file may remain as inert historical state; W10 production does not read it.

Known generated RED4ext log/config residue is preserved rather than treated as package ownership.

## Redscript boundary

redscript is explicitly outside the deletion set. The probe inventories receipt-owned redscript paths as `PRESERVE`. The cleanup records their pre-cleanup hashes and re-verifies them after deletion so the transition cannot silently consume the retained runtime.

## Two-step operator contract

The read-only probe and the mutating cleanup are separate actions.

1. `Probe-LegacyFrameworkTransition.ps1` produces a text report plus a JSON plan containing the exact candidate deletion set and all evidence hashes.
2. `Remove-LegacyFrameworkTransition.ps1` requires that plan and its SHA-256, recomputes the full safety decision immediately before deletion, requires the evidence hashes and deletion set to be unchanged, re-hashes each file again immediately before removal, and then deletes only those exact files.

The mutator removes only now-empty descendant directories reached from deleted files. Shared/protected roots such as `red4ext`, `red4ext/plugins`, `r6`, `bin/x64`, `archive`, `mods`, `LICENSES`, and `biology` are never recursively deleted.

## Evidence boundary

Cloud tests prove the planner/executor safety semantics against fixtures. They do not prove the user's preserved install is safe to mutate. The branch-pinned read-only bootstrap must be run against that install before P01.2 authorizes the separate cleanup action.

Actual cleanup execution, the subsequent canonical-main W09+W10 candidate build/deploy, and gameplay acceptance remain P01.2-owned.
