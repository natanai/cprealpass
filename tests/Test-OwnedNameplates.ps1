$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/NameplatesNative.reds'
if (-not (Test-Path -LiteralPath $path)) { throw 'Missing owned nameplate identity helper.' }
$source = Get-Content -Raw -LiteralPath $path
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

Check ($source.Contains('CRPublicAmbientNameAllowed')) 'W03.3 ambient-name permission helper is missing.'
Check ($source.Contains('CRResolveBiologyAmbientName')) 'Owned ambient identity resolver is missing.'
Check (-not $source.Contains('@wrapMethod')) 'Identity helper still owns a native wrapper instead of leaving the single SetVisualData boundary to E3NameplatesNative.reds.'
Check ($source.Contains('if IsStringValid(data.name)')) 'Native focus/nameplate identity is not explicitly preferred over Biology fallback identity.'
Check ($source.Contains('wref<NPCPuppet> = puppet as NPCPuppet')) 'Ambient identity helper is not restricted to actual NPC puppets.'
Check (-not $source.Contains('npc.IsCharacterCivilian()')) 'W03.3 still excludes police/combatants from the ambient public-name path.'
Check ($source.Contains('npc.IsAttached()')) 'Ambient identity helper does not require an attached live NPC.'
Check ($source.Contains('this.IsQuestTarget()')) 'Ambient identity helper does not respect the native quest-target state.'
Check ($source.Contains('this.crBiologyE3ScannerActive')) 'Ambient identity helper does not yield projected fallback ownership while native scanner detail is active.'
Check ($source.Contains('this.m_forceHide') -and $source.Contains('this.m_npcNamesEnabled')) 'Ambient identity helper ignores native controller visibility policy.'
Check ($source.Contains('npc.GetBoolFromCharacterTweak("hide_nametag")')) 'Ambient identity helper ignores the character hide-name flag.'
Check ($source.Contains('GetAllBlackboardDefs().Puppet.HideNameplate')) 'Ambient identity helper ignores the dynamic native hide-nameplate flag.'
Check ($source.Contains('character.UiNameplate()')) 'Ambient identity helper no longer respects native nameplate record authority.'
Check ($source.Contains('if IsDefined(nameplate) && !nameplate.Enabled()')) 'Ambient identity helper does not reject explicitly disabled native nameplates.'
Check ($source.Contains('npc.GetPS() as ScriptedPuppetPS') -and $source.Contains('ps.HasAlternativeName()')) 'Ambient identity helper can reveal an authored alternative identity.'
Check ($source.Contains('return IsStringValid(puppet.GetDisplayName())')) 'Ambient identity helper does not use the existing public entity display name.'
Check ($source.Contains('return puppet.GetDisplayName()')) 'Ambient resolver does not return the existing public entity display name.'
foreach ($forbidden in @('npc.IsScanned()','ScannerModulePreset','ShoulShowName','GetForcedScannerPreset','record.FullDisplayName()','record.ArchetypeData()','record.Affiliation()')) {
    Check (-not $source.Contains($forbidden)) "Ambient identity helper regained scanner/derived-identity coupling: $forbidden"
}
foreach ($forbidden in @('SetVisible(', 'SetTintColor(', 'm_nameTextMain', 'm_nameFrame', 'm_healthbarWidget', 'currentHealth', 'maximumHealth', 'SetStatPoolValue', 'DarkFuture', 'Project E3')) {
    Check (-not $source.Contains($forbidden)) "Identity helper gained presentation/simulation ownership: $forbidden"
}

Write-Host "PASS: $script:checks W20.3 ambient identity checks; native identity wins, civilian/police/combatant public display names remain ordinary-look capable outside scanner, and scanner/hidden/alternative/quest/disabled-nameplate policy remains protected."
