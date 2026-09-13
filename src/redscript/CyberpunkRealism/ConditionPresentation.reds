// Project-original qualitative projection from authoritative regional injury state
// plus bounded provenance into the Condition UI. No gameplay state is mutated here.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Physiology.*
import CyberpunkRealism.Integration.*

public class CRConditionDescriptor extends IScriptable {
  public let valid: Bool;
  public let hasCondition: Bool;
  public let region: Int32;
  public let regionName: String;
  public let title: String;
  public let severity: String;
  public let functionText: String;
  public let currentState: String;
  public let likelyCause: String;
  public let painText: String;
  public let fieldCare: String;
  public let professionalCare: String;
  public let canDress: Bool;
  public let canSupport: Bool;
  public let canClinical: Bool;
  public let canMechanical: Bool;
}

public class CRConditionPresentation extends IScriptable {
  public static func RegionName(region: Int32) -> String {
    switch region {
      case 1: return "Head";
      case 2: return "Torso";
      case 3: return "Left arm";
      case 4: return "Right arm";
      case 5: return "Left leg";
      case 6: return "Right leg";
    }
    return "Unknown";
  }

  private static func Severity(value: Float) -> String {
    // Presentation thresholds are provisional authored categories, not clinical
    // diagnoses. They intentionally hide exact model values from normal play.
    if value >= 0.70 { return "severe"; }
    if value >= 0.35 { return "significant"; }
    if value > 0.0 { return "minor"; }
    return "none";
  }

  private static func FunctionText(function: Float) -> String {
    if function < 0.0 { return "Function unavailable"; }
    if function < 0.50 { return "Function severely impaired"; }
    if function < 0.85 { return "Function impaired"; }
    return "Function near normal";
  }

  private static func PainText(pain: ref<CRPainProjection>) -> String {
    let text: String;
    if !IsDefined(pain) || !pain.valid {
      return "Pain response unavailable.";
    }
    if pain.perceivedPain >= 0.75 {
      text = "Pain response: severe.";
    } else {
      if pain.perceivedPain >= 0.45 {
        text = "Pain response: significant.";
      } else {
        if pain.perceivedPain >= 0.15 {
          text = "Pain response: noticeable.";
        } else {
          if pain.physicalPain > 0.0 {
            text = "Pain response: subdued.";
          } else {
            text = "Pain response: minimal.";
          }
        }
      }
    }
    if pain.analgesia > 0.0 && pain.physicalPain > 0.0 {
      text += " Trauma Kit analgesia is reducing perceived pain only.";
    }
    if pain.intoxication >= 0.66 {
      text += " Analgesic overuse: severe disorientation.";
    } else {
      if pain.intoxication > 0.0 {
        text += " Analgesic overuse: disorientation.";
      }
    }
    return text;
  }

  private static func ProjectileFamily(family: Int32) -> String {
    switch family {
      case 1: return "handgun";
      case 2: return "revolver";
      case 3: return "assault-rifle";
      case 4: return "machine-gun";
      case 5: return "shotgun";
      case 6: return "precision-rifle";
      case 7: return "submachine-gun";
    }
    return "ranged-weapon";
  }

  private static func Cause(entry: ref<CRInjuryProvenance>) -> String {
    if !CRInjuryProvenanceRuntime.Valid(entry) {
      return "Cause not recorded.";
    }
    let text: String = "Likely caused by a " + CRConditionPresentation.ProjectileFamily(entry.projectileFamily) + " projectile.";
    if entry.unresolvedProtectionLayers > 0 {
      return text + " Some protection could not be identified, so the impact path is incomplete.";
    }
    if entry.protectionEncountered {
      if entry.residualImpactJ > 0.0 {
        return text + " Protection was encountered, but residual impact reached the body.";
      }
      return text + " Protection absorbed the projectile; transferred impact still produced injury.";
    }
    return text + " No mapped protective layer intercepted the hit.";
  }

  private static func CurrentState(r: ref<CRRegionalInjury>) -> String {
    let text: String = "";
    if r.tissueDamage > 0.0 { text += "Soft-tissue trauma: " + CRConditionPresentation.Severity(r.tissueDamage) + ". "; }
    if r.boneDamage > 0.0 { text += "Bone trauma: " + CRConditionPresentation.Severity(r.boneDamage) + ". "; }
    if r.externalBleedMlPerHour > 0.0 { text += "External bleeding active. "; }
    if r.internalBleedMlPerHour > 0.0 { text += "Internal bleeding suspected. "; }
    if r.cyberwareDamage > 0.0 { text += "Cyberware structural damage: " + CRConditionPresentation.Severity(r.cyberwareDamage) + ". "; }
    if r.support > 0.0 && r.boneDamage > 0.0 { text += "Region supported/stabilized. "; }
    if r.clinicalCare > 0.0 && (r.tissueDamage > 0.0 || r.boneDamage > 0.0) { text += "Professional biological aftercare active. "; }
    return text;
  }

