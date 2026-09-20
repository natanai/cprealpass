// Typed substitutes for native services. Production adapter methods are translated
// directly; this fixture does not emulate engine save serialization or callbacks.
public enum gamedataStatType { MaxSpeed, Stamina, StaminaRegenRate, ReloadTime, RecoilAngle, SpreadDefaultX, SpreadDefaultY, RecoilKickMin, RecoilKickMax, SpreadAdsDefaultX, SpreadAdsDefaultY }
public enum gameStatModifierType { Multiplier }
public class gameStatModifierData { public gamedataStatType stat; public float value; }
public class CRModifierSlots : System.Collections.Generic.List<CRInjuryModifierSlot> {}
public class CRNpcList : System.Collections.Generic.List<NPCPuppet> {}
public class StatsSystem {
    public bool failAdd, failRemove;
    public int addAttempts, removeAttempts;
    public System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<gameStatModifierData>> active = new System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<gameStatModifierData>>();
    public bool AddModifier(string id, gameStatModifierData mod) {
        addAttempts++;
        if (failAdd) return false;
        if (!active.ContainsKey(id)) active[id] = new System.Collections.Generic.List<gameStatModifierData>();
        if (active[id].Contains(mod)) throw new System.Exception("Same handle stacked");
        active[id].Add(mod); return true;
    }
    public bool RemoveAndUncacheModifier(string id, gameStatModifierData mod) {
        removeAttempts++;
        if (failRemove) return false;
        return active.ContainsKey(id) && active[id].Remove(mod);
    }
    public int Count(string id) { return active.ContainsKey(id) ? active[id].Count : 0; }
    public float Value(string id, gamedataStatType stat) {
        float value = 1;
        if (active.ContainsKey(id)) foreach(var mod in active[id]) if(mod.stat == stat) value *= mod.value;
        return value;
    }
}
public class ScriptingGame {
    public StatsSystem stats = new StatsSystem();
    public SceneSystem scene = new SceneSystem();
    public PlayerSystem playerSystem = new PlayerSystem();
}
public class GameObject {
    private static int next;
    public string id = "actor-" + (++next);
    public ScriptingGame game = CREffectsFixture.game;
    public string GetEntityID() { return id; }
    public ScriptingGame GetGame() { return game; }
    public static WeaponObject GetActiveWeapon(ScriptedPuppet actor) { return actor.weapon; }
}
public class WeaponObject : GameObject {}
public class ScriptedPuppet : GameObject {
    public bool dead, defeated, replacer, attached = true;
    public WeaponObject weapon;
    public CRInjuryModifierSet crInjuryModifiers;
    public bool IsDead() { return dead; }
    public bool IsAttached() { return attached; }
    public bool IsReplacer() { return replacer; }
    public bool IsPlayer() { return this is PlayerPuppet; }
    public static bool IsDefeated(ScriptedPuppet actor) { return actor.defeated; }
}
// Player lifecycle itself is translated and exercised by
// Test-PlayerLifecycleAndPreferences; this fixture isolates modifier ownership.
public class PlayerPuppet : ScriptedPuppet { public bool lifecycleAllowed = true; }
public static class CRPlayerBodyLifecycle {
    public static bool Allowed(PlayerPuppet player, bool allowMenu) { return player != null && player.lifecycleAllowed; }
}
public enum gamedataNPCType { Human, Android }
public class NPCPuppet : ScriptedPuppet {
    public CRBodyState crInjuryBody;
    public bool crProgressAllowed, mounted;
    public float velocity;
    public gamedataNPCType npcType = gamedataNPCType.Human;
    public gamedataNPCType GetNPCType() { return npcType; }
    public float GetVelocity() { return velocity; }
    public CRInjuryState crLocalizedInjuries;
    public int crInjurySchemaVersion;
}
public class PlayerSystem {
    public ScriptedPuppet player;
    public GameObject GetLocalPlayerMainGameObject() { return player; }
}
public class SceneSystemInterface {
    public System.Collections.Generic.HashSet<string> actors = new System.Collections.Generic.HashSet<string>();
    public bool IsEntityInScene(string id) { return actors.Contains(id); }
}
public class SceneSystem {
    public SceneSystemInterface script = new SceneSystemInterface();
    public SceneSystemInterface GetScriptInterface() { return script; }
}
public static class GameInstance {
    public static StatsSystem GetStatsSystem(ScriptingGame game) { return game.stats; }
    public static SceneSystem GetSceneSystem(ScriptingGame game) { return game.scene; }
    public static PlayerSystem GetPlayerSystem(ScriptingGame game) { return game.playerSystem; }
}
public static class RPGManager {
    public static gameStatModifierData CreateStatModifier(gamedataStatType stat, gameStatModifierType type, float factor) { return new gameStatModifierData {stat=stat,value=factor}; }
}
public static class CRCombatRuntimePolicy { public static bool enabled = true; public static bool Enabled() { return enabled; } }
public static class CREffectsFixture {
    public static bool NotEquals<T>(T a,T b) { return !object.Equals(a,b); }
    public static ScriptingGame game;
    public static CRInjuryEffectsRuntime runtime;
    public static CRBodyConfig config = new CRBodyConfig();
    public static int Size<T>(System.Collections.Generic.List<T> list) { return list.Count; }
    public static void Push<T>(System.Collections.Generic.List<T> list,T value) { list.Add(value); }
    public static void Erase<T>(System.Collections.Generic.List<T> list,int index) { list.RemoveAt(index); }
    public static void Reset() {
        config = new CRBodyConfig(); CRBodyRuntime.pendingHours=0; CRBodyRuntime.observeCalls=0; game = new ScriptingGame(); runtime = new CRInjuryEffectsRuntime(); CRCombatRuntimePolicy.enabled = true;
        game.playerSystem.player = new ScriptedPuppet {weapon = new WeaponObject()};
    }
    public static CRInjuryState Injured() {
        var state = CRInjuryModel.Create();
        for(int i=1;i<=6;i++) CRInjuryModel.Region(state,i).tissueDamage = 0.5f;
        return state;
    }
        public static CRBodyState Reconstruct(CRBodyState body) {
        var options = new System.Text.Json.JsonSerializerOptions { IncludeFields = true };
        return System.Text.Json.JsonSerializer.Deserialize<CRBodyState>(System.Text.Json.JsonSerializer.Serialize(body, options), options);
    }
    public static NPCPuppet NPC() { return new NPCPuppet {crLocalizedInjuries=Injured(),crInjurySchemaVersion=1,weapon=new WeaponObject()}; }
}
public static class Vector4 { public static float Length(float speed) { return System.Math.Abs(speed); } }
public static class VehicleComponent { public static bool IsMountedToVehicle(ScriptingGame game, NPCPuppet npc) { return npc.mounted; } }
public class CRBodyRuntime {
    public static float pendingHours;
    public static int observeCalls;
    public static CRBodyRuntime Get() { return new CRBodyRuntime(); }
    public CRBodyConfig GetBodyConfig() { return CREffectsFixture.config; }
    public void Observe() {
        observeCalls++;
        float hours = pendingHours; pendingHours = 0;
        if(hours > 0) CREffectsFixture.runtime.Advance(hours, CREffectsFixture.config, false);
    }
    public void RefreshInjuryEffects() {}
}
// Blood-loss delivery is verified separately with its own native boundary fixture.
public static class CRBloodLossNative { public static void Clear(ScriptedPuppet actor) {} public static void Refresh(ScriptedPuppet actor,CRInjuryState injury,bool enabled) {} }
