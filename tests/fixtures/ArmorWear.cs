public struct ItemID { public string key; public static bool IsValid(ItemID i) { return !string.IsNullOrEmpty(i.key); } }
public class GameObject { public bool player; public bool IsPlayer() { return player; } }
public class NPCPuppet : GameObject { public int crArmorSchema; public CRArmorCondition crArmorCondition; }
public class CRArmorEntries : System.Collections.Generic.List<CRArmorWearEntry> {}
public static class CRArmorFixture {
 public static CRArmorRegistry registry = new CRArmorRegistry();
 public static int Size(CRArmorEntries e) { return e.Count; }
 public static void Push(CRArmorEntries e, CRArmorWearEntry value) { e.Add(value); }
 public static bool NotEquals(object a,object b) { return !object.Equals(a,b); }
 public static ItemID Item(string key) { return new ItemID { key=key }; }
 public static CRArmorWearPlan Plan(bool player=true) { return new CRArmorWearPlan { target=player ? new GameObject { player=true } : new NPCPuppet() }; }
}