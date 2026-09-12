// Original item classification shared by consumption and preview.
module CyberpunkRealism.Integration
import CyberpunkRealism.Physiology.*

public class CRItemServing extends IScriptable {
  public static func Resolve(itemRecord: wref<Item_Record>) -> ref<CRServing> {
    if !IsDefined(itemRecord) {
      return new CRServing();
    }
    let foodTier: Int32 = 0;
    if itemRecord.TagsContains(n"DarkFutureConsumableNutrition") {
      if itemRecord.TagsContains(n"DarkFutureConsumableNutritionTier4") {
        foodTier = 4;
      } else {
        if itemRecord.TagsContains(n"DarkFutureConsumableNutritionTier3") {
          foodTier = 3;
        } else {
          if itemRecord.TagsContains(n"DarkFutureConsumableNutritionTier2") {
            foodTier = 2;
          } else {
            if itemRecord.TagsContains(n"DarkFutureConsumableNutritionTier1") {
              foodTier = 1;
            }
          }
        }
      }
    }
    let plainWater: Bool = Equals(itemRecord.GetID(), t"Items.GoodQualityDrink10") || Equals(itemRecord.GetID(), t"Items.NomadsDrink1");
    return CRServingModel.Resolve(itemRecord.TagsContains(n"DarkFutureConsumableHydration"), plainWater, foodTier);
  }
}
