// Project-original bounded injury provenance for player-facing Condition details.
// This metadata explains how an already-authoritative regional injury arose; it
// never applies damage, bleeding, impairment or treatment by itself.
module CyberpunkRealism.Integration

import CyberpunkRealism.Combat.*
import CyberpunkRealism.Physiology.*

public class CRInjuryProvenance extends IScriptable {
  public persistent let worldSeconds: Int32;
  // 1 head; 2 torso; 3/4 left/right arm; 5/6 left/right leg.
  public persistent let region: Int32;
  // 1 flesh; 2 armor; 3 cyberware; 4 metal.
  public persistent let material: Int32;
  public persistent let weaponRecord: TweakDBID;
  public persistent let ammoRecord: TweakDBID;
  public persistent let projectileFamily: Int32;
  public persistent let distanceM: Float;
  public persistent let ricochets: Int32;
  public persistent let protectionEncountered: Bool;
  public persistent let knownProtectionLayers: Int32;
  public persistent let unresolvedProtectionLayers: Int32;
  public persistent let initialImpactJ: Float;
  public persistent let residualImpactJ: Float;
  public persistent let bluntTransferJ: Float;
  public persistent let tissueDamage: Float;
  public persistent let boneDamage: Float;
  public persistent let cyberwareDamage: Float;
  public persistent let externalBleedMlPerHour: Float;
  public persistent let internalBleedMlPerHour: Float;
}

public class CRInjuryProvenanceRuntime extends ScriptableSystem {
  // A bounded explanation ledger, not an accumulating gameplay-status system.
  // Sixteen recent accepted wounds is enough to explain current/recent condition
  // without growing save state forever.
  private persistent let recent: array<ref<CRInjuryProvenance>>;
  private persistent let schemaVersion: Int32 = 1;

  public static func Get() -> ref<CRInjuryProvenanceRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRInjuryProvenanceRuntime>()) as CRInjuryProvenanceRuntime;
  }

  private static func ValidRegion(region: Int32) -> Bool {
    return region >= 1 && region <= 6;
  }

  private static func ValidMaterial(material: Int32) -> Bool {
    return material >= 1 && material <= 4;
  }

  public static func Valid(entry: ref<CRInjuryProvenance>) -> Bool {
    if !IsDefined(entry) || !CRInjuryProvenanceRuntime.ValidRegion(entry.region) || !CRInjuryProvenanceRuntime.ValidMaterial(entry.material) {
      return false;
    }
    if entry.worldSeconds < 0 || entry.projectileFamily < 0 || entry.projectileFamily > 32 || entry.distanceM < 0.0 || entry.distanceM > 100000.0 || entry.ricochets < 0 || entry.ricochets > 64 {
      return false;
    }
    if entry.knownProtectionLayers < 0 || entry.knownProtectionLayers > 32 || entry.unresolvedProtectionLayers < 0 || entry.unresolvedProtectionLayers > 32 {
      return false;
    }
    if entry.initialImpactJ < 0.0 || entry.residualImpactJ < 0.0 || entry.residualImpactJ > entry.initialImpactJ || entry.bluntTransferJ < 0.0 || entry.bluntTransferJ > entry.initialImpactJ {
      return false;
    }
    if entry.tissueDamage < 0.0 || entry.tissueDamage > 1.0 || entry.boneDamage < 0.0 || entry.boneDamage > 1.0 || entry.cyberwareDamage < 0.0 || entry.cyberwareDamage > 1.0 {
      return false;
    }
    return entry.externalBleedMlPerHour >= 0.0 && entry.internalBleedMlPerHour >= 0.0;
  }

  private func Prune() -> Void {
    let i: Int32 = ArraySize(this.recent) - 1;
    while i >= 0 {
      if !CRInjuryProvenanceRuntime.Valid(this.recent[i]) {
        ArrayErase(this.recent, i);
      }
      i -= 1;
    }
    while ArraySize(this.recent) > 16 {
      ArrayErase(this.recent, 0);
    }
  }

  private func OnAttach() -> Void {
    if CRBodyRuntimeMasterPolicy.Enabled(this.GetGameInstance()) && this.schemaVersion == 1 {
      this.Prune();
    }
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    if !CRBodyRuntimeMasterPolicy.Enabled(this.GetGameInstance()) || this.schemaVersion != 1 {
      return;
    }
    this.Prune();
  }

  public func Record(sample: ref<CRNativeHitSample>, wound: ref<CRImpactWound>) -> Bool {
    let profile: ref<CRCombatProfileSample>;
    let impact: ref<CRImpactState>;
    let entry: ref<CRInjuryProvenance>;
    if !CRBodyRuntimeMasterPolicy.Enabled(this.GetGameInstance()) || this.schemaVersion != 1 {
      return false;
    }
    if !IsDefined(sample) || !sample.targetIsPlayer || !IsDefined(sample.contact) || !CRWoundModel.HasInjury(wound) || !IsDefined(sample.profiles) {
      return false;
    }
    profile = sample.profiles;
    impact = profile.referenceImpact;
    if !profile.referenceReady || !IsDefined(impact) || !CRImpactModel.ValidState(impact) {
      return false;
    }

    entry = new CRInjuryProvenance();
    entry.worldSeconds = GameTime.GetSeconds(GameInstance.GetTimeSystem(GetGameInstance()).GetGameTime());
    entry.region = sample.contact.region;
    entry.material = sample.contact.material;
    entry.weaponRecord = sample.weaponRecord;
    entry.ammoRecord = profile.ammoRecord;
    entry.projectileFamily = profile.projectileFamily;
    entry.distanceM = profile.distanceM;
    entry.ricochets = profile.ricochets;
    entry.protectionEncountered = sample.contact.hasProtectionLayer || profile.knownLayers > 0;
    entry.knownProtectionLayers = profile.knownLayers;
    entry.unresolvedProtectionLayers = profile.unresolvedProtection;
    entry.initialImpactJ = impact.initialJ;
    entry.residualImpactJ = impact.remainingJ;
    entry.bluntTransferJ = impact.bluntJ;
    entry.tissueDamage = wound.tissueDamage;
    entry.boneDamage = wound.boneDamage;
    entry.cyberwareDamage = wound.cyberwareDamage;
    entry.externalBleedMlPerHour = wound.externalBleedMlPerHour;
    entry.internalBleedMlPerHour = wound.internalBleedMlPerHour;

    if !CRInjuryProvenanceRuntime.Valid(entry) {
      return false;
    }
    ArrayPush(this.recent, entry);
    this.Prune();
    return true;
  }

  public func Count() -> Int32 {
    this.Prune();
    return ArraySize(this.recent);
  }

  // Returns the newest accepted provenance entry for the requested region.
  public func LatestForRegion(region: Int32) -> ref<CRInjuryProvenance> {
    let i: Int32;
    this.Prune();
    if !CRInjuryProvenanceRuntime.ValidRegion(region) {
      return null;
    }
    i = ArraySize(this.recent) - 1;
    while i >= 0 {
      if this.recent[i].region == region {
        return this.recent[i];
      }
      i -= 1;
    }
    return null;
  }

  public func ClearDevelopmentHistory() -> Void {
    ArrayClear(this.recent);
  }
}
