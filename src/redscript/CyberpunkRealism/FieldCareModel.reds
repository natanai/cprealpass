// Original field-care transaction preparation. Clinical care and chrome repair
// cannot be purchased through this portable-kit path.
module CyberpunkRealism.Physiology

public class CRFieldCarePlan extends IScriptable {
  public let before: ref<CRInjuryState>;
  public let after: ref<CRInjuryState>;
  public let region: Int32 = 0;
  public let kind: Int32 = 0;
  public let committed: Bool = false;
  public let spending: Bool = false;
}

public class CRFieldCareModel extends IScriptable {
  public static func CanHelp(state: ref<CRInjuryState>, region: Int32, kind: Int32) -> Bool {
    let r: ref<CRRegionalInjury>;
    if !IsDefined(state) || !CRInjuryModel.ValidState(state) {
      return false;
    }
    r = CRInjuryModel.Region(state, region);
    if !IsDefined(r) {
      return false;
    }
    if kind == 2 {
      return r.externalBleedMlPerHour > 0.0;
    }
    if kind == 3 && region >= 3 && region <= 6 {
      return r.boneDamage > 0.0 && r.support < 1.0;
    }
    return false;
  }

  public static func Prepare(state: ref<CRInjuryState>, region: Int32, kind: Int32) -> ref<CRFieldCarePlan> {
    let plan: ref<CRFieldCarePlan>;
    if !CRFieldCareModel.CanHelp(state, region, kind) {
      return null;
    }
    plan = new CRFieldCarePlan();
    plan.before = CRInjuryModel.Copy(state);
    plan.after = CRInjuryModel.Copy(state);
    plan.region = region;
    plan.kind = kind;
    if !CRInjuryModel.Treat(plan.after, region, kind, 1.0) {
      return null;
    }
    return plan;
  }

  // Check every region and the blood ledger, not just the selected limb. A
  // changed state after an inventory callback invalidates the prepared action.
  public static func Same(a: ref<CRInjuryState>, b: ref<CRInjuryState>) -> Bool {
    let i: Int32 = 1;
    let x: ref<CRRegionalInjury>;
    let y: ref<CRRegionalInjury>;
    if !IsDefined(a) || !IsDefined(b) || !CRInjuryModel.ValidState(a) || !CRInjuryModel.ValidState(b) {
      return false;
    }
    if a.bloodLossExposure != b.bloodLossExposure || a.bloodLostMl != b.bloodLostMl || a.bloodDeficitMl != b.bloodDeficitMl || a.bloodRecoveredMl != b.bloodRecoveredMl {
      return false;
    }
    while i <= 6 {
      x = CRInjuryModel.Region(a, i);
      y = CRInjuryModel.Region(b, i);
      if x.tissueDamage != y.tissueDamage || x.boneDamage != y.boneDamage || x.cyberwareDamage != y.cyberwareDamage || x.externalBleedMlPerHour != y.externalBleedMlPerHour || x.internalBleedMlPerHour != y.internalBleedMlPerHour || x.support != y.support || x.clinicalCare != y.clinicalCare {
        return false;
      }
      i += 1;
    }
    return true;
  }

  public static func Commit(plan: ref<CRFieldCarePlan>, state: ref<CRInjuryState>) -> Bool {
    let expected: ref<CRInjuryState>;
    if !IsDefined(plan) || plan.committed || !CRFieldCareModel.Same(plan.before, state) || !CRFieldCareModel.CanHelp(state, plan.region, plan.kind) {
      return false;
    }
    expected = CRInjuryModel.Copy(state);
    CRInjuryModel.Treat(expected, plan.region, plan.kind, 1.0);
    if !CRFieldCareModel.Same(expected, plan.after) {
      return false;
    }
    // Mutate the existing injury state, retaining its identity and every other
    // field. No HP refill, internal-bleed cure, bone healing or chrome repair.
    CRInjuryModel.Treat(state, plan.region, plan.kind, 1.0);
    plan.committed = true;
    return true;
  }
}
