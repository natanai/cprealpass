// Project-original professional-care eligibility. This layer decides whether a
// completed clinical/mechanical service can materially help the authoritative
// regional injury state. It does not price services, create money scarcity, refill
// native HP, advance time, or mutate injuries itself.
module CyberpunkRealism.Physiology

public class CRProfessionalCareModel extends IScriptable {
  // 4 = completed biological/clinical care; 5 = completed mechanical chrome repair.
  public static func CanHelp(state: ref<CRInjuryState>, region: Int32, kind: Int32) -> Bool {
    let r: ref<CRRegionalInjury>;
    if !IsDefined(state) || !CRInjuryModel.ValidState(state) || region < 1 || region > 6 || (kind != 4 && kind != 5) {
      return false;
    }
    r = CRInjuryModel.Region(state, region);
    if !CRInjuryModel.ValidRegion(r) {
      return false;
    }
    if kind == 4 {
      // Clinical intervention can stop external/internal bleeding immediately and
      // establish professional aftercare that improves later biological recovery.
      // It never directly erases tissue/bone trauma or replaces lost blood.
      return r.externalBleedMlPerHour > 0.0 || r.internalBleedMlPerHour > 0.0 || ((r.tissueDamage > 0.0 || r.boneDamage > 0.0) && r.clinicalCare < 1.0);
    }
    // Mechanical repair is intentionally orthogonal to biological treatment.
    return r.cyberwareDamage > 0.0;
  }

  public static func ClinicalCanHelp(state: ref<CRInjuryState>, region: Int32) -> Bool {
    return CRProfessionalCareModel.CanHelp(state, region, 4);
  }

  public static func MechanicalCanHelp(state: ref<CRInjuryState>, region: Int32) -> Bool {
    return CRProfessionalCareModel.CanHelp(state, region, 5);
  }
}
