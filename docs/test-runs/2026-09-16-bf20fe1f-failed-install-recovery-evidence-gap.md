# Attended test — failed-install recovery evidence-retention gap

Date: 2026-09-16
Cyberpunk version: 2.31
Test mode: ITERATION / recovery-only
Canonical main SHA: `bf20fe1f70c4a07affc88927314ac6dbaf73b08b`
Artifact/package: prior failed candidate `biology-integrated-20260916-144813-04d4c1584df4.zip` (expected SHA-256 `76A86A77A3C7AE36306B203C7946B88C5D56E1F7B0689489DA7EAF6D8783C796`)
Game-state evidence: W15 merged recovery bootstrap was run with the game closed.

## Included work

- W14.1 / issue #70 / collision-safe installer create-path repair and exact failed-install recovery
- W15.1 / issue #72 / ordinary ZIP directory-entry validation repair

## Expected acceptance

- [ ] Recovery authenticates the parent-reviewed failed report and prior candidate evidence.
- [ ] Recovery can inspect/repair the exact failed-install state without relying on user memory of loose temporary evidence files.
- [ ] Recovery remains fail-closed before mutation when required evidence is unavailable or ambiguous.

## Observed results

### PASS

- Recovery failed closed before installed-game mutation.
- Report explicitly records `Recovery mutation started: False` and that the installed game remained unchanged by this recovery attempt.

### FAIL / PARTIAL

- The recovery could not proceed because the retained failed candidate ZIP no longer existed at the loose `C:\Games\Biology-Candidate-Artifacts-...` path.
- Cross-turn correctness therefore still depended on the user remembering which loose report/artifact directories had to remain on disk.

## Evidence

Returned report: `Biology-Failed-Install-Recovery-bf20fe1f-20260916-113115-95248a36.txt`

Key excerpt:

```text
RESULT: FAIL-CLOSED
Error: Retained failed candidate artifact does not exist.
Recovery mutation started: False
Installed game remained unchanged by W14 recovery because failure occurred before recovery mutation began.
```

The report also records the expected failed candidate report SHA-256 `9709493A5D4C36F5960CAE2BF09781F664CEA32EB949A85375E44F2F7E943A1E` and expected retained artifact SHA-256 `76A86A77A3C7AE36306B203C7946B88C5D56E1F7B0689489DA7EAF6D8783C796`.

## Findings and routing

| ID | Finding | Expected | Observed | Owner / route | Follow-up issue/branch |
|---|---|---|---|---|---|
| EVIDENCE-01 | Cross-turn recovery depends on loose `C:\Games` evidence/artifacts surviving manually | Durable evidence should be repo-backed or reproducible; local retention should be machine-managed | Required prior ZIP had been deleted, blocking safe recovery | release/operator tooling follow-up | new parent-routed evidence-lifecycle lane |

## KEEP / FIX / REMOVE

- KEEP — exact source/report/artifact hashes already recorded in durable evidence.
- FIX — make durable operator evidence repo-backed and remove recovery dependence on manually retained loose artifacts where possible.
- REMOVE — manual `KEEP THIS FILE` memory burden as a normal cross-turn contract.

## Milestone disposition

Rejected for recovery completion; accepted as fail-closed evidence.

Reason: the tool protected the game correctly, but the operator evidence lifecycle is not self-managing enough.

## Next integration step

- Implement a repo-backed operator evidence lifecycle and a bounded current-state recovery path that does not require the missing prior ZIP to remain loose under `C:\Games`.
