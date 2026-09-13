// Project-original pre-consumption routing for the regional-care trauma kit.
// The final treatment entry point is CYBERWARE > CONDITION. Until that native UI
// is mounted, this interceptor preserves the kit rather than silently falling back
// to Cyberpunk's generic instant-heal behavior.
module CyberpunkRealism.Integration

public class CRFieldCareItemUse extends IScriptable {
  // True means this request belongs to regional care, not that a kit was consumed.
  public static func Intercept(executor: wref<GameObject>, item: wref<gameItemData>, actionID: TweakDBID) -> Bool {
    if !CRBodyRuntimePolicy.Enabled() || !CRCombatRuntimePolicy.Enabled() || !IsDefined(item) || !Equals(ItemID.GetTDBID(item.GetID()), t"Items.HealthBooster") {
      return false;
    }
    let action: wref<ObjectAction_Record> = TweakDBInterface.GetObjectActionRecord(actionID);
    if !IsDefined(action) || !Equals(action.ActionName(), n"Consume") {
      return false;
    }
    let player: wref<PlayerPuppet> = executor as PlayerPuppet;
    let local: wref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if !IsDefined(player) || !Equals(player, local) || !CRBodyRuntime.Get().OwnsLocalizedInjuries() {
      return false;
    }

    // Ownership persists while temporarily unavailable; never fall back to spending
    // the kit through vanilla healing while realpass owns these injuries.
    if !CRBodyRuntime.Get().CanUseFieldCare() {
      CRFieldCareItemUse.Notify("Field care is unavailable here. Trauma kit kept.");
    } else {
      CRFieldCareItemUse.Notify("Trauma kit kept. Open CYBERWARE > CONDITION to choose treatment.");
    }
    return true;
  }

  private static func Notify(message: String) -> Void {
    let warning: SimpleScreenMessage;
    warning.isShown = true;
    warning.duration = 4.0;
    warning.message = "realpass  |  " + message;
    GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().UI_Notifications).SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warning), true);
  }
}
