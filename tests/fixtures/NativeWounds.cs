// Native boundaries for original bridge tests. These types deliberately model
// only the APIs consumed by CombatWoundsNative; they are not an engine emulator.
public enum gamedataDamageType { Physical, Thermal }
public enum gamedataStatType { Health }
public enum gamedataNPCType { Human, Drone }
public class ScriptingGame {
    public StatsSystem stats = new StatsSystem();
}
public class GameInstance {
    public static StatsSystem GetStatsSystem(ScriptingGame game) { return game.stats; }
}
public class StatsSystem {
    public float maximumHealth = 100;
    public float GetStatValue(string id, gamedataStatType stat) { return maximumHealth; }
}
public class GameObject {
    public string id = "fixture-target";
    public ScriptingGame game = new ScriptingGame();
    public string GetEntityID() { return id; }
    public ScriptingGame GetGame() { return game; }
}
public class NPCPuppet : GameObject {
    public bool replacer;
    public gamedataNPCType npcType = gamedataNPCType.Human;
    public CRInjuryState crLocalizedInjuries;
    public CRBodyState crInjuryBody;
    public int crInjurySchemaVersion;
    public bool IsReplacer() { return replacer; }
    public gamedataNPCType GetNPCType() { return npcType; }
}
public class AttackComputed {
    public float physical = 20;
    public float thermal = 7;
    public float GetAttackValue(gamedataDamageType type) { return type == gamedataDamageType.Physical ? physical : thermal; }
    public void SetAttackValue(float amount, gamedataDamageType type) {
        if (type != gamedataDamageType.Physical) throw new System.Exception("Modified nonphysical channel");
        physical = amount;
    }
}
public class gameHitEvent {
    public GameObject target;
    public object attackData = new object();
    public bool projectionPipeline;
    public bool crWoundPrepared;
    public CRNativeWoundPlan crWoundPlan;
    public CRNativeHitSample crPreparedHit;
    public AttackComputed attackComputed = new AttackComputed();
    public CRNativeHitSample sample;
}
public class SDamageDealt {}
public class CRCombatProfileSample {
    public bool referenceReady = true;
    public CRImpactState referenceImpact;
    public CRArmorWearPlan armorWear;
}
public class CRNativeHitSample {
    public CRHitContact contact;
    public CRHitEligibility eligibility;
    public CRCombatProfileSample profiles;
    public bool targetIsPlayer;
    public string targetID;
    public bool canRoute;
    public float nativePhysicalHealthDamage;
    public bool physicalHealthEvaluated;
}
public static class CRNativeHitAdapter {
    public static CRNativeHitSample Read(gameHitEvent hit, SDamageDealt[] ignored) { return hit.sample; }
}
public static class CRCombatRuntimePolicy {
    public static bool enabled = true;
    public static bool Enabled() { return enabled; }
}
public class CRBodyRuntime {
    public static CRBodyRuntime instance = new CRBodyRuntime();
    public bool allowed = true;
    public CRBodyConfig config = new CRBodyConfig();
    public CRBodyState body;
    public CRBodyInputQueue queue = new CRBodyInputQueue();
    public CRBodyRuntime() { body = CRBodyModel.Create(config); }
    public static CRBodyRuntime Get() { return instance; }
    public void RefreshInjuryEffects() {}
    public void Observe() {}
    public CRBodyConfig GetBodyConfig() { return config; }
    public bool CanAcceptCombatInjury() { return allowed; }
    public bool RecordInjury(int region,float tissue,float bone,float chrome,float external,float internalBleed) {
        if (!allowed) return false;
        bool accepted = CRBodyInputs.Injury(queue,region,tissue,bone,chrome,external,internalBleed);
        CRBodyInputs.Drain(queue,body,config);
        return accepted;
    }
}
public static class NativeWoundFixture {
    public static bool NotEquals<T>(T a, T b) { return !object.Equals(a,b); }
    public static gameHitEvent Hit(bool player, int region = 2, int material = 1, float mass = 8, float speed = 360) {
        var hit = new gameHitEvent { target = player ? new GameObject() : new NPCPuppet() };
        hit.sample = new CRNativeHitSample {
            targetID = hit.target.id, targetIsPlayer = player,
            contact = new CRHitContact { region=region, material=material, bodyFound=true, shapeCount=1 },
            eligibility = new CRHitEligibility { ranged=true, targetSupported=true },
            profiles = new CRCombatProfileSample { referenceImpact=CRImpactModel.Begin(new CRProjectileSpec { massGrams=mass,speedMetersPerSecond=speed,diameterMm=9 }) }
        };
        return hit;
    }
    // Simulates only the boundary values produced by downstream native caps.
    public static bool Finish(gameHitEvent hit, float finalPhysical, float actualLoss) {
        hit.attackComputed.physical=finalPhysical;
        hit.sample.eligibility.actualHealthDamage=actualLoss;
        hit.sample.nativePhysicalHealthDamage=actualLoss;
        hit.sample.physicalHealthEvaluated=true;
        hit.sample.canRoute=CRHitModel.CanRoute(hit.sample.contact, hit.sample.eligibility);
        return CRNativeWoundBridge.Commit(hit,hit.sample);
    }
}

// Wear acceptance boundary only; actual registry/capture methods are exercised
// separately by Test-ArmorWear.ps1 with item and NPC fixtures.
public class CRArmorWearPlan { public int commits; }
public static class CRArmorWearBridge {
 public static bool Commit(CRArmorWearPlan plan) { if(plan==null || plan.commits>0) return false; plan.commits++; return true; }
}
// Impairment lifecycle is exercised separately in Test-InjuryEffects.ps1.
public class CRInjuryEffectsRuntime {
    public static CRInjuryEffectsRuntime Get() { return new CRInjuryEffectsRuntime(); }
    public bool Register(NPCPuppet npc) { return npc != null; }
}