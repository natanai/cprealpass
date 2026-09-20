public partial class CRBodyRuntime {
 public bool localizedInjuryHandover;
 public bool running = true;
 public bool allowed = true;
 public bool needsOwned = true;
 public static CRBodyRuntime instance;
 public static CRBodyRuntime Get(){return instance;}
 public bool OwnsNeeds(){return needsOwned;}
 public bool Allowed(){return allowed;}
}
public partial class DFInjuryConditionSystem {
 public int currentConditionLevel;
 public float accumulatedPercentTowardNextLevel;
 public CRFixturePlayer player;
 public static DFInjuryConditionSystem instance;
 public static DFInjuryConditionSystem Get(){return instance;}
}
public class CRFixturePlayer { public bool legacyEffect; }
public static class StatusEffectSystem {
 public static bool ObjectHasStatusEffectWithTag(CRFixturePlayer player, string tag) {
  if(tag != "DarkFutureConditionInjury") throw new System.Exception("Wrong legacy injury effect tag");
  return player.legacyEffect;
 }
}
public static class CRCombatRuntimePolicy {
 public static bool enabled = true;
 public static bool Enabled(){return enabled;}
}
