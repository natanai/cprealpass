# Biology attended-test ledger

Status: **canonical numbered live-test index**  
Last updated: **2026-09-17**  
Next unallocated live test ID: **T003**

This file is the parent-owned chronological authority for owner-run live Cyberpunk attended sessions. It is intentionally compact. Open the linked completed record for detail.

## Numbering

- `T###` — one owner-run live attended session.
- `T###-A##` — an acceptance check belonging to that session.
- `T###-F##` — a finding produced by that session.
- Every rerun gets a new T number.
- CI, worker fixtures, and read-only audits do not consume T numbers.

Before a live launch, parent creates/updates a GitHub `[T###]` tracking issue so the in-flight session survives chat loss without changing the exact candidate SHA. After evidence returns, parent commits the completed record here and advances the next ID.

## Numbered sessions

| Test | Owner-local date | Exact canonical source | Disposition | Key result / routing |
|---|---|---|---|---|
| **T001** | 2026-09-17 | `205578b11d818f474dc74a873e6d6ea5a1e1accd` | **PARTIAL** | Runtime-backed detail present, but layout wrong -> W02.3; E3 mostly retail/nameplates absent/red artifact -> W03.3; listener false NOT-OBSERVED -> W15.5. |
| **T002** | 2026-09-17 | `3dc049ee99979f924978b671ddbbbda06b472d1b` | **PARTIAL** | Listener fixed; ambient names now live; Biology telemetry still extreme top-left; overall E3 design still insufficient; reticle red artifact persists; persistence sequence not exercised. |

## Records

- `T001-2026-09-17-205578b1-reconstructed-integrated-followup.md`
- `T002-2026-09-17-3dc049ee-live-ui-followup.md`

## Pre-numbering history

Existing dated records in this directory remain authoritative for their exact historical boundaries. They are not retroactively assigned T numbers where the mapping is uncertain.

## Recovery rule

A blind/fresh parent reconstructs live-test state in this order:

1. exact current canonical `main`;
2. this ledger;
3. any open GitHub issue titled `[T###] ATTENDED ...`;
4. latest completed numbered record;
5. `docs/THREAD-LEDGER.md`;
6. current issues/PRs/CI;
7. older chat only as supplemental evidence.

Repository/GitHub state wins over chat recollection.
