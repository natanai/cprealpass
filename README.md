# Biology

Biology is a Cyberpunk 2077 + Phantom Liberty body and physiology overhaul for **game version 2.31**. It combines hydration, nutrition, digestion, sleep/fatigue, elimination and hygiene with localized physical injury, bleeding, pain, protection wear and care. One persistent body is authoritative; native Health loss remains a prerequisite for physical wounds.

**Backpack = possessions. Biology = embodied state. Cyberware = installed equipment.** The Biology screen stays inspectable while healthy. Its overview is qualitative; deliberate drill-down reveals metrics, conditions and contextual actions. Native Cyberware navigation and the modern scanner/quickhack experience remain authoritative.

Biology is one authored simulation. Its optional **E3 HUD + NAMEPLATES** preference changes presentation only. Traditional actor HP bars remain suppressed while Biology is active, independently of that preference. REDlauncher **Enable mods** is the whole-mod activation control.

## Install and play

1. Close Cyberpunk 2077. Have the official REDmod tools installed.
2. Extract the complete Biology ZIP into a separate folder outside the game folder.
3. Double-click **Install Biology.exe**, select your Cyberpunk 2077 folder, and install.
4. Enable mods in REDlauncher and launch normally through Steam.

The package includes the pinned redscript 0.5.31 and standalone cybercmd 0.0.13 runtime, with licenses. No dependency hunting, Git, PowerShell installation, mod manager or separate Biology launcher is required. The installer refuses incompatible shared files and changed/untracked Biology files before mutation. An update replaces only unchanged files proven by the previous receipt, removes retired owned sources, and rolls back failed writes when safe.

Turn REDlauncher Enable mods OFF and relaunch for Biology-inactive play; ON resumes it. To remove the files, close the game and double-click **Uninstall Biology.exe** in the game folder. Removal preserves saves, changed files, shared dependencies and unrelated mods. Never merge the ZIP directly into the game directory.

## Current completion work and evidence

Owner-authorized issue **#152**, branch `autonomous/final-product-completion`, supersedes the old parent/worker routing for this solo completion run. See [ROADMAP.md](ROADMAP.md), the [product matrix](docs/PRODUCT-COMPLETION-MATRIX.md), and [completion evidence](docs/evidence/AUTONOMOUS-COMPLETION-2026-09-20.md) for exact executed gates and pending work. No external distribution has been published.

The current source repairs the T007 player-state gate, E3 preference writes/refresh and scanner identity ownership. It also hardens launcher-off presentation, native-session care/combat authority, installer rollback and safe removal. Compilation/model checks establish source contracts; they do not establish native save serialization, rendered visual acceptance, quest outcomes or combat feel. Old attended failures remain historical evidence, not assertions that the repaired source has reproduced them.

## Development and maintenance

Read [AGENTS.md](AGENTS.md), [AGREED-GOALS.md](AGREED-GOALS.md), the [active roadmap](docs/ACTIVE-REDMOD-ROADMAP.md), and the [owner completion handoff](docs/handoffs/AUTONOMOUS-FINAL-PRODUCT-COMPLETION.md). The [integration policy](docs/INTEGRATION-ORCHESTRATOR.md) and [thread ledger](docs/THREAD-LEDGER.md) retain prior coordination history; the owner handoff governs this run. Before requesting local operator commands, consult [the command catalog](docs/LOCAL-OPERATOR-COMMANDS.md).

Run `pwsh ./tests/Run-CI.ps1` for model, native-contract and package-safety checks. `tools/Build-BiologyPackage.ps1` is the canonical playable builder and requires a clean committed checkout plus the supported installed game's base for exact compilation. `tools/Build-Package.ps1` produces only a non-playable development/source artifact. See [release architecture](docs/RELEASE-ARCHITECTURE.md), [patch resilience](docs/PATCH-RESILIENCE.md), and [clean-room policy](docs/CLEAN-ROOM-TESTING.md).

Production native entry points are reviewed in `manifest/activation-hook-audit.json`. Models own equations; narrow adapters own game signatures. Internal `CR*` and `RealPass` names are retained for compatibility. Runtime code is Biology-owned; Dark Future and Project E3 are private research references only. Their payloads, proprietary game assets, saves, user settings and generated staging/reports never enter the release or repository.

Weather, economy, artificial scarcity, travel restrictions and unrelated difficulty systems are outside the agreed product scope.
