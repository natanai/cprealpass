$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project = Get-ProjectRoot
$paths = @('ImpactModel','BallisticProfiles','WoundModel') | ForEach-Object { Join-Path $project "src/redscript/CyberpunkRealism/$_.reds" }
Add-Type -TypeDefinition (Convert-RedscriptCore $paths)
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Wound([int]$family,[int]$region,[int]$material=1,[float]$distance=0) {
    $profile = [CRBallisticProfiles]::Family($family)
    $projectile = [CRBallisticProfiles]::Projectile($profile,$distance,0,0)
    $impact = [CRImpactModel]::Begin($projectile)
    return [CRWoundModel]::Resolve($impact,[CRWoundModel]::Anatomy($region,$material))
}

# These are intentionally broad qualitative guardrails, not medical probability
# claims. Their job is to prevent future tuning from drifting back toward arcade HP
# sponge behavior while the native feel test remains pending.
$handgunTorso = Wound 1 2
$rifleTorso = Wound 3 2
$rifleHead = Wound 3 1
$rifleArm = Wound 3 3
$rifleLeg = Wound 3 5

Check ([CRWoundModel]::ValidWound($handgunTorso)) 'Representative handgun torso wound is invalid.'
Check ([CRWoundModel]::ValidWound($rifleTorso)) 'Representative rifle torso wound is invalid.'
Check ([CRWoundModel]::ValidWound($rifleHead)) 'Representative rifle head wound is invalid.'
Check ($rifleHead.nativeHealthFraction -ge 1.0) 'Close unarmored rifle head hit drifted below a catastrophic native-output envelope.'
Check ($rifleHead.tissueDamage -ge 0.95) 'Close unarmored rifle head hit no longer produces catastrophic tissue injury.'
Check ($rifleTorso.tissueDamage -ge 0.9) 'Close unarmored rifle torso hit no longer produces severe tissue injury.'
Check ($rifleTorso.internalBleedMlPerHour -gt 0) 'Severe rifle torso injury lost internal-bleeding consequence.'
Check ($rifleTorso.nativeHealthFraction -gt $handgunTorso.nativeHealthFraction) 'Representative rifle torso hit is not more severe than handgun torso hit.'
Check ($handgunTorso.nativeHealthFraction -gt 0.1 -and $handgunTorso.nativeHealthFraction -lt 0.6) 'Handgun torso impact left the intended meaningful-but-not-forced-instant-death envelope.'
Check ($handgunTorso.tissueDamage -gt 0 -and $handgunTorso.externalBleedMlPerHour -gt 0) 'Handgun torso hit became trivial despite penetrating tissue.'
Check ($rifleArm.nativeHealthFraction -lt $rifleTorso.nativeHealthFraction) 'Arm hit became as globally lethal as torso hit.'
Check ($rifleLeg.nativeHealthFraction -lt $rifleTorso.nativeHealthFraction) 'Leg hit became as globally lethal as torso hit.'
Check ($rifleArm.tissueDamage -gt 0 -and $rifleLeg.tissueDamage -gt 0) 'Rifle limb hit lost localized physical injury.'

# Max HP changes only the engine output amount, never the physical wound itself.
$smallHP = [CRWoundModel]::NativeDamage($rifleTorso,100)
$largeHP = [CRWoundModel]::NativeDamage($rifleTorso,10000)
Check ([Math]::Abs($largeHP / $smallHP - 100.0) -lt 0.001) 'Native output no longer scales proportionally with max HP.'
$repeat = Wound 3 2
Check ([Math]::Abs($repeat.tissueDamage - $rifleTorso.tissueDamage) -lt 0.00001) 'Physical wound changed without any physical input changing.'
Check ([Math]::Abs($repeat.internalBleedMlPerHour - $rifleTorso.internalBleedMlPerHour) -lt 0.001) 'Bleeding severity changed without a physical-input change.'

