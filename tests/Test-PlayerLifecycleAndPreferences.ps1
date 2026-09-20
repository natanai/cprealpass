$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src/redscript/CyberpunkRealism'
$hooks = Get-Content -Raw -LiteralPath (Join-Path $source 'BodyNativeHooks.reds')
$settings = Get-Content -Raw -LiteralPath (Join-Path $source 'RealpassSettings.reds')
$gate = [regex]::Match($hooks, '(?s)public class CRPlayerBodyLifecycle extends IScriptable.*?(?=public class CRBodyRuntimeMasterPolicy)').Value
if (-not $gate) { throw 'Player lifecycle adapter missing.' }
# Translate the actual production decisions. Only engine APIs are fixture doubles.
$code = $gate + $settings.Replace('extends ScriptableSystem', 'extends IScriptable').Replace('extends Event', ': Event')
$code = [regex]::Replace($code, '(?m)//[^\r\n]*', '')
$code = [regex]::Replace($code, '(?ms)(^\s*if )(.+?)( \{)', { param($m) $m.Groups[1].Value + ($m.Groups[2].Value -replace '\s+', ' ') + $m.Groups[3].Value })
$code = $code.Replace('GetAllBlackboardDefs()', 'TestNative.defs').Replace('EnumInt(', 'TestNative.EnumInt(').Replace('n"', '"').Replace('t"', '"')
$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-lifecycle-' + [guid]::NewGuid().ToString('N') + '.reds')
try {
    [IO.File]::WriteAllText($temp, $code)
    $translated = Convert-RedscriptCore @($temp)
} finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp } }
$engine = @'
public enum gamePSMHighLevel { Default, SceneTier1, SceneTier2, SceneTier3, SceneTier4, SceneTier5, Swimming, Dead }
public class BlackboardDef { public string HighLevel="tier", IsInMenu="menu"; }
public class BlackboardDefs { public BlackboardDef PlayerStateMachine=new BlackboardDef(), UI_System=new BlackboardDef(); }
public static class TestNative { public static BlackboardDefs defs=new BlackboardDefs(); public static int EnumInt(gamePSMHighLevel v) {return (int)v;} }
public class IBlackboard { public int tier=1; public bool menu; public int GetInt(string key){return tier;} public bool GetBool(string key){return menu;} }
public class TimeSystem { public bool paused; public bool IsPausedState(){return paused;} }
public class Event {}
public class UISystem { public int events; public void QueueEvent(Event evt){events++;} }
public class ScriptableSystemsContainer { public CRRealpassSettings settings=new CRRealpassSettings(); public object Get(string key){return settings;} }
public class GameInstance {
 public IBlackboard ui=new IBlackboard(); public TimeSystem time=new TimeSystem(); public ScriptableSystemsContainer container=new ScriptableSystemsContainer(); public UISystem hud=new UISystem();
 public static UISystem GetUISystem(GameInstance game){return game.hud;}
 public static GameInstance GetBlackboardSystem(GameInstance game){return game;} public IBlackboard Get(BlackboardDef def){return ui;}
 public static TimeSystem GetTimeSystem(GameInstance game){return game.time;} public static ScriptableSystemsContainer GetScriptableSystemsContainer(GameInstance game){return game.container;}
}
public class PlayerPuppet {
 public bool attached=true, replacer, dead, defeated; public GameInstance game=new GameInstance(); public IBlackboard state=new IBlackboard();
 public bool IsAttached(){return attached;} public bool IsReplacer(){return replacer;} public bool IsDead(){return dead;}
 public GameInstance GetGame(){return game;} public IBlackboard GetPlayerStateMachineBlackboard(){return state;}
}
public static class ScriptedPuppet { public static bool IsDefeated(PlayerPuppet p){return p.defeated;} }
public static class TweakDBInterface { public static bool active=true; public static bool GetBool(string key,bool fallback){return active;} }
'@
Add-Type -TypeDefinition ($translated + $engine)
$script:checks = 0
function Check($value, [string]$message) { if (-not $value) { throw $message }; $script:checks++ }
$player = [PlayerPuppet]::new()
Check ([CRPlayerBodyLifecycle]::Allowed($player,$false)) 'Ordinary full gameplay cannot advance.'
foreach ($tier in 2,6) { $player.state.tier=$tier; Check ([CRPlayerBodyLifecycle]::Allowed($player,$false)) "Playable tier $tier cannot advance." }
foreach ($tier in 0,3,4,5,7,999) { $player.state.tier=$tier; Check (-not [CRPlayerBodyLifecycle]::Allowed($player,$false)) "Invalid/cinematic tier $tier advanced." }
$player.state.tier=1
foreach ($field in 'attached','replacer','dead','defeated') {
    $player.$field = $field -ne 'attached'
    Check (-not [CRPlayerBodyLifecycle]::Allowed($player,$false)) "Invalid actor $field advanced."
    $player.$field = $field -eq 'attached'
}
Check (-not [CRPlayerBodyLifecycle]::Allowed($null,$false)) 'Missing player advanced.'
$player.game.ui.menu=$true
Check (-not [CRPlayerBodyLifecycle]::Allowed($player,$false)) 'Menu advanced ordinary body time.'
Check ([CRPlayerBodyLifecycle]::Allowed($player,$true)) 'Menu-selected care cannot access valid body.'
$player.game.ui.menu=$false; $player.game.time.paused=$true
Check (-not [CRPlayerBodyLifecycle]::Allowed($player,$false)) 'Paused game advanced body time.'
$player.game.time.paused=$false; $player.state=$null
Check (-not [CRPlayerBodyLifecycle]::Allowed($player,$false)) 'Missing player state machine advanced.'
$player.state=[IBlackboard]::new()
$game=$player.game
Check ([CRRealpassSettings]::UseE3FirstPersonHudVisuals($game)) 'New saved preference does not default ON.'
Check ([CRRealpassSettings]::ToggleE3FirstPersonHudVisuals($game)) 'OFF write did not report success.'
Check (-not $game.container.settings.e3FirstPersonHudVisuals) 'OFF did not reach saved authority.'
Check (-not [CRRealpassSettings]::UseE3FirstPersonHudVisuals($game)) 'Readback ignored saved OFF.'
Check ([CRRealpassSettings]::ToggleE3FirstPersonHudVisuals($game)) 'ON write did not report success.'
Check ($game.container.settings.e3FirstPersonHudVisuals) 'ON did not reach saved authority.'
Check ($game.hud.events -eq 2) 'Preference changes did not notify existing HUD controllers exactly once.'
Check ([CRRealpassSettings]::SetE3FirstPersonHudVisuals($game,$true)) 'Idempotent preference write failed.'
Check ($game.hud.events -eq 2) 'Unchanged preference caused redundant HUD events.'
[TweakDBInterface]::active=$false
Check (-not [CRPlayerBodyLifecycle]::Allowed($player,$true)) 'Menu exception bypasses launcher OFF.'
Check (-not [CRRealpassSettings]::UseE3FirstPersonHudVisuals($game)) 'Saved ON overrides launcher OFF.'
Check (-not [CRRealpassSettings]::SetE3FirstPersonHudVisuals($game,$false)) 'Inactive preference accepted mutation.'
Check ($game.container.settings.e3FirstPersonHudVisuals) 'Launcher OFF erased saved preference.'
[TweakDBInterface]::active=$true
Check ([CRRealpassSettings]::UseE3FirstPersonHudVisuals($game)) 'Re-enable lost saved preference.'
$game.container.settings=$null
Check (-not [CRRealpassSettings]::UseE3FirstPersonHudVisuals($game)) 'Missing settings masquerades as ON.'
Check (-not [CRRealpassSettings]::ToggleE3FirstPersonHudVisuals($game)) 'Missing settings reports a successful toggle.'
$game.container=$null
Check (-not [CRRealpassSettings]::SetE3FirstPersonHudVisuals($game,$true)) 'Missing container reports success.'
$runtime=Get-Content -Raw -LiteralPath (Join-Path $source 'BodyRuntime.reds')
$effects=Get-Content -Raw -LiteralPath (Join-Path $source 'InjuryEffectsNative.reds')
$ui=Get-Content -Raw -LiteralPath (Join-Path $source 'BiologyPreferencesNative.reds')
Check ($runtime.Contains('CRPlayerBodyLifecycle.Allowed(player, allowMenu)')) 'Body still uses NPC eligibility.'
Check ($effects.Contains('CRPlayerBodyLifecycle.Allowed(actor as PlayerPuppet, false)')) 'Player impairment still uses NPC eligibility.'
Check (-not $gate.Contains('scene.IsEntityInScene')) 'Player gameplay depends on NPC scene membership.'
Check ($ui.Contains('player.GetGame()') -and -not $ui.Contains('GetGameInstance()')) 'Preference uses an ambiguous menu/global session.'
Check ($ui.Contains('SetInteractive(false)') -and -not $ui.Contains('GetCurrentTarget() !=')) 'Decorative child rejects preference clicks.'
Check ($ui.Contains('"UNAVAILABLE"') -and $ui.Contains('if !written')) 'Missing preference authority is concealed.'
Write-Host "PASS: $script:checks actual-source player lifecycle and preference decision checks. Native event delivery and save serialization remain live-only."
