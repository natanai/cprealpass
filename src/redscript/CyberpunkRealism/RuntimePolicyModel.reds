// Project-original, engine-independent runtime policy model.
//
// realpass ships one authored experience. These booleans are development/build
// isolation gates, never player preferences. Native acceptance remains a separate
// fail-closed dimension so an unvalidated adapter cannot run merely because the
// desired release profile includes that authority.
module CyberpunkRealism.Core

public class CRRuntimeFeatureFlags extends IScriptable {
  // Development profile gates. Release tooling fixes the accepted gameplay and
  // presentation authorities on; these exist so developers can isolate faults.
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

  // Diagnostics are development-only and never part of the locked release profile.
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

  // Fixed product decision. Development healthbar comparison builds are produced
  // by omitting the presentation source entirely rather than persisting a setting.
  public static func TraditionalHealthBars(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return false;
  }

  public static func Diagnostics(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return IsDefined(flags) && flags.diagnosticsAccepted && flags.diagnosticsEnabled;
  }

  public static func AnySimulation(flags: ref<CRRuntimeFeatureFlags>) -> Bool {
    return CRRuntimePolicyModel.Body(flags) || CRRuntimePolicyModel.Injury(flags) || CRRuntimePolicyModel.Combat(flags) || CRRuntimePolicyModel.Armor(flags) || CRRuntimePolicyModel.CyberwarePhysiology(flags);
  }
}
