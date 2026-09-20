# Local Cyberpunk game reference

Status: **canonical evidence policy**  
Last updated: **2026-09-15**

## Purpose

Remote GitHub agents do not directly browse the user's installed Cyberpunk 2077 filesystem. Biology therefore keeps redistribution-safe derived metadata under `reference/cyberpunk/` and may ask the user to run narrow local probes when direct supported-build evidence materially improves correctness.

This is part of Biology's patch-resilience strategy: foundational integrations should be based on the actual supported game build and semantic contracts rather than stale web examples, web/community script dumps, or assumptions inherited from another mod.

## Important path rule

The game path is currently known:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077
```

The repository/workspace path is **not** stable. Do not assume or recreate `C:\Games\CyberpunkRealism` or any other fixed repo location. Attended test workspaces are disposable and normally live under a milestone-specific directory such as:

```text
C:\Games\Biology-Test-<short-main-sha>-<YYYYMMDD-HHmmss>-<random8>\
    operator\
    candidate\
```

Repository tools should derive the project root from the checkout they are running from unless a tool explicitly needs a supplied path. Before asking the user to run anything, read `docs/LOCAL-OPERATOR-COMMANDS.md`.

## Prefer the installed official REDmod script tree for script contracts

For questions about a Cyberpunk script class, event, function, field, controller, lifecycle, inheritance relationship, or nearby implementation context, prefer the official REDmod decompiled script tree from the installed supported game whenever it contains the needed evidence:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077\tools\redmod\scripts
```

This is direct evidence from the user's installed 2.31 build, not a web mirror. Use narrow searches and preserve only the relevant relative paths, symbol names, signatures, or short diagnostic conclusions. Do not commit bulk decompiled Cyberpunk source.

Examples of facts that should normally be established here before searching online include current controller/class existence, event/function names, inheritance, editable/private field names visible in the decompiled source, lifecycle ownership, and whether an older Project E3 or community-mod seam still maps to the current game.

For presentation work, `tools/Probe-PresentationNativeContracts.ps1` is the focused example. It reads `tools\redmod\scripts` without modifying the game and reports current HUD/nameplate/minimap controller evidence.

## Exact compilation is the hard script-compatibility gate

Readable REDmod source evidence answers what the installed game exposes. It does not prove that Biology's additive/wrapper code compiles against that build. Exact compatibility is checked against:

```text
C:\Games\Steam\steamapps\common\Cyberpunk 2077\r6\cache\final.redscripts
```

A strong native-seam workflow is:

1. inspect the installed REDmod `.script` source for the current contract;
2. implement the smallest Biology-owned seam;
3. exact-compile against the installed `final.redscripts`;
4. perform attended runtime acceptance only after those static gates pass.

## Two tracked evidence families

Do not conflate these.

### Current observed installation

The root of:

```text
reference\cyberpunk\
```

contains redistribution-safe metadata describing the installation when the snapshot was last refreshed. Depending on the tool/version, that can include environment/version information, filesystem indexes, framework/plugin inventories, installed-script metadata, archive inventories and native-contract fingerprints.

This snapshot may describe vanilla, a Biology test installation or another deliberate state. Treat timestamps/version fields as dated evidence. Use the canonical snapshot command from `docs/LOCAL-OPERATOR-COMMANDS.md` rather than reconstructing a publish workflow in chat.

### Known-clean vanilla baseline

The directory:

```text
reference\cyberpunk\vanilla-baseline\
```

contains derived metadata for a deliberately clean vanilla reference:

- relative paths;
- file sizes;
- SHA-256 hashes;
- supported game/executable version;
- capture time and aggregate counts.

It contains no Cyberpunk payload content. Baseline capture is a deliberate maintenance operation, normally after a supported game patch or when the canonical clean reference must change. It is not a required second 85+ GiB read immediately after every fresh reinstall.

Use the catalogued baseline capture/compare commands in `docs/LOCAL-OPERATOR-COMMANDS.md`.

## Iteration cleanup

The active Biology reset route is:

```text
tools/Reset-BiologyIteration.ps1
```

The old RealPass reset route is legacy only and must not be presented as the normal current command.

The Biology reset is conservative: it uses the installed Biology ownership manifest, validates file identity, removes only safely proven package-owned paths, and fails closed when state cannot be proven safe. The current testing policy is in `docs/CLEAN-ROOM-TESTING.md`.

## Evidence priority

