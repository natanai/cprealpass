// Original bounded bridge bookkeeping. No game clock, HP writes or callbacks.
module CyberpunkRealism.Physiology

public class CRBloodLossDelivery extends IScriptable {
  // 1 queued, 5 admitted, 2 prepared, 3 native response, 0 invalidated.
  public let phase: Int32 = 1;
  public let queuedAt: Float;
  public let proposedDamage: Float;
  public let reportedHealthDamage: Float;
  public let resourcesSubmitted: Bool = false;
}
public class CRBloodLossCursor extends IScriptable {
  public let injury: ref<CRInjuryState>;
  public let exposure: Float;
  public let carry: Float;
  public let allowed: Bool;
  public let pending: ref<CRBloodLossDelivery>;
  public let droppedFraction: Float;
}
public class CRBloodLossModel extends IScriptable {
  public static func Invalidate(cursor: ref<CRBloodLossCursor>) -> Void {
    if !IsDefined(cursor) {
      return;
    }
    if IsDefined(cursor.pending) {
      cursor.pending.phase = 0;
    }
    cursor.pending = null;
    cursor.carry = 0.0;
    cursor.allowed = false;
  }
  public static func Sample(cursor: ref<CRBloodLossCursor>, injury: ref<CRInjuryState>, allowed: Bool, maximumHealth: Float, simSeconds: Float) -> ref<CRBloodLossDelivery> {
    let delta: Float;
    let next: ref<CRBloodLossDelivery>;
    if !IsDefined(cursor) {
      return null;
    }
    if !IsDefined(injury) || !CRInjuryModel.ValidState(injury) || !(simSeconds >= 0.0 && simSeconds <= 1000000000.0) || !(maximumHealth >= 1.0 && maximumHealth <= 1000000000.0) {
      CRBloodLossModel.Invalidate(cursor);
      cursor.injury = null;
      return null;
    }
    // Transient cursor: restoration, replacement and protected intervals never
    // replay an old accumulated demand against the current actor's health.
    if cursor.injury != injury || injury.bloodLossExposure < cursor.exposure || !allowed || !cursor.allowed {
      CRBloodLossModel.Invalidate(cursor);
      cursor.injury = injury;
      cursor.exposure = injury.bloodLossExposure;
      cursor.allowed = allowed;
      return null;
    }
    delta = injury.bloodLossExposure - cursor.exposure;
    cursor.exposure = injury.bloodLossExposure;
    cursor.droppedFraction += MaxF(0.0, cursor.carry + delta - 0.1);
    cursor.carry = MinF(0.1, cursor.carry + delta);
    if IsDefined(cursor.pending) && (cursor.pending.phase == 1 || cursor.pending.phase == 2 || cursor.pending.phase == 5) {
      if simSeconds >= cursor.pending.queuedAt && simSeconds - cursor.pending.queuedAt <= 2.0 {
        return null;
      }
      // A void QueueHitEvent call is not acceptance. Expire its identity rather
      // than retrying the same dose and risking double damage from late delivery.
      cursor.pending.phase = 0;
      cursor.pending = null;
    }
    if cursor.carry * maximumHealth < 1.0 {
      return null;
    }
    next = new CRBloodLossDelivery();
    next.queuedAt = simSeconds;
    next.proposedDamage = cursor.carry * maximumHealth;
    cursor.carry = 0.0;
    cursor.pending = next;
    return next;
  }
  public static func Current(cursor: ref<CRBloodLossCursor>, delivery: ref<CRBloodLossDelivery>, simSeconds: Float) -> Bool {
    return IsDefined(cursor) && cursor.allowed && IsDefined(delivery) && cursor.pending == delivery && (delivery.phase == 1 || delivery.phase == 2 || delivery.phase == 5) && simSeconds >= delivery.queuedAt && simSeconds - delivery.queuedAt <= 2.0;
  }
}