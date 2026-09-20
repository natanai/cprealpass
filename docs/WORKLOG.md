# Biology current worklog

Status: **short current implementation index only**  
Last updated: **2026-09-15**

This file is intentionally small. It is not a second roadmap and it does not preserve superseded worker instructions. Git history and dated `docs/test-runs/` records preserve historical implementation evidence.

For current truth, read in this order:

- `../AGREED-GOALS.md` — locked product intent;
- `../ROADMAP.md` — current work and lane status;
- `ACTIVE-REDMOD-ROADMAP.md` — current attended-follow-up acceptance ledger;
- current GitHub issues/PRs — exact branch/head/implementation state;
- `DECISION-HISTORY.md` — user corrections and superseded interpretations;
- `test-runs/` — exact attended evidence tied to tested artifacts.

Do not recover an old worklog from Git and treat it as current instructions.

---

## 2026-09-15 — REDmod-first integrated milestone reached live testing

The integrated candidate built from `8cf045664b5e4d8b4b014edfc98bf2f8eb270ba5` exact-compiled, installed into a clean Cyberpunk 2077 2.31 game, was recognized by official REDmod as `Biology`, and completed a real five-stage REDmod deployment after the deploy helper was corrected to fail closed on ignored-root/empty-mod false positives.

Attended gameplay then exposed four current follow-up areas rather than invalidating the REDmod foundation:

- **#39 / PR #43** — Biology must reuse the native Cyberware drill-down/back/mode-state grammar cleanly.
- **#41 / PR #47** — authoritative body runtime must be available through the live session/menu path.
- **#40 / PR #46** — ordinary first-person presentation must actually read as E3-inspired, including ambient NPC nameplates, while the modern scanner remains native.
- **#44 / PR #45** — launcher-off vanilla-play behavior and a self-contained, manifest-safe `Uninstall Biology.exe`.

The parent integration thread owns combined merge order, exact compilation, release-shaped packaging, and the next attended candidate. Worker CI is not live acceptance.

## 2026-09-15 — repository guidance hygiene

A repo-wide scrub is retiring stale operational assumptions such as the old permanent `C:\Games\CyberpunkRealism` checkout, merged worker handoffs presented as current, already-proven REDmod gates marked unknown, and obsolete RealPass-era player-package/reset routes.

Current policy is:

- architecture docs describe architecture;
- `ROADMAP.md` + current GitHub issues/PRs describe current work;
- dated test records describe history;
- local commands come from `docs/LOCAL-OPERATOR-COMMANDS.md`;
- foundational engine/tool questions investigate the installed Cyberpunk/CDPR/REDmod capability first rather than assuming the common modder workaround is the best route.

When this file becomes stale, replace the short current entries. Do not append an indefinite chronological project diary here.