  private static func Title(r: ref<CRRegionalInjury>, entry: ref<CRInjuryProvenance>) -> String {
    if r.cyberwareDamage > 0.0 && r.cyberwareDamage >= MaxF(r.tissueDamage, r.boneDamage) { return "Cyberware structural damage"; }
    if CRInjuryProvenanceRuntime.Valid(entry) && entry.projectileFamily > 0 { return "Ballistic trauma"; }
    if r.boneDamage > 0.0 { return "Bone trauma"; }
    if r.tissueDamage > 0.0 { return "Soft-tissue trauma"; }
    if r.externalBleedMlPerHour + r.internalBleedMlPerHour > 0.0 { return "Bleeding injury"; }
    return "Condition";
  }

  private static func ProfessionalCare(r: ref<CRRegionalInjury>, canClinical: Bool, canMechanical: Bool) -> String {
    let text: String = "";
    if canClinical {
      if r.internalBleedMlPerHour > 0.0 { text += "Clinical intervention can control the internal bleeding. "; }
      if r.externalBleedMlPerHour > 0.0 { text += "Clinical intervention can control the external bleeding. "; }
      if r.tissueDamage > 0.0 || r.boneDamage > 0.0 { text += "Professional aftercare can support later biological recovery. "; }
    } else {
      if (r.tissueDamage > 0.0 || r.boneDamage > 0.0) && r.clinicalCare > 0.0 { text += "Professional biological aftercare is already active; recovery still takes body time. "; }
    }
    if canMechanical { text += "Ripperdoc/mechanical repair can address damaged chrome. "; }
    if Equals(text, "") { return "No additional professional intervention currently indicated by realpass."; }
    return text;
  }

  public static func Describe(state: ref<CRInjuryState>, region: Int32, entry: ref<CRInjuryProvenance>) -> ref<CRConditionDescriptor> {
    let result: ref<CRConditionDescriptor> = new CRConditionDescriptor();
    let r: ref<CRRegionalInjury>;
    let burden: Float;
    if !IsDefined(state) || !CRInjuryModel.ValidState(state) || region < 1 || region > 6 {
      return result;
    }
    r = CRInjuryModel.Region(state, region);
    if !CRInjuryModel.ValidRegion(r) {
      return result;
    }
    result.valid = true;
    result.region = region;
    result.regionName = CRConditionPresentation.RegionName(region);
    result.canDress = CRFieldCareModel.CanHelp(state, region, 2);
    result.canSupport = CRFieldCareModel.CanHelp(state, region, 3);
    result.canClinical = CRProfessionalCareModel.ClinicalCanHelp(state, region);
    result.canMechanical = CRProfessionalCareModel.MechanicalCanHelp(state, region);
    result.hasCondition = r.tissueDamage + r.boneDamage + r.cyberwareDamage + r.externalBleedMlPerHour + r.internalBleedMlPerHour > 0.0;
    if !result.hasCondition {
      result.title = "No active condition";
      result.severity = "none";
      result.functionText = "Function near normal";
      result.currentState = "No active regional injury recorded.";
      result.likelyCause = "";
      result.painText = "";
      result.fieldCare = "No field treatment indicated.";
      result.professionalCare = "No professional intervention indicated.";
      return result;
    }

    burden = MaxF(r.tissueDamage, MaxF(r.boneDamage, r.cyberwareDamage));
    result.title = CRConditionPresentation.Title(r, entry);
    result.severity = CRConditionPresentation.Severity(burden);
    result.functionText = CRConditionPresentation.FunctionText(CRInjuryModel.Function(state, region));
    result.currentState = CRConditionPresentation.CurrentState(r);
    result.likelyCause = CRConditionPresentation.Cause(entry);

    if result.canDress && result.canSupport {
      result.fieldCare = "Medical Gauze and limb support can help this condition.";
    } else {
      if result.canDress {
        result.fieldCare = "Medical Gauze can help the external bleeding.";
      } else {
        if result.canSupport {
          result.fieldCare = "Limb support can stabilize the bone injury.";
        } else {
          result.fieldCare = "No effective field treatment is currently available.";
        }
      }
    }
    result.professionalCare = CRConditionPresentation.ProfessionalCare(r, result.canClinical, result.canMechanical);
    return result;
  }

  public static func Current(region: Int32) -> ref<CRConditionDescriptor> {
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    let result: ref<CRConditionDescriptor>;
    if !IsDefined(body) {
      return new CRConditionDescriptor();
    }
    result = CRConditionPresentation.Describe(body.injuries, region, CRInjuryProvenanceRuntime.Get().LatestForRegion(region));
    if IsDefined(result) && result.valid && result.hasCondition {
      result.painText = CRConditionPresentation.PainText(CRPainRuntime.Get().Read());
    }
    return result;
  }
}
