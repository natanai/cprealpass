# Biology local operator command catalog

Status: **canonical user-run command surface**  
Last updated: 2026-09-15

## Why this exists

The project owner can provide direct evidence from the supported local Cyberpunk 2077 installation, but that does not mean every agent should invent a new PowerShell block.

**Agents must reuse this catalog for routine local operations.** If a recurring operation is missing or awkward, improve the repository tool and this document first rather than repeatedly composing bespoke shell logic in chat.

One-off commands are still allowed for genuinely narrow, read-only investigation when no catalog command fits, but the agent must explain the uncertainty being resolved. If the same probe becomes useful more than once, promote it into `tools/` and add it here.

Canonical game root unless the user says otherwise:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

Attended-test source workspaces are disposable and milestone-specific. Do **not** assume `C:\Games\CyberpunkRealism` exists. Prefer:

```text
C:\Games\Biology-Test-<YYYY-MM-DD>-<short-main-sha>\
```

The user may delete that entire test workspace after the attended evidence has been returned to the parent integration thread.

---

## Command 0 — bootstrap a disposable milestone workspace when no repo exists locally

The parent supplies the exact canonical `main` SHA. Substitute only that SHA; do not add extra install/build logic around this block.

```powershell
$Sha = '<40-character canonical main SHA>'
$ShortSha = $Sha.Substring(0,8)
$Root = "C:\Games\Biology-Test-$(Get-Date -Format 'yyyy-MM-dd')-$ShortSha"
$Operator = Join-Path $Root 'operator'

if (Test-Path $Root) {
    throw "Milestone workspace already exists and must not be reused: $Root"
}

New-Item -ItemType Directory -Path $Root -Force | Out-Null
git clone https://github.com/natanai/cprealpass.git $Operator
if ($LASTEXITCODE -ne 0) { throw 'Clone failed.' }

git -C $Operator checkout --detach $Sha
if ($LASTEXITCODE -ne 0) { throw 'Exact main checkout failed.' }

pwsh "$Operator\tools\Prepare-BiologyMilestoneTest.ps1" `
  -MainSha $Sha `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -WorkspaceRoot $Root
```

`Prepare-BiologyMilestoneTest.ps1` owns the rest of routine milestone preparation. It:

1. verifies the operator clone is on the exact SHA;
2. asks whether the user wants the **exhaustive full-file/hash vanilla comparison**;
3. if the user declines, requires confirmation of a just-completed Steam uninstall + residual-directory deletion + reinstall, then runs only the fast sanity probe;
4. creates a second pristine `candidate` clone at the exact SHA;
5. builds the release-shaped Biology ZIP;
6. installs that exact ZIP into the game root;
7. deploys through official REDmod with explicit `-root`;
8. writes `milestone-prep.json` and prints concise evidence;
9. stops before game launch so the parent can issue the attended checklist.

The exhaustive hash check defaults to **No**. Skipping it after a fresh reinstall is allowed, but the evidence must say `exhaustive-hash-check-skipped`; an agent must never report that as “verified against recorded vanilla baseline.”

---

## Command 1 — fast vanilla sanity check

Use after a genuinely fresh Steam reinstall when an exhaustive whole-game hash comparison is unnecessary.

```powershell
pwsh ./tools/Test-VanillaGameSanity.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

It checks:

- supported Cyberpunk version;
- expected official REDmod executable/version;
- known loose-mod roots are empty of payload;
- `mods` contains no payload other than the stock zero-byte `.stub` marker if present.

It is deliberately **not** a proof that every vanilla file hash matches the tracked baseline.

---

## Command 2 — exhaustive vanilla baseline comparison

Use when residue is uncertain, when reusing a game install for iteration, or when the user explicitly chooses the stronger check.

```powershell
pwsh ./tools/Compare-GameToVanillaBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This checks paths, missing/extra files, sizes and SHA-256 hashes for the entire tracked baseline. Because it can take several minutes, it must show durable console progress in addition to `Write-Progress`.

Expected progress form:

```text
VERIFY [#######-------------]  35% | 1842/5200 files | 29.4/84.0 GiB | elapsed 00:01:42
```

---

## Command 3 — capture/publish a new vanilla baseline

This is **not a routine step for every milestone**. Use it when the tracked baseline needs to change: for example after a supported Cyberpunk patch or when the parent deliberately decides the clean reference itself must be refreshed.

Local capture only:

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

Capture and publish safe metadata on a dedicated branch:

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -Publish
```

This operation hashes the full game and therefore has durable `HASH [...]` progress output.

---

## Command 4 — build the release-shaped Biology package

From a pristine exact candidate checkout:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The builder exact-compiles the merged Biology runtime against the supported game before it emits a game-root-shaped ZIP. It does not install, deploy or launch the game.

For normal milestone preparation, prefer **Command 0**, which calls this correctly from a second pristine clone.

---

## Command 5 — deploy installed Biology through official REDmod

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This uses the directly evidenced official REDmod executable and explicit game root. Deployment success is not gameplay acceptance.

For normal milestone preparation, prefer **Command 0**, which invokes this automatically after installing the exact generated ZIP.

---

## Command 6 — reset an iteration install back to the tracked vanilla baseline

Use only when the package architecture/game version is unchanged and the installed Biology manifest is intact:

```powershell
pwsh ./tools/Reset-BiologyIteration.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This removes only exact manifest-owned files and then performs the strict full vanilla comparison. It fails closed to milestone clean-room if anything cannot be proven safe.

---

## Command 7 — direct compatibility audit

Use after a Cyberpunk patch/framework change or when a foundational native seam needs direct supported-install evidence:

```powershell
pwsh ./tools/Audit-GameContracts.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This is investigation evidence, not attended runtime acceptance.

---

## Command 8 — publish the current GitHub-safe game reference snapshot

Use when the current observed installation/framework state needs to be refreshed for remote agents:

```powershell
pwsh ./tools/Publish-LocalGameReferenceSnapshot.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

It publishes derived metadata only, never proprietary Cyberpunk payload.

---

## Rules for agents asking the user to run PowerShell

1. **Look here first.** If a catalog command covers the task, use it exactly rather than reconstructing its internals in chat.
2. Agents may substitute the exact main SHA, disposable test-root name, and known game path where the catalog explicitly permits it.
3. Do not paste the internals of a repository tool into chat merely to avoid invoking that tool.
4. Prefer one catalog entrypoint over a long chain of hand-written commands.
5. Long operations must expose durable console progress. `Write-Progress` alone is not sufficient because some hosts hide it.
6. Do not describe a fast sanity pass as a full baseline/hash verification.
7. After a freshly uninstalled/residual-directory-deleted/reinstalled game, let the user choose whether the additional exhaustive hash check is worth the time. Default is **No**.
8. Iteration cleanup on a reused install remains stricter: `Reset-BiologyIteration.ps1` must prove the return to the tracked baseline before layering another package.
9. If a command fails, return the failure output to the owning agent; do not improvise destructive cleanup commands.
10. If an operation becomes recurring, codify it here and in `tools/` with CI coverage before treating it as standard.
