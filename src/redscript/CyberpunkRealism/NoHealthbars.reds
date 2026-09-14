// realpass presentation policy for traditional actor health bars.
//
// Final RealPass presentation is injury/body-state led rather than HP-meter led,
// but attended development must not remove the player's only useful feedback before
// the replacement Biology/HUD/gameplay cues have actually been accepted in-game.
// Suppression is therefore replacement-gated instead of blindly always-on.
//
// Keep non-health information (RAM, buffs, names, scanner data, status cues) owned
// by their native/presentation systems. When an accepted replacement exists this
// file suppresses continuous HP bars, HP numbers/previews, the dedicated boss-health
// HUD and dedicated companion actor-health HUD without changing simulation state.
module CyberpunkRealism.Presentation

public class CRFeedbackReadiness extends IScriptable {
  // These are acceptance gates, not player settings and not balance controls.
  // Change each to true only after an attended build proves the corresponding
  // replacement feedback remains understandable during ordinary play/combat.
  public static func PlayerHealthReplacementAccepted() -> Bool {
    return false;
  }

  public static func NPCHealthReplacementAccepted() -> Bool {
    return false;
  }
}

public class CRHealthbarPresentationPolicy extends IScriptable {
  public static func ShowTraditionalPlayerHealthBars() -> Bool {
    return !CRFeedbackReadiness.PlayerHealthReplacementAccepted();
  }

  public static func ShowTraditionalNPCHealthBars() -> Bool {
    return !CRFeedbackReadiness.NPCHealthReplacementAccepted();
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

// Overclock has a direct visibility path which can bypass the generic update
// callback. Re-apply accepted suppression after native handling while preserving
// ordinary native behavior during the transitional fallback period.
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
