$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project = Get-ProjectRoot
$source = Join-Path $project 'src\redscript\CyberpunkRealism'
$hooks = Get-Content -Raw -LiteralPath (Join-Path $source 'BodyNativeHooks.reds')
$runtime = Get-Content -Raw -LiteralPath (Join-Path $source 'BodyRuntime.reds')
$effects = Get-Content -Raw -LiteralPath (Join-Path $source 'InjuryEffectsNative.reds')
$inputs = Get-Content -Raw -LiteralPath (Join-Path $source 'BodyInputs.reds')
$model = Get-Content -Raw -LiteralPath (Join-Path $source 'BodyModel.reds')
$serving = Get-Content -Raw -LiteralPath (Join-Path $source 'ItemServing.reds')
$wounds = Get-Content -Raw -LiteralPath (Join-Path $source 'CombatWoundsNative.reds')
$presentation = Get-Content -Raw -LiteralPath (Join-Path $source 'BiologySessionPresentation.reds')
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

# Exercise the actual production player decision. Engine services are the only
# fixture doubles; no copied lifecycle implementation is tested here.
$gate = [regex]::Match($hooks,'(?s)public class CRPlayerBodyLifecycle extends IScriptable.*?(?=public class CRBodyRuntimeMasterPolicy)').Value
Check (-not [string]::IsNullOrWhiteSpace($gate)) 'Player lifecycle adapter missing.'
Check (-not $gate.Contains('SceneSystem') -and -not $gate.Contains('IsEntityInScene')) 'Player physiology still depends on NPC scene membership.'
Check (-not $gate.Contains('GetPlayerStateMachineBlackboard') -and -not $gate.Contains('gamePSMHighLevel')) 'Player physiology is hard-gated by an unproven scene-tier whitelist.'
Check ($gate.Contains('player.IsAttached()') -and $gate.Contains('player.IsDead()') -and $gate.Contains('ScriptedPuppet.IsDefeated(player)')) 'Player lifecycle lost attachment/life guards.'
Check ($gate.Contains('UI_System.IsInMenu') -and $gate.Contains('IsPausedState()')) 'Ordinary body progression lost menu/pause guards.'
Check ($gate.Contains('CRRealpassSettings.IsEnabled(player.GetGame())')) 'Player lifecycle bypasses Biology launcher authority.'

$code = [regex]::Replace($gate,'(?m)//[^\r\n]*','')
$code = [regex]::Replace($code,'(?ms)(^\s*if )(.+?)( \{)', { param($m) $m.Groups[1].Value + ($m.Groups[2].Value -replace '\s+', ' ') + $m.Groups[3].Value })
$code = $code.Replace('GetAllBlackboardDefs()','SystemicFixture.defs')
$temp = Join-Path ([IO.Path]::GetTempPath()) ('biology-systemic-authority-' + [guid]::NewGuid().ToString('N') + '.reds')
try {
  [IO.File]::WriteAllText($temp,$code)
  $translated = Convert-RedscriptCore @($temp)
} finally {
  if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp }
}
$engine = @'
public class BlackboardDef { public string IsInMenu="menu"; }
public class BlackboardDefs { public BlackboardDef UI_System=new BlackboardDef(); }
public class IBlackboard { public bool menu; public bool GetBool(string key){return menu;} }
public class BlackboardSystem { public IBlackboard ui; public IBlackboard Get(BlackboardDef def){return ui;} }
public class TimeSystem { public bool paused; public bool IsPausedState(){return paused;} }
public class GameInstance {
  public BlackboardSystem blackboards=new BlackboardSystem(); public TimeSystem time=new TimeSystem();
  public static BlackboardSystem GetBlackboardSystem(GameInstance game){return game.blackboards;}
  public static TimeSystem GetTimeSystem(GameInstance game){return game.time;}
}
public class ScriptedPuppet { public static bool IsDefeated(PlayerPuppet p){return p.defeated;} }
public class PlayerPuppet {
  public bool attached=true,replacer,dead,defeated; public GameInstance game=new GameInstance();
  public bool IsAttached(){return attached;} public bool IsReplacer(){return replacer;} public bool IsDead(){return dead;}
  public GameInstance GetGame(){return game;}
}
public static class CRRealpassSettings { public static bool enabled=true; public static bool IsEnabled(GameInstance game){return enabled;} }
public static class SystemicFixture { public static BlackboardDefs defs=new BlackboardDefs(); }
'@
Add-Type -TypeDefinition ($translated + $engine)

$p = [PlayerPuppet]::new(); $p.game.blackboards.ui = [IBlackboard]::new()
Check ([CRPlayerBodyLifecycle]::Allowed($p,$false)) 'Ordinary attached gameplay cannot advance authoritative physiology.'
$p.game.blackboards.ui.menu = $true
Check (-not [CRPlayerBodyLifecycle]::Allowed($p,$false)) 'Menu time advanced ordinary physiology.'
Check ([CRPlayerBodyLifecycle]::Allowed($p,$true)) 'Authoritative native intake/body event cannot cross its menu completion boundary.'
$p.game.blackboards.ui.menu = $false; $p.game.time.paused = $true
Check (-not [CRPlayerBodyLifecycle]::Allowed($p,$false)) 'Paused gameplay advanced ordinary physiology.'
Check ([CRPlayerBodyLifecycle]::Allowed($p,$true)) 'Paused native intake/body event lost menu-allowed authority.'
$p.game.time.paused = $false
foreach($field in @('replacer','dead','defeated')) {
  $p.$field = $true
  Check (-not [CRPlayerBodyLifecycle]::Allowed($p,$false) -and -not [CRPlayerBodyLifecycle]::Allowed($p,$true)) "Invalid player lifecycle accepted: $field"
  $p.$field = $false
}
$p.attached = $false
Check (-not [CRPlayerBodyLifecycle]::Allowed($p,$false) -and -not [CRPlayerBodyLifecycle]::Allowed($p,$true)) 'Detached player retained physiology authority.'
$p.attached = $true
[CRRealpassSettings]::enabled = $false
Check (-not [CRPlayerBodyLifecycle]::Allowed($p,$false) -and -not [CRPlayerBodyLifecycle]::Allowed($p,$true)) 'Launcher-disabled Biology retained physiology authority.'
[CRRealpassSettings]::enabled = $true
$p.game.blackboards.ui = $null
Check (-not [CRPlayerBodyLifecycle]::Allowed($p,$false)) 'Missing UI lifecycle context masqueraded as ordinary gameplay.'
Check ([CRPlayerBodyLifecycle]::Allowed($p,$true)) 'Completed native intake/body event incorrectly depends on UI blackboard presence.'

