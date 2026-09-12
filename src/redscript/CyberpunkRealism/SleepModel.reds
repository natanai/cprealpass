// Original sleep bookkeeping. Gameplay model, not a clinical sleep predictor.
module CyberpunkRealism.Physiology

public class CRSleepModel extends IScriptable {
  public static func ValidState(state: ref<CRBodyState>) -> Bool {
    return IsDefined(state) && state.sleepPressureHours >= 0.0 && state.sleepPressureHours <= 1000000000.0 && state.sleepDebtHours >= 0.0 && state.sleepDebtHours <= 1000000000.0 && state.exertionFatigueHours >= 0.0 && state.exertionFatigueHours <= 1000000.0 && state.sleepWindowSeconds >= 0.0 && state.sleepWindowSeconds < 86400.0 && state.sleepWindowSleepSeconds >= 0.0 && state.sleepWindowSleepSeconds <= state.sleepWindowSeconds + 0.01;
  }
  public static func ValidConfig(config: ref<CRBodyConfig>) -> Bool {
    return IsDefined(config) && config.sleepNeedHoursPerDay >= 0.0 && config.sleepNeedHoursPerDay <= 23.0 && config.sleepPressureRecoveryPerHour >= 0.0 && config.sleepPressureRecoveryPerHour <= 100.0 && config.exertionFatigueGainPerHour >= 0.0 && config.exertionFatigueGainPerHour <= 100.0 && config.exertionFatigueRestRecoveryPerHour >= 0.0 && config.exertionFatigueRestRecoveryPerHour <= 100.0 && config.exertionFatigueSleepRecoveryPerHour >= 0.0 && config.exertionFatigueSleepRecoveryPerHour <= 100.0 && config.exertionFatigueMaximumHours > 0.0 && config.exertionFatigueMaximumHours <= 1000.0;
  }

  public static func Advance(state: ref<CRBodyState>, config: ref<CRBodyConfig>, hours: Float, activity: Float, sleeping: Bool) -> Void {
    if !CRSleepModel.ValidState(state) || !CRSleepModel.ValidConfig(config) || !(hours >= 0.0) || !(hours <= 72.0) || !(activity >= 0.0) || !(activity <= 1.0) {
      return;
    }
    if sleeping {
      state.sleepPressureHours = MaxF(0.0, state.sleepPressureHours - config.sleepPressureRecoveryPerHour * hours);
      state.exertionFatigueHours = MaxF(0.0, state.exertionFatigueHours - config.exertionFatigueSleepRecoveryPerHour * hours);
    } else {
      state.sleepPressureHours += hours;
      let acuteRate: Float = activity * config.exertionFatigueGainPerHour - (1.0 - activity) * config.exertionFatigueRestRecoveryPerHour;
      state.exertionFatigueHours = ClampF(state.exertionFatigueHours + acuteRate * hours, 0.0, config.exertionFatigueMaximumHours);
    }
    // Account actual sleep against the configured need once per tracked 24 hours.
    // Normal awake time raises pressure, not a falsely labeled history of missed
    // sleep. Naps count, short nights accumulate debt, and extra sleep repays it.
    let remaining: Float = hours * 3600.0;
    while remaining > 0.0 {
      let segment: Float = MinF(remaining, 86400.0 - state.sleepWindowSeconds);
      if sleeping {
        state.sleepWindowSleepSeconds += segment;
      }
      state.sleepWindowSeconds += segment;
      remaining = MaxF(0.0, remaining - segment);
      if state.sleepWindowSeconds >= 86400.0 - 0.001 {
        let required: Float = ClampF(config.sleepNeedHoursPerDay, 0.0, 23.0);
        state.sleepDebtHours = MaxF(0.0, state.sleepDebtHours + required - state.sleepWindowSleepSeconds / 3600.0);
        state.sleepWindowSeconds = 0.0;
        state.sleepWindowSleepSeconds = 0.0;
      }
    }
  }
}
