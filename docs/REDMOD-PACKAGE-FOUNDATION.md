# Biology REDmod package foundation — archived phase pointer

Status: **historical phase complete; not active guidance**  
Original issue: #28  
Original merged PR: #31  
Target game: Cyberpunk 2077 2.31

This path remains only so old links have an explicit destination. The detailed foundation handoff/status text was retired from the active tree because it contained phase-specific branch names, transition gates, and pending claims that became stale after the integrated milestone.

The durable conclusions that survived the foundation phase are now represented in current architecture/contracts:

- official first-party identity is `mods/Biology`;
- Biology is REDmod-first, not ideologically REDmod-only;
- whole-file REDmod script replacement is used only when it is the robust boundary;
- narrower Biology-owned additive/wrapper seams may remain when direct evidence shows they reduce compatibility surface;
- every retained dependency needs a current concrete consumer;
- Dark Future and Project E3 are reference/provenance only and do not execute or ship;
- installed payload is owned per file/hash and shared roots are never recursively Biology-owned;
- live behavior is accepted only through direct/attended evidence.

The integrated milestone subsequently **proved** official REDmod recognition of `Biology` and a real five-stage deployment on Cyberpunk 2077 2.31. Do not recover the older version of this file and re-open those already-accepted gates.

Current sources of truth:

- `docs/REDMOD-INTEGRATED-ASSEMBLY.md`
- `docs/BIOLOGY-REDMOD-MIGRATION.md`
- `docs/RELEASE-ARCHITECTURE.md`
- `manifest/redmod-package.json`
- `manifest/redmod-install-contract.json`
- `manifest/dependency-graph.json`
- `manifest/redmod-classification.json`
- `tools/Build-BiologyPackage.ps1`
- `tools/Deploy-BiologyRedmod.ps1`
- `docs/test-runs/2026-09-15-8cf04566-redmod-deploy-preflight.md`

Current work/remaining gates belong in `ROADMAP.md`, `docs/ACTIVE-REDMOD-ROADMAP.md`, and live GitHub issues/PRs rather than this archived phase pointer.
