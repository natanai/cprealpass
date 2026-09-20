# REDmod 2.31 activation-sentinel / standalone-tweak grammar evidence — 2026-09-15

Status: **SUPPORTED-INSTALL SOURCE/SCHEMA EVIDENCE + ATTENDED PARSER EVIDENCE; W08.1 OFFICIAL COMPILE/DEPLOY STILL PARENT-OWNED**

Current issue: #55 — W08.1 REDMOD standalone tweak grammar repair  
Provenance: #53 / PR #54 — W07.1 activation-sentinel repair

## Why this record was corrected

W07.1 correctly proved that `IconicWeaponModAbilityBase` exists in CDPR's shipped Cyberpunk/REDmod 2.31 tweak source and that the source language has `package` / `using` concepts. W07.1 then overreached from that source evidence and selected a free-standing top-level `using Items` form for Biology's standalone mod tweak.

The next canonical-main attended deployment disproved that assumption. Official REDmod 2.31 reached Stage 3/5 — TweakDB Compilation and rejected `biology_activation.tweak` with:

```text
Expected end of file but got: 'using'.
```

Exact attended source: `23d67435817cf4d546c88d51ea261332facce69c`  
Exact artifact: `biology-integrated-20260915-185904-23d67435817c.zip`  
Artifact SHA-256: `FFFE1CF33EFB5114F22FC8EA465C0B330F51C6A9845FD25E1D037395CA365615`

That failure does **not** mean `IconicWeaponModAbilityBase` is absent. It means the standalone source grammar selected by W07.1 was not accepted.

## W08.1 exact-head source probe

The W08.1 read-only probe ran from exact worker head:

`4a0bbbf6ca25f9e381b8f01fba669f8a4b7e2c7a`

against:

`C:\Games\Steam\steamapps\common\Cyberpunk 2077`

Observed official REDmod identity:

- file version: `2.3.1.0`
- product version: `2.31`
- `redMod.exe` SHA-256: `144DF5A984669528CD957B40BB2126FE83B73D66BD0E041CA614C80F74E76A7F`
- shipped `.tweak` files scanned: `2684`

Returned report:

`Biology-Redmod-Activation-Sentinel-Probe-20260915-163220-16ec5f83.txt`

The report came directly from the supported installed game/REDmod tree. Its proprietary source excerpts are not committed; this file records only the bounded derived findings required by Biology.

## Direct findings

### 1. Exact package context of the native base

The exact shipped file that defines the native base is:

`tweaks/base/gameplay/static_data/database/items/weapons/parts/mods_abilities.tweak`

Its compilation-unit header begins:

```text
package Items
using RTDB, Prereqs, Effectors, Perks, BaseStats
```

and the base itself is declared unqualified inside that package:

```text
IconicWeaponModAbilityBase : WeaponModAbilityBase
```

Many descendants in the same source file likewise inherit from `IconicWeaponModAbilityBase` unqualified.

### 2. Native directive ordering

The bounded 2.31 scan found representative source files consistently using:

```text
package <PackageName>
using <ImportedPackages>
```

The probe explicitly searched for files whose **first package/import directive is `using`** and found **NO MATCHES**.

Together with the attended parser rejection, this is strong evidence that W07.1's free-standing first directive `using Items` was not native standalone grammar. Source evidence supports `package` as the compilation-unit context and `using` only after that context in the observed shipped surface.

This does not claim a complete formal grammar for every internal CDPR compiler mode; it states exactly what the supported installed source and the official mod parser have demonstrated.

### 3. Package membership is not whole-package replacement

CDPR's shipped tree contains many separate `.tweak` files declaring the same package namespaces. A `package Items` directive therefore acts as compilation namespace/context; it does not mean one source file owns or replaces the entire Items package.

Biology's candidate adds one uniquely named declaration inside that namespace. It does not copy, replace, or redefine CDPR's `mods_abilities.tweak`, and no vanilla gameplay record references the Biology marker.

