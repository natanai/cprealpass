$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$path = Join-Path $project 'src/redscript/CyberpunkRealism/PhysicalOutfits.reds'
$source = Get-Content -Raw -LiteralPath $path
$codeOnly = [regex]::Replace($source,'(?m)//.*$','')
$seams = Get-Content -Raw -LiteralPath (Join-Path $project 'manifest/native-seams.json') | ConvertFrom-Json
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }
function Count([string]$needle) { return [regex]::Matches($source,[regex]::Escape($needle)).Count }

Check ((Count '@wrapMethod(EquipmentSystemPlayerData)') -eq 1) 'Physical Outfit adapter should have exactly one native wrap.'
Check ($source.Contains('public final func EquipWardrobeSet(setID: gameWardrobeClothingSetIndex) -> Void')) 'Vanilla wardrobe semantic boundary is not wrapped.'
Check (-not $source.Contains('@replaceMethod')) 'Outfit adapter replaced the native wardrobe method instead of using a narrow wrapper.'
Check (@($seams.allowedHookFiles) -contains 'PhysicalOutfits.reds') 'Physical Outfit adapter is not registered as a native seam.'

Check ($source.Contains('GetItemList(owner, items)')) 'Physical Outfit resolver does not inspect V''s carried inventory.'
Check ($source.Contains('ItemID.GetTDBID(itemID)') -and $source.Contains('ItemID.GetTDBID(storedVisual)')) 'Stored wardrobe identity is not resolved against actual physical item records.'
Check ($source.Contains('EquipmentSystem.GetEquipAreaType(itemID)') -and $source.Contains('this.IsEquippable(itemData)')) 'Resolved loadout item is not constrained to the requested physical slot/equip rules.'
Check (-not $codeOnly.Contains('GiveItem(')) 'Physical Outfit adapter can conjure a missing clothing item.'
Check (-not $codeOnly.Contains('TransferItem(')) 'Physical Outfit adapter silently pulls clothing from another inventory/stash.'
Check (-not ($codeOnly -match '(?i)stash')) 'Physical Outfit adapter gained executable stash behavior.'

Check ($source.Contains('this.IsWardrobeEnabled()')) 'Quest wardrobe-disable state is not respected.'
Check ($source.Contains('HasTag(n"UnequipBlocked")')) 'Quest/special UnequipBlocked clothing is not protected.'
Check ($source.Contains('CRCanApplyPhysicalOutfit(clothingSet)')) 'Outfit changes are not preflighted before mutation.'
Check ($source.Contains('this.UnequipWardrobeSet();')) 'Existing visual-only wardrobe state is not cleared.'
Check ($source.Contains('this.EquipItem(target, false, false);')) 'Saved Outfit does not equip the resolved real item.'
Check ($source.Contains('this.UnequipItem(current);')) 'Saved empty slots cannot become physically empty.'
Check ($source.Contains('this.ClearVisuals(area);')) 'Per-slot visual override is not cleared after physical equipment application.'
Check (-not $source.Contains('SetActiveClothingSetIndex(setID)')) 'Physical loadout incorrectly leaves the wardrobe visual set authoritative.'

Check ($source.Contains('Head') -and $source.Contains('Face') -and $source.Contains('OuterChest') -and $source.Contains('InnerChest') -and $source.Contains('Legs') -and $source.Contains('Feet')) 'Physical Outfit slot allowlist is incomplete.'
Check ($source.Contains('Missing/blocked items fail the request before any slot')) 'Atomic missing-item policy is not documented beside the native implementation.'
Check ($source.Contains('loadouts, not a persistent second appearance layer') -or $source.Contains('loadouts, not a persistent second appearance')) 'One-shot loadout ownership is not explicit in source.'

# Do not create another armor/protection authority in the wardrobe adapter. Physical
# armor logic must continue reading the normal equipped state elsewhere.
foreach ($forbidden in @('armorJoules','ballistic','CRArmor','tissueDamage','ApplyDamage','SetStatPoolValue')) {
    Check (-not $source.Contains($forbidden)) "Outfit adapter leaked into combat/protection authority: $forbidden"
}

Write-Host "PASS: $script:checks physical Outfit/loadout architecture checks; wardrobe application resolves carried real items, uses ordinary equipment transactions, fails closed on missing/blocked gear, and never leaves cosmetic transmog authoritative."
