// Attended follow-up for the authoritative Biology ScriptableSystem.
//
// The body is still owned by the single CRBodyRuntime ScriptableSystem. This file
// only repairs how that singleton is found and how it reaches its owning session.
// It deliberately does not create menu-local physiology or a second runtime.
module CyberpunkRealism.Integration

import CyberpunkRealism.Settings.*

// The old access path reconstructed a ScriptableSystemsContainer from the global
// GetGameInstance() convenience function at every call site. That is not a stable
// ownership boundary for a REDmod-first, Codeware-independent build, particularly
// from in-game menu controllers. Cache only a weak reference to the already-created
// ScriptableSystem. Persistent physiology remains exclusively on CRBodyRuntime.
@addField(CRBodyRuntime)
private static let crAuthorityInstance: wref<CRBodyRuntime>;

// 0 = no session probe yet, 1 = registered/found, 2 = explicit session lookup failed.
// Transient diagnostic state only; never persisted and never substituted for body data.
@addField(CRBodyRuntime)
private static let crAuthorityRegistrationProbe: Int32;

@addMethod(CRBodyRuntime)
public static func GetForGame(game: GameInstance) -> ref<CRBodyRuntime> {
  let runtime: ref<CRBodyRuntime> = GameInstance.GetScriptableSystemsContainer(game).Get(n"CyberpunkRealism.Integration.CRBodyRuntime") as CRBodyRuntime;
  if IsDefined(runtime) {
    CRBodyRuntime.crAuthorityInstance = runtime;
    CRBodyRuntime.crAuthorityRegistrationProbe = 1;
  } else {
    CRBodyRuntime.crAuthorityRegistrationProbe = 2;
  }
  return runtime;
}

@replaceMethod(CRBodyRuntime)
public static func Get() -> ref<CRBodyRuntime> {
  return CRBodyRuntime.crAuthorityInstance;
}

@addMethod(CRBodyRuntime)
public static func RegistrationProbe() -> Int32 {
  return CRBodyRuntime.crAuthorityRegistrationProbe;
}

@addMethod(CRBodyRuntime)
public func AuthorityGame() -> GameInstance {
  // ScriptableSystem is itself session-owned. Once the game has registered this
  // instance, its inherited game instance is the canonical context for body work.
  return this.GetGameInstance();
}

@wrapMethod(CRBodyRuntime)
private func OnAttach() -> Void {
  CRBodyRuntime.crAuthorityInstance = this;
  CRBodyRuntime.crAuthorityRegistrationProbe = 1;
  wrappedMethod();
}

@wrapMethod(CRBodyRuntime)
private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
  CRBodyRuntime.crAuthorityInstance = this;
  CRBodyRuntime.crAuthorityRegistrationProbe = 1;
  wrappedMethod(saveVersion, gameVersion);
}

@wrapMethod(CRBodyRuntime)
private func OnDetach() -> Void {
  // Keep the authority resolvable while the original detach path tears down
  // transient subordinate systems, then release the session reference.
  wrappedMethod();
  if Equals(CRBodyRuntime.crAuthorityInstance, this) {
    CRBodyRuntime.crAuthorityInstance = null;
    CRBodyRuntime.crAuthorityRegistrationProbe = 0;
  }
}

// Player attachment gives us an indisputable game-owned GameInstance. Probe the
// ScriptableSystemsContainer before either ordering of the existing PlayerPuppet
// wrapper chain asks Biology for readiness.
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  if !this.IsReplacer() {
    CRBodyRuntime.GetForGame(this.GetGame());
  }
  return wrappedMethod();
}

// -----------------------------------------------------------------------------
// CRBodyRuntime instance work must use the GameInstance owned by this system,
// never re-bootstrap through the global convenience function.
// -----------------------------------------------------------------------------

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
  this.tickScheduled = true;
  GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(callback, 1.0);
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