For questions about what Cyberpunk itself contains, exposes, names, calls, stores or does, use this order:

1. current Biology source/tests/docs and already-recorded `reference/cyberpunk/` evidence;
2. the installed official REDmod decompiled script tree under `tools\redmod\scripts` for readable script contracts;
3. targeted direct inspection/exact compile against the user's supported game installation;
4. official CDPR/REDmod/framework/tool documentation and release notes;
5. web/community script dumps, guides and examples only as secondary evidence.

Do not substitute internet examples for a small direct probe when the installed supported build can answer the question more authoritatively. Community examples can suggest candidate seams, but supported installed-game evidence should confirm foundational contracts.

## Local generated workspace

Within whichever checkout is active, tools may use gitignored local paths such as:

```text
game-reference\
    live\        # optional read-only junction to installed game
    index\       # generated indexes
    extracted\   # selective extraction workspace
reports\         # generated local reports
```

Those locations are relative to the **active checkout**, not a permanent absolute repository path. If `game-reference\live` exists, it reaches the real installation and must be treated as read-only during investigation. Only redistribution-safe derived metadata under tracked `reference/cyberpunk/` belongs in Git.

## What remote agents may request

Good reasons for a targeted local probe include:

- exact vanilla resource/controller/script paths;
- class/function/event/stat/status-effect/TweakDB record existence;
- direct REDmod script-source evidence for controller/lifecycle ownership;
- inventory/equipment/controller/state-machine behavior;
- installed framework versions;
- relevant logs;
- narrow archive extraction of one required resource family;
- verification that an online claim still applies to the supported game;
- Project E3 local-reference inspection when a presentation worker needs source-level design archaeology and the public manifest is insufficient.

Before asking:

1. check `docs/LOCAL-OPERATOR-COMMANDS.md`;
2. use an existing canonical command when possible;
3. if a recurring probe is missing, add/refine a repository tool rather than creating another chat-only block;
4. keep game inspection read-only unless the task explicitly requires a supported install/deploy/remove action.

## Report-file rule

User-run evidence commands that produce material diagnostic output should write a plain-text report into the active checkout's `reports/` directory and print the resulting file path.

The preferred handoff is:

```text
run canonical command -> tool writes report -> user returns the .txt report
```

not:

```text
run long command -> user manually copies a large console transcript into chat
```

Console summaries are still useful, but the report is the durable return artifact when the output matters to an agent. If a command fails after it has started collecting evidence, it should still preserve a useful report where practical and state that the run failed.

## WolvenKit / selective extraction

REDmod's installed script tree should be used before archive extraction when the question is purely about script behavior.

If archive-level inspection is needed, use the repository's current toolchain/reference guidance. Selective extraction belongs under the active checkout's gitignored workspace, for example:

```text
game-reference\extracted\
```

Do not bulk-extract the game by default and do not commit proprietary payload.

## What belongs in Git

Appropriate derived additions include:

- technical conclusions;
- vanilla resource/symbol/record names;
- narrow native signatures needed by Biology adapters;
- small indexes/hashes;
- compatibility probes/scripts;
- versioned environment metadata;
- tests/fixtures created by Biology;
- derived mappings from local-only third-party reference material.

Do **not** commit:

- vanilla `.archive` containers;
- game executables/DLLs;
- bulk REDmod-decompiled game scripts;
- textures, meshes, audio, videos or other proprietary game payload;
- bulk decompiled/extracted game content;
- the local `game-reference/` workspace;
- the local `ReferenceMods/` payload merely to make it convenient for remote agents.

## Design consequence

Before adding a parallel Biology mechanism, ask whether Cyberpunk already owns the authoritative state/lifecycle needed for the feature.

Preferred shape:

```text
stable Biology simulation core
        |
        v
small semantic compatibility adapter
        |
        v
native Cyberpunk / official REDmod contract
```

Version-sensitive details belong at the adapter boundary rather than throughout the simulation core.

## Safety rule

Inspection is read-only by default. Commands that install/deploy/remove Biology must use repository-owned, ownership-aware workflows.

A full Steam uninstall + residual-directory deletion + reinstall is reserved for milestone clean-room/recovery cases where prior state cannot be safely accounted for; it is not the normal Biology uninstall workflow.

## Version note

The currently supported/tested evidence in this milestone is Cyberpunk 2077 `2.31`. Treat that as versioned evidence, not a permanent constant. Refresh compatibility evidence after supported game/framework changes.
