# realpass scanner presentation

Status: final source architecture; attended native acceptance pending
Last updated: 2026-09-14

## Decision

realpass does **not** ship a scanner replacement. Cyberpunk 2077's current native scanner/quickhack presentation is the release authority.

Earlier development experiments selectively removed scanner resources from an E3-era HUD integration. That work established that the modern game already supplies the scanner behavior realpass wants, but the integration stack itself is now historical only. The completion candidate contains no scanner archive/resource override and no Project E3 scanner script.

## Owned runtime behavior

There is intentionally no `ScannerNative.reds` replacement. Preserving the native scanner means the safest implementation is absence of an override.

Other realpass presentation seams must coexist with it:

- `NameplatesNative.reds` may provide a public-name fallback for an ordinary scanned civilian only when stock scanner/nameplate policy allows the name;
- `NoHealthbars.reds` suppresses actor HP-specific presentation without hiding scanner identity/quickhack UI;
- `BiologyNativeUI.reds` is a menu/body-state surface and does not hook scanner mode.

## Acceptance

The completion candidate must be attended in game to verify:

1. scanner opens/closes normally;
2. NPC and device targeting remain correct;
3. quickhack panels/memory/cost presentation remain usable;
4. scanning an ordinary civilian can coexist with the owned name fallback;
5. hidden/quest/alternative identities remain protected by stock policy;
6. actor-healthbar suppression does not remove scanner information;
7. entering/leaving scanner mode around combat, vehicles, dialogue and menus does not leave stale realpass UI state.

No scanner-specific calibration should be added unless this native acceptance reveals an actual conflict.

## Historical note

Legacy scanner/E3 patch recipes and research files may remain in `config/patches`, tooling or Git history as provenance. They are not selected by `Build-OwnedRuntimeProfile.ps1`, are forbidden from the standalone runtime, and should not be treated as the current implementation.
