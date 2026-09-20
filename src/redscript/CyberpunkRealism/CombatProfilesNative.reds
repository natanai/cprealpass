// Original adapter for game weapon/equipment records. Reference calculations
// only: no damage, armor-condition commit, logging or extra event loop.
import CyberpunkRealism.Combat.*

public class CRCombatProfileSample extends IScriptable {
  public let projectileFamily: Int32;
  public let ammoRecord: TweakDBID;
  public let distanceM: Float;
  public let ricochets: Int32;
  public let projectile: ref<CRProjectileSpec>;
  public let referenceImpact: ref<CRImpactState>;
  public let referenceReady: Bool;
  // Structural/read failures remain fatal readiness failures.
  public let unresolvedProtection: Int32;
  // Valid equipped records without a Biology protection profile are tracked
  // separately. Player hits may defer conservatively to the native physical
  // channel for these records; NPC appearance protection remains fail-closed.
  public let unmappedProtection: Int32;
  public let nativePhysicalCap: Bool;
  public let protectionRecords: array<TweakDBID>;
  public let equippedItemIDs: array<ItemID>;
  public let knownLayers: Int32;
  public let equipmentVisited: Int32;
  public let armorWear: ref<CRArmorWearPlan>;
}

public class CRCombatProfilesNative extends IScriptable {
  public static func Family(record: ref<WeaponItem_Record>) -> Int32 {
    let overrideFamily: Int32;
    if !IsDefined(record) {
      return 0;
    }
    overrideFamily = TweakDBInterface.GetInt(record.GetID() + t".crProjectileFamily", 0);
    if overrideFamily != 0 {
      return overrideFamily;
    }
    if !IsDefined(record.Evolution()) || !IsDefined(record.ItemType()) || NotEquals(record.Evolution().Type(), gamedataWeaponEvolution.Power) {
      return 0;
    }
    switch record.ItemType().Type() {
      case gamedataItemType.Wea_Handgun: return 1;
      case gamedataItemType.Wea_Revolver: return 2;
      case gamedataItemType.Wea_AssaultRifle: return 3;
      case gamedataItemType.Wea_LightMachineGun: return 4;
      case gamedataItemType.Wea_Shotgun: return 5;
      case gamedataItemType.Wea_ShotgunDual: return 5;
      case gamedataItemType.Wea_PrecisionRifle: return 6;
      case gamedataItemType.Wea_SniperRifle: return 6;
      case gamedataItemType.Wea_SubmachineGun: return 7;
    }
    return 0;
  }

  public static func ProjectileProfile(record: ref<WeaponItem_Record>) -> ref<CRBallisticProfile> {
    let p: ref<CRBallisticProfile> = CRBallisticProfiles.Family(CRCombatProfilesNative.Family(record));
    if !IsDefined(record) || !CRBallisticProfiles.Valid(p) {
      return p;
    }
    // Ammo defines the projectile; weapon-specific overrides can account for
    // barrel/charge differences. Invalid explicit values stay invalid.
    if IsDefined(record.Ammo()) {
      CRCombatProfilesNative.ApplyProjectileOverrides(p, record.Ammo().GetID());
    }
    CRCombatProfilesNative.ApplyProjectileOverrides(p, record.GetID());
    return p;
  }

