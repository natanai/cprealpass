# Biology product completion audit — 2026-09-20

Owner-authorized run: #152, `autonomous/final-product-completion`.
Starting main: `d2a4c8f1c166bbfd0227451cbf32e3793f10ea72`.

This ledger separates source/model proof from engine behavior. **PASS** means the
stated gate actually ran; **BROKEN** means a known defect still needs work;
**MISSING** means an intended deliverable is absent; **LIVE-ONLY** means a working
source/model path still requires native gameplay or visual observation. A compile
or model result never establishes live save serialization or rendered acceptance.

All production sources below are in `src/redscript/CyberpunkRealism/`. All 65 files
exact-compiled together against the installed 2.31 base in
`autonomous-audit-7` and the `cf1bc0994cfc` release build (diagnostics OFF). Tests are under `tests/`. Every production
script is bundled as Biology-owned supplemental redscript; the official REDmod
marker controls activation. Models have no independent timers or native HP pool.

| Canonical goals / feature family | Source authority and native seam | Automated coverage | Persistence / packaging | Audit state |
| --- | --- | --- | --- | --- |
| G-001–005, G-010–017, G-020–022: identity, scope, ownership, native-first dependencies | RuntimePolicyModel; manifest/runtime-modules, feature-inventory, dependency-graph, distribution; original code behind narrow native wrappers | RuntimeOriginPolicy, RuntimePolicyModel, FeatureInventory, ModuleContract, DistributionContract | One mods/Biology identity; only pinned redscript/cybercmd, MIT notices | PASS source contracts and 86-file ZIP/license policy |
| G-023: physical outfits | PhysicalOutfits; native wardrobe apply and carried-item EquipmentSystem transactions | PhysicalOutfits | Native item ownership; no duplicate inventory, no cosmetic protection authority | LIVE-ONLY equip/quest restrictions; source implemented |
| G-030–032: physical hit, regional impact, player/NPC symmetry | CombatNativeBridge, CombatWoundsNative, HitModel, BallisticProfiles, ImpactModel, WoundModel, CombatProfilesNative; ProcessOneShotProtection -> native resource loss -> SendDamageEvents | CombatCore, BallisticProfiles, CombatFeelEnvelope, WoundPipeline | Native Health loss is required; body is the only player injury authority | T007 shared player gate repaired; LIVE-ONLY accepted hit / quest / boss semantics |
| G-022, G-030: stock clothing/protection/armor wear | StockProtectionCatalog, ArmorWearModel/Native; actual equipment IDs, native impact shapes, accepted loss | ArmorWear, WoundPipeline | Wear keyed to actual item; unknown protection caps Biology at native physical damage | LIVE-ONLY equipment calibration; implemented |
| G-040: tissue, bone, chrome, external/internal bleeding | InjuryModel, WoundModel, BodyInputs, CombatWoundsNative | InjuryBody, WoundPipeline, BodyInputs | CRBodyState.injuries; NPC schema 2 migrates old regional state | LIVE-ONLY native hits; model/source covered |
| G-042, G-053: bleeding/recovery/impairment | BloodLossModel/Native, InjuryEffectsModel/Native, NPCBodyModel; one body clock, bounded native modifiers | BloodLoss, InjuryEffects, NPCProgression | Transient modifiers reconstructed; 128 weak NPC registrations maximum | Player gate repaired; LIVE-ONLY native feedback |
| G-047–048: bounded causal history | InjuryProvenance, ConditionPresentation | ConditionArchitecture and condition/UI contracts | Save-backed bounded explanatory history; cannot veto accepted wound | LIVE-ONLY save reload; implemented |
| G-049–052: field/clinical/mechanical care | FieldCareModel/Runtime, FieldCareActionModel/Runtime, ProfessionalCareModel/Runtime, BiologyActionsNative | FieldCare, FieldCareTimed, ProfessionalCare | Real native carried supplies, transaction preflight, context-bound care; same injury state | PASS source/session/supply audit; LIVE-ONLY context/animation interactions |
| G-054–057: MaxDoc, pain, diminishing relief, overdose | PainModel/Runtime, PainNativeEffects, BodyNativeHooks.UseHealChargeAction.ProcessStatusEffects | PainModel, BarlessFeedbackEnvelope | Persistent analgesic load; native inhaler/charge flow; no tissue or HP refill | LIVE-ONLY native feedback; missing/rejected authority now yields native action |
| G-060: awake clock, exertion, hydration, nutrition/energy, digestion, bladder/bowel, hygiene | BodyModel, ClockModel, BodyRuntime, BodyNativeHooks; GameTime + simulation clock + PlayerStateMachine | BodyModel, BodyInputs, ClockModel, PlayerLifecycleAndPreferences | One CRBodyRuntime persistent body; transient clock rebased on restoration | T007 NPC scene predicate replaced with player PSM/pause gate; LIVE-ONLY observed progression |
| G-053, G-060: sleep and WAIT | SleepModel, BodyForecast, BodyNativeHooks; bracket native TimeskipGameController.Apply; hub wait marker | SleepFatigue, BodyForecast, ClockModel | Same body/queue; no second offline clock; duplicate/cancelled skips rejected | LIVE-ONLY sleep/WAIT event classification |
| G-061–066: intake and body interactions | ItemServing, ServingModel, BodyInteractionRuntime, BiologyActionsNative; native ConsumeAction/item transaction and shower completion | BodyInteractions, BodyInputs, BodyPresentation | No duplicated inventory; ordered inputs on same body | LIVE-ONLY actual food/shower/action completion |
| G-060, G-090: body availability and save migration | BodyRuntimeAuthority, BiologyRuntimeAvailability, BodyPresentation | BodyRuntimeAuthority, BodyRuntimePersistence, BiologyRuntimeLifecycle | Body schema 0/1 -> 2, future/corrupt schemas fail closed; no save-file edits | PASS model/schema contracts; LIVE-ONLY game save serialization |
| G-041, G-043–046, G-063: overview, body categories, drill-down/Back, zoom, Cyberware | BiologyCyberwareShell, BiologyLiveShellFollowupNative, BiologyModeSyncNative, BiologyRadialHubNative | BiologyShell, BiologyNativeDrilldown, BiologyBackTransition, BiologyDetailLayout, BiologyDetailPostMountVisibility | Native anatomy/Inventory sibling of cyberwareContainer; no virtualGridContainer host | T007 KEEP evidence; LIVE-ONLY regression of render/equip/vendor flows |
| G-045, G-047, G-062, G-064–066: authoritative metrics and contextual actions | BiologyPresentation, BiologySessionPresentation, BiologyDetailPresentation, BodyStatusPresentation, ConditionPresentation, BiologyActionsNative | BodyPresentation, Biology UI/authority tests | Read-only projection; no fake healthy state; details only | Exact-compile PASS; LIVE-ONLY final rendering |
| G-033, G-074: actor HP suppression independent of E3 | NoHealthbars; native health/boss/nameplate controller wrappers | NoHealthbars, SettingsRuntimeSurface, PlayerDisableContract | No saved meter authority; launcher OFF returns native | LIVE-ONLY actor/vehicle/objective distinction |
| G-070–071: ambient/native/scanner identity | NameplatesNative, E3NameplatesNative; native m_isScanning + authored m_nameTextMain/m_nameFrame | E3NameplateIdentityFollowup, OwnedNameplates, E3OwnedPresentation | No mutation of NPCNextToTheCrosshair; hidden/quest/alternative/disabled policies preserved | T007 conflict repaired in source; LIVE-ONLY scanner transition/render |
| G-071–072: quest, D-pad, ammo, minimap, reticle, interaction/activity accents | E3*HudNative, E3FirstPersonHud, E3PresentationPrimitives; authored semantic hosts | E3OwnedPresentation, E3ReferenceArchaeology | Captured reversible styling; no E3 payload; diagnostics off | T005–T007 KEEP evidence; added preference-change refresh; LIVE-ONLY visual restore |
| G-073: one persistent E3 Boolean | RealpassSettings, BiologyPreferencesNative; player-owned GameInstance -> ScriptableSystemsContainer -> saved preference | SettingsContract, SelfContainedSettings, SettingsRuntimeSurface, BiologyE3PreferencePlacement, PlayerLifecycleAndPreferences | Existing persistent field retained; missing authority fails visibly; launcher always wins | T007 context/target/write defects repaired; LIVE-ONLY click/save reload |
| G-002, G-074, G-080–081: launcher OFF/ON | REDmod-owned Items.BiologyLauncherActivationMarker; policy accessors and all production hooks | ActivationGates, PlayerDisableContract, ActivationHookAudit (87 native entry points) | Saves remain inert; generic loaders preserved; no persistent Biology launcher | PASS all-hook source audit and ON/OFF launch-flag startup; LIVE-ONLY checkbox/gameplay transitions |
| G-016, G-080: obvious safe one-download installer | Build-BiologyPackage, BiologyInstallCore/Program; transactional exact-hash preflight | BiologyReleaseInstallSafety, InstallContract | Extract outside game; shared loader conflicts fail before mutation | PASS native EXE, 31 ownership/upgrade/rollback fixtures + junction rejection; actual upgrade/reinstall |
| G-080: uninstall, upgrade, same-version reinstall | BiologyUninstallCore/Program, BiologyPriorInstallTransition.Core, removal verifier | PlayerUninstaller (46 safety checks), release/transition/removal safety tests | Receipt-bounded files; no recursive game/shared-root deletion; preserve saves/dependencies | PASS actual packaged EXE removal, 9 shared files preserved, clean reinstall and REDmod refresh |
| G-082, G-090: exact compile, reproducible package, CI | Build-OwnedAcceptance, Compile-Profile, Build-BiologyPackage, .github/workflows/ci.yml | Run-CI, PowerShellSyntax, CompileGuard, ArtifactPolicy | Proprietary base read-only; final.redscripts excluded | PASS 88 CI suites, 65-source exact compile, 86-file artifact policy; final merged build identity in release handoff |
| G-083, G-091–093: evidence and safe autonomous completion | Owner #152 handoff supersedes sole-agent/launch process restrictions for this run | Test ledger and exact reports | No save loading/editing; safe main-menu smoke authorized; no workers | PASS local implementation/lifecycle; final source/artifact handoff records reconciliation; LIVE-ONLY observations retained |

