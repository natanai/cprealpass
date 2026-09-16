# P01.2 parent / integration orchestrator handoff

Status: **ACTIVE parent replacement packet**  
Predecessor: **P01.1 — TOO-LONG**  
Successor: **P01.2 — ACTIVE**

This file is the durable handoff for replacing the long P01.1 ChatGPT conversation. `docs/THREAD-LEDGER.md` is authoritative for thread state.

## Paste this into the new parent conversation

```text
[P01.2] PARENT — Integration Orchestrator

Work on repo natanai/cprealpass as the PARENT / INTEGRATION ORCHESTRATOR.

This is parent generation P01.2, replacing P01.1 because the prior parent conversation became too long.

Do not reconstruct state from old chat history. The repository is the continuity source.

READ FIRST, in this order:
- AGENTS.md
- docs/THREAD-LEDGER.md
- docs/handoffs/PARENT-P01.2.md
- docs/handoffs/PARENT-INTEGRATION.md
- AGREED-GOALS.md
- ROADMAP.md
- docs/ACTIVE-REDMOD-ROADMAP.md
- docs/INTEGRATION-ORCHESTRATOR.md
- docs/PARALLEL-AGENT-WORKFLOW.md
- docs/CLEAN-ROOM-TESTING.md
- docs/LOCAL-OPERATOR-COMMANDS.md
- docs/SETTINGS-ARCHITECTURE.md
- docs/DEPENDENCY-AUDIT.md
- docs/PLAYER-DISABLE-UNINSTALL.md
- docs/test-runs/2026-09-15-w09-post-uninstall-redmod-state.md
- the latest relevant records under docs/test-runs/
- current open GitHub issues and PRs

At startup:
1. Confirm docs/THREAD-LEDGER.md marks P01.2 ACTIVE and P01.1 TOO-LONG.
2. Resolve and report the exact current canonical main SHA. Do not assume the SHA in an old chat message is still main.
3. Confirm there are no active worker lanes unless the ledger/GitHub says otherwise.
4. Confirm current open issues/PRs and current main CI before asking the user to run anything locally.

CURRENT FEATURE STATE AT HANDOFF

Latest feature-bearing canonical merge before the parent-transition docs commits:

b312c2338d17488dcb95bbd2614d6040ce234ee9

This merge includes both W09.1 and W10.1. Parent-transition documentation commits descend from it; resolve current main at startup.

W09.1 / issue #59 / PR #62 — MERGED
Worker head:
096cbf5d3a1e4f2b19ffc0509e1afcb70d76abaa

W09 direct supported-install evidence established:
- Cyberpunk 2077 / REDmod 2.31
- after the successful no-mod uninstall refresh and failed redeploy, `r6/cache` existed but `r6/cache/modded` did not
- the attended deploy reached REDmod Stage 3 / TweakDB compilation and failed with Win32 0x3 while moving generated output to `r6/cache/modded/tweakdb_ep1.bin`
- this was distinct from the earlier W08 tweak parser failure

W09 repair now on main:
- `tools/Deploy-BiologyRedmod.ps1` resolves only `<game>/r6/cache/modded`
- if absent, it creates that directory immediately before official `redMod.exe deploy`
- if the path is occupied by a file, it fails closed
- it never deletes/clears existing cache contents
- it never synthesizes/copies/replaces `tweakdb_ep1.bin`, `mods.json`, or other generated REDmod output
- official REDmod remains the authority for deployment/output

W09 merge-context + post-merge cloud CI were green. Issue #59 must remain open until the repaired official REDmod 2.31 deploy is directly attended-passed.

W10.1 / issue #61 / PR #63 — MERGED
Worker head:
134ae11a20d8ae432686a7711cbb72f70e006fa6

The exact W09+W10 merge context was CI-tested at hypothetical merge commit:
f84ba3b59b4e545343a6ca4ba4edf27e48bc791e
Biology CI run #1332 passed the full suite against that combined merge context.

W10 architecture now on main:
- REDlauncher/REDmod is the sole whole-mod public activation boundary
- the redundant persisted in-game `Enable Biology` Boolean is gone
- the sole normal in-game preference is `presentation.e3-first-person-hud-visuals`
- the E3 Boolean is `persistent` state on Biology-owned `CRRealpassSettings` ScriptableSystem and therefore belongs to save persistence
- the user edits it through Biology-owned Ink UI on the existing Biology/Cyberware body screen
- Biology no longer registers a Mod Settings provider/pause-menu row
- Mod Settings 0.2.21 is removed from production release/acquisition/install architecture
- ArchiveXL 1.27.3 is removed from production release/acquisition/install architecture
- RED4ext 1.30.0 is removed from production release/acquisition/install architecture
- redscript 0.5.31 is the only retained bundled third-party runtime dependency
- the self-contained uninstaller no longer performs Mod Settings INI surgery and never targets save-backed preference state

Do not claim W10 live acceptance from source/CI. Exact supported-game compile, Biology-owned preference UI behavior, persistence, blank-menu cleanup, and launcher-OFF behavior remain parent-attended gates.

IMPORTANT CURRENT INSTALLED-GAME STATE

Do NOT assume the user's current Cyberpunk install is the new W09+W10 package.

The current game was previously brought to a fresh Steam/REDmod state, then:
1. the old Biology candidate was installed;
2. the player-facing Uninstall Biology.exe was tested and attended-passed for Biology-owned payload removal + REDmod no-mod refresh;
3. the canonical residue verifier passed for Biology-specific residue;
4. the W08-era candidate from exact source `7e61724071b8c95ba5c334ab9e8d11c43381c94e` was then built/installed;
5. official REDmod reached Stage 3 and failed because `r6/cache/modded` was absent;
6. the user launched with REDlauncher mods disabled;
7. gameplay otherwise appeared normal/no obvious Biology behavior;
8. Windows Security reported Cyberpunk attempting to load `ArchiveXL.dll` (and the user saw an earlier similar warning they did not capture);
9. the pause menu showed a blank inert gap where Mod Settings had been.

Therefore the current install may still contain the PRE-W10 generic framework payload (Mod Settings / ArchiveXL / RED4ext) even though new canonical packages no longer ship it.

This matters: simply overlaying the new W10 package could leave old foreign framework files on disk and produce a false failure for the W10 launcher-OFF test.

Before the next attended candidate, establish a controlled transition from this old installed state. Prefer a repository-owned transition/cleanup path that proves exactly what it removes. Do not ask for another full Cyberpunk reinstall merely to remove these retired files unless a narrower safe route is genuinely impossible.

The old Biology uninstaller intentionally preserves generic/shared dependencies, so running it alone may not remove the now-retired Mod Settings/ArchiveXL/RED4ext files. If a targeted cleanup is required, treat that as a distinct migration/transition problem: verify exact paths/hashes/ownership and absence of other consumers before deleting anything. A materially new implementation goal should receive a fresh W## lane rather than being hidden inside parent glue.

ATTENDED EVIDENCE ALREADY ACCEPTED

- Exact integrated runtime compile against installed CP2077 2.31 passed after W06 repair.
- REDmod package recognition and explicit-root deployment mechanism were proven earlier.
- W08 standalone tweak grammar was directly accepted in the narrow sense that the prior `using` parser error disappeared and REDmod progressed to generated TweakDB output writing.
- Player-facing `Uninstall Biology.exe` attended-passed removal of Biology-owned payload.
- Official REDmod no-mod refresh from the uninstaller succeeded.
- Canonical read-only Biology residue verifier returned PASS after that hard uninstall.
- Save files were not accessed/changed by uninstaller.
- Launcher-OFF with the PRE-W10 package reached main menu and gameplay and otherwise appeared normal, but it is NOT final launcher-OFF acceptance because old framework DLLs still loaded/triggered Windows warnings and the Mod Settings menu gap remained.

OPEN ATTENDED ACCEPTANCE OWNERSHIP

Issue #59:
- repaired W09 official REDmod 2.31 deploy must pass all deployment stages on exact integrated canonical source

Issue #44:
- REDlauncher ON -> Biology active
- REDlauncher OFF -> Biology inactive/native behavior
- no old Mod Settings blank row
- no Biology-caused ArchiveXL/RED4ext/Mod Settings framework footprint/warnings in the new package
- hard uninstall remains accepted after the new package shape

Issue #39:
- Biology uses the native Cyberware shell/interaction grammar
- clean drill-down/detail state
- Back returns detail -> Biology overview
- BIOLOGY/CYBERWARE switching is overview-only
- no Biology visual leakage into Cyberware

Issue #41:
- authoritative body runtime exists in live session
- no `BODY RUNTIME SYSTEM MISSING`
- no fake STABLE fallback
- persistence/session behavior remains authoritative

Issue #40:
- E3 ON is visibly unmistakable in ordinary gameplay
- quest/objective HUD receives intended red/minimal treatment
- civilian/police ambient nameplates work through ordinary look/focus
- E3 OFF removes only E3-specific presentation
- modern scanner/quickhack remains native
- the new Biology-owned E3 preference control edits state and persists across save/reload

NEXT PARENT CYCLE

Do not immediately ask the user to reinstall or launch a worker branch.

Preferred sequence:
1. Confirm current main CI is green after all parent handoff docs commits.
2. Inspect the actual current installed-state transition problem described above.
3. If needed, create a small fresh lane for safe retirement of legacy Mod Settings/ArchiveXL/RED4ext residue from a pre-W10 Biology installation. Do not delete generic framework files blindly.
4. Once the installed state is controlled, use the repo-owned operator surface to exact-compile/build ONE canonical-main release candidate against installed Cyberpunk 2.31.
5. Require exact supported-game REDscript compilation of the new W10 source before install.
6. Install that exact artifact and run the W09-repaired official REDmod deploy path.
7. Capture artifact path + SHA-256 + exact main SHA + REDmod deploy report in a durable test record.
8. If deploy passes, perform ONE attended gameplay cycle covering launcher ON/OFF, Biology shell/runtime, the Biology-owned E3 preference and save persistence, E3/nameplates, and modern scanner preservation.
9. Do not call any source/CI result live acceptance.
10. Route every new failure according to THREAD-LEDGER rules; new goal -> new W## lane.

TESTING / OPERATOR RULES

- Exact game root is `C:\Games\Steam\steamapps\common\Cyberpunk 2077`.
- Official REDmod is under that game's `tools\redmod` tree.
- Do not assume a persistent repo checkout on the user's PC.
- Use repo-owned self-bootstrapping commands/tools from docs/LOCAL-OPERATOR-COMMANDS.md.
- User-run probes must generate one attachable `.txt` on success AND failure and preserve child stdout/stderr/exit/exception evidence.
- Treat installed game as read-only for probes unless mutation is explicitly the operation being tested.
- Do not casually rerun the ~85 GiB exhaustive vanilla hash scan.
- Do not casually reinstall the whole game; the tested uninstaller exists specifically to make routine removal/retest possible.
- Do not give long ad-hoc PowerShell scripts when a repository-owned bootstrap should exist.
- Do not ask the user to install/play separate worker branches by default.

PRODUCT DIRECTION

- Biology is a self-contained realism/biology overhaul, REDmod-first wherever robust.
- Official-source-first: prefer CDPR/REDmod/native game contracts over ecosystem workarounds.
- One authored physical simulation, not independently configurable subsystems.
- REDlauncher is the normal whole-mod ON/OFF boundary.
- One in-game presentation preference: E3-inspired HUD + nameplates.
- Biology owns body/anatomy parent shell; Cyberware is an internal mode.
- Reuse native Cyberware shell/interaction grammar rather than inventing parallel UI.
- Modern scanner/quickhack is intentionally preserved.
- No Project E3 or Dark Future executing runtime.
- Traditional actor HP-bar presentation remains suppressed while Biology is active independent of E3 preference.
- Long-term dependency direction is self-contained/no unnecessary third-party frameworks. Current canonical package retains only redscript as bundled generic runtime; full redscript elimination, if pursued, must be a fresh evidence-driven lane rather than an assumption.

At the beginning of your first response as P01.2, report:
- exact current main SHA
- current main CI status
- open PRs/issues relevant to current cycle
- confirmation that W09 and W10 are merged and no worker is active unless GitHub/ledger says otherwise
- your plan for controlling the old installed dependency residue without a full reinstall
- whether a fresh worker lane is needed before the next combined candidate

Do not continue work in P01.1 except to clarify the handoff if absolutely necessary.
```

## Durable references

- Parent integration contract: `docs/INTEGRATION-ORCHESTRATOR.md`
- General parent bootstrap: `docs/handoffs/PARENT-INTEGRATION.md`
- Canonical thread registry: `docs/THREAD-LEDGER.md`
- Local operator API: `docs/LOCAL-OPERATOR-COMMANDS.md`
- W09 evidence: `docs/test-runs/2026-09-15-w09-post-uninstall-redmod-state.md`
- Issue ledger: #35
- W09 acceptance issue: #59
- Launcher/uninstall acceptance: #44
- Biology shell acceptance: #39
- Presentation acceptance: #40
- Runtime authority acceptance: #41

If chat context disagrees with current GitHub state, GitHub + this ledger are authoritative and the new parent must repair stale prose rather than following it.