  private static func ApplyProjectileOverrides(p: ref<CRBallisticProfile>, record: TweakDBID) -> Void {
    p.massGrams = TweakDBInterface.GetFloat(record + t".crProjectileMassGrams", p.massGrams);
    p.muzzleSpeed = TweakDBInterface.GetFloat(record + t".crProjectileMuzzleSpeed", p.muzzleSpeed);
    p.diameterMm = TweakDBInterface.GetFloat(record + t".crProjectileDiameterMm", p.diameterMm);
    p.penetrationFactor = TweakDBInterface.GetFloat(record + t".crProjectilePenetration", p.penetrationFactor);
    p.speedHalfDistanceM = TweakDBInterface.GetFloat(record + t".crProjectileSpeedHalfDistance", p.speedHalfDistanceM);
    p.ricochetSpeedRetention = TweakDBInterface.GetFloat(record + t".crRicochetSpeedRetention", p.ricochetSpeedRetention);
    p.chargeSpeedGain = TweakDBInterface.GetFloat(record + t".crChargeSpeedGain", p.chargeSpeedGain);
  }
  public static func Protection(record: TweakDBID) -> ref<CRProtectionProfile> {
    let p: ref<CRProtectionProfile> = CRStockProtectionCatalog.Resolve(record);
    p.mapped = TweakDBInterface.GetBool(record + t".crProtectionMapped", p.mapped);
    if !p.mapped {
      return p;
    }
    p.head = TweakDBInterface.GetBool(record + t".crProtectHead", p.head);
    p.torso = TweakDBInterface.GetBool(record + t".crProtectTorso", p.torso);
    p.leftArm = TweakDBInterface.GetBool(record + t".crProtectLeftArm", p.leftArm);
    p.rightArm = TweakDBInterface.GetBool(record + t".crProtectRightArm", p.rightArm);
    p.leftLeg = TweakDBInterface.GetBool(record + t".crProtectLeftLeg", p.leftLeg);
    p.rightLeg = TweakDBInterface.GetBool(record + t".crProtectRightLeg", p.rightLeg);
    p.resistanceJPerMm2 = TweakDBInterface.GetFloat(record + t".crResistanceJPerMm2", p.resistanceJPerMm2);
    p.durabilityJ = TweakDBInterface.GetFloat(record + t".crDurabilityJ", p.durabilityJ);
    p.bluntTransferFraction = TweakDBInterface.GetFloat(record + t".crBluntTransfer", p.bluntTransferFraction);
    return p;
  }

  private static func AddProtection(sample: ref<CRCombatProfileSample>, record: TweakDBID, region: Int32, item: ItemID) -> Void {
    let layer: ref<CRProtectionLayer>;
    let profile: ref<CRProtectionProfile>;
    let beforeJ: Float;
    if sample.equipmentVisited >= 32 {
      sample.unresolvedProtection += 1;
      return;
    }
    sample.equipmentVisited += 1;
    ArrayPush(sample.protectionRecords, record);
    // Keep "unmapped" distinct from malformed/read failure. For a player this
    // can later defer to the already-computed native physical channel instead
    // of vetoing every wound solely because unrelated gear lacks a profile.
    profile = CRCombatProfilesNative.Protection(record);
    if !IsDefined(profile) || !profile.mapped {
      sample.unmappedProtection += 1;
      return;
    }
    // Read persistent condition; preparation itself never commits wear.
    layer = CRCoverageModel.Layer(profile, region, 1.0);
    if !IsDefined(layer) {
      sample.unresolvedProtection += 1;
      return;
    }
    if layer.covered && layer.resistanceJPerMm2 > 0.0 {
      layer.integrity = CRArmorWearBridge.Integrity(sample.armorWear.target, item, region);
    }
    beforeJ = sample.referenceImpact.remainingJ;
    if !CRImpactModel.ApplyLayer(sample.referenceImpact, layer) || !CRArmorWearBridge.Capture(sample.armorWear, item, region, beforeJ - sample.referenceImpact.remainingJ, layer.durabilityJ) {
      sample.unresolvedProtection += 1;
      return;
    }
    sample.knownLayers += 1;
  }

  private static func AddArea(sample: ref<CRCombatProfileSample>, player: ref<PlayerPuppet>, area: gamedataEquipmentArea, region: Int32) -> Void {
    let data: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(player);
    let item: ItemID;
    let slots: Int32;
    let i: Int32 = 0;
    if !IsDefined(data) {
      sample.unresolvedProtection += 1;
      return;
    }
    slots = data.GetNumberOfSlots(area);
    if slots < 0 || slots > 32 {
      sample.unresolvedProtection += 1;
      return;
    }
    while i < slots && sample.equipmentVisited < 32 {
      item = data.GetItemInEquipSlot(area, i);
      if ItemID.IsValid(item) {
        ArrayPush(sample.equippedItemIDs, item);
        CRCombatProfilesNative.AddProtection(sample, ItemID.GetTDBID(item), region, item);
      }
      i += 1;
    }
    if i < slots {
      sample.unresolvedProtection += 1;
    }
  }

