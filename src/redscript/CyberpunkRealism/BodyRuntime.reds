// Cyberpunk Realism original integration adapter using published Dark Future events.
// Staged integration build only. Enabled stays false until model calibration,
// scripted/body interactions and native validation form a coherent gameplay batch.
module CyberpunkRealism.Integration

import CyberpunkRealism.Physiology.*
import DarkFuture.Main.*
import DarkFuture.Needs.*
import DarkFuture.Conditions.DFInjuryConditionSystem
import DarkFuture.Services.DFGameStateService


public class CRBodyRuntimePolicy extends IScriptable {
  public static func Enabled() -> Bool {
    return false;
  }
}

public class CRBodyTestPolicy extends IScriptable {
  public static func Diagnostics() -> Bool {
    return false;
  }
}

public class CRBodyRuntime extends ScriptableSystem {
  private persistent let body: ref<CRBodyState>;
  private persistent let inputs: ref<CRBodyInputQueue>;
  private persistent let unmappedConsumptions: Int32 = 0;
  private persistent let bodySchemaVersion: Int32 = 0;
  private persistent let localizedInjuryHandover: Bool = false;
  private let clock: ref<CRClockState>;
  private let config: ref<CRBodyConfig>;
  private let meterConfig: ref<CRBodyMeterConfig>;
  private let running: Bool = false;
  private let unsupportedSaveVersion: Bool = false;
  private let timeSkipForecastReady: Bool = false;
  private let fieldCareBusy: Bool = false;
  private let testLogCount: Int32 = 0;
  private let testLastSim: Float = 0.0;

