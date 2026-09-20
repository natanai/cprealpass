. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$nativePath=Join-Path $project 'src/redscript/CyberpunkRealism/CombatWoundsNative.reds'
$native=Get-Content -Raw $nativePath
$profilesPath=Join-Path $project 'src/redscript/CyberpunkRealism/CombatProfilesNative.reds'
$profilesNative=Get-Content -Raw $profilesPath
$classes=foreach($name in @('CRNativeWoundPlan','CRNPCInjuryBridge','CRNativeWoundBridge')){
 $match=[regex]::Match($native,'(?m)^public class '+$name+' extends IScriptable')
 if(-not $match.Success){throw "Missing native class $name"}
 $start=$native.IndexOf('{',$match.Index);$depth=1;$end=$start+1
 while($depth -gt 0 -and $end -lt $native.Length){if($native[$end] -eq '{'){$depth++};if($native[$end] -eq '}'){$depth--};$end++}
 if($depth -ne 0){throw 'Unbalanced source class'}
 $native.Substring($match.Index,$end-$match.Index)
}
$generated=Join-Path $project ('staging/native-wound-test-'+[guid]::NewGuid().ToString('N')+'.reds')
[IO.File]::WriteAllText($generated,($classes -join "`n"))
$paths=@('NPCBodyModel','ArmorWearModel','ImpactModel','HitModel','WoundModel','InjuryModel','BodyModel','SleepModel','BodyInputs','FieldCareModel')|ForEach-Object{Join-Path $project "src/redscript/CyberpunkRealism/$_.reds"}
$code=Convert-RedscriptCore ($paths+@($generated))
$code=$code.Replace('array emptyLosses<SDamageDealt>;','SDamageDealt[] emptyLosses = new SDamageDealt[0];').Replace('Cast<StatsObjectID>','').Replace('NotEquals(','NativeWoundFixture.NotEquals(').Replace('String','string')
$code=[regex]::Replace($code,'\bEntityID\b','string')
Add-Type -TypeDefinition ($code+(Get-Content -Raw "$PSScriptRoot/fixtures/NativeWounds.cs"))
$script:checks=0
function Check($condition,$message){if(-not $condition){throw $message};$script:checks++}
Check ($profilesNative.Contains('public let unmappedProtection: Int32;')) 'Native profile reader does not distinguish unmapped protection from structural failure'
Check ($profilesNative.Contains('CRCombatProfileReadiness.Ready(sample.referenceImpact, sample.unresolvedProtection, sample.unmappedProtection, IsDefined(player))')) 'Native profile reader bypasses the shared readiness policy'
Check ($profilesNative.Contains('CRCombatProfileReadiness.RequiresNativePhysicalCap(sample.unmappedProtection, IsDefined(player))')) 'Unmapped player gear is not bound to native physical capping'
Check (-not $profilesNative.Contains('sample.referenceReady = sample.unresolvedProtection == 0 &&')) 'Legacy all-or-nothing profile readiness veto remains active'
function Hit($player=$true,$region=2,$material=1){[NativeWoundFixture]::Hit($player,$region,$material,8,360)}
function Reset { [CRBodyRuntime]::instance=[CRBodyRuntime]::new();[CRCombatRuntimePolicy]::enabled=$true }
Reset
$hit=Hit
[CRNativeWoundBridge]::Prepare($hit)
Check ($null -ne $hit.crWoundPlan -and $hit.attackComputed.thermal -eq 7) 'Mapped physical proposal missing or nonphysical channel overwritten'
Check ([CRBodyRuntime]::Get().lastDiagnosticStage -eq 'prepare-ready') 'Accepted player proposal did not expose its bounded Prepare stage'
$proposal=$hit.crWoundPlan.proposedPhysical;$expected=$hit.crWoundPlan.wound.tissueDamage
Check ($proposal -gt 0 -and [CRBodyRuntime]::Get().queue.appliedWounds -eq 0) 'Preparation applied an unaccepted wound'
[CRNativeWoundBridge]::Prepare($hit)
Check ($hit.crWoundPlan.proposedPhysical -eq $proposal) 'Repeated preparation changed a proposal'
Check ([NativeWoundFixture]::Finish($hit,$proposal,$proposal)) 'Accepted hit did not commit a player wound'
Check ([CRBodyRuntime]::Get().lastDiagnosticStage -eq 'commit-ready') 'Accepted player hit did not expose its bounded Commit stage'
$body=[CRBodyRuntime]::Get().body
Check ($body.injuries.torso.tissueDamage -eq $expected -and [CRBodyRuntime]::Get().queue.appliedWounds -eq 1) 'Player wound did not reach ordered shared-body inputs'
Check (-not [NativeWoundFixture]::Finish($hit,$proposal,$proposal) -and [CRBodyRuntime]::Get().queue.appliedWounds -eq 1) 'Repeated post-damage notification committed twice'
# Impact determines wound severity; native max HP only scales the output channel.
Reset
$small=Hit;$large=Hit;$large.target.game.stats.maximumHealth=10000;$large.attackComputed.physical=9000
[CRNativeWoundBridge]::Prepare($small);[CRNativeWoundBridge]::Prepare($large)
Check ($small.crWoundPlan.wound.tissueDamage -eq $large.crWoundPlan.wound.tissueDamage -and [Math]::Abs($large.crWoundPlan.proposedPhysical/$small.crWoundPlan.proposedPhysical-100) -lt 0.001) 'Level/HP inflation changed the physical wound or preserved a sponge health pool'
# Player-only fallback for unmapped equipped protection preserves the existing
# native physical result as a conservative ceiling instead of vetoing the wound
# or replacing native protection semantics with an invented armor mapping.
Reset
$unknownProtection=Hit
$unknownProtection.attackComputed.physical=1
$unknownProtection.sample.profiles.nativePhysicalCap=$true
[CRNativeWoundBridge]::Prepare($unknownProtection)
$unknownPlan=$unknownProtection.crWoundPlan
$unknownApplied=$unknownProtection.attackComputed.physical
Check ($null -ne $unknownPlan -and $unknownPlan.nativePhysicalCap -and $unknownPlan.nativePhysicalBeforePrepare -eq 1) 'Unmapped player protection did not preserve bounded native-cap evidence'
Check ($unknownPlan.proposedPhysical -gt $unknownApplied -and $unknownApplied -eq 1) 'Unmapped player protection increased native physical damage or failed to retain the native ceiling'
$unknownExpected=$unknownPlan.wound.tissueDamage*($unknownApplied/$unknownPlan.proposedPhysical)
Check ([NativeWoundFixture]::Finish($unknownProtection,$unknownApplied,$unknownApplied)) 'Native-capped unmapped player hit failed to commit'
Check ([Math]::Abs([CRBodyRuntime]::Get().body.injuries.torso.tissueDamage-$unknownExpected) -lt 0.00001) 'Native physical cap did not proportionally constrain the accepted wound'

