// Original adapter over the existing native inventory transaction system.
// Items.HealthBooster is the trauma kit already distributed by the staged DF
// dependency. Using it here supplies regional care instead of its Consume action.
module CyberpunkRealism.Integration
import CyberpunkRealism.Physiology.*

public class CRFieldCareInventory extends IScriptable {
  public static func Kit() -> ItemID {
    return ItemID.CreateQuery(t"Items.HealthBooster");
  }

  public static func Count(player: ref<PlayerPuppet>) -> Int32 {
    if !IsDefined(player) {
      return 0;
    }
    return GameInstance.GetTransactionSystem(player.GetGame()).GetItemQuantity(player, CRFieldCareInventory.Kit());
  }

  // Result: 1 applied; 2 no supplies; 3 state changed and refunded;
  // 4 refund failed (must be surfaced); 5 inventory refused removal.
  public static func Execute(player: ref<PlayerPuppet>, plan: ref<CRFieldCarePlan>, state: ref<CRInjuryState>) -> Int32 {
    return CRFieldCareInventory.ExecuteForAction(player, plan, state, null);
  }
  public static func ExecuteForAction(player: ref<PlayerPuppet>, plan: ref<CRFieldCarePlan>, state: ref<CRInjuryState>, action: ref<CRFieldCareAction>) -> Int32 {
    if IsDefined(action) && !CRFieldCareActionRuntime.Get().IsCompleting(action) {
      return 0;
    }
    if !IsDefined(player) || !IsDefined(plan) || plan.committed || plan.spending || !CRFieldCareModel.Same(plan.before, state) {
      return 0;
    }
    let inventory: ref<TransactionSystem> = GameInstance.GetTransactionSystem(player.GetGame());
    let kit: ItemID = CRFieldCareInventory.Kit();
    if inventory.GetItemQuantity(player, kit) < 1 {
      return 2;
    }
    plan.spending = true;
    if !inventory.RemoveItem(player, kit, 1) {
      plan.spending = false;
      return 5;
    }
    if (!IsDefined(action) || CRFieldCareActionRuntime.Get().IsCompleting(action)) && CRFieldCareModel.Commit(plan, state) {
      plan.spending = false;
      return 1;
    }
    // Inventory callbacks must not turn a stale plan into a paid no-op.
    if inventory.GiveItem(player, kit, 1) {
      plan.spending = false;
      return 3;
    }
    plan.spending = false;
    return 4;
  }
}
