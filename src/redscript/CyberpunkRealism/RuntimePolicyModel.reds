// Project-original, engine-independent runtime policy model.
//
// This deliberately separates player intent from build/native acceptance. Public
// settings can default to the intended realpass experience without activating an
// unaccepted native bridge in a development build. Engine/Mod Settings adapters
// should translate their state into CRRuntimeFeatureFlags rather than duplicating
// dependency logic in every hook.
module CyberpunkRealism.Core

public class CRRuntimeFeatureFlags extends IScriptable {
  // Player intent / authored defaults.
  public let bodyEnabled: Bool = true;
  public let nutritionEnabled: Bool = true;
  public let hydrationEnabled: Bool = true;
  public let sleepEnabled: Bool = true;
  public let exertionEnabled: Bool = true;
  public let eliminationEnabled: Bool = true;
  public let hygieneEnabled: Bool = true;

  public let injuryEnabled: Bool = true;
  public let bloodLossEnabled: Bool = true;
  public let impairmentEnabled: Bool = true;
  public let fieldCareEnabled: Bool = true;
  public let injuryRecoveryEnabled: Bool = true;

  public let combatEnabled: Bool = true;
  public let armorEnabled: Bool = true;
  public let armorWearEnabled: Bool = true;
  public let cyberwarePhysiologyEnabled: Bool = true;

  public let presentationEnabled: Bool = true;
  public let nameplatesEnabled: Bool = true;
  public let statusCuesEnabled: Bool = true;
  // realpass' authored presentation default is no continuous traditional HP bars.
  // This remains an accessibility/player-choice setting, not a combat authority.
  public let traditionalHealthBarsEnabled: Bool = false;

  // Diagnostics are intentionally opt-in even when an attended build allows them.
  public let diagnosticsEnabled: Bool = false;

  // Build/native acceptance gates. Development defaults remain closed.
  public let bodyAccepted: Bool = false;
  public let injuryAccepted: Bool = false;
  public let combatAccepted: Bool = false;
  public let armorAccepted: Bool = false;
  public let cyberwarePhysiologyAccepted: Bool = false;
  public let presentationAccepted: Bool = false;
  public let diagnosticsAccepted: Bool = false;
}

public class CRRuntimePolicyModel extends IScriptable {
  public static func Body(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.bodyAccepted && flags.bodyEnabled;
  }

  public static func Nutrition(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) && flags.nutritionEnabled;
  }

  public static func Hydration(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) && flags.hydrationEnabled;
  }

  public static func Sleep(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) && flags.sleepEnabled;
  }

  public static func Exertion(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) && flags.exertionEnabled;
  }

  public static func Elimination(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) && flags.eliminationEnabled;
  }

  public static func Hygiene(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) && flags.hygieneEnabled;
  }

  public static func Injury(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.injuryAccepted && flags.injuryEnabled;
  }

  public static func BloodLoss(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Injury(flags) && flags.bloodLossEnabled;
  }

  public static func Impairment(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Injury(flags) && flags.impairmentEnabled;
  }

  public static func FieldCare(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Injury(flags) && flags.fieldCareEnabled;
  }

  public static func InjuryRecovery(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Injury(flags) && flags.injuryRecoveryEnabled;
  }

  public static func Combat(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.combatAccepted && flags.combatEnabled;
  }

  // Combat may remain active when injury is disabled. The native adapter must then
  // use its documented non-injury fallback instead of leaving half-active wounds.
  public static func CombatInjury(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Combat(flags) && CRRuntimePolicyModel.Injury(flags);
  }

  public static func Armor(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.armorAccepted && flags.armorEnabled;
  }

  public static func ArmorWear(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Armor(flags) && flags.armorWearEnabled;
  }

  public static func CombatArmor(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Combat(flags) && CRRuntimePolicyModel.Armor(flags);
  }

  public static func CyberwarePhysiology(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.cyberwarePhysiologyAccepted && flags.cyberwarePhysiologyEnabled;
  }

  public static func Presentation(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.presentationAccepted && flags.presentationEnabled;
  }

  public static func Nameplates(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Presentation(flags) && flags.nameplatesEnabled;
  }

  public static func StatusCues(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Presentation(flags) && flags.statusCuesEnabled;
  }

  public static func TraditionalHealthBars(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Presentation(flags) && flags.traditionalHealthBarsEnabled;
  }

  public static func Diagnostics(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.diagnosticsAccepted && flags.diagnosticsEnabled;
  }

  // Presentation and diagnostics intentionally do not count as simulation
  // authorities. This is useful for lifecycle adapters deciding whether any
  // physical state mutator should be scheduled at all.
  public static func AnySimulation(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) || CRRuntimePolicyModel.Injury(flags) || CRRuntimePolicyModel.Combat(flags) || CRRuntimePolicyModel.Armor(flags) || CRRuntimePolicyModel.CyberwarePhysiology(flags);
  }
}
