// Project-original pain runtime. It owns only perceived-pain/analgesic state and
// derives time exclusively from CRBodyRuntime's authored elapsed body time. There is
// no second timer, no HP authority and no independent injury state.
module CyberpunkRealism.Integration

import CyberpunkRealism.Physiology.*

public class CRPainRuntime extends ScriptableSystem {
  private persistent let state: ref<CRPainState>;
  private persistent let lastBodyHours: Float = -1.0;

  public static func Get() -> ref<CRPainRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRPainRuntime>()) as CRPainRuntime;
  }

  private func EnsureState() -> Void {
    if !CRPainModel.Valid(this.state) {
      this.state = CRPainModel.Create();
    }
  }

  // Synchronize analgesic decay to the same body clock that advances hydration,
  // sleep, wounds and blood loss. If a save/rollback rebases elapsed body time,
  // re-anchor rather than inventing negative pharmacology time.
  private func Sync() -> ref<CRBodyState> {
    let body: ref<CRBodyState>;
    let delta: Float;
    this.EnsureState();
    if !CRBodyRuntime.Get().OwnsNeeds() {
      return null;
    }
    body = CRBodyRuntime.Get().GetBodySnapshot();
    if !IsDefined(body) || !body.initialized {
      return null;
    }
    if this.lastBodyHours < 0.0 || body.elapsedHours < this.lastBodyHours {
      this.lastBodyHours = body.elapsedHours;
      return body;
    }
    delta = body.elapsedHours - this.lastBodyHours;
    if delta > 0.0 {
      if !CRPainModel.Advance(this.state, MinF(delta, 72.0)) {
        return null;
      }
      // Extremely long offline/body jumps are already bounded elsewhere; if a
      // future body clock can exceed 72 hours in one observation, consume it in
      // deterministic chunks instead of creating a second timing policy.
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
