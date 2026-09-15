$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot

function Read([string]$relative) {
    $path = Join-Path $project $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing active-roadmap file: $relative" }
    Get-Content -Raw -LiteralPath $path
}
function Require([string]$text,[string]$pattern,[string]$message) {
    if ($text -notmatch $pattern) { throw $message }
}

$root = Read 'ROADMAP.md'
$baseline = Read 'docs/PRE-REDMOD-LIVE-BASELINE-2026-09-15.md'
$roadmap = Read 'docs/ACTIVE-REDMOD-ROADMAP.md'
$ui = Read 'docs/BIOLOGY-UI.md'
$e3 = Read 'docs/E3-PRESENTATION.md'
$handoffA = Read 'docs/handoffs/REDMOD-FOUNDATION.md'
$handoffB = Read 'docs/handoffs/BIOLOGY-UI-RUNTIME.md'
$handoffC = Read 'docs/handoffs/PRESENTATION-HUD-NAMEPLATES.md'

Require $root 'CURRENT ROADMAP' 'Root ROADMAP.md must remain an obvious active-work entry point.'
Require $root 'agent/redmod-foundation' 'Root roadmap must expose REDmod foundation lane.'
Require $root 'agent/biology-ui-runtime' 'Root roadmap must expose Biology UI/runtime lane.'
Require $root 'agent/presentation-hud-nameplates' 'Root roadmap must expose presentation lane.'

Require $baseline 'ec8ba06451c3cbacabfad24f1479e1537147d0c9' 'Attended pre-REDmod baseline must stay tied to the exact tested revision.'
Require $baseline 'top navigation still says `CYBERWARE`' 'Baseline must retain observed inner-navigation failure.'
Require $baseline 'Body state is unavailable' 'Baseline must retain observed body-state failure.'
Require $baseline 'E3-inspired first-person HUD recreation is not visibly present' 'Baseline must retain observed HUD failure.'
Require $baseline 'E3-inspired NPC nameplates are not active' 'Baseline must retain observed nameplate failure.'
Require $baseline 'health-bar suppression is active but does not prove the E3 toggle works' 'Baseline must distinguish barless Biology from E3 completion.'
Require $baseline 'REALPASS' 'Baseline must retain observed obsolete settings identity.'

foreach ($id in @('PKG-01','DEP-01','NAV-01','BIO-01','STATE-01','PRES-01','SET-01')) {
    Require $roadmap ([regex]::Escape($id)) "Active roadmap lost issue ID: $id"
}
Require $roadmap 'Combined milestone acceptance' 'Roadmap must retain an integrated acceptance gate.'

Require $ui '2026-09-15 clean-room attended evidence' 'Biology UI spec must include current attended evidence.'
Require $ui 'Persistent Biology nodes are absent' 'Biology UI spec must not imply healthy drill-down is already accepted.'
Require $e3 '2026-09-15 attended pre-REDmod evidence' 'E3 presentation spec must include current attended evidence.'
Require $e3 'do not count health-bar suppression as evidence that the E3 presentation works' 'E3 spec must separate barless-health ownership from E3 completion.'

Require $handoffA 'agent/redmod-foundation' 'REDmod handoff branch name missing.'
Require $handoffA 'PKG-01' 'REDmod handoff must own package roadmap items.'
Require $handoffB 'agent/biology-ui-runtime' 'Biology UI handoff branch name missing.'
Require $handoffB 'STATE-01' 'Biology UI handoff must own body-state availability.'
Require $handoffC 'agent/presentation-hud-nameplates' 'Presentation handoff branch name missing.'
Require $handoffC 'PRES-01' 'Presentation handoff must own HUD roadmap items.'
Require $handoffC 'modern scanner' 'Presentation handoff must preserve modern scanner.'

Write-Host 'PASS: pre-REDmod attended evidence, active issue roadmap, three parallel branch lanes, and focused UI/presentation acceptance remain explicit.'
