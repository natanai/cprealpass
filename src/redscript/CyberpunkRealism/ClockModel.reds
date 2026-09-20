// Cyberpunk Realism original source. Clock policy has no timers or logging.
module CyberpunkRealism.Physiology

public class CRClockState extends IScriptable {
  public let initialized: Bool = false;
  public let lastWorldSeconds: Int32 = 0;
  public let lastSimSeconds: Float = 0.0;
  public let previousAllowed: Bool = false;
  public let skipPending: Bool = false;
  public let unclassifiedWorldSeconds: Float = 0.0;
  public let suppressedWorldSeconds: Float = 0.0;
  public let lastObservedRatio: Float = 0.0;
}

public class CRClockModel extends IScriptable {
  public static func Reset(state: ref<CRClockState>, worldSeconds: Int32, simSeconds: Float, allowed: Bool) -> Void {
    state.initialized = true;
    state.lastWorldSeconds = worldSeconds;
    state.lastSimSeconds = simSeconds;
    state.previousAllowed = allowed;
  }

  public static func Observe(state: ref<CRClockState>, worldSeconds: Int32, simSeconds: Float, allowed: Bool) -> Float {
    if !state.initialized {
      CRClockModel.Reset(state, worldSeconds, simSeconds, allowed);
      return 0.0;
    }
    let delta: Float = Cast<Float>(worldSeconds - state.lastWorldSeconds);
    let simDelta: Float = simSeconds - state.lastSimSeconds;
    let previousAllowed: Bool = state.previousAllowed;
    CRClockModel.Reset(state, worldSeconds, simSeconds, allowed);
    if delta <= 0.0 || simDelta < 0.0 {
      return 0.0;
    }
    if state.skipPending {
      return 0.0;
    }
    if !allowed || !previousAllowed {
      state.suppressedWorldSeconds += delta;
      return 0.0;
    }
    // Unannounced large jumps are retained for classification. Never silently
    // treat a quest-driven jump as ordinary awake time or as sleep.
    if delta > 600.0 || simDelta <= 0.0 {
      state.unclassifiedWorldSeconds += delta;
      return 0.0;
    }
    state.lastObservedRatio = delta / simDelta;
    return delta / 3600.0;
  }

  public static func BeginSkip(state: ref<CRClockState>, worldSeconds: Int32, simSeconds: Float) -> Void {
    CRClockModel.Reset(state, worldSeconds, simSeconds, false);
    state.skipPending = true;
  }

  public static func FinishSkip(state: ref<CRClockState>, worldSeconds: Int32, simSeconds: Float, hours: Float) -> Float {
    let pending: Bool = state.skipPending;
    state.skipPending = false;
    CRClockModel.Reset(state, worldSeconds, simSeconds, false);
    if !pending || !(hours >= 0.0) || !(hours <= 72.0) {
      return 0.0;
    }
    return hours;
  }

  public static func CancelSkip(state: ref<CRClockState>, worldSeconds: Int32, simSeconds: Float) -> Void {
    state.skipPending = false;
    CRClockModel.Reset(state, worldSeconds, simSeconds, false);
  }
}
