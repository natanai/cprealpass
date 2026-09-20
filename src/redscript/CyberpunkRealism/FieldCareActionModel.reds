// Original interruptible field-care action. Transient; no save state or timer.
module CyberpunkRealism.Physiology
public class CRFieldCareAction extends IScriptable {
  // 1 queued in inventory; 2 working; 3 ready for exactly one completion.
  public let stage: Int32;
  public let region: Int32;
  public let kind: Int32;
  public let elapsed: Float;
  public let lastSim: Float;
  public let samples: Int32;
}
public class CRFieldCareActionModel extends IScriptable {
  public static func Duration(kind: Int32) -> Float {
    if kind == 2 {
      return 8.0;
    }
    if kind == 3 {
      return 12.0;
    }
    return 0.0;
  }
  public static func Create(region: Int32, kind: Int32) -> ref<CRFieldCareAction> {
    let action: ref<CRFieldCareAction>;
    if region < 1 || region > 6 || CRFieldCareActionModel.Duration(kind) <= 0.0 || kind == 3 && region < 3 {
      return null;
    }
    action = new CRFieldCareAction();
    action.stage = 1;
    action.region = region;
    action.kind = kind;
    return action;
  }
  // 0 cancel; 1 queued; 2 started; 3 continue; 4 ready. Completion itself
  // never spends inventory here and must re-prepare from the current body state.
  public static func Sample(action: ref<CRFieldCareAction>, sim: Float, allowed: Bool, inMenu: Bool, moving: Bool) -> Int32 {
    let delta: Float;
    if !IsDefined(action) || action.stage < 1 || action.stage > 2 {
      return 0;
    }
    action.samples += 1;
    if !allowed || !(sim >= 0.0 && sim <= 1000000000.0) || action.samples > 240 {
      action.stage = 0;
      return 0;
    }
    if action.stage == 1 {
      if inMenu {
        return 1;
      }
      if moving {
        action.stage = 0;
        return 0;
      }
      action.stage = 2;
      action.lastSim = sim;
      return 2;
    }
    delta = sim - action.lastSim;
    action.lastSim = sim;
    if inMenu || moving || !(delta >= 0.0 && delta <= 2.0) {
      action.stage = 0;
      return 0;
    }
    action.elapsed += delta;
    if action.elapsed >= CRFieldCareActionModel.Duration(action.kind) {
      action.stage = 3;
      return 4;
    }
    return 3;
  }
}