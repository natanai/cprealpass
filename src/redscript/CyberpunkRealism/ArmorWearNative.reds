// Original item-instance and per-NPC condition persistence. No timer or logger.
import CyberpunkRealism.Combat.*

public class CRArmorItemState extends IScriptable {
  public persistent let item: ItemID;
  public persistent let condition: ref<CRArmorCondition>;
  public persistent let next: ref<CRArmorItemState>;
}
public class CRArmorRegistry extends ScriptableSystem {
  private persistent let schema: Int32 = 0;
  private persistent let first: ref<CRArmorItemState>;
  private persistent let count: Int32 = 0;
  public static func Get() -> ref<CRArmorRegistry> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRArmorRegistry>()) as CRArmorRegistry;
  }
  public func Valid() -> Bool {
    let node: ref<CRArmorItemState> = this.first;
    let visited: Int32 = 0;
    if this.schema == 0 {
      return !IsDefined(node) && this.count == 0;
    }
    if this.schema != 1 || this.count < 0 || this.count > 512 {
      return false;
    }
    while IsDefined(node) && visited < 512 {
      if !ItemID.IsValid(node.item) || !CRArmorWearModel.Valid(node.condition) {
        return false;
      }
      visited += 1;
      node = node.next;
    }
    return !IsDefined(node) && visited == this.count;
  }
  public func CanReserve(amount: Int32) -> Bool {
    return this.Valid() && amount >= 0 && amount <= 32 && this.count + amount <= 512;
  }
  public func Find(item: ItemID) -> ref<CRArmorItemState> {
    let node: ref<CRArmorItemState> = this.first;
    let visited: Int32 = 0;
    while IsDefined(node) && visited < 512 {
      if Equals(node.item, item) {
        return node;
      }
      visited += 1;
      node = node.next;
    }
    return null;
  }
  public func Integrity(item: ItemID, region: Int32) -> Float {
    let node: ref<CRArmorItemState>;
    let other: ref<CRArmorItemState>;
    let visited: Int32 = 0;
    if !ItemID.IsValid(item) || region < 1 || region > 6 || !this.Valid() {
      return -1.0;
    }
    node = this.Find(item);
    if IsDefined(node) {
      other = this.first;
      while IsDefined(other) && visited < 512 {
        if NotEquals(other, node) && (Equals(other.item, item) || Equals(other.condition, node.condition)) {
          return -1.0;
        }
        visited += 1;
        other = other.next;
      }
      return CRArmorWearModel.Integrity(node.condition, region);
    }
    if this.count >= 512 {
      return -1.0;
    }
    return 1.0;
  }
  public func Apply(item: ItemID, region: Int32, dose: Float) -> Bool {
    let node: ref<CRArmorItemState>;
    if this.Integrity(item, region) < 0.0 || !CRImpactModel.InRange(dose, 0.0, 1.0) {
      return false;
    }
    if dose == 0.0 {
      return true;
    }
    node = this.Find(item);
    if !IsDefined(node) {
      node = new CRArmorItemState();
      node.item = item;
      node.condition = new CRArmorCondition();
      node.next = this.first;
      this.first = node;
      this.count += 1;
      this.schema = 1;
    }
    return CRArmorWearModel.Apply(node.condition, region, dose);
  }
}

@addField(NPCPuppet)
public persistent let crArmorCondition: ref<CRArmorCondition>;
@addField(NPCPuppet)
public persistent let crArmorSchema: Int32;

public class CRArmorWearEntry extends IScriptable {
  public let item: ItemID;
  public let region: Int32;
  public let dose: Float;
}
public class CRArmorWearPlan extends IScriptable {
  public let target: wref<GameObject>;
  public let entries: array<ref<CRArmorWearEntry>>;
  public let consumed: Bool = false;
}
public class CRArmorWearBridge extends IScriptable {
  public static func Integrity(target: ref<GameObject>, item: ItemID, region: Int32) -> Float {
    let npc: ref<NPCPuppet>;
    if !IsDefined(target) || region < 1 || region > 6 {
      return -1.0;
    }
    if target.IsPlayer() {
      return CRArmorRegistry.Get().Integrity(item, region);
    }
    npc = target as NPCPuppet;
    if !IsDefined(npc) {
      return -1.0;
    }
    if npc.crArmorSchema == 0 && !IsDefined(npc.crArmorCondition) {
      return 1.0;
    }
    if npc.crArmorSchema != 1 {
      return -1.0;
    }
    return CRArmorWearModel.Integrity(npc.crArmorCondition, region);
  }
  public static func Capture(plan: ref<CRArmorWearPlan>, item: ItemID, region: Int32, absorbed: Float, durability: Float) -> Bool {
    let dose: Float = CRArmorWearModel.Dose(absorbed, durability);
    let entry: ref<CRArmorWearEntry>;
    let i: Int32 = 0;
    if !IsDefined(plan) || plan.consumed || !IsDefined(plan.target) || ArraySize(plan.entries) >= 32 || region < 1 || region > 6 || dose < 0.0 {
      return false;
    }
    if dose == 0.0 {
      return true;
    }
    while i < ArraySize(plan.entries) {
      if Equals(plan.entries[i].item, item) {
        return false;
      }
      i += 1;
    }
    entry = new CRArmorWearEntry();
    entry.item = item;
    entry.region = region;
    entry.dose = dose;
    ArrayPush(plan.entries, entry);
    return true;
  }
  public static func Commit(plan: ref<CRArmorWearPlan>) -> Bool {
    let i: Int32 = 0;
    let npc: ref<NPCPuppet>;
    let j: Int32;
    let newItems: Int32 = 0;
    if !IsDefined(plan) || plan.consumed || !IsDefined(plan.target) || ArraySize(plan.entries) > 32 {
      return false;
    }
    plan.consumed = true;
    // Validate every entry before any condition mutation.
    while i < ArraySize(plan.entries) {
      if !IsDefined(plan.entries[i]) || CRArmorWearBridge.Integrity(plan.target, plan.entries[i].item, plan.entries[i].region) < 0.0 || !CRImpactModel.InRange(plan.entries[i].dose, 0.0, 1.0) {
        return false;
      }
      j = 0;
      while j < i {
        if Equals(plan.entries[j].item, plan.entries[i].item) {
          return false;
        }
        j += 1;
      }
      if plan.target.IsPlayer() && plan.entries[i].dose > 0.0 && !IsDefined(CRArmorRegistry.Get().Find(plan.entries[i].item)) {
        newItems += 1;
      }
      i += 1;
    }
    if plan.target.IsPlayer() && !CRArmorRegistry.Get().CanReserve(newItems) {
      return false;
    }
    i = 0;
    while i < ArraySize(plan.entries) {
      if plan.target.IsPlayer() {
        if !CRArmorRegistry.Get().Apply(plan.entries[i].item, plan.entries[i].region, plan.entries[i].dose) {
          return false;
        }
      } else {
        npc = plan.target as NPCPuppet;
        if !IsDefined(npc.crArmorCondition) {
          npc.crArmorCondition = new CRArmorCondition();
          npc.crArmorSchema = 1;
        }
        if !CRArmorWearModel.Apply(npc.crArmorCondition, plan.entries[i].region, plan.entries[i].dose) {
          return false;
        }
      }
      i += 1;
    }
    return ArraySize(plan.entries) > 0;
  }
}