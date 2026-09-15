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

## Mandatory repository discovery/bootstrap rule

Repository/workspace paths are **not stable**. The retired `C:\Games\CyberpunkRealism` folder structure must not be assumed or recreated.

Before giving the user any repo-dependent PowerShell/CMD command, the command itself must:

1. inspect immediate child directories under `C:\Games` for a Git checkout/worktree whose `origin` resolves to `natanai/cprealpass`;
2. reuse an existing matching checkout only as a seed/control checkout when appropriate;
3. if none exists, clone `https://github.com/natanai/cprealpass.git` automatically into a uniquely signed folder under `C:\Games`;
4. create a fresh uniquely signed checkout/worktree for branch-specific audits or attended candidates rather than mutating an arbitrary existing checkout;
5. print the exact repo/worktree path used.

Unique signatures must include a timestamp and random suffix, for example:

```text
20260915-031500-a1b2c3d4
```

The user should not have to manually set up a repo first as a separate prerequisite.

Canonical discovery/bootstrap preamble:

```powershell
$GamesRoot = 'C:\Games'
$RepoUrl = 'https://github.com/natanai/cprealpass.git'
$RepoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'

$Repo = Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue |
  ForEach-Object {
    if (Test-Path -LiteralPath (Join-Path $_.FullName '.git')) {
      $origin = (& git -C $_.FullName remote get-url origin 2>$null)
      if ($LASTEXITCODE -eq 0 -and $origin -match $RepoPattern) { $_.FullName }
    }
  } |
  Select-Object -First 1

if (-not $Repo) {
  $Signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
  $Repo = Join-Path $GamesRoot "cprealpass-repo-$Signature"
  git clone $RepoUrl $Repo
  if ($LASTEXITCODE -ne 0) { throw 'Could not clone natanai/cprealpass.' }
}

Write-Host "CPREALPASS REPO: $Repo"
```

## Mandatory evidence-report rule

When an agent asks the user to run a local evidence/audit/probe command, the operation must generate a **plain-text `.txt` evidence report** for the user to attach back to ChatGPT.

- Do not make copy/pasting console output into chat the normal handoff.
- The report should contain enough stdout/stderr or a purpose-built summary to diagnose both PASS and FAIL outcomes.
- Use a unique filename containing timestamp and random suffix or exact revision/build identity.
- Print the absolute report path at the end of the command.
- Tell the user to attach that file to the owning thread.
- Repository-owned tools should generate the text report themselves when practical; otherwise the one paste block must capture the tool output to a text file.
- Machine-readable JSON may still be produced for repository automation, but it does not replace the user-returned text evidence file.

`tools/Audit-GameContracts.ps1` follows this rule directly and writes `reports/local-game-contract-audit-<timestamp>-<random8>.txt`, including failure information after the transcript starts.

Attended-test source workspaces are disposable and milestone-specific. Prefer uniquely signed names such as:

```text
C:\Games\Biology-Test-<short-main-sha>-<YYYYMMDD-HHmmss>-<random8>\
```

The user may delete that entire test workspace after the attended evidence has been returned to the parent integration thread.

---

## Command 0 — bootstrap a disposable milestone workspace when no repo exists locally

The parent supplies the exact canonical `main` SHA. This command performs its own repository discovery/bootstrap and creates a uniquely signed milestone root. Substitute only the SHA.

