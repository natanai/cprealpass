. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/RuntimePolicyModel.reds'
Add-Type -TypeDefinition (Convert-RedscriptCore @($path))
$script:checks = 0
function Check($condition,[string]$message){ if(-not $condition){throw $message}; $script:checks++ }

Check (-not [CRRuntimePolicyModel]::Body($null)) 'Null flags activated body.'
Check (-not [CRRuntimePolicyModel]::Combat($null)) 'Null flags activated combat.'
Check (-not [CRRuntimePolicyModel]::AnySimulation($null)) 'Null flags activated simulation.'

$f = [CRRuntimeFeatureFlags]::new()
# Public-intent defaults are on, but every development acceptance gate defaults shut.
Check ($f.bodyEnabled -and $f.injuryEnabled -and $f.combatEnabled -and $f.armorEnabled -and $f.cyberwarePhysiologyEnabled -and $f.presentationEnabled) 'Intended release module defaults changed.'
Check (-not $f.diagnosticsEnabled) 'Diagnostics player intent must default off.'
Check (-not [CRRuntimePolicyModel]::AnySimulation($f)) 'Player defaults bypassed closed acceptance gates.'
Check (-not [CRRuntimePolicyModel]::Presentation($f)) 'Presentation bypassed its acceptance gate.'
Check (-not [CRRuntimePolicyModel]::Diagnostics($f)) 'Diagnostics bypassed its acceptance gate.'

$f.bodyAccepted = $true
Check ([CRRuntimePolicyModel]::Body($f)) 'Accepted body did not activate with player default.'
Check ([CRRuntimePolicyModel]::Nutrition($f) -and [CRRuntimePolicyModel]::Hydration($f) -and [CRRuntimePolicyModel]::Sleep($f) -and [CRRuntimePolicyModel]::Exertion($f)) 'Body subtoggles did not inherit master activation.'
$f.hydrationEnabled = $false
Check (-not [CRRuntimePolicyModel]::Hydration($f) -and [CRRuntimePolicyModel]::Nutrition($f)) 'One body subtoggle disabled an unrelated process.'
$f.bodyEnabled = $false
Check (-not [CRRuntimePolicyModel]::Body($f) -and -not [CRRuntimePolicyModel]::Nutrition($f) -and -not [CRRuntimePolicyModel]::Sleep($f)) 'Body master off left body process active.'

$f.bodyEnabled = $true
$f.injuryAccepted = $true
$f.combatAccepted = $true
Check ([CRRuntimePolicyModel]::Combat($f) -and [CRRuntimePolicyModel]::Injury($f) -and [CRRuntimePolicyModel]::CombatInjury($f)) 'Accepted combat/injury pipeline did not compose.'
$f.injuryEnabled = $false
Check ([CRRuntimePolicyModel]::Combat($f) -and -not [CRRuntimePolicyModel]::Injury($f) -and -not [CRRuntimePolicyModel]::CombatInjury($f)) 'Disabling injury incorrectly disabled combat or left wound bridge active.'
$f.injuryEnabled = $true
$f.combatEnabled = $false
Check (-not [CRRuntimePolicyModel]::Combat($f) -and [CRRuntimePolicyModel]::Injury($f) -and -not [CRRuntimePolicyModel]::CombatInjury($f)) 'Disabling combat incorrectly disabled independent injury state.'

$f.combatEnabled = $true
$f.armorAccepted = $true
Check ([CRRuntimePolicyModel]::Armor($f) -and [CRRuntimePolicyModel]::ArmorWear($f) -and [CRRuntimePolicyModel]::CombatArmor($f)) 'Accepted armor did not compose with combat.'
$f.armorWearEnabled = $false
Check ([CRRuntimePolicyModel]::Armor($f) -and -not [CRRuntimePolicyModel]::ArmorWear($f) -and [CRRuntimePolicyModel]::CombatArmor($f)) 'Armor wear toggle disabled physical armor interception.'
$f.armorEnabled = $false
Check (-not [CRRuntimePolicyModel]::Armor($f) -and -not [CRRuntimePolicyModel]::CombatArmor($f)) 'Armor master off left combat armor active.'

$f.cyberwarePhysiologyAccepted = $true
Check ([CRRuntimePolicyModel]::CyberwarePhysiology($f)) 'Accepted cyberware physiology did not activate.'
$f.cyberwarePhysiologyEnabled = $false
Check (-not [CRRuntimePolicyModel]::CyberwarePhysiology($f)) 'Cyberware physiology player toggle was ignored.'

$f.presentationAccepted = $true
Check ([CRRuntimePolicyModel]::Presentation($f) -and [CRRuntimePolicyModel]::Nameplates($f) -and [CRRuntimePolicyModel]::StatusCues($f)) 'Presentation subtoggles did not compose.'
$f.nameplatesEnabled = $false
Check (-not [CRRuntimePolicyModel]::Nameplates($f) -and [CRRuntimePolicyModel]::StatusCues($f)) 'Nameplate toggle affected unrelated presentation.'
# Presentation never makes AnySimulation true by itself.
$onlyPresentation = [CRRuntimeFeatureFlags]::new()
$onlyPresentation.presentationAccepted = $true
Check ([CRRuntimePolicyModel]::Presentation($onlyPresentation) -and -not [CRRuntimePolicyModel]::AnySimulation($onlyPresentation)) 'Presentation became a simulation authority.'

$f.diagnosticsAccepted = $true
Check (-not [CRRuntimePolicyModel]::Diagnostics($f)) 'Accepted diagnostics activated without explicit player/developer intent.'
$f.diagnosticsEnabled = $true
Check ([CRRuntimePolicyModel]::Diagnostics($f)) 'Explicit attended diagnostics did not activate after acceptance.'

Write-Host "PASS: $script:checks runtime policy checks; player intent cannot bypass acceptance and module toggles remain independent."
