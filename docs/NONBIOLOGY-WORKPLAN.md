# Non-Biology implementation workplan

Status: active implementation handoff
Branch: `agent/nonbiology-settings-outfits-hud`
Base: `main` at `44393b2b332a7b7829ff5bb0983a34ce3790f5d1`
Last updated: 2026-09-14

## Why this file exists

This work is being done in parallel with another agent that owns the **Biology pipeline**. This document is intentionally detailed so a replacement agent can continue the non-Biology work without reconstructing chat history if the current conversation is cut off.

The parallel-work rule is strict:

- **Do not edit or redesign the Biology pipeline owned by the other agent while that work is active.**
- Prefer additive or isolated changes outside Biology-specific native UI files.
- Shared canonical docs may be updated only for explicit product decisions that affect this work, and such edits should be kept narrow to minimize merge conflict.
- Before merging this branch into `main`, compare against current `main`, rebase/merge as needed, resolve conflicts in favor of the newest Biology implementation, run CI, and do not overwrite newer Biology work.

## User decisions governing this batch

### 1. RealPass should appear in Mod Settings

The earlier "no Mod Settings presence" direction is superseded.

RealPass should have a small, stable Mod Settings surface that serves two purposes:

1. prove to the player that RealPass is installed/active;
2. provide a concise **feature ledger** describing the major systems RealPass currently owns.

The ledger is not patch notes, diagnostics, a changelog, or a raw subsystem dump. It should stay short and player-facing.

Likely ledger categories include:

- body / physiology;
- injury / bleeding / recovery;
- pain / MaxDoc analgesia;
- combat / ballistics;
- physical armor / protection;
- presentation / feedback;
- Biology interface once accepted.

The exact wording should describe current accepted ownership rather than promise unfinished features.

### 2. Some binary player preferences are acceptable

The prior all-or-nothing rule still applies to the **simulation authority**, but it does not forbid every user preference.

Allowed player-facing configuration is limited to **binary ON/OFF choices** where toggling the option does not change the underlying authored physical simulation. Examples may include presentation/accessibility channels such as contextual pain vocalizations, stronger visual discomfort effects, optional notifications, or similar non-authoritative cues.

Not allowed:

- damage multipliers;
- hunger/thirst rate sliders;
- bleed scaling;
- pain-strength percentages;
- armor scaling;
- MaxDoc dose/decay sliders;
- any numeric tuning control that produces materially different simulation balance;
- disabling core authorities such as injury, ballistics, body simulation, armor, bleeding or recovery.

Rule of thumb: **same hidden simulation, optional presentation channel** is acceptable. **Different physical rules or rates** are not.

### 3. Do not remove useful health/needs feedback before replacements work

The long-term goal remains to avoid traditional actor HP meters and permanent survival-meter walls. However, the current attended build proved that the replacement Biology/HUD/gameplay feedback is not yet functional enough to carry all necessary information.

Therefore health/needs suppression must be **replacement-gated**, not performed as a blind removal during development.

Transitional policy:

- keep vanilla feedback available where removing it would make the game unreadable before RealPass replacements are accepted;
- do not treat the temporary presence of vanilla feedback as the final design;
- progressively suppress/replace vanilla indicators only after the corresponding RealPass Biology/HUD/gameplay cue is demonstrably usable in-game;
- do not invent duplicate RealPass percentage bars merely to replace vanilla bars.

The top-left attended screenshot showed the current vanilla `HEALTH INDICATOR` still present. That is acceptable as a temporary fallback while the replacement feedback pipeline is incomplete, but it remains a release blocker against the final no-traditional-HP-bar goal.

### 4. Project E3 executing HUD is gone

Attended screenshots from the owned runtime showed no legacy red Project E3 HUD elements. Treat this as positive live evidence that source-mod HUD residue is no longer executing. RealPass-owned presentation can still borrow restrained visual inspiration later, but Project E3 runtime must stay absent.

### 5. Vanilla cosmetic transmog conflicts with physicalized combat

The stock Outfit/transmog system currently allows visible clothing to differ from the actual equipped/protective items. That violates the physicalized combat rule because the projectile should encounter the same physical item the player sees on V.

The preferred RealPass reinterpretation is:

**Outfits become physical equipment loadouts, not cosmetic overrides.**

Activating an outfit should attempt to equip the real items recorded in that outfit into V's actual equipment slots. The visible clothing and the protective clothing should therefore be the same objects.

Required behavior:

