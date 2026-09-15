# Biology local operator command catalog

Status: **canonical user-run command surface**  
Last updated: 2026-09-15

## Why this exists

The project owner can provide direct evidence from the supported local Cyberpunk 2077 installation, but agents should not invent a fresh PowerShell procedure every time. **Agents must reuse this catalog for routine local operations.** If a recurring operation is missing or awkward, improve the repository tool, this document, and its CI contract first.

Canonical game root unless the user says otherwise:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

## Mandatory repository discovery/bootstrap rule

Repository/workspace paths are **not stable**. The retired `C:\Games\CyberpunkRealism` convention must not be assumed or recreated.

Before giving the user a repo-dependent PowerShell/CMD operation, the operation itself must:

1. inspect immediate child directories under `C:\Games` for a usable Git checkout whose `origin` resolves to `natanai/cprealpass`;
2. reuse a matching checkout only as a seed/control checkout when appropriate;
3. if none exists, clone `https://github.com/natanai/cprealpass.git` automatically into a uniquely signed folder under `C:\Games`;
4. create a fresh uniquely signed checkout/worktree for branch-specific audits or attended candidates instead of mutating an arbitrary existing checkout;
5. print the exact repo/worktree path used.

Unique signatures must contain a **timestamp and random suffix**, for example:

```text
20260915-031500-a1b2c3d4
```

A normal reusable seed clone has `.git\config`. Worktrees may have a `.git` pointer file, so discovery code should validate candidates rather than blindly running `git -C` against arbitrary folders.

Canonical discovery/bootstrap preamble when a repository-owned bootstrap tool does not already own this logic:

```powershell
$GamesRoot = 'C:\Games'
$RepoUrl = 'https://github.com/natanai/cprealpass.git'
$RepoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$Signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"

$Repo = Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue |
  ForEach-Object {
    $Config = Join-Path $_.FullName '.git\config'
    if (Test-Path -LiteralPath $Config -PathType Leaf) {
      $Text = Get-Content -Raw -LiteralPath $Config -ErrorAction SilentlyContinue
      if ($Text -match $RepoPattern) { $_.FullName }
    }
  } |
  Select-Object -First 1

if (-not $Repo) {
  $Repo = Join-Path $GamesRoot "cprealpass-repo-$Signature"
  git clone $RepoUrl $Repo
  if ($LASTEXITCODE -ne 0) { throw 'Could not clone natanai/cprealpass.' }
}

Write-Host "CPREALPASS REPO: $Repo"
```

## Mandatory evidence-report rule

When an agent asks the user to run a local evidence/audit/probe operation, it must generate a **plain-text `.txt` evidence report** for the user to attach back to ChatGPT.

- Do not make copy/pasting console output into chat the normal handoff.
- The report must be useful for **failure and success** outcomes (`FAIL`/`PASS`).
- Use a unique filename containing timestamp plus random suffix or exact revision/build identity.
- Print the absolute report path at the end of the operation.
- Tell the user to attach that file to the owning ChatGPT thread.
- Machine-readable JSON may still be produced for automation, but it does not replace the user-returned text evidence file.

`tools/Audit-GameContracts.ps1` follows this rule directly and prints an absolute `LOCAL EVIDENCE REPORT:` line. Repository-owned `Bootstrap-*.ps1` evidence entrypoints must also obey the canonical failure-durable bootstrap contract below.

## Canonical failure-durable probe/bootstrap contract

A repo-owned local probe is **not complete unless its useful evidence survives failure**. A nonzero child exit code by itself is not enough: if the attachable report says only `exit 1` while the child stderr or terminating exception was lost, the probe is incomplete and must not be treated as valid diagnostic evidence.

For user-returned local probes/audits, the canonical bootstrap must:

1. **Pin revision identity.** When branch-specific, require the intended branch plus an exact 40-character expected head, fetch that branch, record the fetched head, and refuse to continue if it differs.
2. **Use disposable isolation.** Discover `natanai/cprealpass` by origin or create a uniquely signed seed clone, then use a uniquely signed detached/disposable checkout or worktree for the requested revision.
3. **Default the installed game/tool tree to read-only.** The Cyberpunk/REDmod installation must be treated as read-only unless mutation is explicitly the purpose of the operator command.
4. **Fingerprint the authority being inspected.** Record the exact supported game/native/tool identity relevant to the question, such as product/file version and, when useful, SHA-256 of the executable/tool actually inspected.
5. **Collect bounded evidence.** Capture only the files/symbols/schema excerpts needed to answer the current question rather than dumping proprietary trees or huge console transcripts.
6. **State the proof boundary.** Clearly distinguish source/symbol/schema evidence from exact compilation, official REDmod deployment, or live-runtime/attended proof. Source evidence must never be reported as deployment or runtime acceptance.
7. **Produce one attachable plain-text report.** The same `.txt` file must contain the useful result on both success and failure.
8. **Preserve child-process diagnostics before throwing.** For every child process whose output matters, capture **stdout, stderr, exit code, and actual exception/error text** into that same report. On nonzero exit, throw only after those diagnostics have been persisted.
9. **Record bootstrap context.** The report must include requested branch/head when applicable, fetched head, disposable checkout/worktree path, and the game/native/tool identity used as evidence.
10. **Always expose one attachment handoff.** Success and failure paths must both end by printing exactly one obvious:

