// RealPass presentation policy for traditional actor health bars.
//
// Attended testing has now explicitly accepted barless actor presentation as the
// RealPass-on behavior. Native health UI is restored only when the global RealPass
// master switch is off. This changes presentation only; native health state remains
// available to the game and to RealPass' physical/injury simulation.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

public class CRFeedbackReadiness extends IScriptable {
  // Explicit attended acceptance: the project owner expects the traditional player
  // health indicator to stay absent while RealPass is enabled, even while richer
  // E3/embodied replacement presentation continues to be implemented.
  public static func PlayerHealthReplacementAccepted() -> Bool {
    return true;
  }

  public static func NPCHealthReplacementAccepted() -> Bool {
    return true;
  }
}

public class CRHealthbarPresentationPolicy extends IScriptable {
  public static func ShowTraditionalPlayerHealthBars() -> Bool {
    return !CRRealpassSettings.IsEnabled(GetGameInstance()) || !CRFeedbackReadiness.PlayerHealthReplacementAccepted();
  }

  public static func ShowTraditionalNPCHealthBars() -> Bool {
    return !CRRealpassSettings.IsEnabled(GetGameInstance()) || !CRFeedbackReadiness.NPCHealthReplacementAccepted();
  }
}

@addMethod(healthbarWidgetGameController)
private func CRApplyPlayerHealthPresentation() -> Void {
  if CRHealthbarPresentationPolicy.ShowTraditionalPlayerHealthBars() {
    return;
  }
  // Hide only health-specific children. Do not hide the controller root: RAM,
  // buffs and other non-health information can share the player biomonitor root.
  inkWidgetRef.SetVisible(this.m_healthBar, false);
  inkWidgetRef.SetVisible(this.m_overshieldBarRef, false);
  inkWidgetRef.SetVisible(this.m_lostHealthAggregationBar, false);
  inkWidgetRef.SetVisible(this.m_damegePreview, false);
  inkWidgetRef.SetVisible(this.m_fullBar, false);
  inkTextRef.SetVisible(this.m_healthTextPath, false);
  inkTextRef.SetVisible(this.m_maxHealthTextPath, false);
}

@wrapMethod(healthbarWidgetGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRApplyPlayerHealthPresentation();
  return result;
}

@wrapMethod(healthbarWidgetGameController)
protected cb func OnUpdateHealthBarVisibility() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRApplyPlayerHealthPresentation();
  return result;
}

@wrapMethod(healthbarWidgetGameController)
public final func EvaluateHealthBarVisibility(isInOverclockedState: Bool) -> Void {
  wrappedMethod(isInOverclockedState);
  this.CRApplyPlayerHealthPresentation();
}

@wrapMethod(healthbarWidgetGameController)
public final func EvaluateOvershieldBarVisibility() -> Void {
  wrappedMethod();
  this.CRApplyPlayerHealthPresentation();
}

@addMethod(NameplateVisualsLogicController)
private func CRApplyNPCHealthPresentation() -> Void {
  if CRHealthbarPresentationPolicy.ShowTraditionalNPCHealthBars() {
    return;
  }
  this.m_healthbarVisible = false;
  inkWidgetRef.SetVisible(this.m_healthbarWidget, false);
  inkWidgetRef.SetVisible(this.m_damagePreviewWrapper, false);
  inkWidgetRef.SetVisible(this.m_damagePreviewWidget, false);
  inkWidgetRef.SetVisible(this.m_damagePreviewArrow, false);
}

@wrapMethod(NameplateVisualsLogicController)
private final func UpdateHealthbarVisibility() -> Void {
  wrappedMethod();
  this.CRApplyNPCHealthPresentation();
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  wrappedMethod(puppet, incomingData, isNewNpc);
  this.CRApplyNPCHealthPresentation();
}

@wrapMethod(BossHealthBarGameController)
private final func ShowBossHealthBar(puppet: ref<NPCPuppet>, useSilentUpdate: Bool) -> Void {
  if CRHealthbarPresentationPolicy.ShowTraditionalNPCHealthBars() {
    wrappedMethod(puppet, useSilentUpdate);
    return;
  }
  this.HideBossHealthBar();
  this.GetRootWidget().SetVisible(false);
}

@wrapMethod(CompanionHealthBarGameController)
protected cb func OnFlatheadStatusChanged(value: Bool) -> Bool {
  let result: Bool = wrappedMethod(value);
  if !CRHealthbarPresentationPolicy.ShowTraditionalNPCHealthBars() {
    this.GetRootWidget().SetVisible(false);
  }
  return result;
}
