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
Check ($source.Contains('npc.IsCharacterCivilian()')) 'Public-name fallback is not restricted to ordinary civilian crowd identity.'
Check (-not $source.Contains('npc.IsScanned()')) 'Ambient civilian identity is structurally scanner-gated instead of available to ordinary E3 focus.'
Check ($source.Contains('this.IsQuestTarget()')) 'Owned fallback does not respect the stock controller quest-target state.'
Check (-not $source.Contains('this.m_isQuestTarget')) 'Owned fallback reaches into the stock private quest-target field instead of its public accessor.'
Check ($source.Contains('npc.GetBoolFromCharacterTweak("hide_nametag")')) 'Owned fallback ignores the stock character hide-name flag.'
Check ($source.Contains('GetAllBlackboardDefs().Puppet.HideNameplate')) 'Owned fallback ignores the dynamic stock hide-nameplate flag.'
Check ($source.Contains('t"UINameplate.CrowdSettings"')) 'Owned fallback is not restricted to the public crowd nameplate record.'
Check ($source.Contains('npc.GetPS() as ScriptedPuppetPS')) 'Owned fallback does not explicitly narrow the puppet persistent-state type.'
Check ($source.Contains('ps.HasAlternativeName()')) 'Owned fallback can reveal an actor that uses an alternative identity.'
Check ($source.Contains('character.ScannerModulePreset()')) 'Owned fallback does not use the same native name-visibility permission source as the scanner/nameplate model.'
Check ($source.Contains('preset.ShoulShowName()')) 'Owned fallback ignores native name-visibility permission.'
Check (-not $source.Contains('GetForcedScannerPreset')) 'Owned fallback gained an unverified forced-scanner-preset dependency.'
Check ($source.Contains('return puppet.GetDisplayName()')) 'Owned fallback does not use the public entity display name.'
Check (-not $source.Contains('incomingData.name =')) 'Owned wrapper mutates the native const script_ref payload in place.'

# Identity resolution remains data-only. E3NameplatesNative.reds owns presentation.
foreach ($forbidden in @('SetVisible(', 'm_nameTextMain', 'm_nameFrame', 'm_healthbarWidget', 'currentHealth', 'maximumHealth', 'SetStatPoolValue', 'DarkFuture', 'Project E3')) {
    Check (-not $source.Contains($forbidden)) "Owned identity seam gained forbidden presentation/simulation ownership: $forbidden"
}

Write-Host "PASS: $script:checks ambient nameplate identity checks; native identity wins, permitted civilian public identity is not scanner-gated, and hidden/alternative identity policy remains native-authoritative."
