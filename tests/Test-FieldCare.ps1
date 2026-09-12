. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('FieldCareActionModel','InjuryModel','BodyModel','SleepModel','BodyInputs','FieldCareModel','FieldCareRuntime')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
$code=Convert-RedscriptCore $paths
$code=[regex]::Replace($code,'(?m)^import .+$','')
$code=$code.Replace('t"','"')
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/FieldCareInventory.cs")+'public class CRFieldCareActionRuntime { public static CRFieldCareActionRuntime Get(){return new CRFieldCareActionRuntime();} public bool IsCompleting(CRFieldCareAction action){return false;} }')
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Wounded {
 $s=[CRInjuryModel]::Create()
 [CRInjuryModel]::Wound($s,5,0.4,0.5,0.6,100,40)|Out-Null
 return $s
}
$s=Wounded;$before=[CRInjuryModel]::Copy($s)
$plan=[CRFieldCareModel]::Prepare($s,5,2)
Check ($null -ne $plan -and [CRFieldCareModel]::Same($s,$before)) 'Preparing care modified real wounds'
Check ($plan.after.leftLeg.externalBleedMlPerHour -eq 0 -and $plan.after.leftLeg.internalBleedMlPerHour -eq 40) 'Dressing preparation changed internal bleeding'
Check (-not [object]::ReferenceEquals($plan.before,$s) -and -not [object]::ReferenceEquals($plan.before.leftLeg,$plan.after.leftLeg)) 'Plan references alias real or candidate wounds'
$p=[PlayerPuppet]::new();$regionRef=$s.leftLeg
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 1 -and $p.game.inventory.count -eq 2) 'Successful care did not spend exactly one kit'
Check ($s.leftLeg.externalBleedMlPerHour -eq 0 -and $s.leftLeg.internalBleedMlPerHour -eq 40 -and $s.leftLeg.boneDamage -eq 0.5 -and $s.leftLeg.cyberwareDamage -eq [float]0.6) 'Field care repaired unrelated biology/chrome'
Check ([object]::ReferenceEquals($regionRef,$s.leftLeg) -and $plan.committed -and -not $plan.spending) 'Commit replaced shared region identity or retained a transaction lock'
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 0 -and $p.game.inventory.count -eq 2 -and $p.game.inventory.removeCalls -eq 1) 'Repeated callback spent or applied treatment twice'
Check ($null -eq [CRFieldCareModel]::Prepare($s,5,2)) 'Re-dressing a nonbleeding region would consume a kit'
$plan=[CRFieldCareModel]::Prepare($s,5,3)
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 1 -and $s.leftLeg.support -eq 1 -and $s.leftLeg.boneDamage -eq 0.5) 'Splint failed to support the injured limb or instantly healed bone'
Check ($null -eq [CRFieldCareModel]::Prepare($s,5,3)) 'Repeated full support would consume a kit'
foreach($region in @(0,1,2,7)){
 $injury=[CRInjuryModel]::Create()
 if($region -in @(1,2)){[CRInjuryModel]::Wound($injury,$region,0.1,0.5,0,0,0)|Out-Null}
 Check ($null -eq [CRFieldCareModel]::Prepare($injury,$region,3)) 'Field limb support accepted unknown/head/torso region'
}
foreach($kind in @(0,1,4,5,6)){
 Check ($null -eq [CRFieldCareModel]::Prepare((Wounded),5,$kind)) 'Portable kit provided wound creation, clinical care or chrome repair'
}
foreach($region in 1..6){
 $injury=[CRInjuryModel]::Create();[CRInjuryModel]::Wound($injury,$region,0.2,0,0,50,20)|Out-Null
 $plan=[CRFieldCareModel]::Prepare($injury,$region,2)
 Check ([CRFieldCareModel]::Commit($plan,$injury) -and ([CRInjuryModel]::Region($injury,$region)).externalBleedMlPerHour -eq 0) 'Dressing could not treat an actual selected region'
}
$s=Wounded;$p=[PlayerPuppet]::new();$p.game.inventory.count=0;$plan=[CRFieldCareModel]::Prepare($s,5,2)
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 2 -and $s.leftLeg.externalBleedMlPerHour -eq 100 -and $p.game.inventory.removeCalls -eq 0) 'No-supply request changed wounds or attempted a debit'
$p.game.inventory.count=1;$p.game.inventory.removeFails=$true
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 5 -and $s.leftLeg.externalBleedMlPerHour -eq 100 -and -not $plan.spending) 'Failed debit gave free care or left the transaction locked'
$p.game.inventory.removeFails=$false
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 1 -and $p.game.inventory.count -eq 0) 'Valid retry after failed debit failed'
$s=Wounded;$p=[PlayerPuppet]::new();$plan=[CRFieldCareModel]::Prepare($s,5,2)
[CareCallbackFixture]::ChangeBody($p,$s)
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 3 -and $p.game.inventory.count -eq 3 -and $p.game.inventory.giveCalls -eq 1) 'State-change failure did not compensate the removed kit'
Check ($s.head.externalBleedMlPerHour -eq 10 -and $s.leftLeg.externalBleedMlPerHour -eq 100 -and -not $plan.committed) 'Stale plan overwrote new injury or partially applied care'
$s=Wounded;$p=[PlayerPuppet]::new();$plan=[CRFieldCareModel]::Prepare($s,5,2);$p.game.inventory.giveFails=$true
[CareCallbackFixture]::ChangeBody($p,$s)
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 4 -and $p.game.inventory.count -eq 2 -and -not $plan.spending) 'Failed compensation was concealed as success/refund'
$s=Wounded;$p=[PlayerPuppet]::new();$plan=[CRFieldCareModel]::Prepare($s,5,2)
[CareCallbackFixture]::Reenter($p,$plan,$s)
Check ([CRFieldCareInventory]::Execute($p,$plan,$s) -eq 1 -and [CareCallbackFixture]::nestedResult -eq 0 -and $p.game.inventory.removeCalls -eq 1) 'Nested inventory callback spent a second kit'
$s=Wounded;$plan=[CRFieldCareModel]::Prepare($s,5,2);$plan.after.leftLeg.boneDamage=0
Check (-not [CRFieldCareModel]::Commit($plan,$s) -and $s.leftLeg.externalBleedMlPerHour -eq 100) 'Tampered candidate bypassed treatment limits'
$s=Wounded;$plan=[CRFieldCareModel]::Prepare($s,5,2);$s.bloodLostMl=10;$s.bloodDeficitMl=10
Check (-not [CRFieldCareModel]::Commit($plan,$s)) 'Blood ledger changed without invalidating a prepared action'
$s=Wounded;$s.leftLeg.support=[float]::NaN
Check ($null -eq [CRFieldCareModel]::Prepare($s,5,2)) 'Invalid injury state accepted a paid action'
# Chronology: settle a pending fraction before field care; subsequent body time
# reflects the dressing but preserves internal bleeding and delayed recovery.
$c=[CRBodyConfig]::new();$c.injuryExternalClotPerHourSquared=0;$c.injuryBloodRecoveryMlPerHour=0
$body=[CRBodyModel]::Create($c);$body.injuries=Wounded
[CRBodyModel]::Advance($body,$c,0.005,0,$false)|Out-Null
Check ([CRBodyModel]::CloseInterval($body,$c) -and [Math]::Abs($body.injuries.bloodLostMl-0.7) -lt 0.001) 'Old fractional bleeding did not settle before paid care'
$plan=[CRFieldCareModel]::Prepare($body.injuries,5,2);$p=[PlayerPuppet]::new()
[CRFieldCareInventory]::Execute($p,$plan,$body.injuries)|Out-Null
[CRBodyModel]::Advance($body,$c,1,0,$false)|Out-Null
Check ([Math]::Abs($body.injuries.bloodLostMl-40.7) -lt 0.01) 'Treatment changed historical bleeding or failed to affect later shared body time'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});fixtureSha256=Get-Sha256 "$PSScriptRoot/fixtures/FieldCareInventory.cs";scope='Actual care preparation/commit and native inventory adapter translated to float32 C# with typed inventory boundary fixtures. Covers regional limits, no-op/debit failure, stale state, compensation, reentrancy, repeated completion and fractional body chronology. Native inventory callbacks, menu layout/input, saves and treatment calibration remain unverified.'}) (Join-Path $project 'reports/field-care-tests.json')
Write-Host "PASS: $script:checks field-care checks."
