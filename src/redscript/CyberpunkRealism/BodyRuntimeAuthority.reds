// Attended follow-up for the authoritative Biology ScriptableSystem.
//
// The body remains the single CRBodyRuntime ScriptableSystem. This seam removes
// reliance on the parameterless GetGameInstance() convenience path wherever the
// authoritative body can instead use a game-owned session context. It creates no
// menu-local physiology, no fallback body and no second persistence authority.
module CyberpunkRealism.Integration

import CyberpunkRealism.Settings.*

// Explicit ScriptableSystem lookup for callers that already own the session.
// Keep the registered module-qualified name visible at the seam so live diagnostics
// can distinguish container/context failure from a genuinely unregistered system.
@addMethod(CRBodyRuntime)
public static func Get(game: GameInstance) -> ref<CRBodyRuntime> {
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return null;
  }
  return container.Get(n"CyberpunkRealism.Integration.CRBodyRuntime") as CRBodyRuntime;
}

// 1 = no ScriptableSystemsContainer for this context; 2 = container exists but the
// Biology body system is not registered; 3 = registered/found. No diagnostic state
// is persisted or cached.
@addMethod(CRBodyRuntime)
public static func SessionProbe(game: GameInstance) -> Int32 {
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return 1;
  }
  if !IsDefined(container.Get(n"CyberpunkRealism.Integration.CRBodyRuntime") as CRBodyRuntime) {
    return 2;
  }
  return 3;
}

@addMethod(CRBodyRuntime)
public func AuthorityGame() -> GameInstance {
  return this.GetGameInstance();
}

@addMethod(CRBodyRuntime)
public func HasAuthorityPlayer() -> Bool {
  return IsDefined(this.Player());
}

@addMethod(CRPainRuntime)
public static func Get(game: GameInstance) -> ref<CRPainRuntime> {
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return null;
  }
  return container.Get(n"CyberpunkRealism.Integration.CRPainRuntime") as CRPainRuntime;
}

@addMethod(CRFieldCareActionRuntime)
public static func Get(game: GameInstance) -> ref<CRFieldCareActionRuntime> {
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return null;
  }
  return container.Get(n"CyberpunkRealism.Integration.CRFieldCareActionRuntime") as CRFieldCareActionRuntime;
}

@addMethod(CRInjuryProvenanceRuntime)
public static func Get(game: GameInstance) -> ref<CRInjuryProvenanceRuntime> {
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return null;
  }
  return container.Get(n"CyberpunkRealism.Integration.CRInjuryProvenanceRuntime") as CRInjuryProvenanceRuntime;
}

// CRInjuryEffectsRuntime is intentionally global-scope source, so its registered
// class name is unqualified even though it consumes Biology state.
@addMethod(CRInjuryEffectsRuntime)
public static func Get(game: GameInstance) -> ref<CRInjuryEffectsRuntime> {
  let container: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(game);
  if !IsDefined(container) {
    return null;
  }
  return container.Get(n"CRInjuryEffectsRuntime") as CRInjuryEffectsRuntime;
}

// -----------------------------------------------------------------------------
// Body lifecycle and ticking stay on the GameInstance owned by CRBodyRuntime.
// -----------------------------------------------------------------------------

@addField(CRBodyTickCallback)
public let crOwner: wref<CRBodyRuntime>;

@replaceMethod(CRBodyTickCallback)
public func Call() -> Void {
  if IsDefined(this.crOwner) {
    this.crOwner.HandleTick(this.generation);
  }
}

@replaceMethod(CRBodyRuntime)
private func Player() -> ref<PlayerPuppet> {
  return GameInstance.GetPlayerSystem(this.GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
}

@replaceMethod(CRBodyRuntime)
private func InMenu() -> Bool {
  let board: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGameInstance()).Get(GetAllBlackboardDefs().UI_System);
  return IsDefined(board) && board.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu);
}

@replaceMethod(CRBodyRuntime)
private func WorldSeconds() -> Int32 {
  return GameTime.GetSeconds(GameInstance.GetTimeSystem(this.GetGameInstance()).GetGameTime());
}

@replaceMethod(CRBodyRuntime)
private func SimSeconds() -> Float {
  return GameInstance.GetSimTime(this.GetGameInstance()).ToFloat();
}

@replaceMethod(CRBodyRuntime)
private func Exertion() -> Float {
  let player: ref<PlayerPuppet> = this.Player();
  if !IsDefined(player) || VehicleComponent.IsMountedToVehicle(this.GetGameInstance(), player) {
    return 0.0;
  }
  return ClampF(Vector4.Length(player.GetVelocity()) / 7.0, 0.0, 1.0);
}

@replaceMethod(CRBodyRuntime)
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

