# Attended milestone deploy failure — 2026-09-15 — `2362dacf`

Status: **DEPLOYMENT BLOCKED — NO GAMEPLAY ACCEPTANCE**

## Exact source

Canonical `main` tested:

```text
2362dacf5dcd6fa8689e4f247313eab8b27b23c7
```

Cyberpunk version:

```text
2.31
```

Milestone workspace:

```text
C:\Games\Biology-Test-2026-09-15-2362dacf
```

Generated release-shaped candidate:

```text
C:\Games\Biology-Test-2026-09-15-2362dacf\candidate\staging\biology-packages\biology-integrated-20260915-154405-2362dacf5dcd.zip
```

The exact candidate build completed successfully before deployment:

- selected component acquisition/verification succeeded;
- 119 owned-runtime policy checks passed;
- project-original REDscript exact compile passed;
- full deployable REDscript exact compile passed;
- game cache was not modified by compilation;
- `Uninstall Biology.exe` compiled;
- artifact policy accepted 117 files.

## Official REDmod deployment failure

The candidate was installed and then deployed through the repository-owned official REDmod helper using the explicit Cyberpunk game root.

REDmod recognized the package correctly:

```text
Found mod "Biology" (v0.1.0) in folder "Biology" (enabled; not deployed; TWEAKS; )
Needs deployment: true
```

Deployment then progressed through:

```text
[DEPLOY] Stage 1/5 - Initialization
[DEPLOY] Stage 2/5 - Script Compilation
[DEPLOY] Stage 3/5 - TweakDB Compilation
```

and failed during TweakDB compilation.

Authoritative error:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077\mods\Biology\tweaks\base\gameplay\static_data\database\items\weapons\parts\biology_activation.tweak:
          Line 8: Base group 'IconicWeaponModAbilityBase' for group 'Items.BiologyLauncherActivationMarker' not found.
          Line 10: Variable 'stackable' in group 'Items.BiologyLauncherActivationMarker' has no type defined
ERROR: TweakDB compilation has failed!
```

The helper correctly failed closed instead of treating the REDmod process as successful.

## REDlauncher confirmation

The user then tried the ordinary REDlauncher with mods enabled. During **Initiating Mods** the launcher stopped around 70% and reported a tweak compilation error. Its log reproduced the same two `biology_activation.tweak` validation errors.

This confirms the problem is not specific to the repository deploy wrapper. The official launcher and direct official REDmod deployment agree that the activation sentinel's TweakDB definition is invalid for the supported Cyberpunk/REDmod 2.31 environment.

## Interpretation

The combined runtime exact-compiles successfully, but the new launcher-activation boundary introduced for issue #44 currently uses an unsupported/incorrect native TweakDB record shape:

```text
Items.BiologyLauncherActivationMarker : IconicWeaponModAbilityBase
{
    stackable = true;
}
```

The intended product behavior remains valid: REDlauncher mods OFF must leave loose Biology supplemental runtime inert. The TweakDB sentinel mechanism must be repaired using directly evidenced official REDmod/vanilla schema support rather than guessed community syntax.

## Routing

Fresh worker lane:

```text
W07.1 — REDMOD / Activation Sentinel Repair
```

GitHub issue:

```text
#53 — Attended follow-up — REDmod activation sentinel fails TweakDB compilation on CP2077 2.31
```

Branch:

```text
agent/redmod-activation-sentinel-repair
```

## Acceptance state

Not accepted / not yet testable in-game:

- REDmod deployment: **FAIL**
- REDlauncher mods-enabled initialization: **FAIL**
- launcher ON behavior: **NOT TESTED**
- launcher OFF vanilla behavior: **NOT TESTED**
- Biology live runtime/UI: **NOT TESTED on this artifact**
- E3 HUD/nameplates: **NOT TESTED on this artifact**
- hard uninstaller: **BUILT, NOT ATTENDED-TESTED**

Do not reuse this candidate for gameplay acceptance after the sentinel repair. Build a fresh exact canonical-main artifact after the fix is integrated.