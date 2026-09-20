# Handoffs

This directory contains only durable handoff packets that are still useful as reusable workflow entry points.

## Active durable handoff

- [`PARENT-INTEGRATION.md`](PARENT-INTEGRATION.md) — start/replace the long-lived parent integration/orchestration thread.

## Worker handoff policy

Worker handoffs are usually **issue-specific and temporary**. Once a worker branch is merged and its task has moved into attended follow-up, its old copy/paste packet should not remain here pretending to be active.

Current worker branches and issue-specific instructions belong in:

1. root `ROADMAP.md`;
2. `../ACTIVE-REDMOD-ROADMAP.md`;
3. current GitHub issues/PRs and their comments;
4. the latest attended test record when a follow-up is evidence-driven.

Git history preserves retired handoffs when historical research is needed.

The project owner normally tests one combined canonical `main` candidate, not separately layered worker branches.
