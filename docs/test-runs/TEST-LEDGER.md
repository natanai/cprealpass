# Biology attended-test ledger

Status: **canonical numbered live-test index**  
Last updated: **2026-09-19**  
Next unallocated live test ID: **T007**

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
| **T003** | 2026-09-18 | `67593bfbb12b4a6ebcec7042066d48b4f5fac427` | **PARTIAL** | Listener/session PASS. Biology selected anatomy works but detail telemetry disappears entirely -> W02.5/#96. E3 nameplate + old reticle fix improved, but WEAPON // AMMO chrome is detached and quest tracker remains untreated -> W03.5/#97. |
| **T004** | 2026-09-18 | `ffa6f64d6c837146d032aaab565d671c932453a2` | **PARTIAL** | Listener/session PASS across two observed launch cycles. Biology breadcrumb proves `MOUNTED` but detail remains blank -> post-mount W02.6. E3 quest/weapon now reach their native regions, but quest treatment is still tiny/partial and lower-left hotkey chrome is visibly mis-composed -> W03.6. |
| **T005** | 2026-09-19 | `a5818db6596e335824d75f596fc8204cc419de4f` | **PARTIAL** | Session/startup PASS; runtime visible and E3 materially improved. Back transition flashes stock Cyberware -> W19.1/#133; nameplate frame + police scan identity -> W20.1/#134; live Health loss not reflected in Biology injury state -> W21.1/#135. Persistence sequence remains open on #41. |
| **T006** | 2026-09-19 | `fbce426fc3305f67f29ec083bfe8c9f644c2572d` | **PARTIAL** | W22 replacement path + session/startup PASS; Biology detail/Back flash fixed (KEEP). Biology stats remain inert -> W21.2/#143/#41. E3 preference clipped/unusable -> W20.2/#144/#40. Persistence and remaining identity acceptance stay open. |

## Records

- `T001-2026-09-17-205578b1-reconstructed-integrated-followup.md`
- `T002-2026-09-17-3dc049ee-live-ui-followup.md`
- `T003-2026-09-18-67593bfb-native-region-e3-followup.md`
- `T004-2026-09-18-ffa6f64d-post-mount-e3-region-followup.md`
- `T005-2026-09-19-a5818db6-integrated-reference-followup.md`
- `T006-2026-09-19-fbce426f-body-state-preference-followup.md`

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