@replaceMethod(CRBodyRuntime)
private func OnDetach() -> Void {
  let fieldCare: ref<CRFieldCareActionRuntime> = CRFieldCareActionRuntime.Get(this.GetGameInstance());
  let effects: ref<CRInjuryEffectsRuntime> = CRInjuryEffectsRuntime.Get(this.GetGameInstance());
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

@replaceMethod(CRBodyRuntime)
public func Suspend() -> Void {
  let fieldCare: ref<CRFieldCareActionRuntime>;
  let effects: ref<CRInjuryEffectsRuntime>;
  this.TestSnapshot("suspend");
  fieldCare = CRFieldCareActionRuntime.Get(this.GetGameInstance());
  effects = CRInjuryEffectsRuntime.Get(this.GetGameInstance());
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

@replaceMethod(CRBodyRuntime)
public func Observe() -> Void {
  let effects: ref<CRInjuryEffectsRuntime>;
  if !this.running || !IsDefined(this.clock) || !IsDefined(this.inputs) || !IsDefined(this.body) {
    return;
  }
  let hours: Float = CRClockModel.Observe(this.clock, this.WorldSeconds(), this.SimSeconds(), this.NativeStateAllowed(false));
  this.ApplyHours(hours, false, this.Exertion());
  if this.OwnsLocalizedInjuries() && !this.inputs.faulted {
    effects = CRInjuryEffectsRuntime.Get(this.GetGameInstance());
    if IsDefined(effects) {
      effects.Advance(hours, this.config, false);
    }
  }
  CRBodyInputs.Drain(this.inputs, this.body, this.config);
  this.Publish();
  this.TestSnapshot("tick");
}

@replaceMethod(CRBodyRuntime)
public func BeginSkip() -> Void {
  let fieldCare: ref<CRFieldCareActionRuntime> = CRFieldCareActionRuntime.Get(this.GetGameInstance());
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

@replaceMethod(CRBodyRuntime)
public func FinishSkipHours(hoursRequested: Float, sleeping: Bool) -> Void {
  let effects: ref<CRInjuryEffectsRuntime>;
  if !this.running || !IsDefined(this.clock) || !IsDefined(this.inputs) || !IsDefined(this.body) {
    return;
  }
  let hours: Float = CRClockModel.FinishSkip(this.clock, this.WorldSeconds(), this.SimSeconds(), hoursRequested);
  this.ApplyHours(hours, sleeping, 0.0);
  if this.OwnsLocalizedInjuries() && !this.inputs.faulted {
    effects = CRInjuryEffectsRuntime.Get(this.GetGameInstance());
    if IsDefined(effects) {
      effects.Advance(hours, this.config, sleeping);
    }
  }
  CRBodyInputs.Drain(this.inputs, this.body, this.config);
  this.Publish();
  this.TestSnapshot("skip-finish");
}

@replaceMethod(CRBodyRuntime)
public func RefreshInjuryEffects() -> Void {
  let effects: ref<CRInjuryEffectsRuntime> = CRInjuryEffectsRuntime.Get(this.GetGameInstance());
  if IsDefined(effects) {
    effects.Refresh(this.body, this.config, this.NativeStateAllowed(false) && this.OwnsLocalizedInjuries());
  }
}

@replaceMethod(CRBodyRuntime)
public func CanUseFieldCare() -> Bool {
  let player: ref<PlayerPuppet> = this.Player();
  return !this.fieldCareBusy && this.OwnsLocalizedInjuries() && this.NativeStateAllowed(true) && IsDefined(this.inputs) && !this.inputs.faulted && IsDefined(player) && !player.IsInCombat() && !VehicleComponent.IsMountedToVehicle(this.GetGameInstance(), player);
}

@replaceMethod(CRBodyRuntime)
public func CanContinueFieldCare() -> Bool {
  let player: ref<PlayerPuppet> = this.Player();
  return this.OwnsLocalizedInjuries() && this.NativeStateAllowed(false) && IsDefined(this.inputs) && !this.inputs.faulted && IsDefined(player) && !player.IsInCombat() && !VehicleComponent.IsMountedToVehicle(this.GetGameInstance(), player);
}

// Pain is a subordinate persistent projection but must share the body's session and
// authored elapsed body clock rather than rediscovering a global game context.
@replaceMethod(CRPainRuntime)
private func Sync() -> ref<CRBodyState> {
  let bodyRuntime: ref<CRBodyRuntime>;
  let body: ref<CRBodyState>;
  let delta: Float;
  this.EnsureState();
  bodyRuntime = CRBodyRuntime.Get(this.GetGameInstance());
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

@replaceMethod(CRInjuryEffectsRuntime)
public func Register(npc: ref<NPCPuppet>) -> Bool {
  let bodyRuntime: ref<CRBodyRuntime>;
  let i: Int32 = 0;
  if !IsDefined(npc) || !CRCombatRuntimePolicy.Enabled() || npc.IsDead() || ScriptedPuppet.IsDefeated(npc) || !npc.IsAttached() {
    return false;
  }
  this.Prune();
  while i < ArraySize(this.npcs) {
    if Equals(this.npcs[i].GetEntityID(), npc.GetEntityID()) {
      return true;
    }
    i += 1;
  }
  if ArraySize(this.npcs) >= 128 {
    this.rejectedRegistrations += 1;
    return false;
  }
  bodyRuntime = CRBodyRuntime.Get(this.GetGameInstance());
  if !IsDefined(bodyRuntime) {
    return false;
  }
  bodyRuntime.Observe();
  npc.crProgressAllowed = CRInjuryEffectsBridge.Allowed(npc, true);
  ArrayPush(this.npcs, npc);
  return true;
}

@replaceMethod(CRInjuryEffectsRuntime)
public func Refresh(body: ref<CRBodyState>, config: ref<CRBodyConfig>, enabled: Bool) -> Void {
  let i: Int32 = 0;
  let player: ref<ScriptedPuppet> = GameInstance.GetPlayerSystem(this.GetGameInstance()).GetLocalPlayerMainGameObject() as ScriptedPuppet;
  let localPlayer: ref<PlayerPuppet> = player as PlayerPuppet;
  this.lastRefreshFailures = 0;
  if IsDefined(body) {
    if !CRInjuryEffectsBridge.Apply(player, body.injuries, config, enabled) {
      this.lastRefreshFailures += 1;
    }
  } else {
    if !CRInjuryEffectsBridge.Clear(player) {
      this.lastRefreshFailures += 1;
    }
  }
  this.Prune();
  while i < ArraySize(this.npcs) {
    this.npcs[i].crProgressAllowed = CRInjuryEffectsBridge.Allowed(this.npcs[i], enabled);
    if !CRInjuryEffectsBridge.Apply(this.npcs[i], CRNPCInjuryBridge.State(this.npcs[i]), config, enabled && CRNPCInjuryBridge.CanAccept(this.npcs[i])) {
      this.lastRefreshFailures += 1;
    }
    i += 1;
  }
  CRPainNativeEffects.Refresh(localPlayer, IsDefined(body) && enabled && CRInjuryEffectsBridge.Allowed(localPlayer, true));
}

// -----------------------------------------------------------------------------
// Readiness/gates with an explicit game-owned session.
// -----------------------------------------------------------------------------

@addMethod(CRBiologyRuntimeAvailability)
public static func Enabled(game: GameInstance) -> Bool {
  return CRBodyRuntimePolicy.Enabled() && CRRealpassSettings.IsEnabled(game);
}

@addMethod(CRBiologyRuntimeAvailability)
public static func EnsureActive(game: GameInstance) -> Bool {
  if !CRBiologyRuntimeAvailability.Enabled(game) {
    return false;
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get(game);
  if !IsDefined(runtime) {
    return false;
  }
  if !runtime.IsRunning() || !runtime.OwnsNeeds() {
    runtime.Activate();
  }
  return runtime.IsRunning() && runtime.OwnsNeeds();
}

@addMethod(CRBiologyRuntimeAvailability)
public static func FailureReason(game: GameInstance) -> String {
  if !CRBodyRuntimePolicy.Enabled() {
    return "BODY RUNTIME BUILD GATE CLOSED";
  }
  if !CRRealpassSettings.IsEnabled(game) {
    return "BIOLOGY DISABLED";
  }
  let probe: Int32 = CRBodyRuntime.SessionProbe(game);
  if probe == 1 {
    return "BODY RUNTIME SESSION CONTEXT UNAVAILABLE";
  }
  if probe == 2 {
    return "BODY RUNTIME SYSTEM NOT REGISTERED";
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get(game);
  if !IsDefined(runtime) {
    return "BODY RUNTIME SYSTEM MISSING";
  }
  if !runtime.HasAuthorityPlayer() {
    return "BODY RUNTIME PLAYER UNAVAILABLE";
  }
  if runtime.HasUnsupportedSaveVersion() {
    return "BODY SAVE VERSION UNSUPPORTED";
  }
  if !runtime.OwnsNeeds() {
    return "BODY RUNTIME NOT INITIALIZED";
  }
  if !runtime.IsRunning() {
    return "BODY RUNTIME NOT RUNNING";
  }
  return "";
}

@addMethod(CRBodyRuntimeMasterPolicy)
public static func Enabled(game: GameInstance) -> Bool {
  return CRBodyRuntimePolicy.Enabled() && CRRealpassSettings.IsEnabled(game);
}

@addMethod(CRBodyRuntimeMasterPolicy)
public static func Ready(game: GameInstance) -> Bool {
  return CRBiologyRuntimeAvailability.EnsureActive(game);
}

// The existing wrapper remains for compatibility with other branch work. This outer
// wrapper adds a second, explicit session-owned startup edge; it is idempotent and
// activates the same ScriptableSystem rather than creating another body.
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  if !this.IsReplacer() && CRBodyRuntimePolicy.Enabled() {
    CRBiologyRuntimeAvailability.EnsureActive(this.GetGame());
  }
  return result;
}
