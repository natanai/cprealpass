# Biology attended test records

This directory stores durable records of meaningful local in-game tests coordinated by the parent/integration thread.

Each record should be tied to an exact canonical `main` SHA and exact release-shaped artifact. Do not write vague notes such as “latest build worked.”

## Numbered attended-session identity

Owner-run live attended sessions use a monotonic parent-owned ID:

```text
T001
T002
T003
...
```

Every new live session consumes a new number, including a rerun of the same feature boundary. Cloud CI runs, worker fixture tests, and read-only audits keep their own native IDs and are referenced from the attended record; they do not consume `T###` numbers.

Acceptance checks and findings inherit the session ID:

```text
T002-A01  acceptance check
T002-F01  attended finding
```

Before launch, the parent records the allocated `T###`, exact canonical main SHA, test mode, included work, acceptance checklist, and expected evidence in a GitHub tracking issue/comment. Do **not** move canonical `main` just to create a planned test record after the exact test candidate has already been approved.

After evidence returns, parent commits the completed record here and updates `TEST-LEDGER.md`.

Recommended completed filename:

```text
T###-YYYY-MM-DD-<short-main-sha>-<slug>.md
```

Older pre-numbering files remain valid historical evidence. Do not invent retroactive T numbers when chronology or boundaries are uncertain.

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
