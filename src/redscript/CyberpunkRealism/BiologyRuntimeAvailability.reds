// Biology-facing readiness bridge for the authoritative body runtime.
//
// CRBodyRuntime remains the only body-state authority. This helper exists so native
// presentation surfaces can safely retry activation after save/menu lifecycle edges
// without creating, caching, or copying a second body state.
module CyberpunkRealism.Integration

import CyberpunkRealism.Settings.*

public class CRBiologyRuntimeAvailability extends IScriptable {
  public static func Enabled() -> Bool {
    return CRBodyRuntimePolicy.Enabled() && CRRealpassSettings.IsEnabled(GetGameInstance());
  }

  public static func Enabled(game: GameInstance) -> Bool {
    return CRBodyRuntimePolicy.Enabled() && CRRealpassSettings.IsEnabled(game);
  }

  public static func EnsureActive() -> Bool {
    if !CRBiologyRuntimeAvailability.Enabled() {
      return false;
    }

    let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
    if !IsDefined(runtime) {
      return false;
    }

    // The player-attach hook remains the normal startup path. This retry is
    // intentionally idempotent and exists for save/session ordering where that one
    // edge can occur before the ScriptableSystem is ready, or a restored system has
    // reset its transient running state before the menu is opened again.
    if !runtime.IsRunning() || !runtime.OwnsNeeds() {
      runtime.Activate();
    }

    return runtime.OwnsNeeds();
  }

  public static func EnsureActive(game: GameInstance) -> Bool {
    if !CRBiologyRuntimeAvailability.Enabled(game) {
      return false;
    }
    let runtime: ref<CRBodyRuntime> = CRBiologySessionAuthority.Body(game);
    if !IsDefined(runtime) {
      return false;
    }
    if !runtime.IsRunning() || !runtime.OwnsNeeds() {
      runtime.Activate();
    }
    return runtime.IsRunning() && runtime.OwnsNeeds();
  }

  public static func FailureReason() -> String {
    if !CRBodyRuntimePolicy.Enabled() {
      return "BODY RUNTIME BUILD GATE CLOSED";
    }
    if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
      return "BIOLOGY DISABLED";
    }

    let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
    if !IsDefined(runtime) {
      return "BODY RUNTIME SYSTEM MISSING";
    }
    if !runtime.OwnsNeeds() {
      return "BODY STATE NOT INITIALIZED";
    }
    return "";
  }

  public static func FailureReason(game: GameInstance) -> String {
    if !CRBodyRuntimePolicy.Enabled() {
      return "BODY RUNTIME BUILD GATE CLOSED";
    }
    if !CRRealpassSettings.IsEnabled(game) {
      return "BIOLOGY DISABLED";
    }
    let probe: Int32 = CRBiologySessionAuthority.BodyProbe(game);
    if probe == 1 {
      return "BODY RUNTIME SESSION CONTEXT UNAVAILABLE";
    }
    if probe == 2 {
      return "BODY RUNTIME SYSTEM NOT REGISTERED";
    }
    let runtime: ref<CRBodyRuntime> = CRBiologySessionAuthority.Body(game);
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
}