Reset
$capped=[NativeWoundFixture]::Hit($true,2,1,4,900);[CRNativeWoundBridge]::Prepare($capped);$w=$capped.crWoundPlan.wound;$proposal=$capped.crWoundPlan.proposedPhysical
Check ([NativeWoundFixture]::Finish($capped,$proposal*0.2,$proposal*0.2)) 'Native-capped hit failed to commit'
Check ([Math]::Abs([CRBodyRuntime]::Get().body.injuries.torso.tissueDamage-$w.tissueDamage*0.2) -lt 0.00001 -and [Math]::Abs([CRBodyRuntime]::Get().body.injuries.torso.internalBleedMlPerHour-$w.internalBleedMlPerHour*0.2) -lt 0.001) 'One-shot/boss cap did not reduce the downstream wound/bleed dose'
Reset
$fatal=Hit;[CRNativeWoundBridge]::Prepare($fatal);$proposal=$fatal.crWoundPlan.proposedPhysical
Check ([NativeWoundFixture]::Finish($fatal,$proposal,0.1) -and [CRBodyRuntime]::Get().body.injuries.torso.tissueDamage -eq $fatal.crWoundPlan.wound.tissueDamage) 'Low remaining HP weakened the terminal injury'
# Zero accepted physical HP, projected hits and flagged protections are not wounds.
foreach($case in @('no-physical-loss','post-protected','post-region','post-target')){
 Reset;$h=Hit;[CRNativeWoundBridge]::Prepare($h);$p=$h.crWoundPlan.proposedPhysical;$loss=$p
 switch($case){
  'no-physical-loss'{$loss=0}
  'post-protected'{$h.sample.eligibility.protectedHit=$true}
  'post-region'{$h.sample.contact.region=1}
  'post-target'{$h.sample.targetID='different-actor'}
 }
 Check (-not [NativeWoundFixture]::Finish($h,$p,$loss) -and [CRBodyRuntime]::Get().queue.appliedWounds -eq 0) "Invalid final hit committed: $case"
}
foreach($case in @('disabled','inactive-body','projection','protected','unmapped','unknown-shape','weakspot','no-physical','invalid-health','armor-body')){
 Reset;$h=Hit
 switch($case){
  'disabled'{[CRCombatRuntimePolicy]::enabled=$false}
  'inactive-body'{[CRBodyRuntime]::Get().allowed=$false}
  'projection'{$h.projectionPipeline=$true}
  'protected'{$h.sample.eligibility.protectedHit=$true}
  'unmapped'{$h.sample.profiles.referenceReady=$false}
  'unknown-shape'{$h.sample.contact.unknownShape=$true}
  'weakspot'{$h.sample.contact.specialShape=$true}
  'no-physical'{$h.attackComputed.physical=0}
  'invalid-health'{$h.target.game.stats.maximumHealth=[float]::NaN}
  'armor-body'{$h.sample.contact.material=2}
 }
 $old=$h.attackComputed.physical;[CRNativeWoundBridge]::Prepare($h)
 Check ($null -eq $h.crWoundPlan -and $h.attackComputed.physical -eq $old -and $h.attackComputed.thermal -eq 7) "Ineligible proposal changed damage: $case"
 if($case -eq 'armor-body'){Check ([CRBodyRuntime]::Get().lastDiagnosticStage -eq 'prepare-anatomy-rejected') 'Armor-body rejection is not distinguishable in attended diagnostics'}
}
Reset
$blocked=Hit;$layer=[CRProtectionLayer]::new();$layer.covered=$true;$layer.resistanceJPerMm2=1000
[CRImpactModel]::ApplyLayer($blocked.sample.profiles.referenceImpact,$layer)|Out-Null
[CRNativeWoundBridge]::Prepare($blocked)
Check ($blocked.attackComputed.physical -eq 0 -and $null -ne $blocked.crWoundPlan -and -not [NativeWoundFixture]::Finish($blocked,0,0)) 'Fully dissipated impact caused damage or wounds'
$blunt=Hit;$layer.bluntTransferFraction=0.1
[CRImpactModel]::ApplyLayer($blunt.sample.profiles.referenceImpact,$layer)|Out-Null
[CRNativeWoundBridge]::Prepare($blunt)
Check ($blunt.crWoundPlan.wound.tissueDamage -gt 0 -and $blunt.crWoundPlan.wound.externalBleedMlPerHour -eq 0) 'Stopped blunt impact manufactured an open projectile tract'
Check ($blunt.crWoundPlan.wound.internalBleedMlPerHour -eq 0) 'Minor blunt trauma became a persistent internal bleed'
$severe=[NativeWoundFixture]::Hit($true,2,1,10,1000);$layer.bluntTransferFraction=0.5
[CRImpactModel]::ApplyLayer($severe.sample.profiles.referenceImpact,$layer)|Out-Null
[CRNativeWoundBridge]::Prepare($severe)
Check ($severe.crWoundPlan.wound.externalBleedMlPerHour -eq 0 -and $severe.crWoundPlan.wound.internalBleedMlPerHour -gt 0) 'Severe blunt trauma could not produce internal injury independently of an open wound'
# Same impact model/region data on human NPCs; retain per-actor injury state.
Reset
$npcHit=Hit $false 5;[CRNativeWoundBridge]::Prepare($npcHit);$proposal=$npcHit.crWoundPlan.proposedPhysical
Check ([NativeWoundFixture]::Finish($npcHit,$proposal,$proposal) -and $npcHit.target.crInjurySchemaVersion -eq 2) 'Accepted NPC wound did not initialize per-actor state'
$npc=$npcHit.target;$prior=$npc.crInjuryBody.injuries.leftLeg.tissueDamage
Check ($prior -gt 0 -and $npc.crInjuryBody.injuries.rightLeg.tissueDamage -eq 0 -and [CRBodyRuntime]::Get().queue.appliedWounds -eq 0) 'NPC wound leaked into another region or V'
$second=Hit $false 4;$second.target=$npc;[CRNativeWoundBridge]::Prepare($second)
Check ([NativeWoundFixture]::Finish($second,$second.crWoundPlan.proposedPhysical,$second.crWoundPlan.proposedPhysical) -and $npc.crInjuryBody.injuries.leftLeg.tissueDamage -eq $prior -and $npc.crInjuryBody.injuries.rightArm.tissueDamage -gt 0) 'New NPC hit cleared earlier localized wounds'
$chrome=Hit $false 3 3;[CRNativeWoundBridge]::Prepare($chrome)
Check ([NativeWoundFixture]::Finish($chrome,$chrome.crWoundPlan.proposedPhysical,$chrome.crWoundPlan.proposedPhysical) -and $chrome.target.crInjuryBody.injuries.leftArm.cyberwareDamage -gt 0 -and $chrome.target.crInjuryBody.injuries.leftArm.tissueDamage -eq 0 -and $chrome.target.crInjuryBody.injuries.leftArm.externalBleedMlPerHour -eq 0) 'Mechanical hit created biological bleeding'
foreach($case in @('replacer','drone','future-schema','missing-saved-state','ambiguous-old-state')){
 $h=Hit $false
 switch($case){
  'replacer'{$h.target.replacer=$true}
  'drone'{$h.target.npcType=[gamedataNPCType]::Drone}
  'future-schema'{$h.target.crInjurySchemaVersion=3}
  'missing-saved-state'{$h.target.crInjurySchemaVersion=1}
  'ambiguous-old-state'{$h.target.crLocalizedInjuries=[CRInjuryModel]::Create()}
 }
 [CRNativeWoundBridge]::Prepare($h)
 Check ($null -eq $h.crWoundPlan -and $h.attackComputed.physical -eq 20) "Unsupported NPC state replaced: $case"
}
# Whole causal chain reaches the existing field-care and body-clock model.
Reset
$h=[NativeWoundFixture]::Hit($true,2,1,4,900);[CRNativeWoundBridge]::Prepare($h);[NativeWoundFixture]::Finish($h,$h.crWoundPlan.proposedPhysical,$h.crWoundPlan.proposedPhysical)|Out-Null
$runtime=[CRBodyRuntime]::Get();$runtime.config.injuryBloodRecoveryMlPerHour=0;$runtime.config.injuryExternalClotPerHourSquared=0
$external=$runtime.body.injuries.torso.externalBleedMlPerHour;$internal=$runtime.body.injuries.torso.internalBleedMlPerHour
[CRBodyInputs]::Time($runtime.queue,0.1,0,$false)|Out-Null;[CRBodyInputs]::Drain($runtime.queue,$runtime.body,$runtime.config)|Out-Null
$before=$runtime.body.injuries.bloodLostMl
Check ([Math]::Abs($before-0.1*($external+$internal)) -lt 0.05) 'Committed impact did not produce shared-clock bleeding'
$care=[CRFieldCareModel]::Prepare($runtime.body.injuries,2,2)
Check ([CRFieldCareModel]::Commit($care,$runtime.body.injuries)) 'Committed impact could not be treated by field-care model'
[CRBodyInputs]::Time($runtime.queue,0.1,0,$false)|Out-Null;[CRBodyInputs]::Drain($runtime.queue,$runtime.body,$runtime.config)|Out-Null
Check ([Math]::Abs($runtime.body.injuries.bloodLostMl-$before-0.1*$internal) -lt 0.05) 'Dressing failed to change subsequent bleeding or cured internal damage'
# Parameter sweep validates dose bounds and terminal/protection energy accounting.
$scenarios=0
foreach($region in 1..6){foreach($material in @(1,3,4)){foreach($speed in @(0,100,360,900,2000)){foreach($resistance in @(0,3,30)){
 $shot=[CRProjectileSpec]::new();$shot.massGrams=8;$shot.speedMetersPerSecond=$speed;$shot.diameterMm=9
 $impact=[CRImpactModel]::Begin($shot);$layer=[CRProtectionLayer]::new();$layer.covered=$true;$layer.resistanceJPerMm2=$resistance;$layer.bluntTransferFraction=0.1
 [CRImpactModel]::ApplyLayer($impact,$layer)|Out-Null
 $wound=[CRWoundModel]::Resolve($impact,[CRWoundModel]::Anatomy($region,$material))
 if(-not [CRWoundModel]::ValidWound($wound)){throw 'Sweep created an invalid wound'}
 if([Math]::Abs($wound.penetratingDepositJ+$wound.exitingJ+$wound.bluntJ+$impact.dissipatedJ-$impact.initialJ) -gt [Math]::Max(0.01,$impact.initialJ*0.00001)){throw 'Terminal mapping created/lost impact energy'}
 if($material -ne 1 -and ($wound.tissueDamage -ne 0 -or $wound.externalBleedMlPerHour -ne 0 -or $wound.internalBleedMlPerHour -ne 0)){throw 'Mechanical sweep created biology'}
 $scenarios++
}}}}
Check ($scenarios -eq 270) 'Parameter sweep incomplete'
foreach($bad in @([float]::NaN,[float]::PositiveInfinity,-1)){
 $profile=[CRWoundModel]::Anatomy(2,1);$profile.depositFraction=$bad
 Check (-not [CRWoundModel]::ValidProfile($profile)) 'Invalid anatomy parameter accepted'
}
# Armor wear is gated independently of injury, and may accept our own full stop.
Reset
$h=Hit;$h.sample.profiles.armorWear=[CRArmorWearPlan]::new()
[CRNativeWoundBridge]::Prepare($h);$p=$h.crWoundPlan.proposedPhysical
Check ([NativeWoundFixture]::Finish($h,$p*0.2,$p*0.2) -and $h.crWoundPlan.armorCommitted -and $h.sample.profiles.armorWear.commits -eq 1) 'Accepted capped hit failed to commit armor wear'
Check (-not [NativeWoundFixture]::Finish($h,$p,$p) -and $h.sample.profiles.armorWear.commits -eq 1) 'Repeated native event wore armor twice'
foreach($case in @('full-stop','native-protection','protected','projection','unacknowledged','post-target')){
 Reset;$h=Hit;$h.sample.profiles.armorWear=[CRArmorWearPlan]::new()
 $impact=$h.sample.profiles.referenceImpact;$impact.dissipatedJ=$impact.initialJ;$impact.remainingJ=0
 [CRNativeWoundBridge]::Prepare($h)
 Check ($h.crWoundPlan.proposedPhysical -eq 0) 'Full dissipation produced a nonzero physical injury proposal'
 switch($case){
  'native-protection'{$h.sample.contact.hasProtectionLayer=$true}
  'protected'{$h.sample.eligibility.protectedHit=$true}
  'projection'{$h.projectionPipeline=$true}
  'post-target'{$h.sample.targetID='different-target'}
 }
 if($case -eq 'unacknowledged'){$result=[CRNativeWoundBridge]::Commit($h,$h.sample)}else{$result=[NativeWoundFixture]::Finish($h,0,0)}
 Check (-not $result -and [CRBodyRuntime]::Get().queue.appliedWounds -eq 0) "Zero physical injury generated a wound: $case"
 Check ($h.crWoundPlan.armorCommitted -eq ($case -eq 'full-stop') -and $h.sample.profiles.armorWear.commits -eq [int]($case -eq 'full-stop')) "Armor stop acceptance mismatch: $case"
}
Reset;$h=Hit;$h.sample.profiles.armorWear=[CRArmorWearPlan]::new();[CRNativeWoundBridge]::Prepare($h)
Check (-not [NativeWoundFixture]::Finish($h,0,0) -and -not $h.crWoundPlan.armorCommitted) 'Downstream damage nullification wore armor'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;parameterScenarios=$scenarios;sources=@(($paths+@($nativePath,$profilesPath))|ForEach-Object{[ordered]@{path=$_;sha256=(Get-Sha256 $_)}});fixtureSha256=Get-Sha256 "$PSScriptRoot/fixtures/NativeWounds.cs";scope='Actual original wound model and native prepare/commit/NPC methods translated to float32 C#, with typed native boundaries. Covers damage output, cap reconciliation, eligibility, exactly-once commitment, NPC schema/region handling and body/field-care chronology. Hit metadata/equipment reads, native cap execution, saves/streaming, engine effects and calibration remain unverified.'}) (Join-Path $project 'reports/wound-pipeline-tests.json')
Write-Host "PASS: $script:checks wound pipeline checks and $scenarios parameter scenarios."