# Reference torso protection must stop a representative handgun while allowing a
# rifle-class threat to remain qualitatively distinct. A stopped projectile can
# transfer blunt load but cannot create an open projectile tract.
$plate = [CRProtectionProfile]::new()
$plate.mapped = $true
$plate.torso = $true
$plate.resistanceJPerMm2 = 20
$plate.durabilityJ = 10000
$plate.bluntTransferFraction = 0.1
$handgunImpact = [CRImpactModel]::Begin([CRBallisticProfiles]::Projectile([CRBallisticProfiles]::Family(1),0,0,0))
$rifleImpact = [CRImpactModel]::Begin([CRBallisticProfiles]::Projectile([CRBallisticProfiles]::Family(3),0,0,0))
[CRImpactModel]::ApplyLayer($handgunImpact,[CRCoverageModel]::Layer($plate,2,1)) | Out-Null
[CRImpactModel]::ApplyLayer($rifleImpact,[CRCoverageModel]::Layer($plate,2,1)) | Out-Null
$stopped = [CRWoundModel]::Resolve($handgunImpact,[CRWoundModel]::Anatomy(2,1))
$penetrated = [CRWoundModel]::Resolve($rifleImpact,[CRWoundModel]::Anatomy(2,1))
Check ($handgunImpact.remainingJ -eq 0) 'Reference torso protection no longer stops representative handgun threat.'
Check ($stopped.externalBleedMlPerHour -eq 0) 'Stopped handgun projectile manufactured an open bleeding tract.'
Check ($stopped.tissueDamage -gt 0) 'Stopped handgun impact lost all blunt-trauma consequence.'
Check ($rifleImpact.remainingJ -gt 0) 'Reference handgun-oriented protection unexpectedly became rifle-proof.'
Check ($penetrated.externalBleedMlPerHour -gt 0) 'Penetrating rifle impact lost open-wound consequence.'

# Mechanical/cybernetic struck material can be damaged but never creates biological
# bleeding solely because a health resource exists underneath it.
$chrome = Wound 3 3 3
Check ($chrome.cyberwareDamage -gt 0) 'Representative cyberware limb hit lost structural damage.'
Check ($chrome.tissueDamage -eq 0 -and $chrome.boneDamage -eq 0) 'Mechanical hit manufactured biological tissue/bone damage.'
Check ($chrome.externalBleedMlPerHour -eq 0 -and $chrome.internalBleedMlPerHour -eq 0) 'Mechanical hit manufactured biological bleeding.'

# Distance may reduce severity through physical speed loss, but can never increase it.
$near = Wound 3 2 1 0
$far = Wound 3 2 1 900
Check ($far.penetratingDepositJ -lt $near.penetratingDepositJ) 'Long-range representative rifle hit gained deposited energy.'
Check ($far.nativeHealthFraction -le $near.nativeHealthFraction) 'Long-range representative rifle hit became more globally severe.'

Write-JsonFile ([ordered]@{
    testedAtUtc = [DateTime]::UtcNow.ToString('o')
    passed = $true
    assertions = $script:checks
    representative = [ordered]@{
        handgunTorsoNativeFraction = $handgunTorso.nativeHealthFraction
        rifleTorsoNativeFraction = $rifleTorso.nativeHealthFraction
        rifleHeadNativeFraction = $rifleHead.nativeHealthFraction
        rifleArmNativeFraction = $rifleArm.nativeHealthFraction
        rifleLegNativeFraction = $rifleLeg.nativeHealthFraction
    }
    sources = @($paths | ForEach-Object { [ordered]@{path=$_;sha256=(Get-Sha256 $_)} })
    scope = 'Qualitative offline combat-feel guardrails over project-original float32-translated models. Prevents regression toward HP-sponge tuning but does not establish clinical outcomes, native weapon mapping, actual armor identity, boss behavior, hit-shape fidelity or in-game feel.'
}) (Join-Path $project 'reports/combat-feel-envelope-tests.json')
Write-Host "PASS: $script:checks qualitative combat-feel envelope checks."
