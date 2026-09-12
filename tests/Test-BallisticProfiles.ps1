. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('ImpactModel','BallisticProfiles')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Energy($profile,$distance=0,$bounces=0,$charge=0){return [CRImpactModel]::Begin([CRBallisticProfiles]::Projectile($profile,$distance,$bounces,$charge))}
$handgun=[CRBallisticProfiles]::Family(1);$rifle=[CRBallisticProfiles]::Family(3);$pellet=[CRBallisticProfiles]::Family(5)
Check ([Math]::Abs((Energy $handgun).initialJ-518.4) -lt 0.001) 'Handgun gram conversion or archetype incorrect'
Check ([Math]::Abs((Energy $rifle).initialJ-1620) -lt 0.001) 'Rifle archetype incorrect'
Check ([Math]::Abs((Energy $pellet).initialJ-252.7) -lt 0.001) 'Pellet energy treated as whole-shell energy'
$half=Energy $handgun $handgun.speedHalfDistanceM
Check ([Math]::Abs($half.initialJ/(Energy $handgun).initialJ-0.25) -lt 0.00001) 'Half-speed distance did not produce quarter energy'
$one=Energy $handgun 0 1;$two=Energy $handgun 0 2
Check ($one.initialJ -lt (Energy $handgun).initialJ -and $two.initialJ -lt $one.initialJ) 'Ricochets added energy'
Check ([Math]::Abs($one.initialJ/(Energy $handgun).initialJ-0.49) -lt 0.00001) 'Speed retention applied directly as energy retention'
Check ((Energy $handgun 0 0 1).initialJ -eq (Energy $handgun).initialJ) 'Uncharged family gained energy from unused charge metadata'
$charged=[CRBallisticProfiles]::Family(3);$charged.chargeSpeedGain=1
Check ([Math]::Abs((Energy $charged 0 0 1).initialJ-4*(Energy $charged).initialJ) -lt 0.001) 'Explicit charge profile did not affect physical speed'
$fresh=[CRBallisticProfiles]::Family(3)
Check ($fresh.chargeSpeedGain -eq 0 -and $fresh.muzzleSpeed -eq 900) 'One weapon override mutated another weapon family'
foreach($family in @(-1,0,8,100)){
 Check (-not [CRBallisticProfiles]::Valid([CRBallisticProfiles]::Family($family))) 'Unknown family silently received a projectile'
}
foreach($bad in @(-1,[float]::NaN,[float]::PositiveInfinity)){
 Check (-not (Energy $handgun $bad).valid) 'Invalid distance became an impact'
 Check (-not (Energy $handgun 0 0 $bad).valid) 'Invalid charge became an impact'
}
Check (-not (Energy $handgun 0 17).valid) 'Unbounded ricochet count accepted'
Check (-not (Energy $handgun 0 -1).valid) 'Negative ricochet count accepted'
$badProfile=[CRBallisticProfiles]::Family(3);$badProfile.ricochetSpeedRetention=1.01
Check (-not [CRBallisticProfiles]::Valid($badProfile)) 'Energy-generating ricochet setting accepted'
$badProfile=[CRBallisticProfiles]::Family(3);$badProfile.massGrams=[float]::NaN
Check (-not [CRBallisticProfiles]::Valid($badProfile)) 'Malformed per-record mass override accepted'
$excess=[CRBallisticProfiles]::Family(3);$excess.muzzleSpeed=5000;$excess.chargeSpeedGain=4
Check (-not (Energy $excess 0 0 1).valid) 'Charged speed beyond solver bounds silently clamped'
# A known plate must protect only mapped regions. Unknown and no protection differ.
$plate=[CRProtectionProfile]::new();$plate.mapped=$true;$plate.torso=$true;$plate.resistanceJPerMm2=20;$plate.durabilityJ=10000;$plate.bluntTransferFraction=0.1
$torso=[CRCoverageModel]::Layer($plate,2,1);$leg=[CRCoverageModel]::Layer($plate,5,1)
Check ($torso.covered -and -not $leg.covered) 'Torso coverage leaked into a limb'
$pistolHit=Energy $handgun;$rifleHit=Energy $rifle;$legHit=Energy $rifle
[CRImpactModel]::ApplyLayer($pistolHit,$torso)|Out-Null
[CRImpactModel]::ApplyLayer($rifleHit,[CRCoverageModel]::Layer($plate,2,1))|Out-Null
[CRImpactModel]::ApplyLayer($legHit,$leg)|Out-Null
Check ($pistolHit.remainingJ -eq 0 -and $rifleHit.remainingJ -gt 0) 'Reference armor lost projectile-dependent penetration'
Check ($legHit.remainingJ -eq (Energy $rifle).initialJ) 'Uncovered limb received torso protection'
Check ([CRCoverageModel]::Layer([CRProtectionProfile]::new(),2,1) -eq $null) 'Unknown armor was treated as known unarmored clothing'
$cloth=[CRProtectionProfile]::new();$cloth.mapped=$true;$cloth.durabilityJ=10000
$knownNone=[CRCoverageModel]::Layer($cloth,2,1)
Check ($null -ne $knownNone -and -not $knownNone.covered -and $knownNone.resistanceJPerMm2 -eq 0) 'Explicit nonprotective clothing was not representable'
Check ([CRCoverageModel]::Layer($plate,0,1) -eq $null) 'Unknown body region received coverage'
Check ([CRCoverageModel]::Layer($plate,2,[float]::NaN) -eq $null) 'Invalid persisted armor condition accepted'
$malformed=[CRProtectionProfile]::new();$malformed.mapped=$true;$malformed.durabilityJ=0
Check ([CRCoverageModel]::Layer($malformed,2,1) -eq $null) 'Partial mapping silently produced protection'
$script:scenarios=0
foreach($family in 1..7){foreach($range in @(0,10,100,500,1000)){foreach($bounce in @(0,1,4,16)){foreach($charge in @(0,0.5,1)){
 $profile=[CRBallisticProfiles]::Family($family)
 $impact=Energy $profile $range $bounce $charge
 if(-not [CRImpactModel]::ValidState($impact) -or $impact.initialJ -gt (Energy $profile).initialJ+0.001){throw 'Family sweep generated energy or invalid state'}
 $script:scenarios++
}}}}
Check ($script:scenarios -eq 420) 'Profile sweep missed expected cases'
$properties=@('head','torso','leftArm','rightArm','leftLeg','rightLeg')
for($index=0;$index -lt 6;$index++){
 $only=[CRProtectionProfile]::new();$only.mapped=$true;$only.durabilityJ=10000;$only.resistanceJPerMm2=20;$only.($properties[$index])=$true
 for($region=1;$region -le 6;$region++){
  if(([CRCoverageModel]::Layer($only,$region,1)).covered -ne ($region -eq $index+1)){throw 'Coverage crossed a body region'}
 }
}
Check ($true) 'Six-by-six coverage isolation'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;profileScenarios=$script:scenarios;coverageCombinations=36;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});scope='Original REDscript converted to float32 C#. Provisional archetypes, units, range/ricochet/charge, invalid overrides, region coverage, unknown-vs-unarmored distinction. Does not validate native TweakDB reads, equipment/appearance coverage, pellets, injury behavior or calibrated real-world ballistics.'}) (Join-Path $project 'reports/ballistic-profile-tests.json')
Write-Host "PASS: $script:checks profile checks, $script:scenarios trajectory cases, 36 coverage combinations."