- preserving the familiar vanilla `Outfits` concept/UI is desirable when feasible;
- saving an outfit records actual clothing/equipment item identities for relevant wearable slots;
- activating an outfit performs real equip transactions for those items;
- it must not conjure the appearance of an item that is not actually equipped;
- it must not silently provide protection from a hidden item while displaying a different cosmetic item;
- a missing item must be handled honestly: do not synthesize it or fake its appearance;
- remote stash teleport is not assumed. If stash-backed loadouts are ever supported, they should require an appropriate stash context rather than materializing clothes anywhere in the world;
- outfit/loadout behavior must respect quest/special-equipment constraints and should fail safely rather than break scripted equipment states.

The exact native hooks and transaction semantics require research against Cyberpunk 2.31 before implementation.

## Workstream A — canonical settings contract

### Goal

Bring project intent/docs/tests into alignment with the new settings decision without weakening the fixed authored simulation.

### Tasks

1. Update `AGREED-GOALS.md` with stable goals that explicitly state:
   - RealPass appears in Mod Settings;
   - Mod Settings contains a concise read-only feature ledger;
   - only binary non-authoritative presentation/accessibility preferences may be exposed;
   - numeric scale/tuning controls are forbidden;
   - core physical authorities remain fixed for a given RealPass version.
2. Update `docs/SETTINGS-ARCHITECTURE.md` to supersede the blanket retirement of Mod Settings.
3. Update relevant package/dependency/manifest docs if Mod Settings becomes a justified generic framework dependency again.
4. Add/adjust tests so future agents cannot accidentally reintroduce gameplay sliders or core-system toggles.

### Acceptance

- Repository policy clearly distinguishes fixed simulation from optional presentation channels.
- CI fails if a player-facing numeric scaling setting or core-authority disable switch is introduced.
- The feature ledger is explicitly descriptive/read-only.

## Workstream B — Mod Settings runtime surface

### Goal

Make RealPass visibly present in the in-game Mod Settings menu without turning settings into a balance console.

### Research first

Inspect current/historical RealPass settings implementation and installed Mod Settings API patterns. Reuse only generic Mod Settings plumbing; do not restore source-mod gameplay ownership.

### Intended shape

A compact `RealPass` page/group with:

- a short status line such as `RealPass active` or equivalent;
- version/build text only if it can be supplied reliably without fragile generated values;
- a concise feature ledger using read-only labels/descriptions;
- a very small number of booleans for accepted presentation/accessibility preferences.

Do not expose hidden simulation values.

### First implementation preference

Start with the **read-only presence + ledger** before adding any optional booleans. Add binary preferences only where the native presentation code already has a safe, isolated on/off seam.

### Acceptance

- `Settings > Mods` visibly lists RealPass.
- Ledger is concise and not patch-note-like.
- No sliders, numeric inputs or balance multipliers exist.
- Core body/injury/combat/armor authorities cannot be disabled there.

## Workstream C — transitional feedback / healthbar policy

### Goal

Prevent the project from removing the player's only useful feedback before the RealPass replacement is functioning.

### Tasks

1. Audit `NoHealthbars.reds` and current native healthbar suppression seams.
2. Separate **final presentation target** from **development fallback behavior**.
3. Introduce a clear readiness gate/feature flag in authored code or build policy so V's stock health indicator is not forcibly removed until the replacement feedback path is accepted.
4. Preserve the ability to hide NPC HP bars where RealPass combat feedback is already adequate, but avoid broad changes that make attended testing unreadable.
5. Do not add permanent replacement percentage bars.
6. Document exactly which stock feedback remains temporarily and what acceptance event allows its removal.

### Important coordination constraint

The Biology agent owns the replacement body/needs presentation. This branch should not decide Biology layout or duplicate its state. It may expose a small adapter/readiness contract if needed, but should not modify the Biology UI itself.

### Acceptance

During development, the player is never left with neither vanilla feedback nor a functioning RealPass replacement. Final release acceptance still requires the traditional actor HP presentation to be removed where technically safe.

## Workstream D — physical Outfit/loadout architecture

### Goal

Eliminate cosmetic transmog as an authority conflict while preserving the convenience of saved outfits.

### Research questions

Identify the Cyberpunk 2.31 classes/systems that own:

- Outfit slot save/apply;
- wardrobe/transmog visual override;
- actual clothing equipment transactions;
- inventory ownership checks;
- equipment restrictions and quest overrides;
- stash availability/context if relevant.

