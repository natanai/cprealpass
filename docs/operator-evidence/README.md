# Biology operator evidence

This subtree is the canonical repository-backed home for **redistributable operator handoff evidence** that later commands may need after the user's local workspace has been discarded.

Each evidence identity lives at:

```text
docs/operator-evidence/<evidence-id>/
    evidence.json
    report.txt
```

The local operator PC does **not** push here. A repo-owned operator command produces one attachable handoff bundle containing exactly `evidence.json` and `report.txt`. The user returns that single bundle to the parent conversation. The parent/assistant verifies and commits those two files unchanged under the evidence ID declared in `evidence.json`.

## Durable vs local state

The repository record is durable. Local clones/worktrees remain disposable. Candidate ZIPs and artifact roots may temporarily survive only as machine-managed cleanup targets recorded in `evidence.json`; they are not a human `KEEP` list and are not the durable source of truth.

After the parent has committed the exact returned `evidence.json` and `report.txt`, the repo-owned operator cleanup command may fetch an exact canonical revision, compare the local handoff bundle byte-for-byte with the durable repository copies, validate any managed artifact root against the recorded payload hashes, and remove only those proven local targets. Changed, foreign, ambiguous, rooted, or reparse-point content fails closed.

## Evidence schema v1

Every record has:

- `schemaVersion: 1`
- `product: Biology`
- stable `evidenceId`
- operation and exact `sourceRevision`
- result classification and proof boundary
- relevant game/tool identity when the operation observed it
- historical artifact identity when applicable
- install/recovery state facts
- `recovery.mode` describing whether later recovery is authorized and by what proof boundary
- one local cleanup contract, when temporary artifacts exist
- for exact-payload recovery, the complete schema-2 Biology `payloadManifest` plus the exact SHA-256 of `biology/build-manifest.json`
- `handoff.reportSha256` for bundles produced by managed tools

The validator is `tools/BiologyOperatorEvidence.Core.ps1`.

### Recovery modes

`exact-payload-manifest`
: The durable record contains the exact schema-2 payload inventory and ownership receipt hash captured before install mutation. Recovery may remove only byte-identical Biology-owned files and now-empty Biology-owned directories. Generic/shared redscript/cybercmd entries are inspect/preserve-only.

`empty-owned-roots-only`
: Legacy escape hatch for an older attended failure that predates exact payload evidence. It may require specific Biology-owned files to be absent and may remove only exact Biology-owned root directories proven empty. Any file or nested content is ambiguous and stops recovery. It never guesses an old payload hash.

`none`
: The evidence is durable but does not authorize failed-install recovery.

## Parent ingestion contract

1. Receive the single operator handoff ZIP from the user.
2. Confirm it contains exactly `evidence.json` and `report.txt`.
3. Preserve those files byte-for-byte; do not pretty-print or rewrite the JSON because cleanup compares the returned files to the durable repository copies.
4. Commit them under `docs/operator-evidence/<evidence-id>/` through the normal reviewed parent GitHub flow.
5. Only after that commit is on an exact canonical revision may the safe local cleanup entrypoint be run.

Do not commit proprietary Cyberpunk payload, generated `final.redscripts`, candidate ZIP binaries, or third-party executable payload merely to preserve operator state.
