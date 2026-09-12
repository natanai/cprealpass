$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$path = Join-Path $project 'manifest/runtime-modules.json'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing manifest/runtime-modules.json' }

$contract = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($contract.schemaVersion -ne 1) { throw 'Unexpected runtime module schema version.' }
if ($contract.product -ne 'realpass') { throw 'Runtime module contract must identify realpass.' }
if ($contract.internalCore.id -ne 'core' -or $contract.internalCore.playerToggle -ne $false) {
    throw 'Core must be an internal, non-player gameplay substrate.'
}

$required = @('body','injury','combat','armor','cyberwarePhysiology','presentation','diagnostics')
$modules = @($contract.modules)
if ($modules.Count -ne $required.Count) { throw "Expected $($required.Count) public/runtime modules; found $($modules.Count)." }

$ids = @{}
$keys = @{}
foreach ($module in $modules) {
    if ([string]::IsNullOrWhiteSpace($module.id)) { throw 'Module without id.' }
    if ($ids.ContainsKey($module.id)) { throw "Duplicate module id: $($module.id)" }
    $ids[$module.id] = $module
    if ([string]::IsNullOrWhiteSpace($module.settingsKey)) { throw "Missing settings key: $($module.id)" }
    if ($keys.ContainsKey($module.settingsKey)) { throw "Duplicate settings key: $($module.settingsKey)" }
    $keys[$module.settingsKey] = $true
    if ($module.settingsKey -ne ($module.id + '.enabled')) { throw "Unexpected settings key for $($module.id): $($module.settingsKey)" }
    if ([string]::IsNullOrWhiteSpace($module.disableContract)) { throw "Missing disable contract: $($module.id)" }
    if (@($module.owns).Count -eq 0) { throw "Module owns no phenomenon: $($module.id)" }
    foreach ($dependency in @($module.requires)) {
        if ($dependency -ne 'core' -and -not $ids.ContainsKey($dependency) -and $required -notcontains $dependency) {
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

if ($ids.diagnostics.releaseDefault -ne $false) { throw 'Diagnostics must default off.' }
if ($ids.diagnostics.playerFacing -ne $false) { throw 'Diagnostics is a development surface, not a normal gameplay feature.' }
if ($ids.presentation.owns -contains 'simulation-state') { throw 'Presentation must not own simulation state.' }
if (@($ids.combat.subtoggles).Count -ne 0) { throw 'Combat currently has no approved player-facing sub-toggle split.' }

$outOfScope = @($contract.outOfScope)
foreach ($forbidden in @('weather-control','economy-rebalance','added-outfit-or-transmog-system')) {
    if ($outOfScope -notcontains $forbidden) { throw "Scope exclusion missing: $forbidden" }
}
foreach ($module in $modules) {
    if ($outOfScope -contains $module.id) { throw "Out-of-scope feature exposed as module: $($module.id)" }
}

# Dependency graph cycle check across hard requirements. Read-only presentation dependencies
# are intentionally not treated as activation requirements.
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

Write-Host "PASS: realpass runtime module contract ($($modules.Count) modules, $($outOfScope.Count) explicit exclusions)."