```text
ATTACH THIS FILE TO CHATGPT:
<absolute path to report.txt>
```

For external/native child processes, the preferred PowerShell implementation uses `System.Diagnostics.ProcessStartInfo` with `UseShellExecute = false`, `RedirectStandardOutput = true`, `RedirectStandardError = true`, and `ArgumentList` for safe argument boundaries. Read stdout/stderr, wait for exit, persist both streams plus the exit code, and only then evaluate success/failure. The outer `catch` must add the exception type and message to the report, and the attachment handoff belongs in a `finally`-equivalent path.

`tools/Bootstrap-RedmodActivationSentinelProbe.ps1` and `tools/Bootstrap-PresentationAudit.ps1` are current examples of this contract. Their inner evidence may fail, but the user-returned `.txt` must still explain **why** it failed rather than merely recording a nonzero exit.

Attended-test source workspaces are disposable and milestone-specific. Prefer uniquely signed names such as:

```text
C:\Games\Biology-Test-<short-main-sha>-<YYYYMMDD-HHmmss>-<random8>\
```

The user may delete that test workspace after evidence has been returned to the parent integration thread.

---

## Command 0 — bootstrap a disposable milestone workspace when no repo exists locally

The parent supplies the exact canonical `main` SHA. Substitute only that SHA.

```powershell
$Sha = '<40-character canonical main SHA>'
$GamesRoot = 'C:\Games'
$RepoUrl = 'https://github.com/natanai/cprealpass.git'
$RepoPattern = '(?i)(?:github\.com[/:])natanai/cprealpass(?:\.git)?$'
$Signature = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$ShortSha = $Sha.Substring(0,8)

$Repo = Get-ChildItem -LiteralPath $GamesRoot -Directory -ErrorAction SilentlyContinue |
  ForEach-Object {
    $Config = Join-Path $_.FullName '.git\config'
    if (Test-Path -LiteralPath $Config -PathType Leaf) {
      $Text = Get-Content -Raw -LiteralPath $Config -ErrorAction SilentlyContinue
      if ($Text -match $RepoPattern) { $_.FullName }
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

`Prepare-BiologyMilestoneTest.ps1` verifies the exact SHA, asks whether to run the **exhaustive full-file/hash vanilla comparison**, establishes the permitted fresh-reinstall fast-sanity path when that scan is declined, creates a second pristine candidate checkout, builds the release-shaped ZIP, installs/deploys it, records evidence, and stops before game launch.

The exhaustive hash check defaults to **No**. Skipping it after a fresh uninstall + residual-directory deletion + reinstall is allowed, but evidence must say `exhaustive-hash-check-skipped`; an agent must never report that as “verified against recorded vanilla baseline.”

---

## Command 1 — fast vanilla sanity check

Use after a genuinely fresh Steam reinstall when an exhaustive whole-game hash comparison is unnecessary:

```powershell
pwsh ./tools/Test-VanillaGameSanity.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This is deliberately **not** a full-file/hash proof. When requested as user evidence, capture the result in the required `.txt` report.

---

## Command 2 — exhaustive vanilla baseline comparison

Use when residue is uncertain, when reusing a game install for iteration, or when the user explicitly chooses the stronger check:

