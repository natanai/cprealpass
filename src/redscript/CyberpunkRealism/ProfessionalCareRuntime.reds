// Project-original professional-service commit boundary. The Cyberware/ripperdoc UI
// supplies the accepted professional context; this helper revalidates that the
// selected service can still help immediately before entering the shared body input
// queue. It owns no vendor economy, native HP or parallel injury state.
module CyberpunkRealism.Integration

import CyberpunkRealism.Physiology.*

public class CRProfessionalCareRuntime extends IScriptable {
  public static func Complete(region: Int32, kind: Int32) -> Bool {
    let runtime: ref<CRBodyRuntime> = CRBodyRuntime.Get();
    let snapshot: ref<CRBodyState>;
    if !IsDefined(runtime) || (kind != 4 && kind != 5) {
      return false;
    }
    runtime.Observe();
    snapshot = runtime.GetBodySnapshot();
    if !IsDefined(snapshot) || !CRProfessionalCareModel.CanHelp(snapshot.injuries, region, kind) {
      return false;
    }
    // CompleteTreatment remains the one ordered treatment input/commit authority.
    // Clinical care and mechanical repair differ only in their validated kind.
    return runtime.CompleteTreatment(region, kind, 1.0);
  }
}
