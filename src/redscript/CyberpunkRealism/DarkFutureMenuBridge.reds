// Cyberpunk Realism original menu event bridge. No new callback timer.
module DarkFuture.Services
import CyberpunkRealism.Integration.*
public func CRBeforeBodyMenuBoundary() -> Void {
  if CRBodyRuntimePolicy.Enabled() { CRBodyRuntime.Get().Observe(); }
}
public func CRAfterBodyMenuBoundary() -> Void {
  if CRBodyRuntimePolicy.Enabled() { CRFieldCareActionRuntime.Get().OnMenuBoundary(); CRBodyRuntime.Get().RebaseObservation(); CRBodyRuntime.Get().TestSnapshot("menu-boundary"); }
}
