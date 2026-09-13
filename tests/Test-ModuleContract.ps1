$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/runtime-modules.json'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing manifest/runtime-modules.json' }

$contract = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($contract.schemaVersion -ne 2) { throw 'Unexpected runtime module schema version.' }
if ($contract.product -ne 'realpass') { throw 'Runtime module contract must identify realpass.' }
if ($contract.releaseMode -ne 'locked-authored-experience') { throw 'Runtime modules must describe the locked release product.' }
if ($contract.internalCore.id -ne 'core' -or $contract.internalCore.developmentGate -ne $false -or $contract.internalCore.releaseEnabled -ne $true) {
    throw 'Core must be an internal always-present substrate, not a player/development feature toggle.'
}

$required = @('body','injury','combat','armor','cyberwarePhysiology','presentation','diagnostics')
$modules = @($contract.modules)
if ($modules.Count -ne $required.Count) { throw "Expected $($required.Count) internal authorities; found $($modules.Count)." }

$ids = @{}
$gates = @{}
foreach ($module in $modules) {
    if ([string]::IsNullOrWhiteSpace($module.id)) { throw 'Module without id.' }
    if ($ids.ContainsKey($module.id)) { throw "Duplicate module id: $($module.id)" }
    $ids[$module.id] = $module
    if ($module.playerFacingToggle -ne $false) { throw "Core authority exposed as player toggle: $($module.id)" }
    if ([string]::IsNullOrWhiteSpace([string]$module.developmentGate)) { throw "Missing development gate: $($module.id)" }
    if ($gates.ContainsKey($module.developmentGate)) { throw "Duplicate development gate: $($module.developmentGate)" }
    $gates[$module.developmentGate] = $true
    if ([string]::IsNullOrWhiteSpace($module.isolationContract)) { throw "Missing isolation contract: $($module.id)" }
    if (@($module.owns).Count -eq 0) { throw "Module owns no phenomenon: $($module.id)" }
    foreach ($dependency in @($module.requires)) {
        if ($dependency -ne 'core' -and $required -notcontains $dependency) {
            throw "Unknown required module '$dependency' from $($module.id)."
        }
    }
    foreach ($read in @($module.reads)) {
        if ($read -ne 'core' -and $required -notcontains $read) {
            throw "Unknown read dependency '$read' from $($module.id)."
        }
    }
}

foreach ($id in $required) {
    if (-not $ids.ContainsKey($id)) { throw "Required module missing: $id" }
}
foreach ($id in @('body','injury','combat','armor','cyberwarePhysiology','presentation')) {
    if ($ids[$id].releaseEnabled -ne $true) { throw "Gameplay/presentation authority is not locked on for release: $id" }
}
if ($ids.diagnostics.releaseEnabled -ne $false) { throw 'Diagnostics must be locked off for release.' }
if ($ids.presentation.fixedReleaseChoices.traditionalActorHealthBars -ne $false) { throw 'Traditional actor health bars must be locked off.' }
if ($ids.presentation.fixedReleaseChoices.nativeModernScanner -ne $true) { throw 'Modern native scanner must remain the release authority.' }

$outOfScope = @($contract.outOfScope)
foreach ($forbidden in @('weather-control','economy-rebalance','added-outfit-or-transmog-system','public-gameplay-module-toggles','public-balance-slider-matrix')) {
    if ($outOfScope -notcontains $forbidden) { throw "Scope exclusion missing: $forbidden" }
}

# Hard-requirement graph must remain acyclic. Read-only presentation dependencies
# do not activate another authority and are intentionally excluded from the graph.
function Visit([string]$id, [hashtable]$visiting, [hashtable]$visited) {
    if ($id -eq 'core') { return }
    if ($visited.ContainsKey($id)) { return }
    if ($visiting.ContainsKey($id)) { throw "Runtime module requirement cycle at $id" }
    $visiting[$id] = $true
    foreach ($dependency in @($ids[$id].requires)) { Visit $dependency $visiting $visited }
    $visiting.Remove($id)
    $visited[$id] = $true
}
$visited = @{}
foreach ($id in $required) { Visit $id @{} $visited }

Write-Host "PASS: realpass internal module contract ($($modules.Count) authorities); accepted release gameplay is locked on, diagnostics off, no public subsystem toggles."
