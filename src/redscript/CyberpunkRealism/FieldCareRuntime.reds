// Project-original adapter over Cyberpunk's native inventory transaction system.
// Trauma Kits are analgesia-only in realpass and are intentionally NOT consumed by
// dressing/support. Field actions use separate stock supplies until/if dedicated
// realpass supply records are introduced.
module CyberpunkRealism.Integration
import CyberpunkRealism.Physiology.*

public class CRFieldCareInventory extends IScriptable {
  // Development-owned supply mapping using stable stock records:
  // 2 dressing -> Medical Gauze junk item; 3 support -> common crafting material.
  // The exact final support item/UX remains an open data-design detail, but this
  // boundary prevents Trauma Kits from becoming wound-healing currency again.
  public static func Supply(kind: Int32) -> ItemID {
    if kind == 2 {
      return ItemID.CreateQuery(t"Items.GenericJunkItem4");
    }
    if kind == 3 {
      return ItemID.CreateQuery(t"Items.CommonMaterial1");
    }
    return ItemID.CreateQuery(t"");
  }

  public static func Count(player: ref<PlayerPuppet>, kind: Int32) -> Int32 {
    if !IsDefined(player) || (kind != 2 && kind != 3) {
      return 0;
    }
    return GameInstance.GetTransactionSystem(player.GetGame()).GetItemQuantity(player, CRFieldCareInventory.Supply(kind));
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
    if !IsDefined(player) || !IsDefined(plan) || plan.committed || plan.spending || (plan.kind != 2 && plan.kind != 3) || !CRFieldCareModel.Same(plan.before, state) {
      return 0;
    }
    let inventory: ref<TransactionSystem> = GameInstance.GetTransactionSystem(player.GetGame());
    let supply: ItemID = CRFieldCareInventory.Supply(plan.kind);
    if inventory.GetItemQuantity(player, supply) < 1 {
      return 2;
    }
    plan.spending = true;
    if !inventory.RemoveItem(player, supply, 1) {
      plan.spending = false;
      return 5;
    }
    if (!IsDefined(action) || CRFieldCareActionRuntime.Get().IsCompleting(action)) && CRFieldCareModel.Commit(plan, state) {
      plan.spending = false;
      return 1;
    }
    // Inventory callbacks must not turn a stale plan into a paid no-op.
    if inventory.GiveItem(player, supply, 1) {
      plan.spending = false;
      return 3;
    }
    plan.spending = false;
    return 4;
  }
}
