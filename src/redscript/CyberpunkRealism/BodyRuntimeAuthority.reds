// Explicit session lookup for Biology-owned ScriptableSystems.
//
// This is a project-owned helper, not a redscript native patch surface. Biology
// classes own their own methods directly; native hook annotations remain reserved
// for actual Cyberpunk classes. No body state is cached or duplicated here.
module CyberpunkRealism.Integration

public class CRBiologySessionAuthority extends IScriptable {
  private static func Container(game: GameInstance) -> ref<ScriptableSystemsContainer> {
    return GameInstance.GetScriptableSystemsContainer(game);
  }

  public static func Body(game: GameInstance) -> ref<CRBodyRuntime> {
    let container: ref<ScriptableSystemsContainer> = CRBiologySessionAuthority.Container(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CyberpunkRealism.Integration.CRBodyRuntime") as CRBodyRuntime;
  }

  // 1 = no ScriptableSystemsContainer for this context; 2 = container exists but
  // the Biology body system is not registered; 3 = registered/found.
  public static func BodyProbe(game: GameInstance) -> Int32 {
    let container: ref<ScriptableSystemsContainer> = CRBiologySessionAuthority.Container(game);
    if !IsDefined(container) {
      return 1;
    }
    if !IsDefined(container.Get(n"CyberpunkRealism.Integration.CRBodyRuntime") as CRBodyRuntime) {
      return 2;
    }
    return 3;
  }

  public static func Pain(game: GameInstance) -> ref<CRPainRuntime> {
    let container: ref<ScriptableSystemsContainer> = CRBiologySessionAuthority.Container(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CyberpunkRealism.Integration.CRPainRuntime") as CRPainRuntime;
  }

  public static func FieldCare(game: GameInstance) -> ref<CRFieldCareActionRuntime> {
    let container: ref<ScriptableSystemsContainer> = CRBiologySessionAuthority.Container(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CyberpunkRealism.Integration.CRFieldCareActionRuntime") as CRFieldCareActionRuntime;
  }

  public static func Provenance(game: GameInstance) -> ref<CRInjuryProvenanceRuntime> {
    let container: ref<ScriptableSystemsContainer> = CRBiologySessionAuthority.Container(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CyberpunkRealism.Integration.CRInjuryProvenanceRuntime") as CRInjuryProvenanceRuntime;
  }

  // CRInjuryEffectsRuntime intentionally lives in global source scope, so its
  // registered name is unqualified even though it consumes Biology state.
  public static func InjuryEffects(game: GameInstance) -> ref<CRInjuryEffectsRuntime> {
    let container: ref<ScriptableSystemsContainer> = CRBiologySessionAuthority.Container(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CRInjuryEffectsRuntime") as CRInjuryEffectsRuntime;
  }
}
