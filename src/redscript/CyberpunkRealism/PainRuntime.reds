// Project-original pain runtime. It owns only perceived-pain/analgesic state and
// derives time exclusively from CRBodyRuntime's authored elapsed body time. There is
// no second timer, no HP authority and no independent injury state.
module CyberpunkRealism.Integration

import CyberpunkRealism.Physiology.*

public class CRPainRuntime extends ScriptableSystem {
  private persistent let state: ref<CRPainState>;
  // REDscript persistent-field defaults must be literal constants. Keep an explicit
  // anchor bit instead of using a negative Float sentinel such as -1.0, which the
  // 2.31 compiler parses as a unary expression rather than a constant initializer.
  private persistent let lastBodyHours: Float = 0.0;
  private persistent let bodyClockAnchored: Bool = false;

  public static func Get() -> ref<CRPainRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRPainRuntime>()) as CRPainRuntime;
  }

  private func EnsureState() -> Void {
    if !CRPainModel.Valid(this.state) {
      this.state = CRPainModel.Create();
    }
  }

  // Synchronize analgesic decay to the same body clock that advances hydration,
  // sleep, wounds and blood loss. Use this ScriptableSystem's session when resolving
  // the single authoritative body rather than rediscovering a global context.
  private func Sync() -> ref<CRBodyState> {
    let bodyRuntime: ref<CRBodyRuntime>;
    let body: ref<CRBodyState>;
    let delta: Float;
    this.EnsureState();
    bodyRuntime = CRBiologySessionAuthority.Body(this.GetGameInstance());
    if !IsDefined(bodyRuntime) || !bodyRuntime.OwnsNeeds() {
      return null;
    }
    body = bodyRuntime.GetBodySnapshot();
    if !IsDefined(body) || !body.initialized {
      return null;
    }
    if !this.bodyClockAnchored || body.elapsedHours < this.lastBodyHours {
      this.lastBodyHours = body.elapsedHours;
      this.bodyClockAnchored = true;
      return body;
    }
    delta = body.elapsedHours - this.lastBodyHours;
    if delta > 0.0 {
      if !CRPainModel.Advance(this.state, MinF(delta, 72.0)) {
        return null;
      }
      delta -= MinF(delta, 72.0);
      while delta > 0.0 {
        if !CRPainModel.Advance(this.state, MinF(delta, 72.0)) {
          return null;
        }
        delta -= MinF(delta, 72.0);
      }
      this.lastBodyHours = body.elapsedHours;
    }
    return body;
  }

  public func Read() -> ref<CRPainProjection> {
    let body: ref<CRBodyState> = this.Sync();
    if !IsDefined(body) {
      return new CRPainProjection();
    }
    return CRPainModel.Read(body.injuries, this.state);
  }

  public func UseMaxDoc() -> Bool {
    if !IsDefined(this.Sync()) {
      return false;
    }
    // Deliberately touches only analgesia. Underlying injury/blood/chrome are not
    // arguments to this mutation and therefore cannot be repaired by MaxDoc.
    return CRPainModel.UseMaxDoc(this.state);
  }

  public func AnalgesicLoad() -> Float {
    this.Sync();
    if !CRPainModel.Valid(this.state) {
      return 0.0;
    }
    return this.state.analgesicLoad;
  }
}
