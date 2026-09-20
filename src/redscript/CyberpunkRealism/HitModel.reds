// Cyberpunk Realism original source. Shared contact eligibility and region
// selection. Unknown/special/protection-only contacts never become torso hits.
module CyberpunkRealism.Combat

public class CRHitContact extends IScriptable {
  // 0 unknown; 1 head; 2 torso; 3/4 left/right arm; 5/6 left/right leg.
  public let region: Int32;
  // 0 unknown; 1 flesh; 2 armor; 3 cyberware; 4 metal.
  public let material: Int32;
  public let bodyFound: Bool;
  public let hasProtectionLayer: Bool;
  public let unknownShape: Bool;
  public let specialShape: Bool;
  public let shapeCount: Int32;
}

public class CRHitEligibility extends IScriptable {
  public let projection: Bool;
  public let protectedHit: Bool;
  public let ranged: Bool;
  public let damageOverTime: Bool;
  public let targetSupported: Bool;
  public let actualHealthDamage: Float;
}

public class CRCombatProfileReadiness extends IScriptable {
  // Structural/profile-read failures remain fatal. An otherwise-valid player
  // profile may retain unmapped equipped protection only when downstream damage
  // is conservatively capped by the already-computed native physical channel.
  // NPC appearance protection remains mapped-or-rejected.
  public static func Ready(impact: ref<CRImpactState>, unresolvedProtection: Int32, unmappedProtection: Int32, playerTarget: Bool) -> Bool {
    if !CRImpactModel.ValidState(impact) || unresolvedProtection < 0 || unresolvedProtection > 64 || unmappedProtection < 0 || unmappedProtection > 32 {
      return false;
    }
    if unresolvedProtection > 0 {
      return false;
    }
    return playerTarget || unmappedProtection == 0;
  }

  public static func RequiresNativePhysicalCap(unmappedProtection: Int32, playerTarget: Bool) -> Bool {
    return playerTarget && unmappedProtection > 0 && unmappedProtection <= 32;
  }
}

public class CRHitModel extends IScriptable {
  public static func AddShape(contact: ref<CRHitContact>, region: Int32, material: Int32, protection: Bool, special: Bool) -> Bool {
    if !IsDefined(contact) || region < 0 || region > 6 || material < 0 || material > 4 {
      return false;
    }
    if contact.shapeCount < 0 || contact.shapeCount >= 32 {
      return false;
    }
    contact.shapeCount += 1;
    contact.hasProtectionLayer = contact.hasProtectionLayer || protection;
    contact.specialShape = contact.specialShape || special;
    if region == 0 || material == 0 {
      contact.unknownShape = true;
    }
    // Preserve the first non-protection contact even when its metadata is
    // unknown. Searching farther for a convenient known region invents a hit.
    if !protection && !contact.bodyFound {
      contact.bodyFound = true;
      contact.region = region;
      contact.material = material;
    }
    return true;
  }

  public static func CanProcess(contact: ref<CRHitContact>, gate: ref<CRHitEligibility>) -> Bool {
    if !IsDefined(contact) || !IsDefined(gate) {
      return false;
    }
    if gate.projection || gate.protectedHit || !gate.ranged || gate.damageOverTime || !gate.targetSupported {
      return false;
    }
    return contact.bodyFound && contact.region >= 1 && contact.region <= 6 && contact.material >= 1 && contact.material <= 4 && !contact.specialShape && !contact.unknownShape && contact.shapeCount > 0 && contact.shapeCount <= 32;
  }

  public static func CanRoute(contact: ref<CRHitContact>, gate: ref<CRHitEligibility>) -> Bool {
    return CRHitModel.CanProcess(contact, gate) && gate.actualHealthDamage > 0.0 && gate.actualHealthDamage <= 1000000000.0;
  }
}
