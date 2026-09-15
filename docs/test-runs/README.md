# Biology attended test records

This directory stores durable records of meaningful local in-game tests coordinated by the parent/integration thread.

Each record should be tied to an exact canonical `main` SHA and exact release-shaped artifact. Do not write vague notes such as “latest build worked.”

Recommended filename:

```text
YYYY-MM-DD-<short-main-sha>-<slug>.md
```

## Template

```markdown
# Attended test — <short description>

Date:
Cyberpunk version:
Test mode: ITERATION | MILESTONE CLEAN-ROOM
Canonical main SHA:
Artifact/package:
Build command:
Game-state evidence:

## Included work

- PR / issue / lane
- PR / issue / lane

## Expected acceptance

- [ ] expectation
- [ ] expectation

## Observed results

### PASS

- ...

### FAIL / PARTIAL

- ...

## Evidence

- screenshot / log / PowerShell output description
- screenshot / log / PowerShell output description

## Findings and routing

| ID | Finding | Expected | Observed | Owner / route | Follow-up issue/branch |
|---|---|---|---|---|---|
| TEST-01 | ... | ... | ... | original lane / new lane / integration / parent tiny fix | ... |

## KEEP / FIX / REMOVE

- KEEP — ...
- FIX — ...
- REMOVE — ...

## Milestone disposition

Accepted | Partially accepted | Rejected

Reason:

## Next integration step

- ...
```

## Rules

- Preserve what was actually observed; do not infer successful behavior from source-level tests.
- If a screenshot contradicts a source/CI assumption, the attended evidence wins for presentation/runtime acceptance.
- Record setting state when behavior depends on a toggle.
- Distinguish a product-wide rule from an optional visual layer. For example, Biology-wide health-bar suppression is not proof that the optional E3-inspired presentation is active.
- Route each actionable finding to an owner before declaring the record complete.
- Large raw logs do not need to be committed if they are inappropriate or noisy; capture the relevant conclusion, hashes/paths, and a safe summarized excerpt instead.
