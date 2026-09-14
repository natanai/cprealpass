$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/NameplatesNative.reds'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing owned nameplate native seam.' }
$source = Get-Content -Raw -LiteralPath $path
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($source.Contains('@wrapMethod(NameplateVisualsLogicController)')) 'Owned nameplate source does not wrap the stock visual-data boundary.'
Check ($source.Contains('public final func SetVisualData(puppet: ref<GameObject>, incomingData: NPCNextToTheCrosshair, opt isNewNpc: Bool) -> Void')) 'Owned nameplate wrapper signature drifted from the stock boundary.'
Check ($source.Contains('wrappedMethod(puppet, incomingData, isNewNpc)')) 'Owned nameplate seam does not hand rendering back to the stock controller.'
Check ($source.Contains('!IsStringValid(incomingData.name)')) 'Owned fallback overwrites a legitimate native focus name.'
Check ($source.Contains('npc.IsScanned()') -and $source.Contains('npc.IsCharacterCivilian()')) 'Owned fallback is not restricted to scanned ordinary civilians.'
Check ($source.Contains('this.IsQuestTarget()')) 'Owned fallback does not respect the stock controller quest-target state.'
Check (-not $source.Contains('this.m_isQuestTarget')) 'Owned fallback reaches into the stock private quest-target field instead of its public accessor.'
Check ($source.Contains('npc.GetBoolFromCharacterTweak("hide_nametag")')) 'Owned fallback ignores the stock character hide-name flag.'
Check ($source.Contains('GetAllBlackboardDefs().Puppet.HideNameplate')) 'Owned fallback ignores the dynamic stock hide-nameplate flag.'
Check ($source.Contains('t"UINameplate.CrowdSettings"')) 'Owned fallback is not restricted to the public crowd nameplate record.'
Check ($source.Contains('npc.GetPS() as ScriptedPuppetPS')) 'Owned fallback does not explicitly narrow the puppet persistent-state type.'
Check ($source.Contains('ps.HasAlternativeName()')) 'Owned fallback can reveal an actor that uses an alternative identity.'
Check ($source.Contains('character.ScannerModulePreset()')) 'Owned fallback does not use the same scanner visibility source as the stock NPC scanner.'
Check ($source.Contains('preset.ShoulShowName()')) 'Owned fallback ignores the stock scanner name-visibility permission.'
Check (-not $source.Contains('GetForcedScannerPreset')) 'Owned fallback invented an unsupported forced-scanner-preset API.'
Check ($source.Contains('incomingData.name = puppet.GetDisplayName()')) 'Owned fallback does not use the public entity display name.'

# This seam may enrich stock input data only. It must not force widgets/health state or
# become a second nameplate renderer.
foreach ($forbidden in @('SetVisible(', 'm_nameTextMain', 'm_nameFrame', 'm_healthbarWidget', 'currentHealth', 'maximumHealth', 'SetStatPoolValue', 'DarkFuture', 'Project E3')) {
    Check (-not $source.Contains($forbidden)) "Owned nameplate seam gained forbidden presentation/simulation ownership: $forbidden"
}

Write-Host "PASS: $script:checks owned scanned-civilian nameplate seam checks; stock identity permissions and renderer remain authoritative."
