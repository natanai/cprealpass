# CONDITION-UI.md — superseded

Status: superseded by `BIOLOGY-UI.md`
Last updated: 2026-09-14

The earlier architecture in this document placed realpass condition presentation under a `CYBERWARE | CONDITION` mode. That product decision was superseded on 2026-09-14.

The canonical player-facing bodily interface is now **Biology**. Conditions remain a subsection of Biology, while Cyberware returns to its vanilla equipment purpose and Backpack remains focused on possessions.

See:

- `../AGREED-GOALS.md` — canonical locked goals, especially G-043 through G-049 and G-060 through G-065.
- `BIOLOGY-UI.md` — current body/needs/conditions UI architecture and acceptance criteria.

Historical implementation work in `ConditionNativeUI.reds` should be treated as migration/prototype evidence only. Do not extend it as the canonical UI architecture; move useful condition-detail behavior into the realpass-owned Biology implementation.
