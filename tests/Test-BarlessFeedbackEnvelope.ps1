$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\InjuryEffectsHarness.ps1"
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

# With continuous HP hidden, severe injuries need to remain legible through their
# physical consequences. These are broad gameplay guardrails, not medical claims.
$c = [CRBodyConfig]::new()

$leg = [CRInjuryModel]::Create()
$leg.leftLeg.boneDamage = 0.8
$legEffect = [CRInjuryEffectsModel]::Read($leg,$c)
Check ($legEffect.valid) 'Severe leg injury produced invalid effects.'
Check ($legEffect.speed -le 0.55) 'Severe unsupported leg injury became too subtle for barless combat feedback.'
Check ($legEffect.reload -eq 1.0 -and $legEffect.recoil -eq 1.0 -and $legEffect.spread -eq 1.0) 'Leg injury leaked into unrelated weapon-handling feedback.'
[CRInjuryModel]::Treat($leg,5,3,1.0) | Out-Null
$supportedLeg = [CRInjuryEffectsModel]::Read($leg,$c)
Check ($supportedLeg.speed -gt $legEffect.speed -and $supportedLeg.speed -lt 0.8) 'Limb support does not produce a noticeable but incomplete functional improvement.'
Check ([Math]::Abs($leg.leftLeg.boneDamage - 0.8) -lt 0.00001) 'Support healed the underlying bone injury instead of improving function.'

$arm = [CRInjuryModel]::Create()
$arm.rightArm.tissueDamage = 0.8
$armEffect = [CRInjuryEffectsModel]::Read($arm,$c)
Check ($armEffect.valid) 'Severe arm injury produced invalid effects.'
Check ($armEffect.reload -ge 1.35) 'Severe arm injury reload consequence became too subtle for barless combat feedback.'
Check ($armEffect.recoil -ge 1.25 -and $armEffect.spread -ge 1.3) 'Severe arm injury weapon-control consequence became too subtle.'
Check ($armEffect.speed -eq 1.0) 'Arm injury incorrectly became a movement-speed cue.'

$head = [CRInjuryModel]::Create()
$head.head.tissueDamage = 0.8
$headEffect = [CRInjuryEffectsModel]::Read($head,$c)
Check ($headEffect.recoil -ge 1.25 -and $headEffect.spread -ge 1.5) 'Severe head injury lost substantial weapon-control feedback.'
Check ($headEffect.speed -eq 1.0 -and $headEffect.reload -eq 1.0) 'Head injury leaked into unrelated movement/reload effects.'

$torso = [CRInjuryModel]::Create()
$torso.torso.tissueDamage = 0.8
$torsoEffect = [CRInjuryEffectsModel]::Read($torso,$c)
Check ($torsoEffect.stamina -le 0.7 -and $torsoEffect.staminaRegen -le 0.8) 'Severe torso injury lost meaningful stamina feedback.'
Check ($torsoEffect.speed -eq 1.0) 'Torso injury incorrectly became a direct movement-speed cue.'

$blood = [CRInjuryModel]::Create()
$blood.bloodLostMl = $c.injuryBloodCapacityMl * 0.5
$blood.bloodDeficitMl = $blood.bloodLostMl
$bloodEffect = [CRInjuryEffectsModel]::Read($blood,$c)
Check ($bloodEffect.valid) 'Severe blood deficit produced invalid effects.'
Check ($bloodEffect.stamina -le 0.35 -and $bloodEffect.staminaRegen -le 0.25) 'Severe blood loss lost major stamina consequences.'
Check ($bloodEffect.speed -le 0.8 -and $bloodEffect.reload -ge 1.25) 'Severe blood loss became too subtle across movement/handling.'

# Healthy state remains completely neutral: removing HP bars is not permission to
# impose ambient penalties merely so the player can “feel” the system.
$healthy = [CRInjuryModel]::Create()
$neutral = [CRInjuryEffectsModel]::Read($healthy,$c)
Check ($neutral.valid -and $neutral.speed -eq 1.0 -and $neutral.stamina -eq 1.0 -and $neutral.staminaRegen -eq 1.0 -and $neutral.reload -eq 1.0 -and $neutral.recoil -eq 1.0 -and $neutral.spread -eq 1.0) 'Healthy actor has non-neutral barless feedback penalties.'

Write-JsonFile ([ordered]@{
    testedAtUtc = [DateTime]::UtcNow.ToString('o')
    passed = $true
    assertions = $script:checks
    representative = [ordered]@{
        severeLegSpeed = $legEffect.speed
        supportedLegSpeed = $supportedLeg.speed
        severeArmReload = $armEffect.reload
        severeArmRecoil = $armEffect.recoil
        severeArmSpread = $armEffect.spread
        severeHeadSpread = $headEffect.spread
        severeTorsoStamina = $torsoEffect.stamina
        severeBloodStamina = $bloodEffect.stamina
    }
    scope = 'Qualitative offline legibility guardrails for physical injury consequences when traditional HP is hidden. Does not prove native stat consumers, animation/audio feedback, accessibility, HUD rendering or subjective gameplay feel.'
}) (Join-Path (Get-ProjectRoot) 'reports/barless-feedback-envelope-tests.json')
Write-Host "PASS: $script:checks barless physical-feedback envelope checks."