  public static func Read(hit: ref<gameHitEvent>, contact: ref<CRHitContact>) -> ref<CRCombatProfileSample> {
    let sample: ref<CRCombatProfileSample> = new CRCombatProfileSample();
    let weapon: ref<WeaponObject>;
    let record: ref<WeaponItem_Record>;
    let p: ref<CRBallisticProfile>;
    let player: ref<PlayerPuppet>;
    let npc: ref<NPCPuppet>;
    let data: ref<EquipmentSystemPlayerData>;
    let cyberAreas: array<gamedataEquipmentArea>;
    let i: Int32 = 0;
    let noItem: ItemID;
    if !IsDefined(hit) || !IsDefined(hit.attackData) || !IsDefined(hit.target) || !IsDefined(contact) {
      return sample;
    }
    sample.armorWear = new CRArmorWearPlan();
    sample.armorWear.target = hit.target;
    weapon = hit.attackData.GetWeapon();
    if !IsDefined(weapon) || !AttackData.IsRangedOnly(hit.attackData.GetAttackType()) || AttackData.IsDoT(hit.attackData) {
      return sample;
    }
    record = weapon.GetWeaponRecord();
    p = CRCombatProfilesNative.ProjectileProfile(record);
    sample.projectileFamily = p.family;
    if IsDefined(record) && IsDefined(record.Ammo()) {
      sample.ammoRecord = record.Ammo().GetID();
    }
    sample.distanceM = Vector4.Distance(hit.attackData.GetAttackPosition(), hit.hitPosition);
    sample.ricochets = hit.attackData.GetNumRicochetBounces();
    sample.projectile = CRBallisticProfiles.Projectile(p, sample.distanceM, sample.ricochets, hit.attackData.GetWeaponCharge());
    sample.referenceImpact = CRImpactModel.Begin(sample.projectile);
    if !sample.referenceImpact.valid || !contact.bodyFound || contact.region < 1 || contact.region > 6 || contact.unknownShape || contact.specialShape {
      return sample;
    }
    player = hit.target as PlayerPuppet;
    npc = hit.target as NPCPuppet;
    if IsDefined(player) {
      data = EquipmentSystem.GetData(player);
      if !IsDefined(data) {
        sample.unresolvedProtection += 1;
        return sample;
      }
      // Clothing before implanted protection. All known/unmapped records are
      // retained, including items which currently provide no armor stat.
      CRCombatProfilesNative.AddArea(sample, player, gamedataEquipmentArea.Outfit, contact.region);
      CRCombatProfilesNative.AddArea(sample, player, gamedataEquipmentArea.OuterChest, contact.region);
      CRCombatProfilesNative.AddArea(sample, player, gamedataEquipmentArea.InnerChest, contact.region);
      CRCombatProfilesNative.AddArea(sample, player, gamedataEquipmentArea.Head, contact.region);
      CRCombatProfilesNative.AddArea(sample, player, gamedataEquipmentArea.Face, contact.region);
      CRCombatProfilesNative.AddArea(sample, player, gamedataEquipmentArea.Legs, contact.region);
      CRCombatProfilesNative.AddArea(sample, player, gamedataEquipmentArea.Feet, contact.region);
      cyberAreas = data.GetAllCyberwareEquipmentAreas();
      if ArraySize(cyberAreas) > 32 {
        sample.unresolvedProtection += 1;
        return sample;
      }
      while i < ArraySize(cyberAreas) {
        CRCombatProfilesNative.AddArea(sample, player, cyberAreas[i], contact.region);
        i += 1;
      }
    } else {
      if IsDefined(npc) {
        // An NPC appearance can vary independently of its character record.
        // Mapping is an authored contract; visible shapes must still be checked
        // in game before treating these reference layers as authoritative.
        CRCombatProfilesNative.AddProtection(sample, npc.GetRecordID(), contact.region, noItem);
      } else {
        sample.unresolvedProtection += 1;
      }
    }
    sample.referenceReady = CRCombatProfileReadiness.Ready(sample.referenceImpact, sample.unresolvedProtection, sample.unmappedProtection, IsDefined(player));
    sample.nativePhysicalCap = sample.referenceReady && CRCombatProfileReadiness.RequiresNativePhysicalCap(sample.unmappedProtection, IsDefined(player));
    return sample;
  }
}
