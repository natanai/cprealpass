. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$nativePath=Join-Path $project 'src/redscript/CyberpunkRealism/CombatProfilesNative.reds'
$native=Get-Content -Raw -LiteralPath $nativePath
# Actual mapping methods, with typed record fixtures. Native code also compiles
# separately against the game bundle. No engine runtime claim is made here.
$methods=foreach($name in @('Family','ProjectileProfile','ApplyProjectileOverrides','Protection')){
 $match=[regex]::Match($native,'(?m)^  (?:public|private) static func '+$name+'\(')
 if(-not $match.Success){throw "Missing native method $name"}
 $start=$native.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $native.Length){if($native[$end] -eq '{'){$depth++};if($native[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced source method'}
 $native.Substring($match.Index,$end-$match.Index)
}
$fixtureSource=Join-Path $project ('staging/native-profile-test-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($fixtureSource,"public class CRCombatProfilesNative extends IScriptable {`n"+($methods -join "`n")+"`n}")
$code=Convert-RedscriptCore @((Join-Path $project 'src/redscript/CyberpunkRealism/ImpactModel.reds'),(Join-Path $project 'src/redscript/CyberpunkRealism/BallisticProfiles.reds'),(Join-Path $project 'src/redscript/CyberpunkRealism/StockProtectionCatalog.reds'),$fixtureSource)
$code=[regex]::Replace($code,'(?m)^(\s*)switch (.+) \{','$1switch ($2) {')
$code=[regex]::Replace($code,'(?m)^import .*$','')
$code=$code.Replace('TweakDBID','string').Replace('t"','"').Replace('NotEquals(', 'CRFixtureRuntime.NotEquals(')
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/NativeProfileRecords.cs"))
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
$r=[WeaponItem_Record]::new()
$families=@{Wea_Handgun=1;Wea_Revolver=2;Wea_AssaultRifle=3;Wea_LightMachineGun=4;Wea_Shotgun=5;Wea_ShotgunDual=5;Wea_PrecisionRifle=6;Wea_SniperRifle=6;Wea_SubmachineGun=7}
foreach($entry in $families.GetEnumerator()){
 $r.itemType.value=[gamedataItemType]$entry.Key
 Check ([CRCombatProfilesNative]::Family($r) -eq $entry.Value) 'Power weapon mapped to incorrect family'
}
$r.itemType.value=[gamedataItemType]::Wea_Katana
Check ([CRCombatProfilesNative]::Family($r) -eq 0) 'Unsupported weapon received gun defaults'
$r.itemType.value=[gamedataItemType]::Wea_Handgun
$r.evolution.value=[gamedataWeaponEvolution]::Tech
Check ([CRCombatProfilesNative]::Family($r) -eq 0) 'Unmapped tech weapon silently used power ballistics'
[TweakDBInterface]::flats['Items.FixtureWeapon.crProjectileFamily']=3
Check ([CRCombatProfilesNative]::Family($r) -eq 3) 'Explicit profile could not opt in a different evolution'
[TweakDBInterface]::flats['Items.FixtureWeapon.crProjectileFamily']=-1
Check (-not [CRBallisticProfiles]::Valid([CRCombatProfilesNative]::ProjectileProfile($r))) 'Explicit disabled profile fell back to generic defaults'
[TweakDBInterface]::flats.Clear();$r.evolution.value=[gamedataWeaponEvolution]::Power
$r.ammo=[CRFixtureAmmo]::new();$r.ammo.id='Ammo.Fixture'
[TweakDBInterface]::flats['Ammo.Fixture.crProjectileMassGrams']=10.0
[TweakDBInterface]::flats['Ammo.Fixture.crProjectilePenetration']=1.5
[TweakDBInterface]::flats['Ammo.Fixture.crProjectileMuzzleSpeed']=400.0
[TweakDBInterface]::flats['Items.FixtureWeapon.crProjectileMuzzleSpeed']=450.0
$p=[CRCombatProfilesNative]::ProjectileProfile($r)
Check ($p.massGrams -eq 10 -and $p.penetrationFactor -eq 1.5 -and $p.muzzleSpeed -eq 450) 'Ammo properties or weapon override precedence lost'
Check ($p.diameterMm -eq 9 -and $p.speedHalfDistanceM -eq 350) 'Missing explicit fields lost family defaults'
[TweakDBInterface]::flats['Items.FixtureWeapon.crProjectileMassGrams']=[float]::NaN
Check (-not [CRBallisticProfiles]::Valid([CRCombatProfilesNative]::ProjectileProfile($r))) 'Invalid explicit value silently fell back to a valid default'
Check ([CRCombatProfilesNative]::Family($null) -eq 0) 'Null weapon record mapping failed'
Check (-not ([CRCombatProfilesNative]::Protection('Items.Unmapped')).mapped) 'Unknown equipment became known unarmored'
[TweakDBInterface]::flats['Items.Plate.crProtectionMapped']=$true
[TweakDBInterface]::flats['Items.Plate.crProtectTorso']=$true
[TweakDBInterface]::flats['Items.Plate.crResistanceJPerMm2']=20.0
[TweakDBInterface]::flats['Items.Plate.crDurabilityJ']=10000.0
[TweakDBInterface]::flats['Items.Plate.crBluntTransfer']=0.1
$plate=[CRCombatProfilesNative]::Protection('Items.Plate')
Check (([CRCoverageModel]::Layer($plate,2,1)).covered -and -not ([CRCoverageModel]::Layer($plate,3,1)).covered) 'Record mapping spread torso armor to arms'
[TweakDBInterface]::flats['Items.Partial.crProtectionMapped']=$true
Check ([CRCoverageModel]::Layer([CRCombatProfilesNative]::Protection('Items.Partial'),2,1) -eq $null) 'Partial record mapping silently used magic armor defaults'
[TweakDBInterface]::flats.Clear()
$catalog=Get-Content -Raw (Join-Path $project 'reports/stock-protection-catalog.json')|ConvertFrom-Json
$recipe=Get-Content -Raw (Join-Path $project 'config/stock-protection.json')|ConvertFrom-Json
$catalogSource=Join-Path $project 'src/redscript/CyberpunkRealism/StockProtectionCatalog.reds'
Check ((Get-Sha256 $catalogSource) -eq $catalog.outputSha256) 'Catalog source differs from audited generated output'
Check ((Get-Sha256 (Join-Path $project 'config/stock-protection.json')) -eq $catalog.recipeSha256) 'Catalog recipe changed without rebuilding'
foreach($entry in $catalog.entries){
 $p=[CRCombatProfilesNative]::Protection($entry.record)
 $expected=$recipe.profiles|Where-Object id -eq $entry.profile
 foreach($region in 1..6){
  $layer=[CRCoverageModel]::Layer($p,$region,1)
  Check ($null -ne $layer -and $layer.covered -eq ($region -in $expected.regions)) "Stock region coverage mismatch: $($entry.record), region $region"
 }
}
foreach($entry in $catalog.excluded){Check (-not ([CRCombatProfilesNative]::Protection($entry.record)).mapped) "Excluded stock record silently resolved: $($entry.record)"}
$vest='Items.Vest_01_basic_01'
$v=[CRCombatProfilesNative]::Protection($vest)
Check ($v.mapped -and $v.torso -and -not $v.head -and -not $v.leftArm -and -not $v.rightArm) 'Vest gave head or arm protection'
$round=[CRBallisticProfiles]::Projectile([CRBallisticProfiles]::Family(1),0,0,0)
$impact=[CRImpactModel]::Begin($round)
[CRImpactModel]::ApplyLayer($impact,[CRCoverageModel]::Layer($v,2,1))|Out-Null
Check ($impact.remainingJ -lt $impact.initialJ -and $impact.bluntJ -gt 0 -and [CRImpactModel]::ValidState($impact)) 'Vest did not partition incident energy into residual, dissipation and blunt load'
$arm=[CRImpactModel]::Begin($round)
[CRImpactModel]::ApplyLayer($arm,[CRCoverageModel]::Layer($v,3,1))|Out-Null
Check ($arm.remainingJ -eq $arm.initialJ -and $arm.bluntJ -eq 0) 'Torso vest changed a bare-arm impact'
$optics=[CRCombatProfilesNative]::Protection('Items.AdvancedKiroshiOpticsBareCommon')
Check ($optics.mapped -and -not $optics.head -and -not $optics.torso -and $optics.resistanceJPerMm2 -eq 0) 'Optical implant became a regional armor shell'
[TweakDBInterface]::flats[$vest+'.crProtectionMapped']=$false
Check (-not ([CRCombatProfilesNative]::Protection($vest)).mapped) 'Explicit stock opt-out was ignored'
[TweakDBInterface]::flats.Clear()
[TweakDBInterface]::flats[$vest+'.crProtectTorso']=$false
Check (-not ([CRCombatProfilesNative]::Protection($vest)).torso) 'Explicit coverage override was ignored'
[TweakDBInterface]::flats[$vest+'.crResistanceJPerMm2']=[float]::NaN
Check ($null -eq [CRCoverageModel]::Layer([CRCombatProfilesNative]::Protection($vest),2,1)) 'Invalid stock override fell back silently'
[TweakDBInterface]::flats.Clear()
Check (-not ([CRCombatProfilesNative]::Protection('Items.AdvancedBoringPlatingStatsShard')).mapped) 'Stat shard was mistaken for an equipped protective item'
Check (-not ([CRCombatProfilesNative]::Protection('Character.UnmappedCivilian')).mapped) 'Unknown NPC was silently mapped to no protection'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;nativeSourceSha256=(Get-Sha256 $nativePath);stockRecords=$catalog.count;stockCatalogSha256=$catalog.outputSha256;methods=@('Family','ProjectileProfile','ApplyProjectileOverrides','Protection');scope='Actual original native mapping methods translated to C# with typed record/TweakDB fixtures. Tests enum routing, opt-out/explicit opt-in, ammo-before-weapon precedence, missing/invalid fields and armor masks. Actual engine TweakDB and equipment/event enumeration remain unverified.'}) (Join-Path $project 'reports/native-profile-mapping-tests.json')
Write-Host "PASS: $script:checks native mapping checks with record fixtures."
