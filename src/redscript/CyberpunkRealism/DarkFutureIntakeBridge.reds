// Original bridge. Called once at the existing central consumption dispatch.
module DarkFuture.Main
import CyberpunkRealism.Integration.*

public func CRForwardBodyConsumption(itemRecord: wref<Item_Record>) -> Void {
  if CRBodyRuntimePolicy.Enabled() {
    CRBodyRuntime.Get().Consume(itemRecord);
  }
}

public func CRForwardBodySkipFinished(data: DFTimeSkipData) -> Void {
  if CRBodyRuntimePolicy.Enabled() {
    CRBodyRuntime.Get().FinishSkip(data);
  }
}