// -----------------------------------------------------------------------------
// Readiness/gates now derive settings from the same session-owned authority.
// A missing authority remains an explicit failure; it never manufactures STABLE.
// -----------------------------------------------------------------------------

@replaceMethod(CRBiologyRuntimeAvailability)
public static func Enabled() -> Bool {
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  if !IsDefined(runtime) {
    // Preserve the authored default while authority is missing so FailureReason
    // reports the runtime defect rather than falsely claiming Biology was disabled.
    return true;
  }
  return CRRealpassSettings.IsEnabled(runtime.AuthorityGame());
}

@replaceMethod(CRBiologyRuntimeAvailability)
public static func EnsureActive() -> Bool {
  if !CRBodyRuntimePolicy.Enabled() {
    return false;
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  if !IsDefined(runtime) || !CRRealpassSettings.IsEnabled(runtime.AuthorityGame()) {
    return false;
  }
  if !runtime.IsRunning() {
    runtime.Activate();
  }
  return runtime.IsRunning() && runtime.OwnsNeeds();
}

@replaceMethod(CRBiologyRuntimeAvailability)
public static func FailureReason() -> String {
  if !CRBodyRuntimePolicy.Enabled() {
    return "BODY RUNTIME BUILD GATE CLOSED";
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  if !IsDefined(runtime) {
    if CRBodyRuntime.RegistrationProbe() == 2 {
      return "BODY RUNTIME SYSTEM MISSING: NOT REGISTERED";
    }
    return "BODY RUNTIME SYSTEM MISSING: SESSION CONTEXT UNAVAILABLE";
  }
  if !CRRealpassSettings.IsEnabled(runtime.AuthorityGame()) {
    return "BIOLOGY DISABLED";
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

@replaceMethod(CRBodyRuntimeMasterPolicy)
public static func Enabled() -> Bool {
  if !CRBodyRuntimePolicy.Enabled() {
    return false;
  }
  let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  return !IsDefined(runtime) || CRRealpassSettings.IsEnabled(runtime.AuthorityGame());
}

// -----------------------------------------------------------------------------
// Body-owned subordinate ScriptableSystems resolve through the body's session.
// This keeps activation/publish/treatment paths on the same GameInstance even when
// the initiating caller is a menu controller.
// -----------------------------------------------------------------------------

@replaceMethod(CRPainRuntime)
public static func Get() -> ref<CRPainRuntime> {
  let body: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  if !IsDefined(body) {
    return null;
  }
  return GameInstance.GetScriptableSystemsContainer(body.AuthorityGame()).Get(n"CyberpunkRealism.Integration.CRPainRuntime") as CRPainRuntime;
}

@replaceMethod(CRFieldCareActionRuntime)
public static func Get() -> ref<CRFieldCareActionRuntime> {
  let body: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  if !IsDefined(body) {
    return null;
  }
  return GameInstance.GetScriptableSystemsContainer(body.AuthorityGame()).Get(n"CyberpunkRealism.Integration.CRFieldCareActionRuntime") as CRFieldCareActionRuntime;
}

@replaceMethod(CRInjuryProvenanceRuntime)
public static func Get() -> ref<CRInjuryProvenanceRuntime> {
  let body: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  if !IsDefined(body) {
    return null;
  }
  return GameInstance.GetScriptableSystemsContainer(body.AuthorityGame()).Get(n"CyberpunkRealism.Integration.CRInjuryProvenanceRuntime") as CRInjuryProvenanceRuntime;
}

@replaceMethod(CRInjuryEffectsRuntime)
public static func Get() -> ref<CRInjuryEffectsRuntime> {
  let body: ref<CRBodyRuntime> = CRBodyRuntime.Get();
  if !IsDefined(body) {
    return null;
  }
  return GameInstance.GetScriptableSystemsContainer(body.AuthorityGame()).Get(n"CRInjuryEffectsRuntime") as CRInjuryEffectsRuntime;
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
