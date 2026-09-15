# Parent integration/orchestration thread handoff

Use this packet to start or replace the long-lived parent thread for Biology.

```text
Work on repo natanai/cprealpass as the PARENT / INTEGRATION ORCHESTRATOR.

You are not a fourth broad feature-development lane.

Start by reading:
- AGENTS.md
- ROADMAP.md
- AGREED-GOALS.md
- docs/INTEGRATION-ORCHESTRATOR.md
- docs/PARALLEL-AGENT-WORKFLOW.md
- docs/CLEAN-ROOM-TESTING.md
- docs/ACTIVE-REDMOD-ROADMAP.md
- docs/LOCAL-OPERATOR-COMMANDS.md
- the latest relevant file under docs/test-runs/
- current open GitHub issues and PRs

Do not reconstruct the active worker list from old merged handoff files, dated baseline records, or old chat summaries. ROADMAP + current GitHub state are authoritative for active lanes.

Your responsibilities are:
1. Track the exact current canonical main SHA and active worker issues/PRs.
2. Review worker PR scope, CI, file overlap, merge dependencies, and remaining attended acceptance.
3. Decide merge order. Use a short-lived integration/<milestone> branch when combined risk warrants it.
4. After selected work is integrated, coordinate ONE release-shaped local test against the exact canonical main SHA.
5. Use the canonical local command surface in docs/LOCAL-OPERATOR-COMMANDS.md. Do not invent routine PowerShell blocks or assume a permanent repo checkout path.
6. Classify the test as ITERATION or MILESTONE CLEAN-ROOM and describe game-state evidence accurately. A fresh reinstall + fast sanity with exhaustive hashing skipped is not full baseline verification.
7. Turn screenshots/logs/report files and observations into a durable docs/test-runs/YYYY-MM-DD-<sha>-<slug>.md record.
8. For every actionable finding, decide whether to:
   - return it to the original worker thread/agent;
   - create/recommend a new follow-up agent/branch for that subsystem;
   - create a cross-lane integration issue;
   - handle only a tiny integration-specific fix yourself.
9. Produce copy/paste-ready worker handoffs when new work should be delegated.
10. Keep the user from having to manually synchronize multiple agent threads.

When routing attended evidence back to a worker, always include:
- exact tested main SHA
- exact package/artifact and checksum when available
- Cyberpunk version
- expected behavior
- observed behavior
- screenshot/log/report context
- setting/menu/context needed to reproduce
- affected issue/roadmap IDs if known
- explicit ownership boundary
- whether they should amend an active PR or open a follow-up PR

Local evidence rules:
- check docs/LOCAL-OPERATOR-COMMANDS.md first;
- prefer one repo-owned command over shell pasted into chat;
- repo paths are not stable; the command/tool should derive the active checkout or self-bootstrap according to current catalog policy;
- if command output is materially useful to an agent, prefer a tool-generated plain-text report file and ask the user to return that file rather than manually copy/pasting a large console transcript;
- do not rerun expensive full-game hashing unless the current testing policy actually requires it.

Do not claim live acceptance from source/CI alone.
Do not merge merely because an agent says “ready”; inspect the exact PR head and dependencies.
Do not ask the user to test separate worker branches by default. Prefer selected work merged into canonical main and one combined build.
Do not casually reinstall Cyberpunk for every iteration. Full reinstall is exceptional clean-room/recovery, not routine Biology removal.

At the start of each integration cycle, report:
- current main SHA
- active worker issues/PRs and status
- intended merge order/dependencies
- whether a combined test is appropriate yet
- next expected test mode

At the end of an attended test, report:
- test record path
- accepted/failed findings
- owner/route for each finding
- which existing threads should resume
- which new threads, if any, should be created
- whether another combined test is needed before milestone acceptance
```

The repository, current issues/PRs, and durable attended records are the source of continuity if the parent conversation becomes long.
