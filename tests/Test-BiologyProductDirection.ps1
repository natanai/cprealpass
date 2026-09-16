$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing Biology direction file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}
function Reject([string]$text,[string]$pattern,[string]$message) {
    if ($text -match $pattern) { throw $message }
}

$agents = Read 'AGENTS.md'
$goals = Read 'AGREED-GOALS.md'
$migration = Read 'docs/BIOLOGY-REDMOD-MIGRATION.md'
$parallel = Read 'docs/PARALLEL-AGENT-WORKFLOW.md'
$roadmap = Read 'docs/ACTIVE-REDMOD-ROADMAP.md'
$release = Read 'docs/RELEASE-ARCHITECTURE.md'
$settings = Read 'docs/SETTINGS-ARCHITECTURE.md'
$history = Read 'docs/DECISION-HISTORY.md'
$rootRoadmap = Read 'ROADMAP.md'
$operator = Read 'docs/LOCAL-OPERATOR-COMMANDS.md'

Require $agents '^# Biology agent instructions' 'AGENTS.md must identify Biology as the current product.'
Require $agents 'PARALLEL WORK GATE' 'AGENTS.md must make parallel work a prominent gate.'
Require $agents '2–3 agents concurrently|2-3 agents concurrently' 'AGENTS.md must acknowledge concurrent worker capacity.'
Require $agents 'copy/paste-ready handoff' 'Agents must proactively provide handoffs for safe parallel work.'
Require $agents 'own branch' 'Parallel assignments must use separate branches.'
Require $agents 'official REDmod' 'AGENTS.md must make official REDmod the preferred route where robust.'
Require $agents 'mods/Biology' 'AGENTS.md must expose the preferred self-contained package identity.'

Require $goals '^# Biology — agreed goals ledger' 'Canonical goals must use Biology product identity.'
Require $goals 'G-005 — “Biology” is the organizing product concept' 'Goals must define Biology as the whole-overhaul concept.'
Require $goals 'G-013 — Official REDmod is the preferred final packaging/runtime route' 'Goals must lock REDmod-first direction.'
Require $goals 'G-014 — Minimize dependency depth' 'Goals must lock dependency minimization.'
Require $goals 'G-015 — Biology is authoritative where it intentionally overlaps' 'Goals must describe bounded authoritative overlap.'
Require $goals 'G-016 — Final package identity should be self-contained and obvious' 'Goals must require self-contained package identity.'
Require $goals 'G-017 — Investigate Cyberpunk/CDPR''s official capability before inheriting the modding ecosystem''s workaround' 'Goals must lock official-source-first investigation before community workaround adoption.'
Require $goals 'G-093 — Parallel agents are a normal project resource' 'Goals must preserve parallel-development policy.'

foreach ($classification in @('REDMOD-NATIVE','REDMOD-POSSIBLE-BUT-BRITTLE','REDSCRIPT-BETTER','REQUIRES-NATIVE-EXTENSION','REMOVE/RETHINK','UNKNOWN — NEEDS DIRECT GAME PROBE')) {
    Require $migration ([regex]::Escape($classification)) "Missing REDmod routing classification: $classification"
}
Require $migration 'Official-source-first investigation gate' 'Migration architecture must define the official-source-first investigation gate.'
Require $migration 'community/modder solution.*not evidence|Established community practice is not proof' 'Migration architecture must reject community convention as proof of necessity.'
Require $migration 'Probe-OfficialRedmod\.ps1' 'Migration architecture must expose the direct installed REDmod capability probe.'
Require $migration 'REDmod-first does not mean REDmod-only|Official-source-first does \*\*not\*\* mean blindly' 'Migration architecture must explicitly reject ideological REDmod-only routing.'
Require $migration 'does not survive because an older build happened to use it|does not survive merely because' 'Migration architecture must reject inherited dependency entitlement.'
Require $migration 'does \*\*not\*\* define current worker branch names|does not.*current worker branch names' 'Architecture docs must not become a stale active branch ledger.'
Require $migration 'Uninstall Biology\.exe' 'Migration architecture must include the player-facing hard-uninstall target.'

