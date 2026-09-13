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
# Desired release authorities default on in the development profile, but every
# native acceptance gate defaults shut.
Check ($f.bodyEnabled -and $f.injuryEnabled -and $f.combatEnabled -and $f.armorEnabled -and $f.cyberwarePhysiologyEnabled -and $f.presentationEnabled) 'Desired release authority defaults changed.'
Check (-not $f.diagnosticsEnabled) 'Diagnostics development gate must default off.'
Check (-not [CRRuntimePolicyModel]::AnySimulation($f)) 'Development defaults bypassed closed acceptance gates.'
Check (-not [CRRuntimePolicyModel]::Presentation($f)) 'Presentation bypassed its acceptance gate.'
Check (-not [CRRuntimePolicyModel]::TraditionalHealthBars($f)) 'Fixed no-healthbar policy was not closed.'
Check (-not [CRRuntimePolicyModel]::Diagnostics($f)) 'Diagnostics bypassed its acceptance gate.'

$f.bodyAccepted = $true
Check ([CRRuntimePolicyModel]::Body($f)) 'Accepted body did not activate with development profile enabled.'
Check ([CRRuntimePolicyModel]::Nutrition($f) -and [CRRuntimePolicyModel]::Hydration($f) -and [CRRuntimePolicyModel]::Sleep($f) -and [CRRuntimePolicyModel]::Exertion($f)) 'Body development facets did not inherit master activation.'
$f.hydrationEnabled = $false
Check (-not [CRRuntimePolicyModel]::Hydration($f) -and [CRRuntimePolicyModel]::Nutrition($f)) 'One development facet disabled an unrelated process.'
$f.bodyEnabled = $false
Check (-not [CRRuntimePolicyModel]::Body($f) -and -not [CRRuntimePolicyModel]::Nutrition($f) -and -not [CRRuntimePolicyModel]::Sleep($f)) 'Body development gate off left body process active.'

$f.bodyEnabled = $true
$f.injuryAccepted = $true
$f.combatAccepted = $true
Check ([CRRuntimePolicyModel]::Combat($f) -and [CRRuntimePolicyModel]::Injury($f) -and [CRRuntimePolicyModel]::CombatInjury($f)) 'Accepted combat/injury pipeline did not compose.'
$f.injuryEnabled = $false
Check ([CRRuntimePolicyModel]::Combat($f) -and -not [CRRuntimePolicyModel]::Injury($f) -and -not [CRRuntimePolicyModel]::CombatInjury($f)) 'Development injury isolation incorrectly disabled combat or left wound bridge active.'
$f.injuryEnabled = $true
$f.combatEnabled = $false
Check (-not [CRRuntimePolicyModel]::Combat($f) -and [CRRuntimePolicyModel]::Injury($f) -and -not [CRRuntimePolicyModel]::CombatInjury($f)) 'Development combat isolation incorrectly disabled independent injury state.'

$f.combatEnabled = $true
$f.armorAccepted = $true
Check ([CRRuntimePolicyModel]::Armor($f) -and [CRRuntimePolicyModel]::ArmorWear($f) -and [CRRuntimePolicyModel]::CombatArmor($f)) 'Accepted armor did not compose with combat.'
$f.armorWearEnabled = $false
Check ([CRRuntimePolicyModel]::Armor($f) -and -not [CRRuntimePolicyModel]::ArmorWear($f) -and [CRRuntimePolicyModel]::CombatArmor($f)) 'Development armor-wear isolation disabled physical armor interception.'
$f.armorEnabled = $false
Check (-not [CRRuntimePolicyModel]::Armor($f) -and -not [CRRuntimePolicyModel]::CombatArmor($f)) 'Armor development gate off left combat armor active.'

$f.cyberwarePhysiologyAccepted = $true
Check ([CRRuntimePolicyModel]::CyberwarePhysiology($f)) 'Accepted cyberware physiology did not activate.'
$f.cyberwarePhysiologyEnabled = $false
Check (-not [CRRuntimePolicyModel]::CyberwarePhysiology($f)) 'Cyberware physiology development gate was ignored.'

$f.presentationAccepted = $true
Check ([CRRuntimePolicyModel]::Presentation($f) -and [CRRuntimePolicyModel]::Nameplates($f) -and [CRRuntimePolicyModel]::StatusCues($f)) 'Presentation development facets did not compose.'
Check (-not [CRRuntimePolicyModel]::TraditionalHealthBars($f)) 'Accepted presentation re-enabled traditional health bars.'
$f.nameplatesEnabled = $false
Check (-not [CRRuntimePolicyModel]::Nameplates($f) -and [CRRuntimePolicyModel]::StatusCues($f) -and -not [CRRuntimePolicyModel]::TraditionalHealthBars($f)) 'Nameplate development isolation affected unrelated presentation.'
$onlyPresentation = [CRRuntimeFeatureFlags]::new()
$onlyPresentation.presentationAccepted = $true
Check ([CRRuntimePolicyModel]::Presentation($onlyPresentation) -and -not [CRRuntimePolicyModel]::AnySimulation($onlyPresentation)) 'Presentation became a simulation authority.'

$f.diagnosticsAccepted = $true
Check (-not [CRRuntimePolicyModel]::Diagnostics($f)) 'Accepted diagnostics activated without explicit development intent.'
$f.diagnosticsEnabled = $true
Check ([CRRuntimePolicyModel]::Diagnostics($f)) 'Explicit attended diagnostics did not activate after acceptance.'

Write-Host "PASS: $script:checks runtime policy checks; development isolation cannot bypass native acceptance and traditional health bars remain fixed off."
