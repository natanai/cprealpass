# Modern scanner with the E3 HUD

The modern presentation preset restores the game's scanner and quickhack panel while retaining the E3 HUD, menus and NPC nameplates. `Build-RealpassPresentation.ps1` defaults to `-ScannerMode Modern`; `-ScannerMode E3` remains available for the original scanner presentation.

From the project directory, build a new local candidate with a unique build ID:

```powershell
./tools/Build-RealpassPresentation.ps1 -BuildId realpass-scanner-review-quiet -ManifestPath manifest/realpass-body-rc2-quiet.deployment.json -ScannerMode Modern
```

This uses the local body rc2 manifest as its source. It stages a candidate; it does not launch the game or install the candidate. Existing immutable build IDs cannot be reused.

## Resources restored

`config/patches/realpass-modern-scanner.json` pins the original archive and every excluded resource by SHA-256. Its 34 exclusions comprise:

- 12 scanning resources, including the scanner HUD, details panel and TwinTone preview.
- 13 quickhack resources, including the panel, animations, styles, atlases and masks.
- Two connected-device resources and the netrunner charges widget.
- Six focus-mode resources: environment settings, effect, particle, scanline material and two scanning color LUTs.

The preset also omits the pinned `cyberpunk/hud/scanner/scanner_border.reds` replacement. Its only override is `scannerBorderGameController.ComputeVisibility`; no other supplied E3 script depends on it.

The installed game's `archive/pc/content` indexes contain **all 34 exact resource paths**, including `netrunner_memory/netrunner_charges.inkwidget`, both connected-device resources and `scanning/twintone/twintone_color_template_preview.inkwidget`. Removing their E3 overrides therefore leaves native resource fallbacks. This was verified by a finite, read-only WolvenKit index command; no game process or logging helper was started.

## HUD separation

Decoded E3 `root.inkwidget` has no external resource paths or scanner-specific named containers. The main `prototype_hud.inkhud` independently spawns `scanning/scanning.inkwidget`, `quickhacks/quickhacks.inkwidget` and `scanning/scandetails.inkwidget`, without attachment to a root HUD slot and with zero margins. Across all 15 supplied HUD entry resources, the 48 scanner-family entries have no root-slot attachment. The player healthbar has no external scanner, quickhack, connected-device or netrunner resource dependency.

These findings support retaining the E3 root, HUD entries, player HUD and nameplates. Shared E3 styles and icons remain, so the native scanner can retain some E3 coloring or icon styling. The independent breach minigame assets also remain.

`Build-RealpassArchive.ps1` preserves the original reference archive, creates a separate archive and round-trips that output to check that all 336 retained resources match their original bytes. These are local integration assets from Project E3 - HUD by Virtuoso75; the original mod remains required. Neither the supplied archive nor the derived archive belongs in a standalone public redistribution.

## Validation status

realpass-presentation-rc4-quiet is installed locally after a fresh save backup. All 114 scripts compile, the exact 225-file update/rollback passes, and candidate/asset verification confirms only the scanner archive and script differ from rc3.

The user's rc3 screenshots confirm that the distinct **Use toilet** action and scanned **Carolyn Veranes** nameplate render. They do not validate the new modern-scanner candidate. Native rendering and interaction acceptance for that candidate remain pending, including opening the scanner, targeting an NPC/device and viewing quickhacks.

Local audit evidence is in `staging/e3-scanner-graph-a6b826ea/`: serialized widget/HUD files, `resource-dependency-graph.json`, `hud-scanner-spawns.json`, `native-scanner-index.txt` and `native-fallback-check.json`. These generated files are ignored and are not required for public project source.
