# REDmod 2.31 activation-sentinel evidence — 2026-09-15

Status: **SUPPORTED-INSTALL SOURCE EVIDENCE; NATIVE BIOLOGY COMPILE/DEPLOY STILL PARENT-OWNED**

Issue: #53 — W07.1 REDMOD activation sentinel repair

## Probe identity

The read-only operator probe ran against the supported Steam install at `C:\Games\Steam\steamapps\common\Cyberpunk 2077` from exact worker head `27128266d65895b23505704d7ccc70044256e30c`.

Observed official REDmod identity:

- file version: `2.3.1.0`
- product version: `2.31`
- `redMod.exe` SHA-256: `144DF5A984669528CD957B40BB2126FE83B73D66BD0E041CA614C80F74E76A7F`
- shipped `.tweak` files scanned: `2684`

The operator report was `Biology-Redmod-Activation-Sentinel-Probe-20260915-111037-3518f2a2.txt`. It was generated from the user's installed game and is intentionally not committed because the repository stores derived metadata rather than proprietary installed-game source payload.

## Derived findings

1. `IconicWeaponModAbilityBase` **does exist** in the shipped 2.31 tweak sources. The probe found its definition in `tweaks/base/gameplay/static_data/database/items/weapons/parts/mods_abilities.tweak` and many native descendants in that same source surface.
2. Official tweak source uses `package` and `using` directives extensively. The attended failure therefore does not establish that the native base is absent from 2.31; it establishes that Biology's standalone file attempted to resolve a source-package-local base without importing its package context.
3. Official source uses explicitly typed Boolean flats. This proves the native tweak grammar has a first-class Boolean flat type; it does **not** by itself prove that an arbitrary unbased Biology group is legal.
4. The bounded probe found **no shipped examples** of an unbased group containing an explicitly typed Boolean flat. W07.1 therefore rejects the tempting `custom group + bool` design as insufficiently evidenced.
5. The shipped `TweakDBInterface` surface declares `GetBool(path, defaultValue)` and the existing Biology REDscript already supplies `false` as the default. Missing launcher authority therefore remains fail-closed.
6. The probe did not find `gamedataItem_Record` in the generated record surface it inspected, so W07.1 does not invent an item-record sentinel as a fallback.

## Selected repair

Keep the existing inert record identity and REDscript read path:

`Items.BiologyLauncherActivationMarker.stackable`

The standalone Biology tweak now imports the native `Items` package before declaring the record:

```text
using Items

Items.BiologyLauncherActivationMarker : IconicWeaponModAbilityBase
{
    stackable = true;
}
```

This is deliberately narrower than introducing a new record family or a new unbased schema. It preserves the #44 product contract and uses the native base that the supported 2.31 source actually ships, while supplying the package visibility that the attended standalone compilation lacked. The marker remains inert because nothing in Biology or vanilla gameplay references the record as a gameplay package; REDscript only reads its Boolean flat as launcher authority.

## Validation boundary

Cloud CI can enforce the source/package/read-path contract and reject the exact unsupported bare-global shape that escaped earlier checks. Cloud CI **cannot** emulate the proprietary REDmod TweakDB compiler.

Therefore:

- W07.1 source/CI evidence may establish that the candidate is internally consistent and grounded in the supported 2.31 source surface.
- Official REDmod 2.31 TweakDB compilation/deployment of the repaired candidate remains a parent P01.1 attended gate.
- No worker-branch install/play is requested by this evidence record.
