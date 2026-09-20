# Known-clean Cyberpunk vanilla baseline

This directory is reserved for a **GitHub-safe derived snapshot** of the user's deliberately clean Cyberpunk 2077 installation.

It is not a copy of the game and must never contain proprietary Cyberpunk files.

A populated baseline contains:

- `environment.json` — capture timestamp, detected game/executable version, file count, total bytes, and hash algorithm;
- `files.csv` — relative game-root path, byte size, and SHA-256 hash for every file in the known-clean installation.

The baseline is captured only during a milestone clean-room cycle with:

```powershell
pwsh ./tools/Capture-VanillaGameBaseline.ps1 -Publish
```

The full hash inventory is intentionally retained in Git history so later agents can distinguish:

- the known-clean vanilla state;
- later RealPass/package-installed snapshots;
- legitimate Cyberpunk patch changes;
- unexplained leftover or modified files.

`Compare-GameToVanillaBaseline.ps1` uses this metadata to prove a reused game installation is back at baseline before an iteration test. `Reset-RealPassIteration.ps1` removes only the immediately prior package's manifest-owned files that did not exist in this baseline, then requires the strict comparison to pass.

If the comparison cannot prove cleanliness, do not weaken the comparison or add broader deletion rules. Use a milestone uninstall/delete/reinstall cycle and capture a new baseline.
