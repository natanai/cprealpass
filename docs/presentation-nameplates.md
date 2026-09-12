# realpass scanned NPC names

The preceding E3 integration could draw a narrow empty name frame because its border/background are separate from the native display-name widget. The native projection can hide the name while the E3 replacement still displays its frame. The integration also removed every fallback for an empty native focus-data name.

The patch restores a public entity display name only for a scanned ordinary civilian using the exact UINameplate.CrowdSettings record. This selectively extends generic crowd presentation. It does not change UINameplate.Disabled, QuestSettings, custom hidden records, or global TweakDB defaults.

The fallback requires:

- An attached, scanned civilian that is not the current quest target.
- An enabled, exact UINameplate.CrowdSettings record.
- Neither the hide_nametag character flag nor the dynamic Puppet.HideNameplate flag.
- A valid persistent state without an alternative identity.
- A scanner preset that permits names, including any forced scanner preset.

A nonempty native focus name takes priority. The fallback reads only GameObject.GetDisplayName(), the public API used by the native civilian scanner. It does not traverse full-name, affiliation, archetype or alternative-name records. If no legitimate name is available, the name text and both E3 decorations are hidden together.

The projection wrapper refreshes the name before the stock IsAnyElementVisible check. This allows completion of a scan to recover from a previously hidden frame without relying on another focus-data event. It then executes the entire native projection callback and keeps its outer visibility decision. The only added display-name permission is the scanned generic-crowd case above. Native distance/projection, mounting, dialogue, rewindable scene sections and dynamic hiding continue to suppress the whole plate.

The game setting for NPC names, forced visual hiding, defeated actors, turrets, and E3 boss versus ordinary name decoration are also respected.

## Local source evidence

All references below are to the locally decoded Cyberpunk 2077 2.31 scripts in staging/game-api-6316aafc68ee4fd9b68f3fdf41d14342/game.reds.

- Lines 258016–258044: NPCNextToTheCrosshair.name is a native-produced field. Redscript does not establish that it is always populated.
- Lines 122639–122668: the NPC scanner respects name-preset visibility and alternative identities; a civilian without a record display name uses GetDisplayName().
- Lines 391885–391967: the native projection enforces record policy, mounting, dialogue/scene and hidden-name flags, then independently sets m_displayName.
- Lines 392307–392358: visual data updates call name coloring, element visibility and health visibility.
- Lines 392414–392419: the native NPC names setting triggers a visual data refresh.
- E3 reference nameplateVisuals.reds, SetElementVisibility: the name frame is shown for every non-turret, even for an empty final name. Its vendor/friendly branch repeats the unconditional name visibility.

These source facts explain two failure paths consistent with the screenshot. The screenshot alone does not identify the focused NPC's exact TweakDB record or prove the archive's text/font binding. The patch retains the original E3 font, font styles and layout; those asset properties still need visual verification.

## Builder integration (implemented)

1. Preserve the existing E3 reference hash validation, minimal settings and inert blanket NPC YAML files.
2. Run the current builder's native-name replacement and notice insertion first.
3. Apply config/patches/realpass-e3-nameplates.json to the prepared nameplateVisuals.reds content. Its expected SHA-256 is the existing rc2 adapted source, 792A9BE253328163809DCB2F12E4BEE063A47762E5F8C9EE272F6CE6B45EB969. Require every exact occurrence count.
4. Copy patches/project-e3-hud/realpassNameplates.reds into the new staged payload at the recipe's supportDestination, r6/scripts/realpass/Presentation/realpassNameplates.reds. Add exactly one script/manifest entry and hash both this support source and recipe in provenance.
5. Keep the current removal of the original E3 projection wrapper. The support script provides the new constrained wrapper.
6. Include the patch source and recipe in local bundle provenance. Preserve the required-original/local-only status of the E3-containing bundle.
7. Update E3 staging tests: the new wrapper lives in its own support file; the GetCustom method retains native-data precedence but now has a scanned-crowd fallback. Total E3 additions become 37 files / 23 scripts.

Do not overwrite old candidates or the running installation. The final combined candidate is realpass-presentation-rc3-quiet, with 226 payload files and 115 scripts. Its exact upgrade/rollback passed, and it is installed locally for the next launch after a verified save backup. The earlier nameplate-only manifest is a separate compile fixture.

## Verification

- tests/Test-RealpassNameplates.ps1: 63 checks execute the actual resolver replacement, added helpers and projection wrapper using controlled native API/widget fixtures. Both separate native display-name references and references that alias the text widget are covered.
- Complete candidate compilation: 115 sources, zero errors, the same nine existing dependency warnings.
- No in-game asset rendering, actual crowd record assignment, save state, or scanning behavior is claimed by these offline checks.
- The next combined test should scan an ordinary civilian, release the scanner and focus them, then look away/back. Check a friendly/quest NPC too, and confirm that dialogue still hides the overhead name.
