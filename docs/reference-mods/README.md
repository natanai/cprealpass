# Reference-mod archaeology

This directory is for **redistribution-safe derived knowledge only**. Third-party mod archives, extracted payloads, source bodies, proprietary game files, and private reference bundles do not belong in Git.

## Private owner workflow

The persistent local reference library is:

`C:\Games\Cyberpunk-ReferenceMods`

The owner-facing command is `tools/Bootstrap-ReferenceModBundle.ps1`. It resolves an exact reviewed cprealpass revision with the normal local-first / exact-head cached-origin fallback, creates a disposable detached checkout, and invokes the read-only bundle builder.

A successful local bundle contains:

- `manifest.json` with selected references, hashes/identities, workflow revision, duplicate handling, provenance/version hints, and archive inspectability;
- `file-index.json` with relative paths, sizes, SHA-256, classification, and inspection status;
- `signals.json` with bounded redscript/framework/UI symbol signals extracted from copied text;
- `payload/` with bounded text/source/config material for **private analysis only**;
- `archive-inventory/` when ZIP or an already-available safe `7z l` listing can expose archive contents without extraction;
- `report.txt` and a prominent private-analysis / no-redistribution notice.

If a resource container cannot be safely listed, the bundle records it as opaque. Workers must not infer archive internals from filenames or screenshots.

For Cyberware/Ripperdoc archaeology, the same command can add `-IncludeBiologyNativeUi`. That optional companion remains read-only against the installed game and privately adds the current installed official `ripperdoc.script` / `ripperdocInventoryController.script`, the exact native-region probe report, and—when the existing WolvenKit-backed probe can resolve it—the full serialized current target `.inkwidget` JSON with resource/archive/hash provenance. The probe also preserves enlarged targeted context for HandleId `219` / package-copy `743`, the direct-parent evidence currently needed to decide whether `virtualGridContainer` sits under a reusable authored content host or only a grid/scroll wrapper.

If that native resource sub-capability cannot resolve or serialize the target, the reference bundle still completes and records the native portion as failed/opaque rather than inventing hierarchy.

The bundle is intentionally written outside both the repository and the source reference payload folders, by default under `C:\Games\Biology-Reference-Bundles`. Selected reference-mod folders are read-only and reference mods are not installed into Cyberpunk for this workflow.

Command 18 may maintain an owner-authorized reusable dependency cache at `C:\Games\Cyberpunk-ReferenceMods\_tooling`. That reserved folder is not a reference mod and is excluded from selection. Pinned WolvenKit CLI / portable .NET assets may be downloaded there once, then checksum/inventory-verified and reused on later probes instead of being downloaded into every disposable checkout. A cache mismatch still fails closed rather than silently replacing or trusting an unverified tool.

## Worker request convention

Before another speculative native probe or attended iteration in a subsystem that an established mod already changes, ask:

1. Is there a mature reference mod that already crosses this seam?
2. Could its scripts/config/resource provenance or dependency chain identify the real native controller/widget/resource faster?
3. If yes, request a bundle before guessing.

A worker request must state the reference mod/dependencies wanted, why they are relevant, and the exact uncertainty the bundle is expected to resolve.

## Durable derived record

After private inspection, commit only a record conforming to `reference-record.schema.json`. The record may preserve source/version/provenance, selected relative path + SHA-256 identities, dependency/framework roles, derived native mappings, Biology-owned conclusions, validation, and explicitly opaque areas.

Do not paste or paraphrase third-party implementation bodies into these records. A derived mapping should be independently actionable against current CP2077 native/official contracts.
