// Original provisional serving model. Quantities are design assumptions pending
// per-item calibration, not measured contents of fictional products.
module CyberpunkRealism.Physiology

public class CRServing extends IScriptable {
  public let recognized: Bool = false;
  public let waterMl: Float = 0.0;
  public let energyKcal: Float = 0.0;
  public let residueGrams: Float = 0.0;
}

public class CRServingModel extends IScriptable {
  public static func Resolve(drink: Bool, plainWater: Bool, foodTier: Int32) -> ref<CRServing> {
    let serving: ref<CRServing> = new CRServing();
    if drink || plainWater {
      serving.recognized = true;
      // Drink quality does not change the amount of water in the same serving.
      serving.waterMl = 330.0;
      if plainWater {
        serving.waterMl = 500.0;
      }
    }
    if foodTier == 1 {
      serving.recognized = true;
      serving.waterMl += 20.0;
      serving.energyKcal = 125.0;
      serving.residueGrams = 8.0;
    }
    if foodTier == 2 {
      serving.recognized = true;
      serving.waterMl += 60.0;
      serving.energyKcal = 300.0;
      serving.residueGrams = 15.0;
    }
    if foodTier == 3 {
      serving.recognized = true;
      serving.waterMl += 200.0;
      serving.energyKcal = 650.0;
      serving.residueGrams = 35.0;
    }
    if foodTier == 4 {
      serving.recognized = true;
      serving.waterMl += 300.0;
      serving.energyKcal = 900.0;
      serving.residueGrams = 45.0;
    }
    return serving;
  }
}