```powershell
pwsh ./tools/Compare-GameToVanillaBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The full comparison shows durable progress, for example:

```text
VERIFY [#######-------------]  35% | 1842/5200 files | 29.4/84.0 GiB | elapsed 00:01:42
```

When requested as user evidence, return the generated/captured `.txt` report rather than pasted console output.

---

## Command 3 — capture/publish a new vanilla baseline

Use only when the clean reference itself needs to change, such as after a supported Cyberpunk patch:

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077' `
  -Publish
```

This hashes the full game and therefore has durable `HASH [...]` progress output.

---

## Command 4 — build the release-shaped Biology package

From a pristine exact candidate checkout:

```powershell
pwsh ./tools/Build-BiologyPackage.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The builder exact-compiles the merged Biology runtime against the supported game before emitting a game-root-shaped ZIP. The current package also contains the REDmod activation marker, schema-2 ownership receipt, and `Uninstall Biology.exe`. It does not install, deploy, or launch the game.

For normal milestone preparation, prefer **Command 0**.

---

## Command 5 — deploy installed Biology through official REDmod

```powershell
pwsh ./tools/Deploy-BiologyRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

The helper is deliberately fail-closed. Output containing `No root specified`, `Invalid root path found`, or `No mods found, no deployment is needed` is a deployment **failure** for an installed Biology candidate even if REDmod exits `0`. Positive deployment requires actual `[DEPLOY]` stage output and `Commandlet deploy has succeeded`.

---

## Command 6 — reset an iteration install back to the tracked vanilla baseline

Use only when the package architecture/game version is unchanged and the installed Biology manifest is intact:

```powershell
pwsh ./tools/Reset-BiologyIteration.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This developer reset follows the same exact-hash/fail-closed Biology ownership semantics as the player uninstaller, but may remove an unchanged generic dependency only when the recorded vanilla baseline proves the file was absent before Biology. It then performs the strict full vanilla comparison and fails closed if safety cannot be proven.

---

## Command 7 — verify Biology-specific residue after player hard uninstall

The **player-facing** hard-uninstall action is not PowerShell: close Cyberpunk 2077 and **double-click `Uninstall Biology.exe`** in the game root.

For an attended/development test, follow that with the read-only verifier:

```powershell
pwsh ./tools/Verify-BiologyRemoval.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This checks Biology-specific runtime/package residue (`mods/Biology`, `r6/scripts/CyberpunkRealism`, Biology metadata and player uninstaller). Generic redscript/RED4ext/ArchiveXL/Mod Settings files may remain intentionally because the player uninstaller preserves shared dependencies. It never deletes anything.

---

## Command 8 — direct compatibility audit

Use after a Cyberpunk patch/framework change or when foundational native seams need direct supported-install evidence:

```powershell
pwsh ./tools/Audit-GameContracts.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

`Audit-GameContracts.ps1` derives its repository root from the checkout containing the script and automatically creates a text evidence report. At completion or failure after startup it prints:

```text
LOCAL EVIDENCE REPORT: C:\...\reports\local-game-contract-audit-....txt
```

Attach that `.txt` file to the owning ChatGPT thread. This is investigation evidence, not attended runtime acceptance.

For branch-specific presentation audits, use repository-owned `tools/Bootstrap-PresentationAudit.ps1`; it discovers or creates a usable cprealpass seed, fetches the exact branch/head, creates a uniquely signed detached worktree, fingerprints the game identity, runs the presentation audit through redirected child stdout/stderr capture, preserves child exit/error evidence in the same report, and prints `ATTACH THIS FILE TO CHATGPT:` followed by the evidence path.

---

## Command 9 — ask the installed official REDmod tool what it can do

Use this before adopting a community/framework workaround when the uncertainty is whether CDPR's own REDmod toolchain already exposes a suitable capability:

```powershell
pwsh ./tools/Probe-OfficialRedmod.ps1 `
  -GameRoot 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

This read-only probe queries the installed `tools\redmod\bin\redMod.exe`, fingerprints it, inventories official toolset signals, captures `redMod.exe --help`, and writes a text report. Community/modder practice is **fallback evidence**, not proof that the official route is unavailable or inferior. If the official route would require a broader whole-file replacement or otherwise increase compatibility risk, document that direct evidence before selecting the narrower seam.

---

## Command 10 — publish the current GitHub-safe game reference snapshot

Use when current observed install/framework metadata needs to be refreshed for remote agents:

```powershell
pwsh ./tools/Publish-LocalGameReferenceSnapshot.ps1 `
  -GamePath 'C:\Games\Steam\steamapps\common\Cyberpunk 2077'
```

It publishes derived metadata only, never proprietary Cyberpunk payload.

---

## Rules for agents asking the user to run PowerShell

1. **Look here first.** If a catalog command covers the task, use it rather than reconstructing its internals in chat.
2. **Never assume a permanent repo path.** Repo-dependent operations must discover `natanai/cprealpass` under `C:\Games` or create a uniquely signed clone automatically.
3. Do not use or recreate `C:\Games\CyberpunkRealism`; that path convention is retired.
4. Branch-specific/local-audit work should use a fresh uniquely signed worktree/checkout, not silently mutate an arbitrary existing repo.
5. **Every user-returned evidence operation must create a `.txt` report file** and print its absolute path; ask the user to attach it rather than paste a transcript.
6. Evidence reports must preserve clear PASS and FAIL outcomes **and the actual child diagnostics needed to explain failures**. A child nonzero exit with missing stderr/exception evidence is an incomplete probe.
7. Branch-specific probe bootstraps must pin the requested branch and exact head, record the fetched head and disposable checkout, and follow the canonical failure-durable probe/bootstrap contract above.
8. For foundational runtime/package questions, probe the installed game/CDPR/REDmod toolchain before assuming the established community route is necessary.
9. Prefer one repository-owned entrypoint over a long chain of unrelated commands.
10. Long operations must expose durable console progress; `Write-Progress` alone is insufficient.
11. Do not describe a fast sanity pass as a full baseline/hash verification.
12. After a freshly uninstalled/residual-directory-deleted/reinstalled game, let the user choose whether the additional exhaustive hash check is worth the time. Default is **No**.
13. Iteration cleanup on a reused install remains stricter: `Reset-BiologyIteration.ps1` must prove the return to the tracked baseline before layering another package.
14. After a player hard-uninstall test, prefer `Verify-BiologyRemoval.ps1`; do not invent destructive cleanup or misclassify intentionally preserved generic dependencies as Biology residue.
15. If a command fails, return its evidence report to the owning agent; do not improvise destructive cleanup commands.
16. If an operation becomes recurring, codify it here and in `tools/` with CI coverage before treating it as standard.
