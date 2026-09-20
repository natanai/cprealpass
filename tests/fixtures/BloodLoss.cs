// Native boundaries only: these controlled substitutes do not emulate REDengine.
public enum gamedataStatType { Health, MaxPercentDamageTakenPerHit }
public enum gamedataDamageType { Physical, Thermal }
public enum gamedataStatPoolType { Health, Armor }
public enum gamedataNPCType { Human, Drone }
public enum gamedataNPCRarity { Normal, MaxTac }
public enum gamedataAttackType { Effect }
public enum hitFlag { CanDamageSelf,FriendlyFire,DamageOverTime,DisableNPCHitReaction,IgnoreImmortalityModes,IgnoreStatPoolCustomLimit,Kill,Nonlethal,DealNoDamage,DamageNullified,ImmortalTarget,CannotModifyDamage,DeterministicDamage }
public class ScriptedPuppet {
 public bool player=true, attached=true, dead, scene, replacer, fastFinisher;
 public float maximumHealth=100, maxPercentDamage;
 public CRBloodLossCursor crBloodLossCursor;
 public bool IsPlayer(){return player;}
 public bool GetIsInFastFinisher(){return fastFinisher;}
 public string GetEntityID(){return "actor";}
 public ScriptedPuppet GetGame(){return this;}
 public float GetWorldPosition(){return 0;}
}
public class NPCPuppet : ScriptedPuppet {
 public bool boss;
 public gamedataNPCType type=gamedataNPCType.Human;
 public gamedataNPCRarity rarity;
 public NPCPuppet(){player=false;}
 public bool IsBoss(){return boss;}
 public gamedataNPCType GetNPCType(){return type;}
 public gamedataNPCRarity GetNPCRarity(){return rarity;}
}
public class Attack_Record {}
public class AttackInitContext { public Attack_Record record; public ScriptedPuppet instigator,source; }
public class IAttack {
 public AttackInitContext context;
 public static IAttack Create(AttackInitContext context){return CRBloodFixture.failAttack?null:new IAttack{context=context};}
}
public class AttackData {
 public ScriptedPuppet instigator,source;
 public IAttack attack; public object weapon; public object GetWeapon(){return weapon;}
 public gamedataAttackType type;
 public System.Collections.Generic.HashSet<hitFlag> flags=new System.Collections.Generic.HashSet<hitFlag>();
 public void SetAttackDefinition(IAttack x){attack=x;}
 public void SetInstigator(ScriptedPuppet x){instigator=x;}
 public void SetSource(ScriptedPuppet x){source=x;}
 public ScriptedPuppet GetInstigator(){return instigator;}
 public ScriptedPuppet GetSource(){return source;}
 public void SetAttackType(gamedataAttackType x){type=x;}
 public void SetAttackTime(float x){}
 public void SetAttackPosition(float x){}
 public void AddFlag(hitFlag f,string reason){flags.Add(f);}
 public bool HasFlag(hitFlag f){return flags.Contains(f);}
 public void PreAttack(){}
}
public class AttackComputed {
 public float[] values=new float[]{2,7};
 public float[] GetAttackValues(){return (float[])values.Clone();}
 public void SetAttackValues(float[] x){values=x;}
 public float GetAttackValue(gamedataDamageType type){return values[(int)type];}
 public void SetAttackValue(float x,gamedataDamageType type){values[(int)type]=x;}
 public void MultAttackValue(float f){for(int i=0;i<values.Length;i++)values[i]*=f;}
}
public class gameHitEvent {
 public ScriptedPuppet target;
 public CRBloodLossDelivery crBloodLossDelivery;
 public AttackData attackData;
 public AttackComputed attackComputed=new AttackComputed();
 public bool projectionPipeline;
 public float hitPosition;
}
public class SDamageDealt { public gamedataStatPoolType affectedStatPool; public float value; }
public class StatsSystem {
 ScriptedPuppet actor;
 public StatsSystem(ScriptedPuppet actor){this.actor=actor;}
 public float GetStatValue(string id,gamedataStatType type){return type==gamedataStatType.Health?actor.maximumHealth:actor.maxPercentDamage;}
}
public class DamageSystem {
 public void QueueHitEvent(gameHitEvent hit,ScriptedPuppet actor){CRBloodFixture.hits.Add(hit);}
}
public static class GameInstance {
 public static StatsSystem GetStatsSystem(ScriptedPuppet actor){return new StatsSystem(actor);}
 public static DamageSystem GetDamageSystem(ScriptedPuppet actor){return new DamageSystem();}
}
public static class TweakDBInterface {
 public static float dotProportion=1; public static float GetFloat(string id,float fallback){return dotProportion;}
 public static Attack_Record GetAttackRecord(string id){if(id!="Attacks.BaseDOTTick")throw new System.Exception("Unexpected definition");return CRBloodFixture.failRecord?null:new Attack_Record();}
}
public static class CRInjuryEffectsBridge {
 public static bool Allowed(ScriptedPuppet actor,bool enabled){return enabled&&actor!=null&&actor.attached&&!actor.dead&&!actor.scene&&!actor.replacer;}
}
public static class CRCombatRuntimePolicy {public static bool enabled=true;public static bool Enabled(){return enabled;}}
public class CRBodyRuntime {public static CRBodyRuntime Get(){return new CRBodyRuntime();} public bool CanAcceptCombatInjury(){return CRBloodFixture.allowed;}}
public static class CRBloodFixture {
 public static float sim;
 public static bool allowed=true,failRecord,failAttack;
 public static System.Collections.Generic.List<gameHitEvent> hits=new System.Collections.Generic.List<gameHitEvent>();
 public static bool NotEquals<T>(T a,T b){return !object.Equals(a,b);}
 public static int Size<T>(T[] a){return a.Length;}
 public static void Reset(){sim=0;allowed=true;failRecord=false;failAttack=false;hits.Clear();CRCombatRuntimePolicy.enabled=true;}
 public static gameHitEvent Last(){return hits.Count==0?null:hits[hits.Count-1];}
 public static SDamageDealt[] Losses(float health,float armor){return new[]{new SDamageDealt{affectedStatPool=gamedataStatPoolType.Health,value=health},new SDamageDealt{affectedStatPool=gamedataStatPoolType.Armor,value=armor}};}
}