Excluded inventory features remain deliberately absent: Dark Future item renames,
carry/stamina hardship, stash restrictions, fast-travel restrictions/marker hiding,
vehicle summon limits, random sleep encounters, arbitrary nerve death, humanity/
cyberpsychosis, addiction, economy/prices, consumable weight rebalance, source-mod
transmog, and E3 scanner replacement. `Test-FeatureInventory` and runtime/artifact
origin guards cover all `remove` dispositions. Development diagnostics remain
compile-gated OFF in normal packages.

## Evidence and limits

- Baseline full suite: one failure, `Test-ReferenceModArchaeology` attempted a
  network tool download after intentionally failing its missing-game fixture.
  Guard repaired; focused rerun PASS. No production game files changed.
- Exact compile `autonomous-t007-2` and `autonomous-audit-7` and the `cf1bc0994cfc` release build: PASS, 65 sources,
  redscript CLI 0.5.31; installed base used read-only.
- Actual-source lifecycle/preference regression: 41 checks PASS. Engine-facing
  APIs are fixture doubles; these tests cannot prove real pointer dispatch.
- The T007 ZIP was not found in designated local evidence folders. Owner-provided
  findings and issue #151 remain the available primary attended evidence.
- T007 did not record individual old eligibility predicates. The NPC scene query
  is demonstrably the wrong player lifecycle abstraction; its exact live Boolean
  at the failed tick cannot be reconstructed from that evidence. The replacement
  uses installed native PSM tiers and pause/menu state; do not claim an observed
  before/after gameplay run without actually performing one.

Final lifecycle/artifact/CI findings will replace the pending gate entries here
and be summarized in the owner handoff when work completes.
