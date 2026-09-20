// Cyberpunk Realism original source. Prototype model, not clinical calibration.
// Pure simulation core: no timers, logging, game hooks, UI, or background process.
module CyberpunkRealism.Physiology

public class CRBodyConfig extends IScriptable {
  public let injuryBloodCapacityMl: Float = 5000.0;
  public let injuryBloodWaterFraction: Float = 0.8;
  public let injuryTissueRecoveryPerHour: Float = 0.002;
  public let injuryBoneRecoveryPerHour: Float = 0.0005;
  public let injuryClinicalRecoveryMultiplier: Float = 2.0;
  public let injuryExternalClotPerHourSquared: Float = 100.0;
  public let injuryBloodRecoveryMlPerHour: Float = 10.0;
  public let injuryMetabolicKcalPerHour: Float = 5.0;
  public let injuryExertionBleedMultiplier: Float = 0.5;
  public let targetBodyWaterMl: Float = 42000.0;
  public let fluidAbsorptionMlPerHour: Float = 900.0;
  public let foodAbsorptionKcalPerHour: Float = 500.0;
  public let restingWaterLossMlPerHour: Float = 35.0;
  public let exertionWaterLossMlPerHour: Float = 600.0;
  public let baselineUrineMlPerHour: Float = 60.0;
  public let minimumUrineMlPerHour: Float = 15.0;
  public let excessWaterClearancePerHour: Float = 0.5;
  public let maximumUrineMlPerHour: Float = 500.0;
  public let waterConservationDeficitMl: Float = 1000.0;
  public let restingEnergyKcalPerHour: Float = 85.0;
  public let exertionEnergyKcalPerHour: Float = 350.0;
  public let upperGutTransitHours: Float = 4.0;
  public let colonTransitHours: Float = 24.0;
  public let sleepNeedHoursPerDay: Float = 8.0;
  public let sleepPressureRecoveryPerHour: Float = 2.0;
  // Acute exertion is recoverable during rest; it is not extra time awake.
  public let exertionFatigueGainPerHour: Float = 0.25;
  public let exertionFatigueRestRecoveryPerHour: Float = 0.1;
  public let exertionFatigueSleepRecoveryPerHour: Float = 0.5;
  public let exertionFatigueMaximumHours: Float = 8.0;
  public let hygieneLoadPerHour: Float = 0.5;
  public let exertionHygieneLoadPerHour: Float = 2.0;
}

public class CRBodyState extends IScriptable {
  public persistent let injuries: ref<CRInjuryState>;
  public persistent let bloodWaterLostMl: Float = 0.0;
  public persistent let initialized: Bool = false;
  public persistent let pendingHours: Float = 0.0;
  public persistent let pendingExertion: Float = 0.0;
  public persistent let pendingSleeping: Bool = false;
  public persistent let lastAdvanceAccepted: Bool = false;
  public persistent let elapsedHours: Float = 0.0;
  public persistent let gutWaterMl: Float = 0.0;
  public persistent let bodyWaterMl: Float = 0.0;
  public persistent let bladderMl: Float = 0.0;
  public persistent let waterLostMl: Float = 0.0;
  public persistent let waterVoidedMl: Float = 0.0;
  public persistent let gutEnergyKcal: Float = 0.0;
  public persistent let energyBalanceKcal: Float = 0.0;
  public persistent let energyUsedKcal: Float = 0.0;
  public persistent let upperGutResidueGrams: Float = 0.0;
  public persistent let colonResidueGrams: Float = 0.0;
  public persistent let bowelGrams: Float = 0.0;
  public persistent let residueVoidedGrams: Float = 0.0;
  public persistent let sleepPressureHours: Float = 0.0;
  public persistent let sleepDebtHours: Float = 0.0;
  // Additive save field: older saves retain their pressure/debt and start at zero.
  public persistent let exertionFatigueHours: Float = 0.0;
  public persistent let sleepWindowSeconds: Float = 0.0;
  public persistent let sleepWindowSleepSeconds: Float = 0.0;
  public persistent let hygieneLoad: Float = 0.0;
}

public class CRBodyModel extends IScriptable {
  public static func Create(config: ref<CRBodyConfig>) -> ref<CRBodyState> {
    let state: ref<CRBodyState> = new CRBodyState();
    state.bodyWaterMl = MaxF(0.0, config.targetBodyWaterMl);
    state.injuries = CRInjuryModel.Create();
    state.initialized = true;
    return state;
  }

