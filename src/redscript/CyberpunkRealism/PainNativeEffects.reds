// Project-original native presentation of perceived pain and analgesic overuse.
// Pain uses owned stat-modifier handles on the active weapon. Overuse reuses CDPR's
// existing fullscreen drunk effect loops directly, without applying the stock Drunk
// status effect (and therefore without inheriting alcohol's unrelated gameplay).
import CyberpunkRealism.Physiology.*
import CyberpunkRealism.Integration.*

public class CRPainModifierSet extends IScriptable {
  private let slots: array<ref<CRInjuryModifierSlot>>;

  public func Clear() -> Bool {
    let i: Int32 = 0;
    let ok: Bool = true;
    while i < ArraySize(this.slots) {
      if !this.slots[i].Clear() {
        ok = false;
      }
      i += 1;
    }
    return ok;
  }

  public func Sync(player: ref<PlayerPuppet>, pain: ref<CRPainProjection>) -> Bool {
    let weapon: ref<WeaponObject>;
    let ok: Bool = true;
    if !IsDefined(player) || !IsDefined(pain) || !pain.valid {
      return this.Clear();
    }
    while ArraySize(this.slots) < 7 {
      ArrayPush(this.slots, new CRInjuryModifierSlot());
    }
    weapon = GameObject.GetActiveWeapon(player);
    if !this.slots[0].Sync(weapon, gamedataStatType.SwaySideMaximumAngleDistance, pain.weaponSway) { ok = false; }
    if !this.slots[1].Sync(weapon, gamedataStatType.SwaySideMinimumAngleDistance, pain.weaponSway) { ok = false; }
    if !this.slots[2].Sync(weapon, gamedataStatType.SpreadAdsDefaultX, pain.painSpread) { ok = false; }
    if !this.slots[3].Sync(weapon, gamedataStatType.SpreadAdsDefaultY, pain.painSpread) { ok = false; }
    if !this.slots[4].Sync(weapon, gamedataStatType.RecoilAngle, pain.painRecoil) { ok = false; }
    if !this.slots[5].Sync(weapon, gamedataStatType.RecoilKickMin, pain.painRecoil) { ok = false; }
    if !this.slots[6].Sync(weapon, gamedataStatType.RecoilKickMax, pain.painRecoil) { ok = false; }
    return ok;
  }
}

@addField(PlayerPuppet)
private let crPainModifiers: ref<CRPainModifierSet>;

@addField(PlayerPuppet)
private let crPainIntoxicationLevel: Int32;

public class CRPainNativeEffects extends IScriptable {
  private static func IntoxicationLevel(value: Float) -> Int32 {
    if value >= 1.0 { return 3; }
    if value >= 0.5 { return 2; }
    if value > 0.0 { return 1; }
    return 0;
  }

  private static func ClearIntoxication(player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(player) {
      return;
    }
    GameObjectEffectHelper.BreakEffectLoopEvent(player, n"status_drunk_level_1");
    GameObjectEffectHelper.BreakEffectLoopEvent(player, n"status_drunk_level_2");
    GameObjectEffectHelper.BreakEffectLoopEvent(player, n"status_drunk_level_3");
    GameObject.SetAudioParameter(player, n"vfx_fullscreen_drunk_level", 0.0);
    player.crPainIntoxicationLevel = 0;
  }

  private static func SyncIntoxication(player: ref<PlayerPuppet>, intoxication: Float) -> Void {
    let level: Int32 = CRPainNativeEffects.IntoxicationLevel(intoxication);
    if !IsDefined(player) || level == player.crPainIntoxicationLevel {
      return;
    }
    CRPainNativeEffects.ClearIntoxication(player);
    if level == 1 {
      GameObjectEffectHelper.StartEffectEvent(player, n"status_drunk_level_1");
      GameObject.SetAudioParameter(player, n"vfx_fullscreen_drunk_level", 1.0);
    }
    if level == 2 {
      GameObjectEffectHelper.StartEffectEvent(player, n"status_drunk_level_2");
      GameObject.SetAudioParameter(player, n"vfx_fullscreen_drunk_level", 2.0);
    }
    if level == 3 {
      GameObjectEffectHelper.StartEffectEvent(player, n"status_drunk_level_3");
      GameObject.SetAudioParameter(player, n"vfx_fullscreen_drunk_level", 3.0);
    }
    player.crPainIntoxicationLevel = level;
  }

  public static func Clear(player: ref<PlayerPuppet>) -> Bool {
    let ok: Bool = true;
    if IsDefined(player) && IsDefined(player.crPainModifiers) && !player.crPainModifiers.Clear() {
      ok = false;
    }
    CRPainNativeEffects.ClearIntoxication(player);
    return ok;
  }

  public static func Refresh(player: ref<PlayerPuppet>, enabled: Bool) -> Bool {
    let pain: ref<CRPainProjection>;
    if !IsDefined(player) || !enabled {
      return CRPainNativeEffects.Clear(player);
    }
    pain = CRPainRuntime.Get().Read();
    if !IsDefined(pain) || !pain.valid {
      return CRPainNativeEffects.Clear(player);
    }
    if !IsDefined(player.crPainModifiers) {
      player.crPainModifiers = new CRPainModifierSet();
    }
    let ok: Bool = player.crPainModifiers.Sync(player, pain);
    // Analgesic-overuse feedback is part of the authored body presentation rather
    // than a separate player preference. The sole public preference is the E3 HUD
    // visual skin; neither choice changes pain/injury state or weapon handling.
    CRPainNativeEffects.SyncIntoxication(player, pain.intoxication);
    return ok;
  }
}

// CRInjuryEffectsRuntime owns the transient-effects reconstruction point and calls
// CRPainNativeEffects.Refresh directly. Keeping that call inside the owned runtime
// avoids trying to @wrapMethod another project-defined class, which REDscript 2.31
// does not expose as a native wrapping target.

@wrapMethod(PlayerPuppet)
protected cb func OnDetach() -> Bool {
  CRPainNativeEffects.Clear(this);
  return wrappedMethod();
}
