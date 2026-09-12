public struct Vector4 {
    public float X;
    public static float Length(Vector4 v) { return System.Math.Abs(v.X); }
    public static float DistanceSquared(Vector4 a, Vector4 b) { return (a.X-b.X)*(a.X-b.X); }
}
public partial class PlayerPuppet {
    public Vector4 velocity, position;
    public IBlackboard board=new IBlackboard();
    public IBlackboard GetPlayerStateMachineBlackboard(){return board;}
    public bool combat, dead, mounted, scene;
    public Vector4 GetVelocity() { return velocity; }
    public Vector4 GetWorldPosition() { return position; }
    public bool IsInCombat() { return combat; }
    public bool IsDead() { return dead; }
}
public class PlayerSystem { public PlayerPuppet GetLocalPlayerMainGameObject() {return CareTimedFixture.player;} }
public struct CareSimTime { public float value; public float ToFloat(){return value;} }
public partial class GameInstance {
    public static PlayerSystem GetPlayerSystem(GameInstance game) {return new PlayerSystem();}
    public static CareSimTime GetSimTime(GameInstance game) {return new CareSimTime{value=CareTimedFixture.sim};}
    public static CareDelaySystem GetDelaySystem(GameInstance game) {return CareTimedFixture.delays;}
    public static CareBlackboardSystem GetBlackboardSystem(GameInstance game) {return new CareBlackboardSystem();}
}
public struct SimpleScreenMessage { public bool isShown; public float duration; public string message; }
public class CareBlackboardSystem { public CareBlackboard Get(object def) { return new CareBlackboard();} }
public class CareBlackboard { public void SetVariant(string key, SimpleScreenMessage message, bool notify) {CareTimedFixture.messages.Add(message.message);} }
public class CareNotifications { public string WarningMessage = "warning"; }
public class CareDefs { public CareNotifications UI_Notifications = new CareNotifications(); public CarePSM PlayerStateMachine=new CarePSM(); }
public class CareDelaySystem {
    private int next;
    public int scheduled, cancelled;
    public bool failSchedule;
    public System.Collections.Generic.Dictionary<int,CRFieldCareActionCallback> callbacks = new System.Collections.Generic.Dictionary<int,CRFieldCareActionCallback>();
    public int DelayCallback(CRFieldCareActionCallback callback,float seconds,bool dilation) {
        if(seconds != 0.25f || dilation) throw new System.Exception("Unexpected scheduling contract");
        if(failSchedule) return 0;
        scheduled++; callbacks[++next]=callback; return next;
    }
    public void CancelCallback(int id) { cancelled++; callbacks.Remove(id); }
    public CRFieldCareActionCallback Fire() {
        if(callbacks.Count != 1) throw new System.Exception("Expected exactly one outstanding callback, got "+callbacks.Count);
        int id=0; foreach(var key in callbacks.Keys) {id=key;break;}
        var callback=callbacks[id]; callbacks.Remove(id); callback.Call(); return callback;
    }
}
public class DFGameStateService {
    public static bool inMenu=true, valid=true;
    public static DFGameStateService Get(){return new DFGameStateService();}
    public bool IsInAnyMenu(){return inMenu;}
    public bool IsValidGameState(object owner){return valid;}
}
public class DFInjuryConditionSystem {
    public static DFInjuryConditionSystem Get(){return new DFInjuryConditionSystem();}
    public bool CRIsClearForHandover(){return true;}
}
public static class CRCombatRuntimePolicy {public static bool Enabled(){return true;}}
public static class VehicleComponent { public static bool IsMountedToVehicle(GameInstance game,PlayerPuppet player){return player.mounted;} }
public static class CRInjuryEffectsBridge {public static bool Allowed(PlayerPuppet player,bool enabled){return enabled && !player.scene;}}
public partial class CRBodyRuntime {
    public bool running=true, localizedInjuryHandover=true, fieldCareBusy;
    public CRBodyInputQueue inputs=new CRBodyInputQueue();
    public CRBodyConfig config=new CRBodyConfig();
    public CRBodyState body;
    public float pendingHours;
    public int publications;
    public static CRBodyRuntime Get(){return CareTimedFixture.body;}
    public bool OwnsNeeds(){return true;}
    public bool OwnsLocalizedInjuries(){return localizedInjuryHandover;}
    public CRBodyState GetBodySnapshot(){return body;}
    public void Observe(){CRBodyModel.Advance(body,config,pendingHours,0,false);pendingHours=0;}
    public void Publish(){publications++;}
}
public static class CareTimedFixture {
    public static GameInstance game;
    public static PlayerPuppet player;
    public static CRBodyRuntime body;
    public static CRFieldCareActionRuntime runtime;
    public static CareDelaySystem delays;
    public static CareDefs defs=new CareDefs();
    public static float sim;
    public static System.Collections.Generic.List<string> messages;
    public static void Reset() {
        player=new PlayerPuppet(); game=player.game; body=new CRBodyRuntime(); body.body=CRBodyModel.Create(body.config);
        CRInjuryModel.Wound(body.body.injuries,5,0.4f,0.5f,0.6f,100,40);
        runtime=new CRFieldCareActionRuntime();delays=new CareDelaySystem();sim=0;messages=new System.Collections.Generic.List<string>();
        DFGameStateService.inMenu=true;DFGameStateService.valid=true;
    }
    public static void Sample(float seconds=0.25f){sim+=seconds;delays.Fire();}
}
public enum gamePSMRangedWeaponStates { Default, Ready, Safe, NoAmmo, Reload=9 }
public enum gamePSMUpperBodyStates { Default, Aim }
public class CarePSM {public string Weapon="weapon",MeleeWeapon="melee",Consumable="consumable",CombatGadget="gadget",LeftHandCyberware="chrome",UpperBody="upper";}
public class IBlackboard {
    public System.Collections.Generic.Dictionary<string,int> values=new System.Collections.Generic.Dictionary<string,int>();
    public int GetInt(string key){return values.ContainsKey(key)?values[key]:0;}
}