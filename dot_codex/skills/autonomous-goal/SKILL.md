---
name: autonomous-goal
description: Prepare or execute a persistent repository goal whose completion is enforced by verification and the Codex Stop hook. Use when the user invokes $autonomous-goal, asks Codex to keep working autonomously until a concrete outcome passes its checks, or resumes an active .agent goal. Do not use for ordinary interactive tasks that should end after one turn.
---

# Autonomous Goal

Turn a clear outcome into a small, externally checked implementation loop. The
goal and its runtime state live under the current Git repository's `.agent/`
directory and stay local through `.git/info/exclude`.

## Select the mode

- **Resume:** When `.agent/ACTIVE` exists, read `GOAL.md` and `PROGRESS.md`, then
  continue the work immediately.
- **Run now:** When invoked with a sufficiently clear goal, inspect the repo,
  write the contract, activate it, and execute it in the same session.
- **Prepare only:** When the user asks for review, preparation, or a later fresh
  session, write the contract but do not run `agent-goal start`.

Use Grill Me before preparation only when the user requests it or unresolved
choices would materially change the goal. Do not keep grilling during execution.

## Prepare the contract

Create `.agent/GOAL.md` with only the decisions needed to execute:

```markdown
# Goal

## Outcome

## Acceptance criteria

## Scope

### May modify

### May operate

## Invariants

## Verification

Run `./scripts/verify`.

## Git workflow

No commits, current-branch commits, or branch + MR. State commit, push, and MR
authority separately.
```

Acceptance criteria must be observable. Treat `--yolo` as tool access, not as
permission for commits, pushes, deployments, cluster changes, or destructive
operations. Those actions require explicit authority in the goal or user prompt.

Use the existing executable `scripts/verify` by default. If it cannot cover the
goal-specific checks, create an executable `.agent/VERIFY` wrapper before
activation and pass `--verify .agent/VERIFY`. Do not modify the selected verifier
after activation. If changing repository verification is itself the goal, use a
separate stable wrapper that checks the intended result.

For prepare-only mode, stop after showing the contract and how to begin in a
fresh session. For run-now mode, activate with:

```bash
agent-goal start [--verify .agent/VERIFY]
```

Starting requires a clean worktree unless the user deliberately authorized
`--allow-dirty`.

## Execute

1. Read applicable `AGENTS.md` files and inspect existing implementation before
   editing.
2. Use only skills relevant to the task. Ponytail and Caveman are not automatic
   defaults; the goal and measured local benchmark decide.
3. Make the smallest coherent change that satisfies the acceptance criteria.
4. Make routine implementation decisions without asking. Diagnose failures,
   change approach, and continue.
5. Rewrite `.agent/PROGRESS.md` after material milestones and before likely
   compaction. Keep it under roughly 60 lines with current work, completed work,
   next action, and failed approaches worth avoiding.
6. Redirect genuinely large output to `.agent/` logs and read back only the
   useful result or failure tail.

Do not weaken acceptance criteria, modify the active verifier, discard unrelated
work, or interpret repeated failure as permission to stop.

## Finish or block

Inspect the final diff, ensure every acceptance criterion has evidence, then run:

```bash
agent-goal complete
```

If verification fails, continue working. The global Stop hook also continues an
active goal when a turn ends prematurely.

Only a genuinely unavailable external dependency may end an incomplete run.
Record what is unavailable, evidence, attempted alternatives, and the exact
unblocking action:

```bash
agent-goal block \
  --reason "..." \
  --evidence "..." \
  --attempted "..." \
  --unblock "..."
```

The user can always interrupt Codex or run `agent-goal pause`. Resume paused or
blocked work with `agent-goal resume`.