# Systemic architecture: one player lifecycle decision feeds ordinary time and
# combat; native consumption enters the same persistent input/body authority.
$nativeGate = [regex]::Match($runtime,'(?s)private func NativeStateAllowed\(allowMenu: Bool\).*?\n  \}').Value
Check ($nativeGate.Contains('CRPlayerBodyLifecycle.Allowed(this.Player(), allowMenu)')) 'Body runtime does not use player lifecycle authority.'
Check (-not $nativeGate.Contains('CRInjuryEffectsBridge.Allowed')) 'Body runtime still routes player authority through NPC injury-effect eligibility.'
Check ($effects.Contains('actor.IsPlayer()') -and $effects.Contains('CRPlayerBodyLifecycle.Allowed(actor as PlayerPuppet, false)')) 'Player impairment does not share player lifecycle authority.'
Check ($effects.Contains('scene.IsEntityInScene(actor.GetEntityID())')) 'NPC scene-aware impairment lifecycle was removed instead of isolated.'

Check ($runtime.Contains('CRClockModel.Observe(this.clock, this.WorldSeconds(), this.SimSeconds(), allowed)')) 'Ordinary world time no longer enters the repaired authority gate.'
Check ($runtime.Contains('CRBodyInputs.Time(this.inputs, hours, exertion, sleeping);')) 'Elapsed time no longer enters shared body inputs.'
Check ($runtime.Contains('CRClockModel.FinishSkip(this.clock, this.WorldSeconds(), this.SimSeconds(), hoursRequested)')) 'WAIT/SLEEP no longer use the shared clock authority.'
Check ($runtime.Contains('CRBodyInputs.Drain(this.inputs, this.body, this.config);')) 'Shared body inputs no longer drain into persistent body state.'

Check ($hooks.Contains('@wrapMethod(ConsumeAction)') -and $hooks.Contains('runtime.Consume(record);')) 'Completed native consumable action no longer reaches body runtime.'
$consume = [regex]::Match($runtime,'(?s)public func Consume\(itemRecord: wref<Item_Record>\).*?\n  \}').Value
Check ($consume.Contains('this.NativeStateAllowed(true)')) 'Native consumption bypasses/over-tightens the menu-allowed player lifecycle.'
Check ($consume.Contains('CRItemServing.Resolve(itemRecord)') -and $consume.Contains('CRBodyInputs.Intake(this.inputs') -and $consume.Contains('CRBodyInputs.Drain(this.inputs, this.body, this.config)')) 'Consumable does not follow serving -> shared input -> persistent body.'
Check ($serving.Contains('itemRecord.TagsContains(n"Drink")') -and $serving.Contains('CRServingModel.Resolve')) 'Drink sentinel is not generalized through native record classification.'
Check ($model.Contains('state.gutWaterMl += waterMl') -and $model.Contains('state.bladderMl += urine')) 'Drink water cannot naturally propagate through digestion to bladder.'

Check ($runtime.Contains('public func CanAcceptCombatInjury()') -and $runtime.Contains('this.NativeStateAllowed(false)')) 'Combat does not share the player lifecycle gate.'
Check ($wounds.Contains('plan.committed = CRBodyRuntime.Get().RecordInjury')) 'Accepted player damage does not reach the single body runtime.'
$record = [regex]::Match($runtime,'(?s)public func RecordInjury\(.*?\n  \}').Value
Check ($record.Contains('CRBodyInputs.Injury(this.inputs') -and $record.Contains('CRBodyInputs.Drain(this.inputs, this.body, this.config)')) 'Combat injury bypasses ordered persistent body inputs.'
Check ($wounds.Contains('sample.nativePhysicalHealthDamage') -and $wounds.Contains('CRHitModel.CanRoute')) 'Combat repair replaced native accepted physical-Health causality.'

Check ($runtime.Contains('private persistent let body: ref<CRBodyState>') -and $runtime.Contains('private persistent let inputs: ref<CRBodyInputQueue>')) 'Body/input authority is no longer one persistent runtime.'
Check ($runtime.Contains('private func OnRestored(saveVersion: Int32, gameVersion: Int32)') -and $runtime.Contains('this.ResetTransientState();')) 'Save restore no longer preserves body while rebuilding transient runtime state.'
Check ($presentation.Contains('runtime.GetBodySnapshot()') -and $presentation.Contains('runtime.GetMeters()')) 'Biology projection does not reread the authoritative runtime.'
Check (-not $presentation.Contains('new CRBodyState')) 'Biology projection manufactured a second body state.'

Write-Host "PASS: $script:checks systemic body-authority checks; actual player lifecycle decision plus time, intake/bladder, combat, WAIT/SLEEP, persistence and projection architecture are connected. Engine event delivery/save serialization remain attended 2.31 acceptance."