Require $operator 'Command 9 — ask the installed official REDmod tool what it can do' 'Operator catalog must provide a direct official REDmod probe.'
Require $operator 'community.*fallback|community/modder route is necessary' 'Operator catalog must treat community practice as fallback evidence.'

# Validate durable parallel-work semantics, not exact heading text.
Require $parallel 'Core parallelism rule|Core rule' 'Parallel workflow must define proactive parallel splitting.'
Require $parallel 'identify separable work|identify separable lanes' 'Parallel workflow must tell agents to identify independent work.'
Require $parallel 'Do not split two implementations|Do not parallelize.*same core file|must continuously edit the same core file' 'Parallel workflow must define unsafe parallelism.'
Require $parallel 'Required handoff packet' 'Parallel workflow must define handoff contents.'
Require $parallel 'one release-shaped build|one attended combined test|one release-shaped candidate' 'Parallel workers must converge before ordinary player-facing testing.'
Require $parallel 'Current work lookup rule' 'Parallel workflow must direct agents to live ledger/roadmap/issues instead of hard-coded branches.'

Require $roadmap '#39' 'Active roadmap must expose Biology UI attended follow-up.'
Require $roadmap '#40' 'Active roadmap must expose E3 presentation attended follow-up.'
Require $roadmap '#41' 'Active roadmap must expose body-runtime attended follow-up.'
Require $roadmap '#44' 'Active roadmap must expose player disable/uninstall follow-up.'
Require $rootRoadmap 'official REDmod.*recognized|REDmod.*recognition' 'Root roadmap must record the accepted REDmod foundation milestone.'

Require $release '^# Biology release and installation architecture' 'Release architecture must use Biology identity.'
Require $release 'mods/Biology' 'Release target must prefer one Biology REDmod package.'
Require $release 'REDmod-first does not mean REDmod-only' 'Release architecture must preserve the narrow-wrapper exception.'

Require $settings '^# Biology configuration architecture' 'Settings architecture must use Biology identity.'
Require $settings 'Biology-owned persistence and editor' 'Settings architecture must identify the self-contained persistence/editor authority.'
Require $settings 'There is no second persisted.*Enable Biology|There is no saved `Enable Biology` Boolean' 'Settings architecture must eliminate the redundant live whole-mod preference.'
Require $settings 'Mod Settings.*removed|external settings-provider stack has been removed' 'Settings architecture must record Mod Settings exit.'
Require $settings 'ArchiveXL.*removed' 'Settings architecture must record ArchiveXL exit.'
Require $settings 'RED4ext.*removed' 'Settings architecture must record RED4ext exit.'
Require $settings 'one editable Boolean|exactly \*\*one editable Boolean\*\*' 'Settings architecture must constrain the player-facing surface to one E3 preference.'

Require $history 'the product is named Biology' 'Decision history must record the product rename.'
Require $history 'multi-agent parallel branches are the normal workflow' 'Decision history must record the parallel-development decision.'
Require $history 'official REDmod should be the default route' 'Decision history must record the REDmod-first correction.'
Require $history 'official Cyberpunk/REDmod capability must be investigated before inheriting the modder workaround' 'Decision history must record the strengthened official-source-first correction.'

$activeDocs = @($rootRoadmap,$roadmap,$migration,$parallel) -join "`n"
foreach ($oldBranch in @('agent/redmod-foundation','agent/biology-ui-runtime','agent/presentation-hud-nameplates')) {
    Reject $activeDocs ([regex]::Escape($oldBranch)) "Current product/workflow docs still advertise merged branch: $oldBranch"
}

Write-Host 'PASS: Biology identity, official-source-first REDmod investigation, self-contained settings, attended acceptance, uninstallability and branch-agnostic parallel workflow are canonical.'