  public static func Get() -> ref<CRBodyRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRBodyRuntime>()) as CRBodyRuntime;
  }

  private func OnAttach() -> Void {
    this.ResetTransientState();
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.ResetTransientState();
  }

  private func OnDetach() -> Void {
    CRFieldCareActionRuntime.Get().Cancel(false);
    CRInjuryEffectsRuntime.Get().Suspend();
    this.running = false;
    this.clock = null;
  }

  private func ResetTransientState() -> Void {
    this.clock = new CRClockState();
    this.config = new CRBodyConfig();
    this.meterConfig = new CRBodyMeterConfig();
    this.running = false;
    this.unsupportedSaveVersion = this.bodySchemaVersion < 0 || this.bodySchemaVersion > 2;
    this.TestSnapshot("restore");
    this.fieldCareBusy = false;
  }

  public func Activate() -> Void {
    if !CRBodyRuntimePolicy.Enabled() {
      return;
    }
    this.ResetTransientState();
    if this.unsupportedSaveVersion {
      return;
    }
    if this.bodySchemaVersion == 0 {
      // Refuse an ambiguous pre-existing body rather than overwriting it.
      if IsDefined(this.body) {
        return;
      }
      let migrated: ref<CRBodyState> = CRBodyPresentation.Migrate(this.config, this.meterConfig, DFHydrationSystem.Get().GetNeedValue(), DFNutritionSystem.Get().GetNeedValue(), DFEnergySystem.Get().GetNeedValue());
      if !IsDefined(migrated) {
        return;
      }
      this.body = migrated;
      this.bodySchemaVersion = 2;
    }
    let upgradedSchema: Int32 = CRBodyPresentation.UpgradeSchema(this.bodySchemaVersion, this.body, this.config, this.meterConfig);
    if upgradedSchema < 0 {
      return;
    }
    this.bodySchemaVersion = upgradedSchema;
    if this.bodySchemaVersion != 2 || !IsDefined(this.body) || !this.GetMeters().valid {
      return;
    }
    if !IsDefined(this.inputs) {
      this.inputs = new CRBodyInputQueue();
    }
    DFHydrationSystem.Get().CRPrepareBodyHandover();
    DFNutritionSystem.Get().CRPrepareBodyHandover();
    DFEnergySystem.Get().CRPrepareBodyHandover();
    DFEnergySystem.Get().ClearEnergyManagementEffects();
    this.running = true;
    this.ResetClock();
    this.TryInjuryHandover();
    this.Publish();
    this.TestSnapshot("activate");
  }

  // Attended test diagnostics use existing game callbacks only. No timer or helper.
  public func TestStatus() -> String {
    if !CRBodyTestPolicy.Diagnostics() || !IsDefined(this.clock) || !IsDefined(this.body) || !IsDefined(this.inputs) {
      return "";
    }
    return "TEST CLOCK  |  Last rate " + ToString(this.clock.lastObservedRatio) + "x  |  Body hours " + ToString(this.body.elapsedHours) + "  |  Meals/drinks " + ToString(this.inputs.appliedIntakes) + "  |  Queue " + ToString(this.inputs.count) + "  |  Fault " + ToString(this.inputs.faulted);
  }

  public func TestSnapshot(event: String) -> Void {
    if !CRBodyTestPolicy.Diagnostics() || this.testLogCount >= 500 {
      return;
    }
    let sim: Float = this.SimSeconds();
    if Equals(event, "tick") && sim >= this.testLastSim && sim - this.testLastSim < 60.0 {
      return;
    }
    this.testLastSim = sim;
    this.testLogCount += 1;
    let line: String = "[CRTEST] event=" + event + " schema=" + ToString(this.bodySchemaVersion) + " running=" + ToString(this.running) + " owns=" + ToString(this.OwnsNeeds()) + " world=" + ToString(this.WorldSeconds()) + " sim=" + ToString(sim);
    if IsDefined(this.clock) {
      line += " ratio=" + ToString(this.clock.lastObservedRatio) + " suppressed=" + ToString(this.clock.suppressedWorldSeconds) + " unclassified=" + ToString(this.clock.unclassifiedWorldSeconds) + " skipPending=" + ToString(this.clock.skipPending);
    }
    if IsDefined(this.body) {
      let meters: ref<CRBodyMeters> = this.GetMeters();
      line += " valid=" + ToString(meters.valid) + " hydration=" + ToString(meters.hydration) + " nutrition=" + ToString(meters.nutrition) + " energy=" + ToString(meters.energy) + " elapsed=" + ToString(this.body.elapsedHours) + " pending=" + ToString(this.body.pendingHours) + " gutWater=" + ToString(this.body.gutWaterMl) + " gutEnergy=" + ToString(this.body.gutEnergyKcal) + " water=" + ToString(this.body.bodyWaterMl) + " bladder=" + ToString(this.body.bladderMl) + " bowel=" + ToString(this.body.bowelGrams) + " sleepPressure=" + ToString(this.body.sleepPressureHours) + " sleepDebt=" + ToString(this.body.sleepDebtHours) + " hygiene=" + ToString(this.body.hygieneLoad);
    }
    if IsDefined(this.inputs) {
      line += " queued=" + ToString(this.inputs.count) + " fault=" + ToString(this.inputs.faulted) + " intakes=" + ToString(this.inputs.appliedIntakes) + " interactions=" + ToString(this.inputs.appliedInteractions);
    }
    FTLog(line);
  }

  public func OwnsNeeds() -> Bool {
    // Retain ownership through suspension; resuming must not refill saved needs.
    return CRBodyRuntimePolicy.Enabled() && this.bodySchemaVersion == 2 && IsDefined(this.body) && this.body.initialized;
  }

  public func GetBodyConfig() -> ref<CRBodyConfig> {
    return this.config;
  }
  public func GetMeters() -> ref<CRBodyMeters> {
    return CRBodyPresentation.Read(this.body, this.config, this.meterConfig);
  }

  public func RefreshInjuryEffects() -> Void {
    CRInjuryEffectsRuntime.Get().Refresh(this.body, this.config, this.running && this.OwnsLocalizedInjuries() && DFGameStateService.Get().IsValidGameState(this));
  }

  private func Publish() -> Void {
    this.RefreshInjuryEffects();
    if this.running && this.OwnsNeeds() && DFGameStateService.Get().IsValidGameState(this, true) {
      CRPublishBodyMeters(this.GetMeters());
    }
  }
  public func GetBodySnapshot() -> ref<CRBodyState> {
    return CRBodyForecast.CopyBody(this.body);
  }

  public func BeginForecast() -> ref<CRBodyForecastState> {
    if !this.OwnsNeeds() {
      return new CRBodyForecastState();
    }
    return CRBodyForecast.Create(this.body, this.inputs, this.config, this.meterConfig);
  }

  public func BeginTimeSkipForecast() -> ref<CRBodyForecastState> {
    let forecast: ref<CRBodyForecastState> = this.BeginForecast();
    this.timeSkipForecastReady = forecast.ready;
    return forecast;
  }

  public func InvalidateTimeSkipForecast() -> Void {
    this.timeSkipForecastReady = false;
  }

  public func IsTimeSkipForecastReady() -> Bool {
    return this.timeSkipForecastReady;
  }
  public func Suspend() -> Void {
    this.TestSnapshot("suspend");
    CRFieldCareActionRuntime.Get().Cancel(false);
    CRInjuryEffectsRuntime.Get().Suspend();
    this.running = false;
    this.ResetClock();
  }

  private func WorldSeconds() -> Int32 {
    return GameTime.GetSeconds(GameInstance.GetTimeSystem(GetGameInstance()).GetGameTime());
  }

  private func SimSeconds() -> Float {
    return GameInstance.GetSimTime(GetGameInstance()).ToFloat();
  }

  private func ResetClock() -> Void {
    if IsDefined(this.clock) {
      CRClockModel.CancelSkip(this.clock, this.WorldSeconds(), this.SimSeconds());
      this.RebaseObservation();
    }
  }

  public func RebaseObservation() -> Void {
    if this.running && IsDefined(this.clock) {
      // Preserve skipPending: closing a sleep menu must not cancel its finish event.
      CRClockModel.Reset(this.clock, this.WorldSeconds(), this.SimSeconds(), this.Allowed());
    }
  }
  private func Allowed() -> Bool {
    let guard: ref<DFGameStateService> = DFGameStateService.Get();
    return this.running && guard.IsValidGameState(this) && !guard.IsInAnyMenu();
  }

  private func Exertion() -> Float {
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if !IsDefined(player) || VehicleComponent.IsMountedToVehicle(GetGameInstance(), player) {
      return 0.0;
    }
    // Provisional movement proxy. Stamina use, swimming and combat effort require
    // additional signals; vehicle movement must never count as running.
    return ClampF(Vector4.Length(player.GetVelocity()) / 7.0, 0.0, 1.0);
  }

  private func ApplyHours(hours: Float, sleeping: Bool, exertion: Float) -> Void {
    if hours <= 0.0 {
      return;
    }
    CRBodyInputs.Time(this.inputs, hours, exertion, sleeping);
  }

  public func Observe() -> Void {
    if !this.running || !IsDefined(this.clock) {
      return;
    }
    let hours: Float = CRClockModel.Observe(this.clock, this.WorldSeconds(), this.SimSeconds(), this.Allowed());
    this.ApplyHours(hours, false, this.Exertion());
    if this.OwnsLocalizedInjuries() && !this.inputs.faulted {
      CRInjuryEffectsRuntime.Get().Advance(hours, this.config, false);
    }
    CRBodyInputs.Drain(this.inputs, this.body, this.config);
    this.Publish();
    this.TestSnapshot("tick");
  }

  public func BeginSkip() -> Void {
    CRFieldCareActionRuntime.Get().Cancel(false);
    if !this.running {
      return;
    }
    this.Observe();
    CRClockModel.BeginSkip(this.clock, this.WorldSeconds(), this.SimSeconds());
    this.TestSnapshot("skip-start");
  }

  public func FinishSkip(data: DFTimeSkipData) -> Void {
    if !this.running {
      return;
    }
    let hours: Float = CRClockModel.FinishSkip(this.clock, this.WorldSeconds(), this.SimSeconds(), Cast<Float>(data.hoursSkipped));
    this.ApplyHours(hours, NotEquals(data.timeSkipType, DFTimeSkipType.TimeSkip), 0.0);
    if this.OwnsLocalizedInjuries() && !this.inputs.faulted {
      // V sleeping is not evidence that every other actor slept.
      CRInjuryEffectsRuntime.Get().Advance(hours, this.config, true);
    }
    CRBodyInputs.Drain(this.inputs, this.body, this.config);
    this.Publish();
    this.TestSnapshot("skip-finish");
  }

  // Shared injury ownership and native committed combat paths. Wound magnitudes
  // must come from mapped anatomy/impact, never inferred from an HP percentage.
  public func OwnsLocalizedInjuries() -> Bool {
    // Ownership survives a temporary suspension; damage notifications must not
    // wake the old HP-percentage accumulator while the body is paused.
    return CRCombatRuntimePolicy.Enabled() && this.OwnsNeeds() && this.localizedInjuryHandover;
  }

  private func TryInjuryHandover() -> Void {
    if !this.localizedInjuryHandover && CRCombatRuntimePolicy.Enabled() && this.OwnsNeeds() && this.running && this.Allowed() && DFInjuryConditionSystem.Get().CRIsClearForHandover() {
      this.localizedInjuryHandover = true;
    }
  }
  public func CanAcceptCombatInjury() -> Bool {
    this.TryInjuryHandover();
    return this.running && this.OwnsLocalizedInjuries() && this.Allowed() && IsDefined(this.inputs) && !this.inputs.faulted && CRInjuryModel.CanAdvance(this.body.injuries, this.config);
  }
  public func RecordInjury(region: Int32, tissue: Float, bone: Float, cyberware: Float, externalBleed: Float, internalBleed: Float) -> Bool {
    if !this.CanAcceptCombatInjury() {
      return false;
    }
    this.Observe();
    CRFieldCareActionRuntime.Get().Cancel(true);
    let accepted: Bool = CRBodyInputs.Injury(this.inputs, region, tissue, bone, cyberware, externalBleed, internalBleed);
    if accepted {
      CRBodyInputs.Drain(this.inputs, this.body, this.config);
      this.Publish();
    }
    return accepted;
  }

  public func CompleteTreatment(region: Int32, kind: Int32, effectiveness: Float) -> Bool {
    if !this.running || !this.OwnsNeeds() || !DFGameStateService.Get().IsValidGameState(this, true) || !IsDefined(this.inputs) || this.inputs.faulted {
      return false;
    }
    this.Observe();
    let accepted: Bool = CRBodyInputs.Treatment(this.inputs, region, kind, effectiveness);
    if accepted {
      CRBodyInputs.Drain(this.inputs, this.body, this.config);
      this.Publish();
    }
    return accepted;
  }
  public func CanUseFieldCare() -> Bool {
    return !this.fieldCareBusy && this.CanContinueFieldCare();
  }
  public func CanContinueFieldCare() -> Bool {
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    return this.running && this.OwnsLocalizedInjuries() && IsDefined(this.inputs) && !this.inputs.faulted && DFGameStateService.Get().IsValidGameState(this) && IsDefined(player) && !player.IsInCombat() && !player.IsDead() && !VehicleComponent.IsMountedToVehicle(GetGameInstance(), player) && CRInjuryEffectsBridge.Allowed(player, true);
  }

  public func UseFieldCare(region: Int32, kind: Int32) -> Int32 {
    if CRCombatRuntimePolicy.Enabled() && this.OwnsNeeds() && !this.localizedInjuryHandover && !DFInjuryConditionSystem.Get().CRIsClearForHandover() {
      return 7;
    }
    return CRFieldCareActionRuntime.Get().Begin(region, kind);
  }
  public func CommitFieldCare(action: ref<CRFieldCareAction>) -> Int32 {
    if !CRFieldCareActionRuntime.Get().IsCompleting(action) {
      return 0;
    }
    let region: Int32 = action.region;
    let kind: Int32 = action.kind;
    if CRCombatRuntimePolicy.Enabled() && this.OwnsNeeds() && !this.localizedInjuryHandover && !DFInjuryConditionSystem.Get().CRIsClearForHandover() {
      return 7;
    }
    if !this.CanUseFieldCare() {
      return 0;
    }
    this.fieldCareBusy = true;
    this.Observe();
    // A paid interaction never jumps ahead of pending body events. Let the
    // existing tick drain a long backlog; no extra polling/timer is created.
    if this.inputs.faulted || this.inputs.count != 0 || !CRBodyModel.CloseInterval(this.body, this.config) {
      this.fieldCareBusy = false;
      return 0;
    }
    let plan: ref<CRFieldCarePlan> = CRFieldCareModel.Prepare(this.body.injuries, region, kind);
    if !IsDefined(plan) {
      this.fieldCareBusy = false;
      return 6;
    }
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let result: Int32 = CRFieldCareInventory.ExecuteForAction(player, plan, this.body.injuries, action);
    if result == 1 {
      this.inputs.appliedTreatments += 1;
    }
    this.fieldCareBusy = false;
    this.Publish();
    return result;
  }
  public func CanUseBodyInteraction() -> Bool {
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    return this.running && this.OwnsNeeds() && IsDefined(this.inputs) && !this.inputs.faulted && this.Allowed() && IsDefined(player) && !player.IsInCombat();
  }

  public func CompleteBodyInteraction(kind: Int32) -> Bool {
    // Shower completion may occur in a cinematic; retain core story/replacer
    // exclusions while allowing that temporary scene tier.
    if !this.running || !this.OwnsNeeds() || !DFGameStateService.Get().IsValidGameState(this, true) {
      return false;
    }
    this.Observe();
    let accepted: Bool = CRBodyInputs.Interact(this.inputs, kind, 1.0);
    if accepted {
      CRBodyInputs.Drain(this.inputs, this.body, this.config);
      this.Publish();
      CRShowBodyMeters();
    }
    return accepted;
  }
  public func Consume(itemRecord: wref<Item_Record>) -> Void {
    // Inventory menus are a valid consumption surface even though time is paused.
    if !this.running || !IsDefined(itemRecord) || !DFGameStateService.Get().IsValidGameState(this, true) {
      return;
    }
    this.Observe();
    let serving: ref<CRServing> = CRItemServing.Resolve(itemRecord);
    if !serving.recognized {
      // Includes unmapped alcohol/drugs: do not manufacture food or negative water.
      this.unmappedConsumptions += 1;
      this.TestSnapshot("unmapped-item");
      return;
    }
    CRBodyInputs.Intake(this.inputs, serving.waterMl, serving.energyKcal, serving.residueGrams);
    CRShowBodyMeters();
    CRBodyInputs.Drain(this.inputs, this.body, this.config);
    this.Publish();
    this.TestSnapshot("consume");
  }
  public func CancelSkip() -> Void {
    this.ResetClock();
  }
}

