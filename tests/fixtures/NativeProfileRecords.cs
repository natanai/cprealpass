public static class CRFixtureRuntime { public static bool NotEquals(object a, object b) { return !object.Equals(a,b); } }
public enum gamedataWeaponEvolution { Power, Smart, Tech }
public enum gamedataItemType { Wea_Handgun, Wea_Revolver, Wea_AssaultRifle, Wea_LightMachineGun, Wea_Shotgun, Wea_ShotgunDual, Wea_PrecisionRifle, Wea_SniperRifle, Wea_SubmachineGun, Wea_Katana }
public class CRFixtureEvolution { public gamedataWeaponEvolution value; public gamedataWeaponEvolution Type(){return value;} }
public class CRFixtureItemType { public gamedataItemType value; public gamedataItemType Type(){return value;} }
public class CRFixtureAmmo { public string id; public string GetID(){return id;} }
public class WeaponItem_Record {
 public string id="Items.FixtureWeapon";
 public CRFixtureAmmo ammo;
 public CRFixtureEvolution evolution=new CRFixtureEvolution();
 public CRFixtureItemType itemType=new CRFixtureItemType();
 public string GetID(){return id;}
 public CRFixtureAmmo Ammo(){return ammo;}
 public CRFixtureEvolution Evolution(){return evolution;}
 public CRFixtureItemType ItemType(){return itemType;}
}
public static class TweakDBInterface {
 public static System.Collections.Generic.Dictionary<string,object> flats=new System.Collections.Generic.Dictionary<string,object>();
 public static float GetFloat(string id,float fallback){return flats.ContainsKey(id)?System.Convert.ToSingle(flats[id]):fallback;}
 public static int GetInt(string id,int fallback){return flats.ContainsKey(id)?System.Convert.ToInt32(flats[id]):fallback;}
 public static bool GetBool(string id,bool fallback){return flats.ContainsKey(id)?System.Convert.ToBoolean(flats[id]):fallback;}
}
