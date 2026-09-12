// Original project bridge for presenting shared state through existing needs UI.
module DarkFuture.Needs
import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public func CROwnsBodyNeed(kind: DFNeedType) -> Bool {
  if !CRBodyRuntimePolicy.Enabled() {
    return false;
  }
  return (Equals(kind, DFNeedType.Hydration) || Equals(kind, DFNeedType.Nutrition) || Equals(kind, DFNeedType.Energy)) && CRBodyRuntime.Get().OwnsNeeds();
}

public func CRBodyNeedDelta(kind: DFNeedType, current: Float, requested: Float) -> Float {
  if !CROwnsBodyNeed(kind) {
    return requested;
  }
  let meters: ref<CRBodyMeters> = CRBodyRuntime.Get().GetMeters();
  if !meters.valid {
    return 0.0;
  }
  if Equals(kind, DFNeedType.Hydration) {
    return CRBodyPresentation.ResolveDelta(true, current, requested, meters.hydration);
  }
  if Equals(kind, DFNeedType.Nutrition) {
    return CRBodyPresentation.ResolveDelta(true, current, requested, meters.nutrition);
  }
  return CRBodyPresentation.ResolveDelta(true, current, requested, meters.energy);
}

public func CRPublishBodyMeters(meters: ref<CRBodyMeters>) -> Void {
  if !meters.valid {
    return;
  }
  // Preserve the existing notification/FX path. Avoid repeated zero-change events
  // when multiple existing needs ticks observe the same game-clock instant.
  let hydration: ref<DFHydrationSystem> = DFHydrationSystem.Get();
  let nutrition: ref<DFNutritionSystem> = DFNutritionSystem.Get();
  let energy: ref<DFEnergySystem> = DFEnergySystem.Get();
  if hydration.GetNeedValue() >= 0.0 && AbsF(hydration.GetNeedValue() - meters.hydration) > 0.0001 {
    hydration.ChangeNeedValue(0.0);
  }
  if nutrition.GetNeedValue() >= 0.0 && AbsF(nutrition.GetNeedValue() - meters.nutrition) > 0.0001 {
    nutrition.ChangeNeedValue(0.0);
  }
  if energy.GetNeedValue() >= 0.0 && AbsF(energy.GetNeedValue() - meters.energy) > 0.0001 {
    energy.ChangeNeedValue(0.0);
  }
}

public func CRShowBodyMeters() -> Void {
  DFHydrationSystem.Get().UpdateNeedHUDUI(true, false, true, true);
  DFNutritionSystem.Get().UpdateNeedHUDUI(true, false, true, true);
  DFEnergySystem.Get().UpdateNeedHUDUI(true, false, true, true);
}
