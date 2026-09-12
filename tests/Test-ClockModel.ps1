. "$PSScriptRoot\..\tools\Common.ps1"
. "$PSScriptRoot\CoreHarness.ps1"
$project=Get-ProjectRoot
$path=Join-Path $project 'src/redscript/CyberpunkRealism/ClockModel.reds'
Add-Type -TypeDefinition (Convert-RedscriptCore @($path))
$script:checks=0
function Check($Condition,$Message){if(-not $Condition){throw $Message};$script:checks++}
$c=[CRClockState]::new()
Check ([CRClockModel]::Observe($c,100000,100,$true) -eq 0) 'First sample charged offline time'
$hours=[CRClockModel]::Observe($c,100300,137.5,$true)
Check ([Math]::Abs($hours-1.0/12) -lt 0.000001 -and [Math]::Abs($c.lastObservedRatio-8) -lt 0.00001) 'Observed game-clock delta or ratio wrong'
Check ([CRClockModel]::Observe($c,100300,137.5,$true) -eq 0) 'Repeated callback double-counted time'
Check ([CRClockModel]::Observe($c,100400,150,$false) -eq 0) 'Menu entry charged protected interval'
Check ([CRClockModel]::Observe($c,100800,200,$false) -eq 0) 'Progressed while in menu'
Check ([CRClockModel]::Observe($c,100850,206.25,$true) -eq 0) 'Menu exit charged menu time'
Check ($c.suppressedWorldSeconds -eq 550) 'Suppressed interval accounting wrong'
Check ([CRClockModel]::Observe($c,101150,243.75,$true) -gt 0) 'Did not resume after menu'
[CRClockModel]::BeginSkip($c,101150,243.75)
Check ([CRClockModel]::Observe($c,115550,245,$true) -eq 0) 'Observed skip before finish event'
Check ([CRClockModel]::FinishSkip($c,115550,245,4) -eq 4) 'Skip duration not accepted once'
Check ([CRClockModel]::FinishSkip($c,115550,245,4) -eq 0) 'Duplicate skip finish accepted'
[CRClockModel]::BeginSkip($c,115550,245)
[CRClockModel]::CancelSkip($c,115550,246)
Check ([CRClockModel]::FinishSkip($c,115550,246,8) -eq 0) 'Cancelled skip still advanced'
[CRClockModel]::Reset($c,115550,246,$true)
Check ([CRClockModel]::Observe($c,201950,247,$true) -eq 0 -and $c.unclassifiedWorldSeconds -eq 86400) 'Unannounced quest jump treated as awake/sleep time'
Check ([CRClockModel]::Observe($c,90000,250,$true) -eq 0) 'Backward clock jump charged time'
$restored=[CRClockState]::new()
Check ([CRClockModel]::Observe($restored,1000000,10,$true) -eq 0) 'Reload baseline advanced the body'
[CRClockModel]::BeginSkip($c,90000,250)
# Menu-boundary rebasing must preserve an in-flight skip.
[CRClockModel]::Reset($c,104400,251,$false)
Check ($c.skipPending -and [CRClockModel]::FinishSkip($c,104400,251,4) -eq 4) 'Menu reset cancelled real sleep'
[CRClockModel]::BeginSkip($c,104400,251)
Check ([CRClockModel]::FinishSkip($c,104400,251,-1) -eq 0) 'Negative skip accepted'
[CRClockModel]::BeginSkip($c,104400,251)
Check ([CRClockModel]::FinishSkip($c,104400,251,1000) -eq 0) 'Unbounded skip accepted'
Write-JsonFile ([ordered]@{testedAtUtc=[DateTime]::UtcNow.ToString('o');passed=$true;assertions=$script:checks;sourceSha256=(Get-Sha256 $path);scope='Actual clock policy translated to C#; duplicates, menus, reload baselines, skipped/cancelled/duplicate time skips and unknown jumps. Engine callbacks and save serialization remain untested.'}) (Join-Path $project 'reports/clock-model-tests.json')
Write-Host "PASS: $script:checks clock policy checks."
