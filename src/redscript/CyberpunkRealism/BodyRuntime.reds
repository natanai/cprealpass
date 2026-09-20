// Project-original body runtime. This adapter talks directly to Cyberpunk native
// lifecycle/time/player state and to other realpass systems. Dark Future and other
// gameplay mods are not runtime hosts.
module CyberpunkRealism.Integration

import CyberpunkRealism.Physiology.*

public class CRBodyRuntimePolicy extends IScriptable {
  // Canonical source remains fail-closed. Attended/release builders open this only
  // after compiling the exact owned-runtime candidate against the installed game.
  public static func Enabled() -> Bool {
    return false;
  }
}

public class CRBodyTestPolicy extends IScriptable {
  public static func Diagnostics() -> Bool {
    return false;
  }
}

public class CRBodyTickCallback extends DelayCallback {
  public let generation: Int32;
  public let crOwner: wref<CRBodyRuntime>;

  public func Call() -> Void {
    if IsDefined(this.crOwner) {
      this.crOwner.HandleTick(this.generation);
    }
  }
}

public class CRBodyRuntime extends ScriptableSystem {
  private persistent let body: ref<CRBodyState>;
  private persistent let inputs: ref<CRBodyInputQueue>;
  private persistent let unmappedConsumptions: Int32 = 0;
  private persistent let bodySchemaVersion: Int32 = 0;

  private let clock: ref<CRClockState>;
  private let config: ref<CRBodyConfig>;
  private let meterConfig: ref<CRBodyMeterConfig>;
  private let running: Bool = false;
  private let unsupportedSaveVersion: Bool = false;
  private let timeSkipForecastReady: Bool = false;
  private let fieldCareBusy: Bool = false;
  private let tickGeneration: Int32 = 0;
  private let tickScheduled: Bool = false;
  private let nextSkipFromWaitMenu: Bool = false;
  private let testSnapshotCount: Int32 = 0;
  private let testLastSim: Float = 0.0;
  private let testLastSnapshot: String;
  // W21.2/T007 attended diagnostics are transient and bounded. They never become
  // save state, a second physiology authority, or an external telemetry stream.
  private let testTickCount: Int32 = 0;
  private let testProgressCount: Int32 = 0;
  private let testLastObservedHours: Float = 0.0;
  private let testLastNativeAllowed: Bool = false;
  private let testCombatEventCount: Int32 = 0;
  private let testLastCombat: String;
  private let testPresentationCount: Int32 = 0;
  private let testLastPresentation: String;