  // Intake enters the gut; it does not instantly hydrate the body or fill the bladder.
  // The adapter must supply item quantities and call this exactly once per consumption.
  public static func Ingest(state: ref<CRBodyState>, waterMl: Float, energyKcal: Float, residueGrams: Float) -> Bool {
    if !state.initialized || waterMl < 0.0 || energyKcal < 0.0 || residueGrams < 0.0 {
      return false;
    }
    if !(waterMl <= 10000.0) || !(energyKcal <= 20000.0) || !(residueGrams <= 5000.0) {
      return false;
    }
    state.gutWaterMl += waterMl;
    state.gutEnergyKcal += energyKcal;
    state.upperGutResidueGrams += residueGrams;
    return true;
  }

  // Use only elapsed in-game hours supplied by the clock adapter. Fixed one-minute
  // steps make normal play and time skips share the same transition equations.
  // At most 72 hours is processed per call. Larger skips remain queued, never discarded.
  public static func Advance(state: ref<CRBodyState>, config: ref<CRBodyConfig>, hours: Float, exertion: Float, sleeping: Bool) -> Int32 {
    state.lastAdvanceAccepted = false;
    if !state.initialized || !(state.bodyWaterMl >= 0.0) || !(state.gutWaterMl >= 0.0) || !(state.bodyWaterMl + state.gutWaterMl <= 1000000.0) || !(state.pendingExertion >= 0.0) || !(state.pendingExertion <= 1.0) || !CRInjuryModel.CanAdvance(state.injuries, config) || !CRSleepModel.ValidState(state) || !CRSleepModel.ValidConfig(config) || !(hours >= 0.0) || !(hours <= 1000000.0) || !(exertion >= -1000000.0) || !(exertion <= 1000000.0) {
      return 0;
    }
    let tick: Float = 1.0 / 60.0;
    let activity: Float = ClampF(exertion, 0.0, 1.0);
    if sleeping {
      activity = 0.0;
    }
    // Do not process queued awake time as sleep (or the reverse). The adapter
    // must drain a full backlog with hours=0 before submitting a new context.
    if hours > 0.0 && state.pendingHours > 0.0 && (activity != state.pendingExertion || !Equals(sleeping, state.pendingSleeping)) {
      if state.pendingHours + 0.000001 >= tick {
        return 0;
      }
      CRBodyModel.Step(state, config, state.pendingHours, state.pendingExertion, state.pendingSleeping);
      state.elapsedHours += state.pendingHours;
      state.pendingHours = 0.0;
    }
    if hours > 0.0 {
      state.pendingExertion = activity;
      state.pendingSleeping = sleeping;
    }
    let totalHours: Float = state.pendingHours + hours;
    state.lastAdvanceAccepted = true;
    let count: Int32 = 0;
    let totalMinutes: Float = totalHours * 60.0;
    // Compare integer tick counts against one total. Repeated subtraction can
    // accumulate enough float32 error to omit a minute from an eight-hour skip.
    while count < 4320 && Cast<Float>(count + 1) <= totalMinutes + 0.00006 {
      CRBodyModel.Step(state, config, tick, state.pendingExertion, state.pendingSleeping);
      count += 1;
    }
    let processed: Float = Cast<Float>(count) / 60.0;
    state.pendingHours = MaxF(0.0, totalHours - processed);
    state.elapsedHours += processed;
    return count;
  }
  // Close fractional time before intake so a new meal cannot be absorbed earlier.
  // Full backlog must first be drained with bounded Advance calls.
  public static func CloseInterval(state: ref<CRBodyState>, config: ref<CRBodyConfig>) -> Bool {
    if !state.initialized || !(state.bodyWaterMl >= 0.0) || !(state.gutWaterMl >= 0.0) || !(state.bodyWaterMl + state.gutWaterMl <= 1000000.0) || !(state.pendingExertion >= 0.0) || !(state.pendingExertion <= 1.0) || !CRInjuryModel.CanAdvance(state.injuries, config) || !CRSleepModel.ValidState(state) || !CRSleepModel.ValidConfig(config) || !(state.pendingHours >= 0.0) || state.pendingHours + 0.000001 >= 1.0 / 60.0 {
      return false;
    }
    if state.pendingHours > 0.0 {
      CRBodyModel.Step(state, config, state.pendingHours, state.pendingExertion, state.pendingSleeping);
      state.elapsedHours += state.pendingHours;
      state.pendingHours = 0.0;
    }
    return true;
  }
  private static func Step(state: ref<CRBodyState>, config: ref<CRBodyConfig>, hours: Float, exertion: Float, sleeping: Bool) -> Void {
    let activity: Float = exertion;
    if sleeping {
      activity = 0.0;
    }
    let absorbedWater: Float = MinF(state.gutWaterMl, MaxF(0.0, config.fluidAbsorptionMlPerHour) * hours);
    state.gutWaterMl -= absorbedWater;
    state.bodyWaterMl += absorbedWater;

    let waterLoss: Float = MaxF(0.0, config.restingWaterLossMlPerHour) + activity * MaxF(0.0, config.exertionWaterLossMlPerHour);
    waterLoss = MinF(state.bodyWaterMl, waterLoss * hours);
    state.bodyWaterMl -= waterLoss;
    state.waterLostMl += waterLoss;

    let deficit: Float = MaxF(0.0, config.targetBodyWaterMl - state.bodyWaterMl);
    let conservation: Float = ClampF(deficit / MaxF(1.0, config.waterConservationDeficitMl), 0.0, 1.0);
    let baselineUrine: Float = MaxF(0.0, config.baselineUrineMlPerHour);
    let minimumUrine: Float = ClampF(config.minimumUrineMlPerHour, 0.0, baselineUrine);
    let urineRate: Float = baselineUrine - conservation * (baselineUrine - minimumUrine);
    urineRate += MaxF(0.0, state.bodyWaterMl - config.targetBodyWaterMl) * MaxF(0.0, config.excessWaterClearancePerHour);
    urineRate = ClampF(urineRate, 0.0, MaxF(0.0, config.maximumUrineMlPerHour));
    let urine: Float = MinF(state.bodyWaterMl, urineRate * hours);
    state.bodyWaterMl -= urine;
    state.bladderMl += urine;

    let absorbedEnergy: Float = MinF(state.gutEnergyKcal, MaxF(0.0, config.foodAbsorptionKcalPerHour) * hours);
    state.gutEnergyKcal -= absorbedEnergy;
    state.energyBalanceKcal += absorbedEnergy;
    let energyUsed: Float = (MaxF(0.0, config.restingEnergyKcalPerHour) + activity * MaxF(0.0, config.exertionEnergyKcalPerHour) + config.injuryMetabolicKcalPerHour * CRInjuryModel.TissueBurden(state.injuries)) * hours;
    state.energyBalanceKcal -= energyUsed;
    state.energyUsedKcal += energyUsed;

    let upperTransfer: Float = MinF(state.upperGutResidueGrams, state.upperGutResidueGrams * hours / MaxF(hours, config.upperGutTransitHours));
    // Compute downstream transfer from the old colon state: a new meal cannot
    // produce immediate bowel content in the same integration step.
    let colonTransfer: Float = MinF(state.colonResidueGrams, state.colonResidueGrams * hours / MaxF(hours, config.colonTransitHours));
    state.upperGutResidueGrams -= upperTransfer;
    state.colonResidueGrams += upperTransfer - colonTransfer;
    state.bowelGrams += colonTransfer;

    CRSleepModel.Advance(state, config, hours, activity, sleeping);
    let recoveryFactor: Float = ClampF(state.bodyWaterMl / MaxF(1.0, config.targetBodyWaterMl), 0.0, 1.0) * ClampF(1.0 + state.energyBalanceKcal / 8000.0, 0.0, 1.0);
    if sleeping {
      recoveryFactor *= 1.25;
    }
    let bloodLost: Float = CRInjuryModel.Advance(state.injuries, config, hours, activity, recoveryFactor, state.bodyWaterMl);
    let bloodWater: Float = MaxF(0.0, bloodLost) * config.injuryBloodWaterFraction;
    state.bodyWaterMl = MaxF(0.0, state.bodyWaterMl - bloodWater);
    state.waterLostMl += bloodWater;
    state.bloodWaterLostMl += bloodWater;
    state.hygieneLoad += (MaxF(0.0, config.hygieneLoadPerHour) + activity * MaxF(0.0, config.exertionHygieneLoadPerHour)) * hours;
  }

  // Explicit interactions only. There is no automatic accident or arbitrary death.
  public static func EmptyBladder(state: ref<CRBodyState>) -> Float {
    let amount: Float = state.bladderMl;
    state.waterVoidedMl += amount;
    state.bladderMl = 0.0;
    return amount;
  }

  public static func EmptyBowel(state: ref<CRBodyState>) -> Float {
    let amount: Float = state.bowelGrams;
    state.residueVoidedGrams += amount;
    state.bowelGrams = 0.0;
    return amount;
  }

  public static func Wash(state: ref<CRBodyState>, effectiveness: Float) -> Void {
    state.hygieneLoad *= 1.0 - ClampF(effectiveness, 0.0, 1.0);
  }
}
