# realpass combat calibration plan

## Purpose

This document defines how the combat model should be calibrated toward physical plausibility without pretending that a video-game hit region can produce a clinical prediction. It is a research/acceptance guide for the existing `ImpactModel`, `BallisticProfiles`, `WoundModel`, armor, injury and native bridge work.

The core rule is unchanged:

`projectile/ammunition -> impact region -> encountered material/protection -> penetration/energy transfer -> tissue or cybernetic structure -> physiological consequence -> treatment/recovery`

Native HP is an output adapter for the game engine. Target level/max HP must not determine the physical wound produced by the same impact.

## Evidence principles

### Shot placement and path outrank a single damage number

Wound-ballistics reviews emphasize that entrance location and projectile path are major determinants of serious injury or death; central nervous system disruption and massive organ/vascular destruction are qualitatively different from a generic loss of “health.” Projectile mass/velocity, construction, yaw/deformation/fragmentation, tissue properties and the permanent/temporary cavities all affect the injury.

Useful references:

- Maiden N. *Ballistics reviews: mechanisms of bullet wound trauma.* Forensic Sci Med Pathol. 2009. DOI: 10.1007/s12024-009-9096-6. https://pubmed.ncbi.nlm.nih.gov/19644779/
- Stefanopoulos PK et al. *Wound ballistics of firearm-related injuries—part 1: missile characteristics and mechanisms of soft tissue wounding.* Int J Oral Maxillofac Surg. 2014. DOI: 10.1016/j.ijom.2014.07.013. https://pubmed.ncbi.nlm.nih.gov/25128259/
- Stefanopoulos PK et al. *Wound ballistics 101: the mechanisms of soft tissue wounding by bullets.* Eur J Trauma Emerg Surg. 2017. DOI: 10.1007/s00068-015-0581-1. https://pubmed.ncbi.nlm.nih.gov/26470704/
- Baum GR et al. *Gunshot Wounds: Ballistics, Pathology, and Treatment Recommendations, with a Focus on Retained Bullets.* Orthop Res Rev. 2022. https://pmc.ncbi.nlm.nih.gov/articles/PMC9462949/

**Implementation consequence:** do not collapse realism into `kinetic energy -> HP`. Energy and penetration are useful physical inputs, but anatomy/region/material determine what that energy means. The current model already separates impact state from wound state; preserve that separation.

### High-energy transfer is not simply “high velocity”

The medical literature describes injury in terms of actual energy transfer and projectile/tissue interaction, not a velocity label alone. Projectile shape/construction/stability and the tissue encountered alter how much energy is deposited and what cavity is formed.

**Implementation consequence:** `BallisticProfiles` may start from representative mass/velocity/diameter values, but future mappings should add only distinctions the engine can reliably identify (for example projectile family/construction or armor-piercing behavior). Do not invent a large taxonomy that cannot be sampled from live attacks.

### Armor is a threat/coverage system, not a clothing stat

NIJ Standard 0101.07 and its threat-level companion distinguish handgun and rifle threat classes and test actual armor against specified projectiles/velocities. The standard concerns ballistic-resistant armor intended to protect covered torso areas; it does not imply that ordinary clothing is ballistic protection.

References:

- National Institute of Justice. *Ballistic Resistance of Body Armor, NIJ Standard 0101.07.* https://nij.ojp.gov/library/publications/ballistic-resistance-body-armor-nij-standard-010107
- NIJ background on HG/RF threat classes and representative test threats: https://nij.ojp.gov/topics/equipment-and-technology/ballistic-resistance-body-armor-nij-standard-010107

**Implementation consequence:** realpass armor needs (1) actual protective construction/class, (2) region coverage, (3) projectile-dependent resistance/penetration behavior, and (4) optional wear/degradation. A shirt or pants record must not become useful ballistic armor because the base game assigns a generic armor-related stat. A vest protects its covered region, not an exposed arm or leg.

NIJ classes are **calibration references, not lore claims** that a fictional 2077 item is certified to a modern real-world standard. Cyberpunk materials/cyberware may legitimately exceed modern armor, but the profile must say why rather than relying on item level.

## Current model strengths to preserve

The repository already contains several important anti-RPG invariants:

- the same physical impact creates the same wound regardless of target max HP; max HP only scales the native output channel;
- fully stopped projectiles can create blunt injury but do not create a fictitious open projectile tract;
- mechanical/cybernetic hits do not automatically create biological bleeding;
- injury state is regional rather than one global injury meter;
- accepted native reductions/protections can scale/reject the downstream wound so authored boss/quest protections are not blindly bypassed;
- armor wear is driven by absorbed impact rather than arbitrary combat ticks.