  public static func Get() -> ref<CRBodyRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRBodyRuntime>()) as CRBodyRuntime;
  }

  public func AuthorityGame() -> GameInstance {
    return this.GetGameInstance();
  }

  public func HasAuthorityPlayer() -> Bool {
    return IsDefined(this.Player());
  }

  public func HasUnsupportedSaveVersion() -> Bool {
    return this.unsupportedSaveVersion;
  }

  private func OnAttach() -> Void {
    this.ResetTransientState();
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.ResetTransientState();
  }

  private func OnDetach() -> Void {
    let fieldCare: ref<CRFieldCareActionRuntime> = CRBiologySessionAuthority.FieldCare(this.GetGameInstance());
    let effects: ref<CRInjuryEffectsRuntime> = CRBiologySessionAuthority.InjuryEffects(this.GetGameInstance());
    if IsDefined(fieldCare) {
      fieldCare.Cancel(false);
    }
    if IsDefined(effects) {
      effects.Suspend();
    }
    this.running = false;
    this.tickGeneration += 1;
    this.tickScheduled = false;
    this.clock = null;
  }

  private func ResetTransientState() -> Void {
    this.clock = new CRClockState();
    this.config = new CRBodyConfig();
    this.meterConfig = new CRBodyMeterConfig();
    this.running = false;
    this.unsupportedSaveVersion = this.bodySchemaVersion < 0 || this.bodySchemaVersion > 2;
    this.timeSkipForecastReady = false;
    this.fieldCareBusy = false;
    this.nextSkipFromWaitMenu = false;
    this.tickGeneration += 1;
    this.tickScheduled = false;
    this.testSnapshotCount = 0;
    this.testLastSim = 0.0;
    this.testLastSnapshot = "";
    this.testTickCount = 0;
    this.testProgressCount = 0;
    this.testLastObservedHours = 0.0;
    this.testLastNativeAllowed = false;
    this.testCombatEventCount = 0;
    this.testLastCombat = "";
    this.testPresentationCount = 0;
    this.testLastPresentation = "";
  }

  public func Activate() -> Void {
    if !CRBodyRuntimeMasterPolicy.Enabled(this.GetGameInstance()) {
      return;
    }
    this.ResetTransientState();
    if this.unsupportedSaveVersion {
      return;
    }

    // A clean realpass save starts from realpass' own physiological baseline. We do
    // not import percentages or persistent state from another gameplay mod.
    if this.bodySchemaVersion == 0 {
      if IsDefined(this.body) {
        return;
      }
      this.body = CRBodyModel.Create(this.config);
      if !IsDefined(this.body) {
        return;
      }
      this.bodySchemaVersion = 2;
    }

    let upgradedSchema: Int32 = CRBodyPresentation.UpgradeSchema(this.bodySchemaVersion, this.body, this.config, this.meterConfig);
    if upgradedSchema < 0 {
      this.bodySchemaVersion = -1;
      return;
    }
    this.bodySchemaVersion = upgradedSchema;
    if this.bodySchemaVersion != 2 || !IsDefined(this.body) || !this.GetMeters().valid {
      return;
    }
    if !IsDefined(this.inputs) {
      this.inputs = new CRBodyInputQueue();
    }

    this.running = true;
    this.ResetClock();
    this.Publish();
    this.ScheduleTick();
    this.TestSnapshot("activate");
  }

  public func Suspend() -> Void {
    let fieldCare: ref<CRFieldCareActionRuntime>;
    let effects: ref<CRInjuryEffectsRuntime>;
    this.TestSnapshot("suspend");
    fieldCare = CRBiologySessionAuthority.FieldCare(this.GetGameInstance());
    effects = CRBiologySessionAuthority.InjuryEffects(this.GetGameInstance());
    if IsDefined(fieldCare) {
      fieldCare.Cancel(false);
    }
    if IsDefined(effects) {
      effects.Suspend();
    }
    this.running = false;
    this.tickGeneration += 1;
    this.tickScheduled = false;
    this.ResetClock();
  }

  public func IsRunning() -> Bool {
    return this.running;
  }

  public func OwnsNeeds() -> Bool {
    // Ownership survives temporary menu/cinematic suspension; the saved body is
    // never refilled merely because progression is paused.
    return CRBodyRuntimeMasterPolicy.Enabled(this.GetGameInstance()) && this.bodySchemaVersion == 2 && IsDefined(this.body) && this.body.initialized;
  }

  public func OwnsLocalizedInjuries() -> Bool {
    return CRCombatRuntimePolicy.Enabled() && this.OwnsNeeds();
  }

  public func GetBodyConfig() -> ref<CRBodyConfig> {
    return this.config;
  }

  public func GetMeters() -> ref<CRBodyMeters> {
    return CRBodyPresentation.Read(this.body, this.config, this.meterConfig);
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

  private func Player() -> ref<PlayerPuppet> {
    return GameInstance.GetPlayerSystem(this.GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
  }

  private func InMenu() -> Bool {
    let board: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGameInstance()).Get(GetAllBlackboardDefs().UI_System);
    return IsDefined(board) && board.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu);
  }

  private func NativeStateAllowed(allowMenu: Bool) -> Bool {
    let player: ref<PlayerPuppet> = this.Player();
    if !this.running || !CRPlayerBodyLifecycle.Allowed(player, allowMenu) {
      return false;
    }
    return allowMenu || !this.InMenu();
  }

  private func WorldSeconds() -> Int32 {
    return GameTime.GetSeconds(GameInstance.GetTimeSystem(this.GetGameInstance()).GetGameTime());
  }

  private func SimSeconds() -> Float {
    return GameInstance.GetSimTime(this.GetGameInstance()).ToFloat();
  }

  private func ResetClock() -> Void {
    if IsDefined(this.clock) {
      CRClockModel.CancelSkip(this.clock, this.WorldSeconds(), this.SimSeconds());
      this.RebaseObservation();
    }
  }

  public func RebaseObservation() -> Void {
    if this.running && IsDefined(this.clock) {
      CRClockModel.Reset(this.clock, this.WorldSeconds(), this.SimSeconds(), this.NativeStateAllowed(false));
    }
  }

  private func Exertion() -> Float {
    let player: ref<PlayerPuppet> = this.Player();
    if !IsDefined(player) || VehicleComponent.IsMountedToVehicle(this.GetGameInstance(), player) {
      return 0.0;
    }
    // Provisional movement proxy. It is intentionally owned here and can later be
    // enriched with stamina/swim/combat signals without changing the body model.
    return ClampF(Vector4.Length(player.GetVelocity()) / 7.0, 0.0, 1.0);
  }

  private func ApplyHours(hours: Float, sleeping: Bool, exertion: Float) -> Void {
    if hours <= 0.0 {
      return;
    }
    CRBodyInputs.Time(this.inputs, hours, exertion, sleeping);
  }

  public func Observe() -> Void {
    let effects: ref<CRInjuryEffectsRuntime>;
    if !CRBodyRuntimeMasterPolicy.Enabled(this.GetGameInstance()) {
      this.Suspend();
      return;
    }
    if !this.running || !IsDefined(this.clock) || !IsDefined(this.inputs) || !IsDefined(this.body) {
      return;
    }
    let allowed: Bool = this.NativeStateAllowed(false);
    let hours: Float = CRClockModel.Observe(this.clock, this.WorldSeconds(), this.SimSeconds(), allowed);
    if CRBodyTestPolicy.Diagnostics() {
      this.testLastNativeAllowed = allowed;
      this.testLastObservedHours = hours;
      if hours > 0.0 && this.testProgressCount < 1000000 {
        this.testProgressCount += 1;
      }
    }
    this.ApplyHours(hours, false, this.Exertion());
    if this.OwnsLocalizedInjuries() && !this.inputs.faulted {
      effects = CRBiologySessionAuthority.InjuryEffects(this.GetGameInstance());
      if IsDefined(effects) {
        effects.Advance(hours, this.config, false);
      }
    }
    CRBodyInputs.Drain(this.inputs, this.body, this.config);
    this.Publish();
    this.TestSnapshot("tick");
  }

  private func ScheduleTick() -> Void {
    let callback: ref<CRBodyTickCallback>;
    if !this.running || this.tickScheduled || !CRBodyRuntimePolicy.Enabled() {
      return;
    }
    callback = new CRBodyTickCallback();
    callback.generation = this.tickGeneration;
    callback.crOwner = this;
    this.tickScheduled = true;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(callback, 1.0);
  }

  public func HandleTick(generation: Int32) -> Void {
    if generation != this.tickGeneration || !this.running || !CRBodyRuntimePolicy.Enabled() {
      return;
    }
    this.tickScheduled = false;
    if CRBodyTestPolicy.Diagnostics() && this.testTickCount < 1000000 {
      this.testTickCount += 1;
    }
    this.Observe();
    this.ScheduleTick();
  }

  // The normal pause/hub "skip time" entry point marks the next popup as waiting.
  // Other stock TimeskipGameController invocations are treated as bed sleep. The
  // native hook consumes this marker at popup initialization so cancellation cannot
  // leave stale classification behind.
  public func MarkNextTimeSkipAsWait() -> Void {
    this.nextSkipFromWaitMenu = true;
  }

  public func ConsumeNextTimeSkipSleeping() -> Bool {
    let sleeping: Bool = !this.nextSkipFromWaitMenu;
    this.nextSkipFromWaitMenu = false;
    return sleeping;
  }

  public func BeginSkip() -> Void {
    let fieldCare: ref<CRFieldCareActionRuntime> = CRBiologySessionAuthority.FieldCare(this.GetGameInstance());
    if IsDefined(fieldCare) {
      fieldCare.Cancel(false);
    }
    if !this.running || !IsDefined(this.clock) {
      return;
    }
    this.Observe();
    CRClockModel.BeginSkip(this.clock, this.WorldSeconds(), this.SimSeconds());
    this.TestSnapshot("skip-start");
  }

  public func FinishSkipHours(hoursRequested: Float, sleeping: Bool) -> Void {
    let effects: ref<CRInjuryEffectsRuntime>;
    if !this.running || !IsDefined(this.clock) || !IsDefined(this.inputs) || !IsDefined(this.body) {
      return;
    }
    let hours: Float = CRClockModel.FinishSkip(this.clock, this.WorldSeconds(), this.SimSeconds(), hoursRequested);
    this.ApplyHours(hours, sleeping, 0.0);
    if this.OwnsLocalizedInjuries() && !this.inputs.faulted {
      effects = CRBiologySessionAuthority.InjuryEffects(this.GetGameInstance());
      if IsDefined(effects) {
        effects.Advance(hours, this.config, sleeping);
      }
    }
    CRBodyInputs.Drain(this.inputs, this.body, this.config);
    this.Publish();
    this.TestSnapshot("skip-finish");
  }

  public func CancelSkip() -> Void {
    this.ResetClock();
  }

  public func RefreshInjuryEffects() -> Void {
    let effects: ref<CRInjuryEffectsRuntime> = CRBiologySessionAuthority.InjuryEffects(this.GetGameInstance());
    if IsDefined(effects) {
      effects.Refresh(this.body, this.config, this.NativeStateAllowed(false) && this.OwnsLocalizedInjuries());
    }
  }

  private func Publish() -> Void {
    // Presentation is separately owned. The body runtime publishes no values into
    // another mod's needs systems and creates no duplicate HUD authority.
    this.RefreshInjuryEffects();
  }

  public func CanAcceptCombatInjury() -> Bool {
    return this.NativeStateAllowed(false) && this.OwnsLocalizedInjuries() && IsDefined(this.inputs) && !this.inputs.faulted && CRInjuryModel.CanAdvance(this.body.injuries, this.config);
  }

  public func RecordInjury(region: Int32, tissue: Float, bone: Float, cyberware: Float, externalBleed: Float, internalBleed: Float) -> Bool {
    if !this.CanAcceptCombatInjury() {
      this.TestCombatStage("record-rejected", region, 0, 0, tissue);
      return false;
    }
    this.Observe();
    let fieldCare: ref<CRFieldCareActionRuntime> = CRBiologySessionAuthority.FieldCare(this.GetGameInstance());
    if IsDefined(fieldCare) {
      fieldCare.Cancel(true);
    }
    let accepted: Bool = CRBodyInputs.Injury(this.inputs, region, tissue, bone, cyberware, externalBleed, internalBleed);
    if accepted {
      CRBodyInputs.Drain(this.inputs, this.body, this.config);
      this.Publish();
      this.TestCombatStage("record-accepted", region, 0, 0, tissue);
    } else {
      this.TestCombatStage("record-input-rejected", region, 0, 0, tissue);
    }
    return accepted;
  }

  public func CompleteTreatment(region: Int32, kind: Int32, effectiveness: Float) -> Bool {
    if !this.OwnsNeeds() || !this.NativeStateAllowed(true) || !IsDefined(this.inputs) || this.inputs.faulted {
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

  // Field care is selected from a menu (Condition mode), so initiation must allow
  // a paused/menu state. The timed action itself only advances after the menu is
  // closed; CanContinueFieldCare remains the stricter gameplay gate.
  public func CanUseFieldCare() -> Bool {
    let player: ref<PlayerPuppet> = this.Player();
    return !this.fieldCareBusy && this.OwnsLocalizedInjuries() && this.NativeStateAllowed(true) && IsDefined(this.inputs) && !this.inputs.faulted && IsDefined(player) && !player.IsInCombat() && !VehicleComponent.IsMountedToVehicle(this.GetGameInstance(), player);
  }

  public func CanContinueFieldCare() -> Bool {
    let player: ref<PlayerPuppet> = this.Player();
    return this.OwnsLocalizedInjuries() && this.NativeStateAllowed(false) && IsDefined(this.inputs) && !this.inputs.faulted && IsDefined(player) && !player.IsInCombat() && !VehicleComponent.IsMountedToVehicle(this.GetGameInstance(), player);
  }

  public func UseFieldCare(region: Int32, kind: Int32) -> Int32 {
    let fieldCare: ref<CRFieldCareActionRuntime> = CRBiologySessionAuthority.FieldCare(this.GetGameInstance());
    if !IsDefined(fieldCare) {
      return 0;
    }
    return fieldCare.Begin(region, kind);
  }

  public func CommitFieldCare(action: ref<CRFieldCareAction>) -> Int32 {
    let fieldCare: ref<CRFieldCareActionRuntime> = CRBiologySessionAuthority.FieldCare(this.GetGameInstance());
    if !IsDefined(fieldCare) || !fieldCare.IsCompleting(action) || !this.CanUseFieldCare() {
      return 0;
    }
    let region: Int32 = action.region;
    let kind: Int32 = action.kind;
    this.fieldCareBusy = true;
    this.Observe();
    // A paid interaction never jumps ahead of pending body events. Let the normal
    // body drain settle first rather than creating a second timing authority.
    if this.inputs.faulted || this.inputs.count != 0 || !CRBodyModel.CloseInterval(this.body, this.config) {
      this.fieldCareBusy = false;
      return 0;
    }
    let plan: ref<CRFieldCarePlan> = CRFieldCareModel.Prepare(this.body.injuries, region, kind);
    if !IsDefined(plan) {
      this.fieldCareBusy = false;
      return 6;
    }
    let result: Int32 = CRFieldCareInventory.ExecuteForAction(this.Player(), plan, this.body.injuries, action);
    if result == 1 {
      this.inputs.appliedTreatments += 1;
    }
    this.fieldCareBusy = false;
    this.Publish();
    return result;
  }

  public func CanUseBodyInteraction() -> Bool {
    let player: ref<PlayerPuppet> = this.Player();
    return this.OwnsNeeds() && this.NativeStateAllowed(false) && IsDefined(this.inputs) && !this.inputs.faulted && IsDefined(player) && !player.IsInCombat();
  }

  public func CompleteBodyInteraction(kind: Int32) -> Bool {
    // Shower completion can occur during a native cinematic, so allow menu/scene
    // presentation here while retaining the realpass body/schema/input guards.
    if !this.running || !this.OwnsNeeds() || !IsDefined(this.inputs) || this.inputs.faulted {
      return false;
    }
    this.Observe();
    let accepted: Bool = CRBodyInputs.Interact(this.inputs, kind, 1.0);
    if accepted {
      CRBodyInputs.Drain(this.inputs, this.body, this.config);
      this.Publish();
    }
    return accepted;
  }

  public func Consume(itemRecord: wref<Item_Record>) -> Void {
    // Inventory is a valid native consumption surface even though UI time is paused.
    if !this.running || !this.OwnsNeeds() || !IsDefined(itemRecord) || !this.NativeStateAllowed(true) || !IsDefined(this.inputs) || this.inputs.faulted {
      return;
    }
    this.Observe();
    let serving: ref<CRServing> = CRItemServing.Resolve(itemRecord);
    if !serving.recognized {
      this.unmappedConsumptions += 1;
      this.TestSnapshot("unmapped-item");
      return;
    }
    CRBodyInputs.Intake(this.inputs, serving.waterMl, serving.energyKcal, serving.residueGrams);
    CRBodyInputs.Drain(this.inputs, this.body, this.config);
    this.Publish();
    this.TestSnapshot("consume");
  }

  // Attended diagnostics remain in-memory only. No external log, watcher, file,
  // timer service or telemetry process is created by the diagnostic surface.
  public func TestCombatStage(stage: String, region: Int32, material: Int32, shapeCount: Int32, value: Float) -> Void {
    if !CRBodyTestPolicy.Diagnostics() {
      return;
    }
    if this.testCombatEventCount < 10000 {
      this.testCombatEventCount += 1;
    }
    this.testLastCombat = stage + " r=" + ToString(region) + " m=" + ToString(material) + " shapes=" + ToString(shapeCount) + " v=" + ToString(value);
  }

  public func TestPresentationRead(surface: String) -> Void {
    if !CRBodyTestPolicy.Diagnostics() || !IsDefined(this.body) {
      return;
    }
    if this.testPresentationCount < 10000 {
      this.testPresentationCount += 1;
    }
    this.testLastPresentation = surface + " body=" + ToString(this.body.elapsedHours) + "h tissue=" + ToString(CRInjuryModel.TissueBurden(this.body.injuries));
  }

  public func TestStatus() -> String {
    if !CRBodyTestPolicy.Diagnostics() || !IsDefined(this.clock) || !IsDefined(this.body) || !IsDefined(this.inputs) {
      return "";
    }
    return "T007 AUTH | ticks " + ToString(this.testTickCount) + " progressed " + ToString(this.testProgressCount) + " allowed " + ToString(this.testLastNativeAllowed) + " dt " + ToString(this.testLastObservedHours) + "h rate " + ToString(this.clock.lastObservedRatio) + "x | body " + ToString(this.body.elapsedHours) + "h | combat " + ToString(this.testCombatEventCount) + " " + this.testLastCombat + " | view " + ToString(this.testPresentationCount) + " " + this.testLastPresentation + " | queue " + ToString(this.inputs.count) + " fault " + ToString(this.inputs.faulted);
  }

  public func TestSnapshot(event: String) -> Void {
    if !CRBodyTestPolicy.Diagnostics() || this.testSnapshotCount >= 500 {
      return;
    }
    let sim: Float = this.SimSeconds();
    if Equals(event, "tick") && sim >= this.testLastSim && sim - this.testLastSim < 60.0 {
      return;
    }
    this.testLastSim = sim;
    this.testSnapshotCount += 1;
    this.testLastSnapshot = "event=" + event + " schema=" + ToString(this.bodySchemaVersion) + " running=" + ToString(this.running) + " world=" + ToString(this.WorldSeconds()) + " sim=" + ToString(sim);
  }

  public func TestLastSnapshot() -> String {
    if !CRBodyTestPolicy.Diagnostics() {
      return "";
    }
    return this.testLastSnapshot;
  }
}