Whether official REDmod accepts this additive `package Items` declaration from a standalone mod-owned file is still a **compile/deploy acceptance question**, not something cloud CI or source inspection can prove. P01.1 owns that next direct test.

### 4. Qualified base spelling

The shipped 2.31 source does contain qualified-base inheritance in other packages, for example forms such as `CombatDecorator.InsideCoverDecorator` and `Condition.MovePolicyCooldown`.

However, the exact scan found **NO MATCHES** for:

`Items.IconicWeaponModAbilityBase`

Therefore W08.1 does not invent that spelling. The strongest direct evidence for this base is same-package, unqualified inheritance under `package Items`.

### 5. Boolean/schema and REDscript read evidence

The shipped tweak source uses explicitly typed Boolean flats, but the bounded scan found **no shipped examples** of an arbitrary unbased group containing an explicitly typed Boolean flat. Biology therefore continues to avoid inventing a custom unbased Boolean schema.

The shipped `TweakDBInterface` surface declares:

`GetBool(path, defaultValue)`

Biology's existing REDscript read path remains:

`Items.BiologyLauncherActivationMarker.stackable`

with `false` as the missing-value default. Launcher authority therefore remains fail-closed if the marker is absent.

The generated record surface inspected by the probe still yielded no `gamedataItem_Record` evidence, so W08.1 does not invent an item-record fallback either.

## Explicit answers to issue #55

1. **Native ordering/scope:** observed shipped 2.31 `.tweak` units declare `package` first. When imports are needed, `using` follows the package declaration. The exact `IconicWeaponModAbilityBase` source is `package Items` and uses the base unqualified within that namespace.
2. **Is free-standing `using` legal?** Official REDmod 2.31 attended parsing proves Biology's first-directive `using Items` form is not legal in this standalone mod unit. The shipped-source scan found no first-directive `using` examples. W08.1 does not claim more than that evidence supports.
3. **Can Biology declare `package Items`?** Source semantics show package declarations are shared namespace membership rather than whole-file/package replacement. The candidate is additive and uniquely named, so it does not pretend to replace CDPR's Items source. **Standalone REDmod acceptance remains pending the parent compile/deploy test.**
4. **If package membership is rejected for mod-owned source:** no community/TweakXL convention is adopted preemptively. The next investigation must identify another inert official REDmod-owned signal that is present only with REDmods enabled/deployed and queryable from Biology REDscript. That fallback is intentionally unresolved until official REDmod proves the package candidate invalid.
5. **Fully-qualified native base spelling:** qualified inheritance exists generally, but `Items.IconicWeaponModAbilityBase` does not appear in the scanned official 2.31 source. W08.1 does not invent it.

## Selected W08.1 candidate

Preserve the existing final TweakDB identity and REDscript read path:

`Items.BiologyLauncherActivationMarker.stackable`

Use the source shape that most directly mirrors the native base file:

```text
package Items

BiologyLauncherActivationMarker : IconicWeaponModAbilityBase
{
    stackable = true;
}
```

The marker remains inert: no gameplay record points to it. Its only Biology consumer is the launcher-activation Boolean read.

## Validation boundary

Cloud CI can and should establish:

- the marker file is packaged;
- source structure uses `package Items` before the unqualified declaration;
- the attended-invalid free-standing `using Items` form is rejected by regression tests;
- the final TweakDB/read-path identity stays `Items.BiologyLauncherActivationMarker.stackable`;
- missing marker state remains `GetBool(..., false)` fail-closed;
- package/install/build contracts remain structurally consistent;
- local probe/bootstrap failure evidence remains durable.

Cloud CI **cannot emulate the proprietary REDmod TweakDB parser** and must not report source/schema evidence as official mod compilation.

Therefore official REDmod 2.31 TweakDB compilation/deployment of the W08.1 candidate remains pending the **parent P01.1** integrated gate. No worker-branch install/play is requested.