// Reuse existing lifecycle/tick events; create no independent polling timer.
public class CRBodyRuntimeEvents extends ScriptableService {
  public cb func OnLoad() {
    if !CRBodyRuntimePolicy.Enabled() {
      return;
    }
    let callbacks = GameInstance.GetCallbackSystem();
    callbacks.RegisterCallback(n"DarkFuture.Main.MainSystemLifecycleInitDoneEvent", this, n"OnStart", true);
    callbacks.RegisterCallback(n"DarkFuture.Main.MainSystemLifecycleResumeDoneEvent", this, n"OnResume", true);
    callbacks.RegisterCallback(n"DarkFuture.Main.MainSystemLifecycleSuspendEvent", this, n"OnSuspend", true);
    callbacks.RegisterCallback(n"DarkFuture.Main.MainSystemPlayerDeathEvent", this, n"OnDeath", true);
    callbacks.RegisterCallback(n"DarkFuture.Main.MainSystemTimeSkipStartEvent", this, n"OnSkipStart", true);
    callbacks.RegisterCallback(n"DarkFuture.Main.MainSystemTimeSkipCancelledEvent", this, n"OnSkipCancel", true);
  }
  private cb func OnStart(event: ref<MainSystemLifecycleInitDoneEvent>) { CRBodyRuntime.Get().Activate(); }
  private cb func OnResume(event: ref<MainSystemLifecycleResumeDoneEvent>) { CRBodyRuntime.Get().Activate(); }
  private cb func OnSuspend(event: ref<MainSystemLifecycleSuspendEvent>) { CRBodyRuntime.Get().Suspend(); }
  private cb func OnDeath(event: ref<MainSystemPlayerDeathEvent>) { CRBodyRuntime.Get().Suspend(); }
  private cb func OnSkipStart(event: ref<MainSystemTimeSkipStartEvent>) { CRBodyRuntime.Get().BeginSkip(); }
  private cb func OnSkipCancel(event: ref<MainSystemTimeSkipCancelledEvent>) { CRBodyRuntime.Get().CancelSkip(); }
}
