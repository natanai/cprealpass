# 2026-09-15 — canonical-main REDmod retest failure

Status: **ATTENDED DEPLOY FAILURE — TweakDB parse grammar**

Parent: **P01.1**

Exact source:

`23d67435817cf4d546c88d51ea261332facce69c`

Game/tooling:
- Cyberpunk 2077 2.31
- REDmod product version 2.31
- REDmod SHA-256 `144DF5A984669528CD957B40BB2126FE83B73D66BD0E041CA614C80F74E76A7F`

Built artifact:

`biology-integrated-20260915-185904-23d67435817c.zip`

SHA-256:

`FFFE1CF33EFB5114F22FC8EA465C0B330F51C6A9845FD25E1D037395CA365615`

## Build evidence

The exact canonical-main package build passed:
- 119 owned-runtime policy checks;
- project REDscript exact compile: 61 sources;
- deployable runtime exact compile: 66 sources / 104 files;
- self-contained `Uninstall Biology.exe` compile;
- artifact policy: 117 files.

The installed sentinel was verified to contain the W07.1 repair:

```text
using Items
```

## Official REDmod result

REDmod recognized Biology and proceeded through script compilation:

```text
[DEPLOY] Stage 1/5 - Initialization
Found mod "Biology" (v0.1.0) in folder "Biology" (enabled; not deployed; TWEAKS; )
Needs deployment: true
[DEPLOY] Stage 2/5 - Script Compilation
[DEPLOY] Stage 3/5 - TweakDB Compilation
```

Official REDmod then rejected `biology_activation.tweak` during parsing:

```text
failed to parse file '...\biology_activation.tweak'

Parsing errors:
Line 15: Error while parsing file. Expected end of file but got: 'using'. File not parsed!
ERROR: TweakDB compilation has failed!
```

This is authoritative attended evidence that the standalone Biology tweak compilation unit does **not** accept the W07.1 top-level `using Items` form in this location/grammar.

It does **not** invalidate W07.1's separate source evidence that `IconicWeaponModAbilityBase` exists in CDPR's shipped 2.31 tweak source. It narrows the unresolved problem to standalone REDmod tweak package/import grammar or the need for a different official REDmod-owned activation signal.

## Operator-interface observation

The parent retest was initiated through a long ad-hoc PowerShell block. After the real REDmod failure had already been captured, the interactive console split the trailing `finally` block from its `try/catch`, producing a secondary `finally is not recognized` shell error.

That secondary error did **not** alter the REDmod result or artifact evidence, but the workflow violated the repository's canonical operator rule. Future parent/user retests must use a repository-owned bootstrap/entrypoint that writes one attachable `.txt` report on success and failure rather than a long freehand PowerShell workflow.

## Routing

Fresh follow-up:
- issue #55
- lane **W08.1 — REDMOD / Standalone Tweak Grammar Repair**

Gameplay acceptance remains paused. Do not retry the same package in REDlauncher and do not reinstall Cyberpunk merely because of this failure.