These are tested offline in the existing combat/wound/armor harnesses. Native behavior remains unaccepted until attended gameplay proves the engine data actually maps into those abstractions correctly.

## Known model limitations

### Region granularity

The current six-region anatomy model cannot distinguish heart/lung/aorta/spinal cord from generic torso tissue or brain/face/neck subpaths from a generic head region. Therefore coefficients such as `nativeHealthFractionAtFull` and bleed rates are aggregate game abstractions, not organ-level predictions.

**Do not “fix” this by random critical-hit dice.** First determine whether the engine exposes stable hit-shape/bone/material information that can support reproducible subregion classification. Randomness should represent unavoidable uncertainty only after deterministic engine evidence is exhausted.

### Energy deposition coefficients

Current deposit/tissue/bone/mechanical capacities are provisional. Energy conservation tests prove arithmetic consistency, not biological validity. Before retuning, collect representative live mappings for weapon/projectile family, speed/energy, region, armor state and final native result.

### Bleeding rates

Current external/internal bleeding rates are bounded gameplay approximations. Real hemorrhage depends on vessel/organ disruption and can vary enormously. Do not present ml/hour values to players as clinical measurements. Internally, they are useful for making severe vascular/torso injury evolve over credible minutes rather than via arbitrary damage-over-time ticks.

### Immediate incapacitation versus delayed death

Realistic combat needs to distinguish immediate loss of combat function from eventual blood-loss death. A severe limb injury can disable use without being immediately fatal; a penetrating torso injury may permit brief action before hemorrhage; destructive CNS injury can incapacitate immediately.

The game-facing adapter should therefore avoid making “fatal” synonymous with “subtract 100% HP instantly” in every case. Where the engine cannot model unconscious/incapacitated states safely, document the approximation explicitly.

## Calibration scenarios

These scenarios are acceptance targets, not exact medical probabilities:

| Scenario | Required qualitative result |
| --- | --- |
| Unarmored head hit, rifle-class projectile | Normally immediate catastrophic/incapacitating outcome; target level must not create a sponge. |
| Unarmored center torso hit, rifle-class projectile | Severe penetrating/internal injury with high incapacitation/fatality potential; no several-round HP sponge solely from level. |
| Unarmored torso hit, handgun-class projectile | Meaningful penetrating injury and plausible bleeding/impairment; may be survivable depending on path, so do not force deterministic instant death from energy alone. |
| Unarmored limb hit | Local tissue/bone/vascular injury and functional impairment; should not usually behave like a torso/head hit. |
| Projectile stopped by covered armor | No penetrating tract; blunt trauma may occur; uncovered regions remain vulnerable. |
| Rifle threat against handgun-only soft armor | High penetration risk unless fictional item profile explicitly justifies stronger material. |
| Hit outside vest coverage | Vest contributes no protection to that region. |
| Cybernetic limb hit | Structural/mechanical damage appropriate to construction; no default biological bleeding from a fully mechanical structure. |
| Same unarmored impact on low- and high-level ordinary human NPCs | Same physical wound severity before authored/quest protection logic. |
| Boss/quest-protected target | Preserve explicit authored immunity/caps through the acceptance/reconciliation layer; do not reinterpret level scaling as physical armor. |

## Native evidence to collect in an attended test

For a small controlled weapon set, record only finite, explicit observations while the player is present:

1. weapon/item record and attack/projectile profile that realpass sees;
2. target type and authored protection state;
3. hit region/shape/material classification;
4. sampled physical impact values before realpass;
5. equipped protective item and the region realpass thinks it covers;
6. realpass impact result: initial, dissipated, remaining and blunt energy;
7. proposed wound by region;
8. final native accepted physical damage/loss after game protections;
9. committed wound/bleed/impairment state;
10. visible gameplay outcome.

Do not leave a watcher/logger running between tests. A finite diagnostic command or short attended capture is sufficient.

## Promotion rule

No coefficient should be called “realistic” merely because it produces desirable difficulty. Promote a combat calibration only when:

- its causal explanation matches the physical pipeline;
- its representative outputs are consistent with wound-ballistics/armor principles at the level the engine can support;
- target level/max HP does not alter wound severity for an otherwise identical ordinary-human impact;
- armor protects only where/against what its profile says;
- player and ordinary human NPCs follow the same physical rules where the engine permits;
- authored boss/quest/nonlethal exceptions still work;
- the result survives save/reload and does not introduce unacceptable script latency.
