$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/NameplatesNative.reds'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing owned nameplate native seam.' }
$source = Get-Content -Raw -LiteralPath $path
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($source.Contains('@wrapMethod(NameplateVisualsLogicController)')) 'Owned nameplate source does not wrap the stock visual-data boundary.'
Check ($source.Contains('public final func SetVisualData(puppet: ref<GameObject>, const incomingData: script_ref<NPCNextToTheCrosshair>, opt isNewNpc: Bool) -> Void')) 'Owned nameplate wrapper signature drifted from the Cyberpunk 2.31 script_ref boundary.'
Check ($source.Contains('let resolved: NPCNextToTheCrosshair = Deref(incomingData)')) 'Owned nameplate seam does not copy the native script_ref payload before enrichment.'
Check ($source.Contains('wrappedMethod(puppet, resolved, isNewNpc)')) 'Owned nameplate seam does not hand its local payload back to the stock controller.'
Check ($source.Contains('if IsStringValid(data.name)')) 'Native focus identity is not explicitly preferred over Biology fallback identity.'
Check ($source.Contains('npc.IsCharacterCivilian()')) 'Public-name fallback is not restricted to ordinary civilian identity.'
Check (-not $source.Contains('npc.IsScanned()')) 'Ambient civilian identity is structurally scanner-gated instead of available to ordinary E3 focus.'
Check ($source.Contains('this.IsQuestTarget()')) 'Owned fallback does not respect the stock controller quest-target state.'
Check (-not $source.Contains('this.m_isQuestTarget')) 'Owned fallback reaches into the stock private quest-target field instead of its public accessor.'
Check ($source.Contains('npc.GetBoolFromCharacterTweak("hide_nametag")')) 'Owned fallback ignores the stock character hide-name flag.'
Check ($source.Contains('GetAllBlackboardDefs().Puppet.HideNameplate')) 'Owned fallback ignores the dynamic stock hide-nameplate flag.'
Check ($source.Contains('character.UiNameplate()')) 'Owned fallback no longer respects the native nameplate-record authority.'
Check ($source.Contains('if IsDefined(nameplate) && !nameplate.Enabled()')) 'Owned fallback does not reject an explicitly disabled native nameplate record.'
Check (-not $source.Contains('t"UINameplate.CrowdSettings"')) 'Owned fallback regressed to the disproven W03.1 assumption that one specific crowd record is required.'
Check ($source.Contains('npc.GetPS() as ScriptedPuppetPS')) 'Owned fallback does not explicitly narrow the puppet persistent-state type.'
Check ($source.Contains('ps.HasAlternativeName()')) 'Owned fallback can reveal an actor that uses an alternative identity.'
Check (-not $source.Contains('character.ScannerModulePreset()')) 'Baseline ordinary-look identity is still coupled to scanner-module records.'
Check (-not $source.Contains('preset.ShoulShowName()')) 'Baseline ordinary-look identity is still gated by scanner-name permission.'
Check (-not $source.Contains('GetForcedScannerPreset')) 'Owned fallback gained an unverified forced-scanner-preset dependency.'
Check ($source.Contains('return puppet.GetDisplayName()')) 'Owned fallback does not use the existing public entity display name.'
Check (-not $source.Contains('record.FullDisplayName()')) 'Owned fallback started deriving richer record identity instead of using public display identity.'
Check (-not $source.Contains('record.ArchetypeData()')) 'Owned fallback started deriving archetype identity.'
Check (-not $source.Contains('record.Affiliation()')) 'Owned fallback started deriving affiliation identity.'
Check (-not $source.Contains('incomingData.name =')) 'Owned wrapper mutates the native const script_ref payload in place.'

# Identity resolution remains data-only. E3NameplatesNative.reds owns presentation.
foreach ($forbidden in @('SetVisible(', 'm_nameTextMain', 'm_nameFrame', 'm_healthbarWidget', 'currentHealth', 'maximumHealth', 'SetStatPoolValue', 'DarkFuture', 'Project E3')) {
    Check (-not $source.Contains($forbidden)) "Owned identity seam gained forbidden presentation/simulation ownership: $forbidden"
}

Write-Host "PASS: $script:checks W03.2 ambient nameplate identity checks; native identity wins, public civilian display identity is ordinary-look capable without scanner gating, and hidden/alternative/disabled-nameplate policy remains native-authoritative."
