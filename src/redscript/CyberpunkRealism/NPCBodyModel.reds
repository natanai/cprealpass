// Original NPC progression through the shared body solver. No native clock.
module CyberpunkRealism.Physiology
public class CRNPCBodyModel extends IScriptable {
  public static func Create(previous: ref<CRInjuryState>, config: ref<CRBodyConfig>) -> ref<CRBodyState> {
    let body: ref<CRBodyState>;
    if !CRInjuryModel.CanAdvance(previous, config) {
      return null;
    }
    body = CRBodyModel.Create(config);
    if IsDefined(previous) {
      // One owner in the new save schema; never depend on serialized aliases.
      body.injuries = CRInjuryModel.Copy(previous);
    }
    return body;
  }
  public static func Valid(body: ref<CRBodyState>, config: ref<CRBodyConfig>) -> Bool {
    if !IsDefined(body) || !body.initialized || !IsDefined(body.injuries) {
      return false;
    }
    return CRInjuryModel.CanAdvance(body.injuries, config) && CRSleepModel.ValidState(body) && body.pendingHours >= 0.0 && body.pendingHours <= 72.0 && body.pendingExertion >= 0.0 && body.pendingExertion <= 1.0 && body.bodyWaterMl >= 0.0 && body.gutWaterMl >= 0.0 && body.bodyWaterMl + body.gutWaterMl <= 1000000.0 && body.energyBalanceKcal >= -1000000000.0 && body.energyBalanceKcal <= 1000000000.0;
  }
  public static func Advance(body: ref<CRBodyState>, config: ref<CRBodyConfig>, hours: Float, activity: Float) -> Bool {
    if !CRNPCBodyModel.Valid(body, config) || !(hours >= 0.0 && hours <= 72.0) || !(activity >= 0.0 && activity <= 1.0) {
      return false;
    }
    // Drain retained time in its original context before accepting a new one.
    CRBodyModel.Advance(body, config, 0.0, 0.0, false);
    if !body.lastAdvanceAccepted || body.pendingHours + 0.000001 >= 1.0 / 60.0 {
      return false;
    }
    if hours > 0.0 {
      CRBodyModel.Advance(body, config, hours, activity, false);
    }
    return body.lastAdvanceAccepted;
  }
  public static func BeforeEvent(body: ref<CRBodyState>, config: ref<CRBodyConfig>) -> Bool {
    if !CRNPCBodyModel.Advance(body, config, 0.0, 0.0) {
      return false;
    }
    return CRBodyModel.CloseInterval(body, config);
  }
}