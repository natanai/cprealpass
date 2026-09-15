# Patch Resilience Architecture

## Goal

RealPass is intended to be a foundational realism layer rather than a patch-specific collection of tweaks. An ordinary Cyberpunk 2077 update should not require broad rewrites. Breakage should occur only when CDPR changes a genuinely relevant contract, and when that happens the affected compatibility seam should be small, obvious, and repairable.

This document defines the architecture policy for achieving that goal.

## Core principle

**Understand the supported game build directly, then integrate at the most semantic stable seam available.**

Do not choose an integration simply because a web guide, another mod, or an old implementation happens to use it. When the actual installed game can answer a question, direct evidence is preferred.

The intended architecture is:

```text
RealPass simulation / policy core
        |
        v
small owned compatibility adapter
        |
        v
semantic Cyberpunk contract
```

The simulation core should not know unnecessary patch-local details.

## Evidence order

For vanilla game internals, agents should use:

1. tracked RealPass source, tests, docs, and `reference/cyberpunk/`;
2. targeted inspection of the user's installed supported game build;
3. official game/framework/tool documentation and release notes;
4. community/web material as secondary evidence.

If the local snapshot is insufficient, remote agents are explicitly expected to ask the user for a single copy/paste-ready PowerShell, CMD, or WolvenKit probe. See `AGENTS.md` and `docs/LOCAL-GAME-REFERENCE.md`.

## Prefer stable contracts

Prefer integration through concepts whose identity is meaningful to the game rather than incidental to one build, including where available:

- named script/native classes and methods;
- lifecycle events and callbacks;
- TweakDB records and typed relationships;
- stats/status effects with semantic ownership;
- inventory/equipment APIs;
- authoritative player/game state;
- stable controllers and event-driven UI seams;
- documented framework APIs;
- resource identities that are semantically tied to the feature rather than discovered only by ordering or position.

A named contract can still change, but it gives RealPass a narrow place to validate and repair. An incidental implementation detail tends to spread fragility.

## Avoid patch-local coupling

Do not introduce these unless there is no reasonable semantic alternative:

- hard-coded process memory addresses or offsets;
- assumptions about compiled layout;
- copied or vendored vanilla implementation bodies;
- exact line numbers;
- reliance on file enumeration order;
- magic indexes into arrays whose semantic identity is available elsewhere;
- brittle widget-child positions when a named controller/event/property exists;
- fixed timing delays used as substitutes for lifecycle signals;
- duplicated shadow copies of state already authoritatively owned by the game;
- unnecessary dependencies on third-party mods as intermediaries to a vanilla contract.

When one of these is unavoidable, it must be treated as a compatibility seam, not normal architecture.

## Compatibility seam rule

A version-sensitive integration should be:

1. **small** — minimal code surface touching unstable details;
2. **isolated** — behind an owned adapter rather than distributed throughout the model;
3. **evidence-backed** — record what local inspection established the seam;
4. **validated** — detect absence/signature/shape changes where practical;
5. **fail-obvious** — prefer disabling that narrow feature or surfacing incompatibility to silently corrupting simulation;
6. **replaceable** — the rest of RealPass should not care how the adapter satisfies the contract.

## Native authority before shadow state

Before adding persistent RealPass state, ask whether Cyberpunk already owns the authoritative state or lifecycle needed for the feature.

Reuse or observe vanilla authority when doing so prevents drift. RealPass-owned state is appropriate when RealPass is genuinely introducing a new simulation concept, but it should not duplicate vanilla truth merely for convenience.

Examples:

- observe authoritative inventory ownership instead of maintaining a parallel item inventory;
- use semantic equipment events rather than polling guessed UI state;
- attach Biology consequences to stable player lifecycle hooks rather than an arbitrary timer if a suitable lifecycle exists.

## Runtime discovery where appropriate

If a value or capability can safely be discovered at runtime, prefer discovery plus validation over unnecessary hard-coding.

Discovery is not automatically better: it must still be deterministic enough for the feature. The objective is to encode the **rule for finding the correct thing**, not a patch-local answer, when a stable rule exists.

## Patch workflow

When Cyberpunk updates:

1. regenerate or refresh the local environment snapshot;
2. run compatibility probes and exact compilation before changing architecture;
3. inspect failures at game-facing adapters first;
4. determine whether the underlying semantic contract changed or only an incidental representation;
5. repair the narrow adapter if possible;
6. change the simulation core only if the game changed a concept RealPass actually models;
7. record the new evidence and supported version.

Do not preemptively rewrite working architecture just because a patch exists.

## Web research policy

Online research is appropriate for:

- official framework/API documentation;
- release notes and changelogs;
- discovering candidate concepts or terminology;
- comparing known compatibility reports;
- learning how tooling such as WolvenKit exposes data.

For a statement such as "the supported game has method X with signature Y" or "this controller owns event Z," direct supported-build evidence should be obtained when feasible before making it foundational architecture.

## Long-term target

A mature RealPass release should be able to distinguish three categories after an upstream patch:

- **unchanged contracts** — no RealPass work required;
- **changed compatibility seams** — small adapter repair and revalidation;
- **fundamental game-model changes** — deliberate architectural review.

If ordinary patches routinely require broad changes across Biology, combat, UI, equipment, and persistence simultaneously, that is evidence that patch-specific assumptions have leaked too far into the architecture.

The desired end state is a bedrock mod whose core simulation remains stable while a small, auditable boundary translates between RealPass and Cyberpunk.
