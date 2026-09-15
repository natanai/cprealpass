# realpass

A Cyberpunk 2077 + Phantom Liberty realism overhaul in development. RealPass starts from the **vanilla game** and replaces selected underlying mechanics with project-original physical/physiological systems while preserving CDPR item identities, screens, assets, animations and interaction language wherever they remain useful.

RealPass is not intended to be a repackaged mod stack or a collection of arbitrary difficulty toggles. The finished release is one authored simulation: connected body/needs, regional injury and recovery, physical projectile/impact behavior, meaningful armor/clothing coverage, relevant cyberware physiology and restrained presentation that communicates those systems.

Weather control, economy overhaul, artificial scarcity, added random encounters, travel restrictions and a separate cosmetic outfit/transmog simulation are intentionally out of scope.

## Read this first

Development agents should read these in order:

1. `AGENTS.md` — current operational rules, local paths and workflow precedence.
2. `AGREED-GOALS.md` — canonical product-intent ledger.
3. `docs/PROJECT-STATUS.md` — current implementation state and live-test gates.
4. `docs/ATTENDED-ACCEPTANCE.md` — canonical local gameplay acceptance checklist.
5. `docs/WORKLOG.md` — chronological history; older entries may describe superseded workflows.

If an older implementation note, tool or test conflicts with a newer user decision or the canonical current documents above, the newer rule wins and the stale artifact should be corrected or retired.

## Current architecture

The executing RealPass gameplay/presentation runtime is project-owned code/data. Dark Future and Project E3 are historical/reference sources only, not runtime hosts.

Current project-original systems include body/needs and time progression, physical projectile/impact routing, regional wounds, blood loss, impairment, armor wear, pain/analgesia, field treatment, professional biological/mechanical care, injury provenance, supported NPC progression, the Biology body-state interface, physical Outfit loadouts, RealPass settings/presence and the transitional actor-health presentation work.

The current owned candidate preserves Backpack as possessions and uses **Biology** for embodied state. Cyberware remains equipment-focused; ripperdoc contexts may expose Biology professional care. MaxDoc remains MaxDoc and is modeled as analgesia rather than magical tissue/blood/chrome repair.

Patch-sensitive native hooks should remain thin and feed stable RealPass models. Canonical source activation remains fail-closed until the exact staged candidate passes local compile and attended gameplay evidence.

## Current local operator path

The current development entry point is:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1
```

That performs repository checks, builds the owned candidate, exact-compiles against the installed supported Cyberpunk scripts and plans the flat install without changing the game.

To install the exact current candidate for an attended session:

```powershell
pwsh ./tools/Prepare-OwnedSession.ps1 -Deploy
```

The deploy path installs only the current owned payload, verifies hashes, records the flat owned-file state, removes known retired/source-mod runtime residue and stops. It does **not** launch Cyberpunk and it does **not** create a RealPass-managed save backup.

After the tool reports ready, launch Cyberpunk normally through Steam.

Development recovery is intentionally simple: `Remove-OwnedRuntime.ps1` removes recorded RealPass-owned extra files; Steam **Verify Files** or reinstall is the stock-game repair authority when needed. Do not reintroduce redundant save-backup or multi-generation rollback machinery.

## Project status

The repository contains durable ledgers so work can continue cleanly across ChatGPT, local Codex/agents and future maintainers:

- [Agent operating rules](AGENTS.md)
- [Canonical agreed goals](AGREED-GOALS.md)
- [Project status and completion estimate](docs/PROJECT-STATUS.md)
- [Canonical attended acceptance plan](docs/ATTENDED-ACCEPTANCE.md)
- [Chronological worklog](docs/WORKLOG.md)
- [Realism specification](REALISM-SPEC.md)
- [Biology UI](docs/BIOLOGY-UI.md)
- [Settings architecture](docs/SETTINGS-ARCHITECTURE.md)
- [Modular development architecture](docs/MODULAR-ARCHITECTURE.md)
- [Combat calibration plan](docs/COMBAT-CALIBRATION.md)
- [Roadmap](docs/ROADMAP.md)
- [Release / one-download architecture](docs/RELEASE-ARCHITECTURE.md)
- Machine-readable acceptance gates: `manifest/acceptance.json`

Source volume or offline compilation alone does not count as native gameplay acceptance.

## Distribution goal

The finished player experience should be one download: extract/copy RealPass into the Cyberpunk 2077 game root, then launch Cyberpunk normally through Steam. A permanent RealPass launcher, Vortex knowledge or a manual stack of reference mods should not be required.

GitHub source does not modify an installed game by itself. Runtime files must first be assembled into the paths Cyberpunk loads. Public playable artifacts remain gated until dependency redistribution, native gameplay acceptance, update/uninstall safety and artifact verification are complete.

## Current generic runtime plumbing

The current owned candidate uses project-original RealPass REDscript plus only the generic framework plumbing required by the accepted runtime/settings surface. `docs/PROJECT-STATUS.md`, `manifest/profiles.json` and `manifest/distribution.json` are authoritative for the exact current dependency set.

Generic frameworks may provide plumbing; they may not own RealPass simulation policy or state. Dark Future and Project E3 gameplay scripts/assets are forbidden from the finished owned runtime.

## Source layout

- `src/redscript`: RealPass physiology, injury, combat, treatment, presentation and thin native adapters.
- `config`: authored calibration/reference data plus historical adaptation recipes that are not the owned-runtime target.
- `manifest`: runtime, feature-inventory, acceptance, ownership and distribution contracts.
- `tools`: acquisition/staging, exact compilation, current flat install/removal, packaging and artifact policy.
- `tests`: model, integration, contract, policy and file-transaction checks.
- `package` and `LICENSES`: package documentation and dependency/reference notices.
- `docs`: architecture, calibration, acceptance notes, roadmap, status and worklog.

Downloaded components, game assets, generated staging output, local deployment manifests, runtime reports and machine inventories remain outside the public repository.

## Development policy

Prepare coherent batches and verify the exact build before gameplay testing. Keep patch-sensitive Cyberpunk hooks thin and fail closed when signatures change. Do not launch the game unattended or leave watchers, recorders, services, scheduled jobs or other external helpers running.

RealPass development/testing must not create or require an additional save backup. Save/reload persistence itself remains part of native gameplay acceptance.
