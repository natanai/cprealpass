. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$paths=@('ImpactModel','HitModel')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
function Projectile($mass=8,$speed=400,$diameter=9,$factor=1){$p=[CRProjectileSpec]::new();$p.massGrams=$mass;$p.speedMetersPerSecond=$speed;$p.diameterMm=$diameter;$p.penetrationFactor=$factor;return $p}
function Layer($resistance=5,$covered=$true,$blunt=0.1){$l=[CRProtectionLayer]::new();$l.covered=$covered;$l.resistanceJPerMm2=$resistance;$l.bluntTransferFraction=$blunt;$l.durabilityJ=10000;return $l}
$p=Projectile
$s=[CRImpactModel]::Begin($p)
Check ($s.valid -and [Math]::Abs($s.initialJ-640) -lt 0.001) 'Gram/metre units produced incorrect kinetic energy'
$l=Layer
$area=[Math]::PI*4.5*4.5
Check ([CRImpactModel]::ApplyLayer($s,$l)) 'Valid covered layer rejected'
Check ([Math]::Abs($s.remainingJ-(640-5*$area)) -lt 0.001) 'Residual energy incorrect'
Check ([Math]::Abs($s.bluntJ-0.5*$area) -lt 0.001) 'Blunt energy was lost or created'
Check ([Math]::Abs($l.integrity-(1-5*$area/10000)) -lt 0.00001) 'Armor condition did not record absorbed energy'
Check ([CRImpactModel]::ValidState($s)) 'Energy no longer conserved after armor'
$strong=Layer 20;$stopped=[CRImpactModel]::Begin($p)
[CRImpactModel]::ApplyLayer($stopped,$strong)|Out-Null
Check ($stopped.remainingJ -eq 0 -and [Math]::Abs($stopped.bluntJ-64) -lt 0.001 -and [Math]::Abs($stopped.dissipatedJ-576) -lt 0.001) 'Stopped projectile energy partition incorrect'
$behind=Layer 50;$old=$behind.integrity
[CRImpactModel]::ApplyLayer($stopped,$behind)|Out-Null
Check ($behind.integrity -eq $old -and $stopped.bluntJ -eq 64) 'Already stopped projectile damaged a second layer'
$uncovered=Layer 50 $false;$exposed=[CRImpactModel]::Begin($p)
[CRImpactModel]::ApplyLayer($exposed,$uncovered)|Out-Null
Check ($exposed.remainingJ -eq 640 -and $uncovered.integrity -eq 1) 'Armor protected an uncovered region'
$cloth=Layer 0;$unarmored=[CRImpactModel]::Begin($p)
[CRImpactModel]::ApplyLayer($unarmored,$cloth)|Out-Null
Check ($unarmored.remainingJ -eq 640 -and $cloth.integrity -eq 1) 'Zero-resistance clothing provided magic protection'
$ap=[CRImpactModel]::Begin((Projectile 8 400 9 2));$apl=Layer
[CRImpactModel]::ApplyLayer($ap,$apl)|Out-Null
Check ($ap.remainingJ -gt $s.remainingJ) 'Penetration modifier reduced penetration'
$copy=[CRImpactModel]::CopyLayer($l);$preview=[CRImpactModel]::Begin($p);$old=$l.integrity
[CRImpactModel]::ApplyLayer($preview,$copy)|Out-Null
Check ($l.integrity -eq $old -and $copy.integrity -lt $old) 'Preview wore down real armor'
$worn=Layer;$worn.integrity=0.2;$wear=[CRImpactModel]::Begin($p)
[CRImpactModel]::ApplyLayer($wear,$worn)|Out-Null
Check ($wear.remainingJ -gt $s.remainingJ) 'Worn armor stopped more energy'
foreach($bad in @([float]::NaN,[float]::PositiveInfinity,-1)){
 $badP=Projectile;$badP.massGrams=$bad
 Check (-not ([CRImpactModel]::Begin($badP)).valid) 'Invalid projectile accepted'
 $badL=Layer;$badL.integrity=$bad;$before=$s.remainingJ
 Check (-not [CRImpactModel]::ApplyLayer($s,$badL) -and $s.remainingJ -eq $before) 'Invalid layer mutated an impact'
}
$drift=[CRImpactModel]::Begin($p);$drift.bluntJ=100
Check (-not [CRImpactModel]::ApplyLayer($drift,(Layer))) 'Corrupt energy state accepted'
$bounded=[CRImpactModel]::Begin($p)
for($n=0;$n -lt 32;$n++){[CRImpactModel]::ApplyLayer($bounded,(Layer 0))|Out-Null}
Check (-not [CRImpactModel]::ApplyLayer($bounded,(Layer 0)) -and $bounded.layersApplied -eq 32) 'Layer processing was unbounded'
$script:scenarios=0
foreach($mass in @(4,8,16)){foreach($speed in @(0,100,400,900)){foreach($diameter in @(5.5,9,12)){foreach($resistance in @(0,1,10,100)){foreach($factor in @(0.5,1,2)){
 $impact=[CRImpactModel]::Begin((Projectile $mass $speed $diameter $factor))
 foreach($fraction in @(0,0.1,1)){
  $layer=Layer $resistance $true $fraction
  if(-not [CRImpactModel]::ApplyLayer($impact,$layer) -or -not [CRImpactModel]::ValidState($impact)){throw 'Sweep found invalid or non-conserving impact'}
  if($layer.integrity -lt 0 -or $layer.integrity -gt 1){throw 'Sweep found armor condition outside bounds'}
 }
 $script:scenarios++
}}}}}
Check ($script:scenarios -eq 432) 'Impact sweep did not cover expected cases'
# Contact fixtures represent native mapped metadata, not synthetic physics hits.
$c=[CRHitContact]::new();$g=[CRHitEligibility]::new();$g.ranged=$true;$g.targetSupported=$true;$g.actualHealthDamage=10
[CRHitModel]::AddShape($c,2,2,$true,$false)|Out-Null
Check (-not [CRHitModel]::CanRoute($c,$g)) 'Protection-only contact became an injury region'
[CRHitModel]::AddShape($c,3,1,$false,$false)|Out-Null
Check ([CRHitModel]::CanRoute($c,$g) -and $c.region -eq 3 -and $c.hasProtectionLayer) 'Body contact behind protection lost its region'
[CRHitModel]::AddShape($c,2,1,$false,$false)|Out-Null
Check ($c.region -eq 3) 'One hit was reassigned to a deeper body region'
foreach($flag in @('projection','protectedHit','damageOverTime')){
 $g.$flag=$true;Check (-not [CRHitModel]::CanRoute($c,$g)) 'Excluded event became an injury';$g.$flag=$false
}
foreach($value in @(0,-1,[float]::NaN,[float]::PositiveInfinity)){
 $g.actualHealthDamage=$value;Check (-not [CRHitModel]::CanRoute($c,$g)) 'No/invalid actual health loss was accepted'
}
$g.actualHealthDamage=10;$g.targetSupported=$false
Check (-not [CRHitModel]::CanRoute($c,$g)) 'Unsupported target admitted'
$g.targetSupported=$true;$g.ranged=$false
Check (-not [CRHitModel]::CanRoute($c,$g)) 'Non-projectile event admitted to ballistic routing'
$g.ranged=$true
$unknown=[CRHitContact]::new()
[CRHitModel]::AddShape($unknown,0,0,$false,$false)|Out-Null
[CRHitModel]::AddShape($unknown,1,1,$false,$false)|Out-Null
Check ($unknown.region -eq 0 -and -not [CRHitModel]::CanRoute($unknown,$g)) 'Unknown shape silently became a head/torso hit'
$special=[CRHitContact]::new();[CRHitModel]::AddShape($special,1,1,$false,$true)|Out-Null
Check (-not [CRHitModel]::CanRoute($special,$g)) 'Special weakspot admitted as ordinary tissue'
$regions=0
foreach($region in 1..6){$r=[CRHitContact]::new();[CRHitModel]::AddShape($r,$region,1,$false,$false)|Out-Null;if([CRHitModel]::CanRoute($r,$g)){$regions++}}
Check ($regions -eq 6) 'Player/NPC shared policy omitted a region'
Check (-not [CRHitModel]::AddShape($c,7,1,$false,$false)) 'Unknown region code accepted'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;impactScenarios=$script:scenarios;sources=@($paths|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});scope='Original REDscript translated to float32 C#. Energy/armor accounting, coverage, wear, preview isolation, invalid input, bounded work and contact routing. Native callbacks, projectile/material calibration, injuries and real saves are not validated by these tests.'}) (Join-Path $project 'reports/combat-core-tests.json')
Write-Host "PASS: $script:checks combat checks and $script:scenarios impact scenarios."
