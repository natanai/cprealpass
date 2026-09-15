# RealPass clean-room testing contract

Status: canonical attended-test workflow
Last updated: 2026-09-15

## Purpose

RealPass is intended to ship as a simple game-root-shaped package that a player can extract/copy into a clean Cyberpunk 2077 installation and then launch normally through Steam.

Attended development testing should therefore exercise the same installation shape rather than relying on a long-lived developer game directory with accumulated mod residue or a long-lived repository checkout with local state.

## Canonical clean-room cycle

For each broad attended build test:

1. Cyberpunk 2077 is closed.
2. The local RealPass workspace (`C:\Games\CyberpunkRealism`) is disposable and should be deleted/re-created from the current canonical repository state before building the candidate.
3. The Cyberpunk 2077 game directory is restored to a genuinely vanilla state before the candidate is applied.
4. A release-shaped RealPass test package is built from the fresh repository checkout.
5. That package is merged into the vanilla game root exactly the way a normal player package would be merged.
6. Cyberpunk is launched normally through Steam.
7. The attended acceptance session evaluates that exact installed package.
8. Before the next broad candidate, repeat from a fresh workspace and vanilla game root rather than assuming uninstall/upgrade tooling removed every prior file.

This is intentionally stricter than ordinary rapid developer iteration. It tests the end goal directly: a self-contained drag-and-drop RealPass package that does not depend on hidden local state.

## What counts as vanilla

Steam **Verify Files** repairs or restores stock files, but it is not relied on to discover/delete arbitrary extra mod files. A strong clean-room reset is:

1. uninstall Cyberpunk 2077 in Steam;
2. after uninstall finishes, manually remove any remaining `Cyberpunk 2077` game directory if it still exists;
3. reinstall Cyberpunk 2077 through Steam;
4. optionally launch once with no RealPass package installed to confirm the base game starts normally;
5. close the game before building/applying the candidate.

Deleting the game install directory is distinct from deleting save data. RealPass testing must not delete the user's saves/settings unless the user explicitly requests that separately.

A full reinstall is expensive, so narrow compile/API probes may still use an existing local environment. But **broad attended candidate acceptance** starts from the clean-room baseline above.

## Fresh repository rule

The broad test candidate should be built from the repository exactly as another person would receive it:

- use the current canonical `main` state;
- no uncommitted local source changes;
- no stale generated `staging`, `vendor`, `reports`, local deployment receipts, or retired scripts should be assumed as inputs;
- a disposable fresh clone/download is preferred over repairing an old working tree before each broad test.

Generated dependency caches and staging produced *after* the fresh checkout by the package builder are allowed; they are build outputs, not hidden source inputs.

## Package-under-test rule

Do not directly treat the repository root as the player mod. The repository contains source, tests, tools and documentation that should not be copied into the game.

The package under test should be a generated **game-root-shaped artifact** containing only the runtime payload and required bundled generic framework files/notices allowed by `manifest/distribution.json`.

The intended manual test action is conceptually:

`fresh RealPass package root -> copy/merge into fresh Cyberpunk 2077 game root -> Steam Play`

The same file layout and dependency set used for attended testing should converge on the eventual downloadable release ZIP.

## Why this rule exists

This workflow catches classes of failure that an in-place developer installer can hide:

- retired scripts left behind from older builds;
- missing files that happened to exist from a previous test;
- framework/plugin versions inherited from the machine rather than supplied by RealPass;
- package omissions masked by an already-modded game directory;
- incorrect update/uninstall assumptions;
- runtime behavior that works only because the developer workspace has generated state not present in a user's download.

A candidate that works only in an accumulated developer installation has not satisfied the product goal.

## Narrow investigation exception

Targeted native-signature checks, read-only game-reference inspection, compile probes and other narrow diagnostics do not require a complete reinstall when the result does not depend on installed mod state. These are evidence-gathering steps, not broad acceptance.

When in doubt, prefer the clean-room path for anything described as a full build, candidate, live test, acceptance pass, or release-like test.

## Agent rule

Future agents should not instruct the user to use `Prepare-OwnedSession.ps1 -Deploy` as the canonical broad acceptance workflow once a release-shaped clean-room package builder is available. Direct deployment tooling may remain useful for narrow development iteration, but broad user-facing validation is performed from vanilla plus the generated drag-and-drop artifact described here.
