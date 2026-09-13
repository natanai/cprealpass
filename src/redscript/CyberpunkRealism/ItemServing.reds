// Project-original stock-consumable classification shared by intake and preview.
// Uses native Cyberpunk item tags/records only; no source-mod tags or tweak payloads.
module CyberpunkRealism.Integration
import CyberpunkRealism.Physiology.*

public class CRItemServing extends IScriptable {
  public static func Resolve(itemRecord: wref<Item_Record>) -> ref<CRServing> {
    let serving: ref<CRServing>;
    let foodTier: Int32 = 0;
    if !IsDefined(itemRecord) {
      return new CRServing();
    }

    // Stock food records inherit the native Food tag and commonly expose a physical
    // size tag. Size is a better provisional portion proxy than price/rarity.
    if itemRecord.TagsContains(n"Food") {
      if itemRecord.TagsContains(n"Large") {
        foodTier = 3;
      } else {
        if itemRecord.TagsContains(n"Medium") {
          foodTier = 2;
        } else {
          // Native Small and un-sized stock foods use a conservative small serving
          // until exact fictional-product portions are authored from game evidence.
          foodTier = 1;
        }
      }
    }

    let plainWater: Bool = Equals(itemRecord.GetID(), t"Items.GoodQualityDrink10") || Equals(itemRecord.GetID(), t"Items.NomadsDrink1") || Equals(itemRecord.GetID(), t"Items.MediumQualityDrink3") || Equals(itemRecord.GetID(), t"Items.MediumQualityDrink4");
    let ordinaryDrink: Bool = itemRecord.TagsContains(n"Drink") && !itemRecord.TagsContains(n"Alcohol");
    serving = CRServingModel.Resolve(ordinaryDrink, plainWater, foodTier);

    // Alcohol is intentionally not an addiction/humanity subsystem, but swallowed
    // fluid still enters the body. These provisional amounts model one consumed
    // container without importing another mod's alcohol progression mechanics.
    if itemRecord.TagsContains(n"Alcohol") {
      serving.recognized = true;
      serving.waterMl = 120.0;
      serving.energyKcal = 100.0;
      serving.residueGrams = 0.0;
    }
    return serving;
  }
}
