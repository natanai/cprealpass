// Project-original professional-service commit boundary. The Cyberware/ripperdoc UI
// supplies the accepted professional context; this method revalidates that the
// selected service can still help immediately before entering the shared body input
// queue. It owns no vendor economy, native HP or parallel injury state.
module CyberpunkRealism.Integration

import CyberpunkRealism.Physiology.*

@addMethod(CRBodyRuntime)
public func CompleteProfessionalCare(region: Int32, kind: Int32) -> Bool {
  let snapshot: ref<CRBodyState>;
  if kind != 4 && kind != 5 {
    return false;
  }
  snapshot = this.GetBodySnapshot();
  if !IsDefined(snapshot) || !CRProfessionalCareModel.CanHelp(snapshot.injuries, region, kind) {
    return false;
  }
  // CompleteTreatment is the one ordered treatment input/commit authority. Clinical
  // care and mechanical repair differ only in their validated treatment kind.
  return this.CompleteTreatment(region, kind, 1.0);
}
