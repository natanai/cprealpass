# Patch resilience architecture

Status: **canonical architecture policy**  
Last updated: **2026-09-15**

## Goal

Biology is intended to be a foundational body/physiology layer rather than a patch-specific collection of tweaks. Ordinary Cyberpunk updates should affect a small compatibility boundary, not force broad rewrites throughout the simulation.

## Core principle

**Understand the supported game build directly, then integrate at the most semantic stable seam available.**

Do not choose an integration merely because an old guide, another mod or a historical Biology/RealPass implementation used it.

Preferred architecture:

```text
Biology simulation / policy core
        |
        v
small owned compatibility adapter
        |
        v
semantic Cyberpunk / REDmod contract
```

The simulation core should not know unnecessary patch-local details.

## Evidence order

For game internals, use:

1. current Biology source/tests/docs and `reference/cyberpunk/`;
2. targeted direct inspection of the user's supported installed game;
3. official CDPR/REDmod/framework/tool documentation and release notes;
4. community/web examples as secondary evidence.

Before asking the user to run anything, read `docs/LOCAL-OPERATOR-COMMANDS.md`.

Do not assume a permanent repository checkout path. The supported game path may be stable while the repo workspace is disposable.

## Prefer stable contracts

Prefer concepts whose identity is meaningful to the game:

- named script/native classes and methods;
- lifecycle events/callbacks;
- TweakDB records and typed relationships;
- stats/status effects with semantic ownership;
- inventory/equipment APIs;
- authoritative player/game state;
- stable controllers and event-driven UI seams;
- documented REDmod/framework APIs;
- resource identities tied to the feature rather than enumeration order.

A named contract can still change, but it gives Biology a narrow place to validate and repair.

## Avoid patch-local coupling

Avoid unless no reasonable semantic alternative exists:

- hard-coded process memory addresses/offsets;
- assumptions about compiled layout;
- copied vanilla implementation bodies;
- exact source line numbers;
- file enumeration order;
- magic array indexes when semantic identity exists;
- brittle widget-child positions when named ownership/events/properties exist;
- fixed delays used instead of lifecycle signals;
- duplicated shadow state already owned authoritatively elsewhere;
- unnecessary third-party gameplay/presentation mods as intermediaries to a vanilla contract.

If unavoidable, isolate the dependency as a compatibility seam.

## Compatibility seam rule

A version-sensitive seam should be:

1. **small** — minimal unstable surface;
2. **isolated** — behind an owned adapter;
3. **evidence-backed** — record what direct evidence established it;
4. **validated** — detect absence/signature/shape changes where practical;
5. **fail-obvious/fail-closed** — do not silently corrupt simulation or present fake healthy state;
6. **replaceable** — the rest of Biology should not depend on the adapter's internal method.

The live `BODY RUNTIME SYSTEM MISSING` failure is an example of why a compatibility/lifecycle failure must stay distinguishable from a healthy body.

## Native authority before shadow state

Before adding persistent Biology state, determine whether Cyberpunk already owns the authoritative state/lifecycle needed.

Examples:

- observe authoritative inventory ownership instead of maintaining a parallel item inventory;
- use equipment/inventory transactions rather than manually decrementing items;
- reuse native menu/controller state machines rather than layering an unrelated duplicate navigation model;
- use one Biology body runtime rather than a UI-owned copy;
- use native identity/knowledge authority for NPC nameplates rather than creating a second identity database.

Biology-owned state is appropriate where Biology genuinely introduces a new simulation concept.

## Runtime discovery where appropriate

Prefer discovery + validation over unnecessary hard-coding when the rule for finding the correct thing is deterministic and semantically meaningful.

Discovery is not automatically safer; validate the discovered result and fail obviously when the expected contract is absent.

## Patch workflow

When Cyberpunk/REDmod/frameworks update:

1. obtain current canonical source in an active/disposable checkout;
2. use the canonical local compatibility command from `docs/LOCAL-OPERATOR-COMMANDS.md`;
3. refresh relevant redistribution-safe evidence;
4. exact-compile/package before changing architecture;
5. inspect failures at the game-facing adapters first;
6. determine whether the semantic contract changed or only an incidental representation;
7. repair the narrow adapter when possible;
8. change the simulation core only if the underlying concept Biology models actually changed;
9. record the new evidence/version/seam decision.

Do not preemptively rewrite working architecture merely because a patch exists.

## Local report rule

Broad compatibility audits and other user-run evidence commands should emit:

- a concise console summary; and
- a plain-text report under the active checkout's `reports/` directory that the user can return to the requesting agent.

This avoids requiring large console transcripts and keeps direct evidence attributable to one exact run.

If an audit fails after starting, preserve the report where practical and identify which phase failed.

## Web research policy

Online research is appropriate for:

- official APIs/documentation;
- release notes/changelogs;
- discovering candidate concepts/terminology;
- known compatibility reports;
- learning tool capabilities.

For foundational claims such as “the supported game has method X with signature Y” or “controller Y owns event Z,” prefer direct supported-build evidence when feasible.

## REDmod route selection

Official REDmod is the preferred packaging/runtime route where robust, but REDmod-first is not ideological REDmod-only.

A whole-file REDmod script replacement can be more brittle than a narrow additive wrapper if it copies more vanilla implementation than Biology actually needs. Choose the smallest stable compatibility surface.

See `BIOLOGY-REDMOD-MIGRATION.md`.

## Reference-mod policy

Dark Future and Project E3 may be studied as research/provenance sources but must not become executing Biology dependencies.

For Project E3, the public repository keeps a derived inventory/mapping while the actual third-party reference payload remains local-only. Derived controller/responsibility knowledge is appropriate; redistributing the third-party payload is not.

## Long-term target

After an upstream patch, a mature Biology release should distinguish:

- **unchanged contracts** — no Biology work required;
- **changed compatibility seams** — narrow adapter repair/revalidation;
- **fundamental game-model changes** — deliberate architecture review.

If ordinary patches routinely require broad changes across body simulation, combat, UI, equipment and persistence simultaneously, patch-specific assumptions have leaked too far into the architecture.

The desired end state is a bedrock mod whose core simulation remains stable while a small auditable boundary translates between Biology and Cyberpunk.