```powershell
$Sha = '<40-character canonical main SHA>'
$GamesRoot = 'C:\Games'
$RepoUrl = 'https://github.com/natanai/cprealpass.git'
$RepoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$Signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$ShortSha = $Sha.Substring(0,8)

$Repo = Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue |
  ForEach-Object {
    if (Test-Path -LiteralPath (Join-Path $_.FullName '.git')) {
      $origin = (& git -C $_.FullName remote get-url origin 2>$null)
      if ($LASTEXITCODE -eq 0 -and $origin -match $RepoPattern) { $_.FullName }
    }
  } |
  Select-Object -First 1

if (-not $Repo) {
  $Repo = Join-Path $GamesRoot "cprealpass-repo-$Signature"
  git clone $RepoUrl $Repo
  if ($LASTEXITCODE -ne 0) { throw 'Clone failed.' }
}

git -C $Repo fetch origin
if ($LASTEXITCODE -ne 0) { throw 'Fetch failed.' }

$Root = Join-Path $GamesRoot "Biology-Test-$ShortSha-$Signature"
$Operator = Join-Path $Root 'operator'
New-Item -ItemType Directory -Path $Root -Force | Out-Null

git -C $Repo worktree add --detach $Operator $Sha
if ($LASTEXITCODE -ne 0) { throw 'Exact milestone worktree creation failed.' }

pwsh "$Operator\tools\Prepare-BiologyMilestoneTest.ps1" `
  -MainSha $Sha `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -WorkspaceRoot $Root

Write-Host "CPREALPASS SEED: $Repo"
Write-Host "MILESTONE ROOT: $Root"
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

Before this is used as a user evidence handoff, its operator wrapper must also provide the required `.txt` evidence report described above.

---

## Command 1 — fast vanilla sanity check

From an active checkout, use after a genuinely fresh Steam reinstall when an exhaustive whole-game hash comparison is unnecessary.

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

When this is requested from the user as evidence, the calling paste block/tool must write the result to the required `.txt` report.

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

When this is requested from the user as evidence, the calling paste block/tool must write the result to the required `.txt` report.

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

This operation hashes the full game and therefore has durable `HASH [...]` progress output. The published GitHub-safe metadata remains useful, but when the user is asked to return evidence to a thread, also generate the required `.txt` report.

---

## Command 4 — build the release-shaped Biology package

From a pristine exact candidate checkout:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The builder exact-compiles the merged Biology runtime against the supported game before it emits a game-root-shaped ZIP. It does not install, deploy or launch the game.

For normal milestone preparation, prefer **Command 0**, which creates and calls the correct uniquely signed checkout.

When a build is requested from the user as evidence, capture its result in the required `.txt` report.

---

## Command 5 — deploy installed Biology through official REDmod

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This uses the directly evidenced official REDmod executable and explicit game root. Deployment success is not gameplay acceptance.

The helper is deliberately fail-closed. REDmod sometimes returns exit code `0` even when it ignored the requested game root or found nothing to deploy. Therefore any output containing `No root specified`, `Invalid root path found`, or `No mods found, no deployment is needed` is a deployment **failure** for an installed Biology candidate, not a pass. Positive deployment also requires the actual `[DEPLOY]` stage and `Commandlet deploy has succeeded` evidence.

For normal milestone preparation, prefer **Command 0**, which invokes this automatically after installing the exact generated ZIP. When deployment output is requested from the user, return it through the required `.txt` evidence report.

---

## Command 6 — reset an iteration install back to the tracked vanilla baseline

Use only when the package architecture/game version is unchanged and the installed Biology manifest is intact:

```powershell
pwsh ./tools/Reset-BiologyIteration.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This removes only exact manifest-owned files and then performs the strict full vanilla comparison. It fails closed to milestone clean-room if anything cannot be proven safe. When requested from the user as evidence, return its result through the required `.txt` report.

---

## Command 7 — direct compatibility audit

Use after a Cyberpunk patch/framework change or when a foundational native seam needs direct supported-install evidence.

`Audit-GameContracts.ps1` now derives its repository root from the checkout containing the script; it has no permanent checkout-path default. It generates the required text evidence file automatically.

```powershell
pwsh ./tools/Audit-GameContracts.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

At completion or failure after startup, it prints an absolute line beginning:

```text
LOCAL EVIDENCE REPORT: C:\...\reports\local-game-contract-audit-....txt
```

Attach that `.txt` file to the owning ChatGPT thread rather than pasting the console transcript. This is investigation evidence, not attended runtime acceptance.

---

## Command 8 — publish the current GitHub-safe game reference snapshot

Use when the current observed installation/framework state needs to be refreshed for remote agents:

```powershell
pwsh ./tools/Publish-LocalGameReferenceSnapshot.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

It publishes derived metadata only, never proprietary Cyberpunk payload. If the user is expected to return a result to chat, also generate the required `.txt` evidence report.

---

## Rules for agents asking the user to run PowerShell

1. **Look here first.** If a catalog command covers the task, use it instead of reconstructing its internals in chat.
2. **Never assume a permanent repo path.** Repo-dependent paste blocks must discover a matching `natanai/cprealpass` checkout under `C:\Games` or create a uniquely signed clone automatically.
3. **Never use `C:\Games\CyberpunkRealism`.** That local folder convention is retired.
4. Branch-specific/local-audit work should use a fresh uniquely signed worktree/checkout, not silently mutate an arbitrary existing repo.
5. **Every user-returned evidence operation must create a `.txt` report file.** Ask the user to attach the file; do not ask them to paste a long console transcript into chat.
6. The evidence report must be useful on failure as well as success and the command must print its absolute path.
7. Agents may substitute the exact main/branch SHA, unique disposable test-root name, and known game path where the catalog explicitly permits it.
8. Do not paste the internals of a repository tool into chat merely to avoid invoking that tool; the bootstrap shell around it is allowed when no repo can be assumed.
9. Prefer one catalog entrypoint over a long chain of unrelated hand-written commands.
10. Long operations must expose durable console progress. `Write-Progress` alone is not sufficient because some hosts hide it.
11. Do not describe a fast sanity pass as a full baseline/hash verification.
12. After a freshly uninstalled/residual-directory-deleted/reinstalled game, let the user choose whether the additional exhaustive hash check is worth the time. Default is **No**.
13. Iteration cleanup on a reused install remains stricter: `Reset-BiologyIteration.ps1` must prove the return to the tracked baseline before layering another package.
14. If a command fails, return the generated evidence report to the owning agent; do not improvise destructive cleanup commands.
15. If an operation becomes recurring, codify it here and in `tools/` with CI coverage before treating it as standard.
