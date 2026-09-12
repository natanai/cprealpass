// Original project presentation and migration policy; provisional gameplay scales.
module CyberpunkRealism.Physiology

public class CRBodyMeterConfig extends IScriptable {
  public let waterDeficitAtZeroMl: Float = 4200.0;
  public let energyDeficitAtZeroKcal: Float = 4000.0;
  public let sleepPressureAtZeroHours: Float = 32.0;
  public let sleepDebtAtZeroHours: Float = 16.0;
}

public class CRBodyMeters extends IScriptable {
  public let valid: Bool = false;
  public let hydration: Float = 0.0;
  public let nutrition: Float = 0.0;
  public let energy: Float = 0.0;
}

public class CRBodyPresentation extends IScriptable {
  private static func ValidConfig(config: ref<CRBodyMeterConfig>) -> Bool {
    if !IsDefined(config) {
      return false;
    }
    return config.waterDeficitAtZeroMl > 0.0 && config.waterDeficitAtZeroMl <= 10000.0 && config.energyDeficitAtZeroKcal > 0.0 && config.energyDeficitAtZeroKcal <= 20000.0 && config.sleepPressureAtZeroHours > 0.0 && config.sleepPressureAtZeroHours <= 1000.0 && config.sleepDebtAtZeroHours > 0.0 && config.sleepDebtAtZeroHours <= 1000.0;
  }

  public static func Read(state: ref<CRBodyState>, bodyConfig: ref<CRBodyConfig>, config: ref<CRBodyMeterConfig>) -> ref<CRBodyMeters> {
    let meters: ref<CRBodyMeters> = new CRBodyMeters();
    if !IsDefined(state) || !state.initialized || !CRInjuryModel.CanAdvance(state.injuries, bodyConfig) || !CRSleepModel.ValidState(state) || !CRSleepModel.ValidConfig(bodyConfig) || !IsDefined(bodyConfig) || !CRBodyPresentation.ValidConfig(config) {
      return meters;
    }
    if !(bodyConfig.targetBodyWaterMl >= config.waterDeficitAtZeroMl) || !(bodyConfig.targetBodyWaterMl <= 1000000.0) || !(state.bodyWaterMl >= 0.0) || !(state.bodyWaterMl <= 1000000.0) || !(state.energyBalanceKcal >= -1000000000.0) || !(state.energyBalanceKcal <= 1000000000.0) || !(state.sleepPressureHours >= 0.0) || !(state.sleepPressureHours <= 1000000000.0) || !(state.sleepDebtHours >= 0.0) || !(state.sleepDebtHours <= 1000000000.0) {
      return meters;
    }
    meters.hydration = ClampF(100.0 * (1.0 - MaxF(0.0, bodyConfig.targetBodyWaterMl - state.bodyWaterMl) / config.waterDeficitAtZeroMl), 0.0, 100.0);
    meters.nutrition = ClampF(100.0 * (1.0 + MinF(0.0, state.energyBalanceKcal) / config.energyDeficitAtZeroKcal), 0.0, 100.0);
    let fatigue: Float = MaxF((state.sleepPressureHours + state.exertionFatigueHours) / config.sleepPressureAtZeroHours, state.sleepDebtHours / config.sleepDebtAtZeroHours);
    meters.energy = ClampF(100.0 * (1.0 - fatigue), 0.0, 100.0);
    meters.valid = true;
    return meters;
  }

  // Old saves contain percentages, not intake or sleep history. Seed equivalent
  // meters once, with empty gut/waste and no invented historical sleep debt.
  public static func Migrate(bodyConfig: ref<CRBodyConfig>, config: ref<CRBodyMeterConfig>, hydration: Float, nutrition: Float, energy: Float) -> ref<CRBodyState> {
    if !CRSleepModel.ValidConfig(bodyConfig) || !CRBodyPresentation.ValidConfig(config) || !(bodyConfig.targetBodyWaterMl >= config.waterDeficitAtZeroMl) || !(bodyConfig.targetBodyWaterMl <= 1000000.0) || !(hydration >= 0.0) || !(hydration <= 100.0) || !(nutrition >= 0.0) || !(nutrition <= 100.0) || !(energy >= 0.0) || !(energy <= 100.0) {
      return null;
    }
    let state: ref<CRBodyState> = CRBodyModel.Create(bodyConfig);
    state.bodyWaterMl -= (1.0 - hydration / 100.0) * config.waterDeficitAtZeroMl;
    state.energyBalanceKcal = -(1.0 - nutrition / 100.0) * config.energyDeficitAtZeroKcal;
    state.sleepPressureHours = (1.0 - energy / 100.0) * config.sleepPressureAtZeroHours;
    return state;
  }

  // Additive migration from the pre-injury prototype. Version 2 must retain
  // its injury object; a missing field there is not permission to heal a save.
  public static func UpgradeSchema(version: Int32, state: ref<CRBodyState>, bodyConfig: ref<CRBodyConfig>, config: ref<CRBodyMeterConfig>) -> Int32 {
    if version < 1 || version > 2 || !IsDefined(state) {
      return -1;
    }
    if version == 2 && !IsDefined(state.injuries) {
      return -1;
    }
    if !CRBodyPresentation.Read(state, bodyConfig, config).valid {
      return -1;
    }
    if !IsDefined(state.injuries) {
      state.injuries = CRInjuryModel.Create();
    }
    return 2;
  }
  // A managed meter is a view: legacy mutations cannot refill/deplete its value.
  // The unmanaged path (e.g. Nerve) retains its existing behavior.
  public static func ResolveDelta(owned: Bool, current: Float, requested: Float, projected: Float) -> Float {
    if owned {
      if !(projected >= 0.0) || !(projected <= 100.0) {
        return 0.0;
      }
      return projected - current;
    }
    return requested;
  }
}
