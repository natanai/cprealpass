# realpass

A Cyberpunk 2077 + Phantom Liberty realism overhaul in development. realpass starts from the **vanilla game** and replaces selected underlying mechanics with project-original physical/physiological systems while preserving CDPR's item identities, screens, assets, animations and interaction language wherever they remain useful.

realpass is not intended to be a repackaged mod stack or a collection of arbitrary difficulty toggles. The finished release is one authored, all-or-nothing simulation: connected body/needs, regional injury and recovery, physical projectile/impact behavior, meaningful armor/clothing coverage, relevant cyberware physiology and restrained presentation that communicates those systems.

Weather control, economy overhaul, artificial scarcity, added random encounters, travel restrictions and a separate outfit/transmog simulation are intentionally out of scope.

## Read this first

`AGREED-GOALS.md` is the canonical product-intent ledger. If an older implementation note conflicts with a locked goal there, the locked goal wins and the old implementation/documentation should be corrected.

The most important current architecture rules are:

- Dark Future and Project E3 are **reference/inspiration only**, not runtime hosts.
- Executing realpass gameplay/presentation behavior must be realpass-owned code/data.
- Preserve vanilla names/identities instead of importing another mod's renames. For example, MaxDoc remains MaxDoc, Bounce Back remains Bounce Back and Health Booster remains Health Booster.
- Prefer thin hooks at native Cyberpunk semantic boundaries feeding stable realpass models.
- Development modules can be isolated for debugging, but normal releases are one fixed authored simulation.

## Current milestone

The current owned-runtime work is converging on one broad attended candidate rather than the earlier Dark Future/E3-integrated prototype.

Project-original systems currently include the body/needs model, sleep/fatigue/clock handling, ballistic/impact models, regional wounds, blood loss, impairment, armor wear, NPC body progression, field treatment, professional biological/mechanical care, injury provenance, no-traditional-healthbar presentation, pain/analgesia and the first `CYBERWARE | CONDITION` injury interface.

The Condition interface mounts onto Cyberpunk's stock Cyberware/ripperdoc screen and reuses the game's own body/paper-doll zoom language. Active injuries become selectable condition entries; the detail view explains regional trauma, likely cause, bleeding, biological/chrome damage, functional consequences, field treatment and professional care without exposing native HP as the injury authority.

Pain is derived from realpass injury state. The current native adapter keeps the vanilla **MaxDoc** identity/use flow but replaces its magical HP-regeneration effect with pain-only analgesia, including diminishing returns and an overuse/disorientation envelope. Health Booster and Bounce Back are not aliases for MaxDoc and do not inherit Dark Future naming.

Combat/body activation remains deliberately gated until the exact owned runtime compiles against the installed Cyberpunk 2.31 environment and passes attended gameplay testing.

## Project status

The repository contains durable ledgers so work can continue cleanly across ChatGPT, local Codex/agents and future maintainers:

- [Canonical agreed goals](AGREED-GOALS.md)
- [Project status and completion estimate](docs/PROJECT-STATUS.md)
- [Chronological worklog](docs/WORKLOG.md)
- [Realism specification](REALISM-SPEC.md)
- [Condition / injury UI](docs/CONDITION-UI.md)
- [Modular development architecture](docs/MODULAR-ARCHITECTURE.md)
- [Combat calibration plan](docs/COMBAT-CALIBRATION.md)
- [Roadmap](docs/ROADMAP.md)
- [Release / one-download architecture](docs/RELEASE-ARCHITECTURE.md)
- Machine-readable acceptance gates: `manifest/acceptance.json`

The status ledger records a conservative percentage toward a gameplay-validated, safely distributable 1.0. Source volume or offline compilation alone does not count as native gameplay acceptance.

## Distribution goal

The finished player experience should be one download: extract/copy realpass into the Cyberpunk 2077 game root (or use one equally simple bootstrap installer only if generic framework licensing/update safety genuinely requires it), then launch Cyberpunk normally through Steam. A permanent realpass launcher, Vortex knowledge or a manual stack of reference mods should not be required.

GitHub source does not modify an installed game by itself. Runtime files must first be assembled into the paths Cyberpunk loads. `manifest/distribution.json` records packaging policy and release gates. Public playable artifacts remain gated until generic dependency redistribution, native gameplay acceptance, save/update safety and artifact verification are complete.

A cloud-safe GitHub Actions workflow runs model/contract checks and artifact policy. Local tooling separately exact-compiles the owned candidate against the installed game before any attended deployment.

## Source layout

- `src/redscript` and `src/tweaks`: realpass physiology, injury, combat, treatment, presentation and thin native adapters.
- `config`: authored calibration/reference data plus historical adaptation recipes that are not the owned-runtime target.
- `manifest`: runtime, feature-inventory, acceptance, ownership and distribution contracts.
- `tools`: acquisition of generic frameworks, staging, exact compilation, packaging, artifact policy and reversible deployment.
- `tests`: model, integration, contract, policy and file-transaction checks.
- `package` and `LICENSES`: package documentation and dependency/reference notices.
- `docs`: architecture, calibration, acceptance notes, roadmap, status and worklog.

## Third-party/reference material

Dark Future and Project E3 were useful research/reference sources during early prototyping. Their gameplay scripts, state machines, UI assets and archives are **not permitted as dependencies of the finished owned runtime** under the current product goals.

Historical license/provenance material remains in the repository so earlier research and authorship are not erased. Generic modding frameworks may remain only when they supply necessary plumbing; they may not own realpass simulation policy or state. Framework versions, hashes and license evidence are tracked separately.

Downloaded components, game assets, generated staging output, local deployment manifests, runtime reports, machine inventories and save backups remain outside the public repository.

## Development policy

Prepare coherent batches and verify the exact build before gameplay testing. Keep patch-sensitive Cyberpunk hooks thin and fail closed when signatures change. Do not launch the game unattended or leave watchers, recorders, services, scheduled jobs or other external helpers running.

Back up saves before live deployment. File rollback does not migrate a save backward or remove persistent mod state. Native gameplay acceptance must cover ordinary combat, armor, injury, bleeding, pain/MaxDoc, Condition treatment, professional repair, save/reload and time progression together before those systems are treated as accepted.
