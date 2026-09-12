// Cyberpunk Realism original bridge. Called by the pinned local DF tick adaptation.
module DarkFuture.Needs
import CyberpunkRealism.Integration.*
public func CRObserveBodyTick() -> Void {
  if CRBodyRuntimePolicy.Enabled() {
    CRBodyRuntime.Get().Observe();
  }
}
