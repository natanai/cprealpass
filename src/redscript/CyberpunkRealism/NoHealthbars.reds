// realpass presentation: no traditional health bars.
//
// Keep non-health information (RAM, buffs, names, scanner data, status cues) owned
// by their native/presentation systems. This file only suppresses continuous HP
// bars, HP numbers/previews and the dedicated boss-health HUD. The simulation and
// native damage systems remain authoritative; hiding a bar must never change HP.
//
// Hook signatures are verified against Cyberpunk 2077 script sources and again by
// local compilation before an attended profile can be deployed.
module CyberpunkRealism.Presentation

public class CRHealthbarPresentationPolicy extends IScriptable {
  // realpass' authored default is an information-sparse, injury-led combat read.
  // A future settings adapter may expose this as presentation.traditionalHealthBars.
  public static func ShowTraditionalHealthBars() -> Bool {
    return false;
  }
}

@addMethod(healthbarWidgetGameController)
private func CRHideTraditionalPlayerHealth() -> Void {
  if CRHealthbarPresentationPolicy.ShowTraditionalHealthBars() {
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
  this.CRHideTraditionalPlayerHealth();
  return result;
}

@wrapMethod(healthbarWidgetGameController)
protected cb func OnUpdateHealthBarVisibility() -> Bool {
  let result: Bool = wrappedMethod();
  this.CRHideTraditionalPlayerHealth();
  return result;
}

@addMethod(NameplateVisualsLogicController)
private func CRHideTraditionalNPCHealth() -> Void {
  if CRHealthbarPresentationPolicy.ShowTraditionalHealthBars() {
    return;
  }
  this.m_healthbarVisible = false;
  inkWidgetRef.SetVisible(this.m_healthbarWidget, false);
  // E3/native layouts can keep damage-preview children outside the visible fill.
  // Suppress them too so the removed HP bar is not reconstructed by preview UI.
  inkWidgetRef.SetVisible(this.m_damagePreviewWrapper, false);
  inkWidgetRef.SetVisible(this.m_damagePreviewWidget, false);
  inkWidgetRef.SetVisible(this.m_damagePreviewArrow, false);
}

@wrapMethod(NameplateVisualsLogicController)
private final func UpdateHealthbarVisibility() -> Void {
  wrappedMethod();
  this.CRHideTraditionalNPCHealth();
}

@wrapMethod(NameplateVisualsLogicController)
public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void {
  wrappedMethod(puppet, incomingData, isNewNpc);
  this.CRHideTraditionalNPCHealth();
}

@wrapMethod(BossHealthBarGameController)
private final func ShowBossHealthBar(puppet: ref<NPCPuppet>, useSilentUpdate: Bool) -> Void {
  if CRHealthbarPresentationPolicy.ShowTraditionalHealthBars() {
    wrappedMethod(puppet, useSilentUpdate);
    return;
  }
  // Keep native boss/quest state untouched while preventing the dedicated HP HUD.
  // HideBossHealthBar owns listener/animation cleanup in the native controller.
  this.HideBossHealthBar();
  this.GetRootWidget().SetVisible(false);
}
