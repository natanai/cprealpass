// Original non-mutating forecast of the same body transitions used during play.
module CyberpunkRealism.Physiology

public class CRBodyForecastState extends IScriptable {
  public let ready: Bool = false;
  public let body: ref<CRBodyState>;
  public let config: ref<CRBodyConfig>;
  public let meters: ref<CRBodyMeterConfig>;
}

public class CRBodyForecast extends IScriptable {
  public static func CopyBody(source: ref<CRBodyState>) -> ref<CRBodyState> {
    if !IsDefined(source) || !CRInjuryModel.ValidState(source.injuries) {
      return null;
    }
    let copy: ref<CRBodyState> = new CRBodyState();
    copy.initialized = source.initialized;
    copy.injuries = CRInjuryModel.Copy(source.injuries);
    copy.bloodWaterLostMl = source.bloodWaterLostMl;
    copy.pendingHours = source.pendingHours;
    copy.pendingExertion = source.pendingExertion;
    copy.pendingSleeping = source.pendingSleeping;
    copy.lastAdvanceAccepted = source.lastAdvanceAccepted;
    copy.elapsedHours = source.elapsedHours;
    copy.gutWaterMl = source.gutWaterMl;
    copy.bodyWaterMl = source.bodyWaterMl;
    copy.bladderMl = source.bladderMl;
    copy.waterLostMl = source.waterLostMl;
    copy.waterVoidedMl = source.waterVoidedMl;
    copy.gutEnergyKcal = source.gutEnergyKcal;
    copy.energyBalanceKcal = source.energyBalanceKcal;
    copy.energyUsedKcal = source.energyUsedKcal;
    copy.upperGutResidueGrams = source.upperGutResidueGrams;
    copy.colonResidueGrams = source.colonResidueGrams;
    copy.bowelGrams = source.bowelGrams;
    copy.residueVoidedGrams = source.residueVoidedGrams;
    copy.sleepPressureHours = source.sleepPressureHours;
    copy.sleepDebtHours = source.sleepDebtHours;
    copy.exertionFatigueHours = source.exertionFatigueHours;
    copy.sleepWindowSeconds = source.sleepWindowSeconds;
    copy.sleepWindowSleepSeconds = source.sleepWindowSleepSeconds;
    copy.hygieneLoad = source.hygieneLoad;
    return copy;
  }

  private static func CopyQueue(source: ref<CRBodyInputQueue>) -> ref<CRBodyInputQueue> {
    if !IsDefined(source) || source.faulted || source.count < 0 || source.count > 128 {
      return null;
    }
    let copy: ref<CRBodyInputQueue> = new CRBodyInputQueue();
    copy.acceptedIntakes = source.acceptedIntakes;
    copy.appliedIntakes = source.appliedIntakes;
    copy.appliedInteractions = source.appliedInteractions;
    copy.appliedWounds = source.appliedWounds;
    copy.appliedTreatments = source.appliedTreatments;
    let input: ref<CRBodyInput> = source.first;
    let tail: ref<CRBodyInput> = null;
    while IsDefined(input) && copy.count < 128 {
      let node: ref<CRBodyInput> = new CRBodyInput();
      node.isIntake = input.isIntake;
      node.medicalKind = input.medicalKind;
      node.injuryRegion = input.injuryRegion;
      node.tissueDamage = input.tissueDamage;
      node.boneDamage = input.boneDamage;
      node.cyberwareDamage = input.cyberwareDamage;
      node.externalBleed = input.externalBleed;
      node.internalBleed = input.internalBleed;
      node.interactionKind = input.interactionKind;
      node.effectiveness = input.effectiveness;
      node.submitted = input.submitted;
      node.hours = input.hours;
      node.exertion = input.exertion;
      node.sleeping = input.sleeping;
      node.waterMl = input.waterMl;
      node.energyKcal = input.energyKcal;
      node.residueGrams = input.residueGrams;
      if IsDefined(tail) {
        tail.next = node;
      } else {
        copy.first = node;
      }
      tail = node;
      copy.count += 1;
      input = input.next;
    }
    if IsDefined(input) || copy.count != source.count {
      return null;
    }
    return copy;
  }

  public static func Create(source: ref<CRBodyState>, inputs: ref<CRBodyInputQueue>, config: ref<CRBodyConfig>, meters: ref<CRBodyMeterConfig>) -> ref<CRBodyForecastState> {
    let forecast: ref<CRBodyForecastState> = new CRBodyForecastState();
    if !CRBodyPresentation.Read(source, config, meters).valid || !(source.pendingHours >= 0.0) || !(source.pendingHours <= 1000000.0) || !(source.pendingExertion >= 0.0) || !(source.pendingExertion <= 1.0) {
      return forecast;
    }
    let queue: ref<CRBodyInputQueue> = CRBodyForecast.CopyQueue(inputs);
    if !IsDefined(queue) {
      return forecast;
    }
    forecast.body = CRBodyForecast.CopyBody(source);
    forecast.config = config;
    forecast.meters = meters;
    // Bound preparation. An unusually large backlog is reported unavailable,
    // not silently ignored or processed without limit on the UI thread.
    CRBodyInputs.Drain(queue, forecast.body, config);
    if queue.faulted || queue.count != 0 || forecast.body.pendingHours + 0.000001 >= 1.0 / 60.0 {
      return forecast;
    }
    forecast.ready = true;
    return forecast;
  }

  public static func AddServing(forecast: ref<CRBodyForecastState>, serving: ref<CRServing>) -> Bool {
    if !forecast.ready || !IsDefined(serving) || !serving.recognized {
      return false;
    }
    if !CRBodyModel.CloseInterval(forecast.body, forecast.config) {
      forecast.ready = false;
      return false;
    }
    return CRBodyModel.Ingest(forecast.body, serving.waterMl, serving.energyKcal, serving.residueGrams);
  }

  public static func Step(forecast: ref<CRBodyForecastState>, hours: Float, sleeping: Bool) -> ref<CRBodyMeters> {
    if !forecast.ready || !(hours >= 0.0) || !(hours <= 72.0) {
      forecast.ready = false;
      return new CRBodyMeters();
    }
    CRBodyModel.Advance(forecast.body, forecast.config, hours, 0.0, sleeping);
    if !forecast.body.lastAdvanceAccepted || forecast.body.pendingHours + 0.000001 >= 1.0 / 60.0 {
      forecast.ready = false;
      return new CRBodyMeters();
    }
    let result: ref<CRBodyMeters> = CRBodyPresentation.Read(forecast.body, forecast.config, forecast.meters);
    forecast.ready = result.valid;
    return result;
  }
}