Prefer a thin semantic hook at "apply outfit" or equivalent rather than replacing the full wardrobe UI.

### Proposed model

Each saved Outfit slot should resolve to a set of actual item identities/records for physical wearable slots. Applying the Outfit requests normal equip transactions for those actual items.

Potential safe behavior for unavailable items:

- equip all valid available items and clearly leave unavailable slots unchanged, or
- reject application as incomplete.

Choose the behavior only after understanding native UI feedback and transaction semantics. Do not silently substitute another item.

### Physical authority rules

- protection derives only from actually equipped protective items;
- visual appearance must follow actually equipped items rather than a parallel cosmetic set;
- ordinary clothing remains ordinary clothing;
- armor coverage/wear logic reads the same equipped state the player sees;
- no hidden transmog layer may make a different item appear over the protective item.

### Quest safety

Do not break scripted disguises, special quest outfits, forced equipment, or cutscene state. Detect and preserve stock game overrides where necessary.

### Acceptance

An attended test should demonstrate:

1. save an Outfit containing owned clothing;
2. change actual clothes;
3. apply the saved Outfit;
4. actual equipment slots change to the saved physical items;
5. appearance matches those equipped items;
6. armor/protection logic sees those same items;
7. removing/selling a saved item does not conjure it;
8. quest/special outfit behavior remains safe.

## Workstream E — attended evidence and project status

Record current live observations without overstating implementation:

- owned runtime installed and REDscript loaded after stale `realpass` namespace cleanup;
- legacy Project E3 red HUD elements absent in attended screenshots;
- vanilla health indicator still visible;
- vanilla consumable buff icons still visible after eating/drinking;
- no usable player-facing confirmation of RealPass needs response in the tested build;
- stock cosmetic Outfit/transmog remains active and conflicts with the intended physical-equipment model.

These observations should inform status/acceptance ledgers. Do not mark hidden physiology or combat mechanics as working merely because the game launches.

## Implementation order

Recommended sequence for this branch:

1. **Write/lock this workplan** — done first by design.
2. Update canonical goals/settings architecture for the explicit user decisions.
3. Audit and implement the minimum Mod Settings presence + read-only ledger.
4. Add settings policy tests forbidding numeric balance controls/core-system toggles.
5. Audit transitional healthbar behavior and implement replacement-gated suppression without touching Biology UI.
6. Research stock Outfit/transmog/equipment native seams.
7. Implement physical Outfit -> real equipment loadout behavior with quest safety.
8. Add model/policy/native-seam tests where possible.
9. Run cloud CI on this branch.
10. Compare branch against latest `main` because the Biology agent may have advanced it.
11. Integrate/rebase carefully; preserve newer Biology work.
12. Run CI again on the integrated head.
13. Fast-forward/merge into `main` only when green and conflict-free.
14. Give the user one concise local pull/deploy command plus an attended test checklist focused on settings, transitional HUD feedback, and physical Outfit behavior.

## Files likely to change

Expected non-Biology files include, subject to research:

- `AGREED-GOALS.md`
- `docs/SETTINGS-ARCHITECTURE.md`
- `docs/WORKLOG.md`
- `docs/PROJECT-STATUS.md` / acceptance ledger where appropriate
- `manifest/settings.json`
- dependency/package/runtime manifests if Mod Settings is reintroduced as justified plumbing
- a new or restored RealPass-owned settings adapter under `src/redscript/CyberpunkRealism/`
- `src/redscript/CyberpunkRealism/NoHealthbars.reds` or a nearby presentation gate
- new RealPass-owned Outfit/loadout adapter/model files
- tests covering settings policy, HUD transition policy and loadout authority

Avoid editing Biology-specific UI implementation files on this branch unless a later integration conflict forces a minimal compatibility change.

## Merge / handoff checklist

A future agent picking this up should first:

1. read `AGREED-GOALS.md`;
2. read this file fully;
3. inspect current `main` and determine what the Biology agent changed after base `44393b2`;
4. inspect branch `agent/nonbiology-settings-outfits-hud` for completed commits and CI status;
5. do not force-reset or overwrite `main`;
6. preserve the latest Biology pipeline when resolving conflicts;
7. keep the user-facing simulation fixed and never add numeric balance sliders;
8. remember that temporary vanilla health/needs feedback may remain until its replacement is actually accepted in-game;
9. remember that Outfit convenience is retained only by turning Outfit into a physical equipment loadout, not by preserving transmog.
