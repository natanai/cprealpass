# Autonomous completion evidence

Owner authorization: issue #152 and
`docs/handoffs/AUTONOMOUS-FINAL-PRODUCT-COMPLETION.md`. Work is solo on
`autonomous/final-product-completion`; starting main is
`d2a4c8f1c166bbfd0227451cbf32e3793f10ea72`.

## Player lifecycle and T007

The installed 2.31 native player high-level state machine distinguishes normal
SceneTier1/SceneTier2 and Swimming from restricted/cinematic SceneTier3–5 and
other states. The prior player body gate reused an NPC actor-scene membership
query. Player body progression, combat admission and impairment now use a
shared player-specific gate: attached, alive, not replaced/defeated, accepted
high-level state, and (outside deliberate menu care) not in a menu or paused.
NPC protection keeps its independent actor-scene check. All runtime ownership
and observations also require the REDmod activation marker.

The owner reported ticking with `allowed=false`, no body-time progression and
`commit-body-gate`. Individual old predicate values were not captured. The exact
T007 ZIP was not found locally; this run does not claim to have reproduced its
internal scene Boolean or observed repaired gameplay. The source defect and
replacement contract are distinct from a live before/after observation.

Preference clicks now use the native controller's player session to resolve the
existing save-backed setting. Decorative children cannot intercept the row;
failed writes return failure and show UNAVAILABLE, while saving OFF is correctly
reported as a successful write. A UI event requests refresh of existing HUD
controllers. Scanner mode owns native identity while active; ordinary names use
native supplied identity first and only a permitted public fallback when absent.

The all-hook review also found stale E3 tint restoration: an OFF callback could
overwrite newly updated native colors with colors captured at initialization.
Tinted surfaces now restore before native updates, capture only while applying
E3, and clear their restoration flags. Disabled fresh sessions do not create E3
chrome or Biology action panels. Interaction adapters resolve their player's
session and tolerate unavailable systems. A rejected/missing MaxDoc replacement
effect yields the original native action.

## Installer and removal

The release now builds `Install Biology.exe` with Windows .NET Framework.
The script entry point delegates to that binary, including preflight-only mode;
no policy bypass, dependency download or external scripting runtime is needed
by the player. The installer is separate from the runtime and does not persist
as a launcher or watcher.

Its complete source/target preflight checks package hashes, prior receipt hashes,
narrow ownership paths, all shared dependency conflicts, stale owned sources,
untracked Biology namespace files, duplicate/unsafe Windows paths and reparse
points. Replacement is restricted to unchanged, previous Biology-owned files.
The prior receipt and atomic rollback copies remain available until all writes
succeed; the new receipt is committed last. Concurrently changed rollback files
are preserved and reported rather than overwritten. Empty directories may
remain after an interrupted install; they contain no executing payload.

`Uninstall Biology.exe` shares the path resolver, rechecks its receipt, preserves
changed/shared files, retains the receipt when untracked namespace files remain,
and uses official REDmod refresh only after Biology's namespace is absent. Its
GUI can relocate the same binary into Windows Temp; no helper script/process is
generated for deletion. A closed previous temporary copy is cleaned only when
its filename and SHA match this exact binary; the current copy follows the OS
Temp lifecycle. Command-mode removal runs the exact receipt-matching uninstaller
from the extracted release outside the game root, avoiding self-image locking.

## Executed checks so far

- Exact 2.31 compile `autonomous-t007-5`: all 65 production sources passed with
  redscript CLI 0.5.31, diagnostics OFF, using the game base read-only.
- Actual-source player lifecycle/preference regression: 41 checks passed.
- Injury effects: 1,437; NPC progression: 40; barless feedback: 17; pain
  architecture: 44; body interactions: 23; E3 presentation: 177 checks passed.
- Native installer: 31 checks passed, including clean install, same-version
  reinstall, upgrade/stale-source removal, corrupt sources, ownership conflicts,
  destination races and rollback after an actual Windows sharing violation.
- A real Windows junction was rejected by the shared path resolver.
- Uninstaller core: 42 checks passed; prior-install transition fixtures passed.
- Integrated package source contracts: 80 checks passed.
- Baseline CI exposed an optional reference-probe tool download after a deliberate
  missing-game fixture; the guard was corrected and the focused test passed.
  Three intermediate injury fixture failures were repaired. A changed shared
  loader contract required explicit test updates; final full CI is still pending.

No game install, removal or launch has happened yet in this run. Package lifecycle,
main-menu smoke, final ZIP inventory, final CI and release revision remain open.
No saved game has been opened or changed. Model/compile checks do not establish
native UI event delivery, save serialization, rendered behavior or combat feel.

## Whole-product audit checkpoint

Checkpoint `e86f101343a578fad4cc422abe50d78732270a66` passed all 87 then-current
CI suites. Its release-shaped package contains 86 verified files and passed the
native installer's read-only preflight against the existing T007 installation.
No game mutation was performed at that checkpoint.

The subsequent source audit bound timed field care, inventory debits, clinical
care, condition projections, wounds and blood loss to the actual native player's
GameInstance. Missing systems fail closed. Supplies are shown using native item
display names; native item identities are unchanged. Pain state initializes only
after a valid active body snapshot. Injury provenance preserves unknown schemas
and does not prune persistent data while launcher activation is OFF.

`manifest/activation-hook-audit.json` inventories all 62 wrappers and 25 additive
native event/callback entry points. The new CI gate rejects an unreviewed change
to this inventory. It also checks E3 restoration ordering and care session usage.
The body ScriptableSystem attach/restore callbacks reset transient clocks only;
detach invalidates callbacks and clears owned effects. Care detach/restore cancels
its transient action. Provenance attach/restore is activation/schema guarded.
Armor, pain, injury effects and settings have no automatic persistent-mutation
attach/restore callback. Body activation remains the clock/timer authority.

All 65 sources exact-compiled in `autonomous-audit-7`. A read-only installed 2.31
contract audit passed native seam policy and recorded 301 hook declarations
(including helper methods and fields), distinct from the 87 native entry points.
The game base hash is
`2119046F3F3466206D8A16A4803B0EF0F3C90926AB689F9ABBD5B8E42E28EE86`.
Uninstaller fixtures now pass 46 checks, including changed-receipt refusal before
mutation and receipt retention for untracked residual files. Native installer
fixtures remain 31 passing checks plus a real junction refusal; player preflight
also requires installed official REDmod tools matching 2.31.
