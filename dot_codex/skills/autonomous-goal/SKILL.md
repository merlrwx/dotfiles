---
name: autonomous-goal
description: Prepare, execute, or resume a persistent verified goal. Use when the user invokes autonomous-goal or asks to keep working to a concrete outcome. Supports repository work and organization goals; ordinary interactive tasks do not need goal state.
---

# Autonomous goal

Use the user's objective and existing authority. Inspect applicable instructions,
Git state, and `agent-goal status --json` before writing files. Resume an active
contract; preserve completed records before starting a new one. Invalid state
needs diagnosis, not deletion or a fabricated completion marker.

## Prepare or run

For review/preparation, write the contract without activating it. For a clear
implementation request, prepare and execute in this session. Grill only when
requested or when an unresolved choice materially changes the outcome.

The contract in `.agent/GOAL.md` needs outcome, observable acceptance criteria,
scope (`May modify`, `May operate`), invariants, verification, and Git workflow.
Carry commit, push, PR, and deployment authority from the user's instructions;
never repeatedly request authority already granted. Tool access does not grant
publishing authority. Workers inherit only their assigned subset.

Prefer the project's executable `scripts/verify`. Otherwise prepare a stable
`.agent/VERIFY` with goal-specific assertions. Freeze relevant helper files with
repeatable `--verify-input PATH`; do not claim a wrapper hash protects every
check it discovers. When changing tests is the task, keep the independent
acceptance assertions fixed and review the changed tests.

## Continuation

- **Codex:** use its native goal tool or `/goal` for persistence. Start the local
  verifier contract with `agent-goal start --continuation native --verify PATH`,
  then activate the native goal with the same outcome and require a successful
  `agent-goal complete` before declaring success. The CLI flag alone does not
  create a native goal. Native continuation and verification receipts have
  different responsibilities.
- **Pi:** use `agent-goal start --continuation pi --verify PATH`. The installed Pi
  extension consumes the same lifecycle validator; only one implementation
  agent may occupy an active-goal worktree.
- **Older Codex:** `--continuation hook` is a compatibility reminder with one
  repeat-stop guard, not an unbounded persistence guarantee. Prefer native goals.

Starting needs a clean checkout; do not use `--allow-dirty` to bypass unrelated
work. A root agent can use the current dedicated checkout. Additional autonomous
implementation agents need their own worktrees under the configured central root.

## Organization goals

A parent directory need not be a Git repository. Keep the coordinator's native
goal there. The user's standing preference authorizes bounded per-repository
delegation for autonomous implementation across multiple selected repositories;
use `parallel-work` without requiring the user to repeat that choice.
Discover/select repositories, keep contracts beside the run manifest under
`~/.local/state/agent-runs/`, and assign one local goal per worker worktree.
Do not initialize a parent Git repository or add sibling folders just to hold
state. Shared run planning and dependencies belong to `agent-worker`.

## Execute and finish

Make and verify scoped progress; rewrite `.agent/PROGRESS.md` at material
milestones, keeping it short. Keep large output in local logs. Preserve the
active verifier and its pinned inputs; failed checks require further work.

Run `agent-goal complete` after reviewing the diff and acceptance evidence.
Only then mark a native goal achieved. Invalid/legacy completion markers do not
prove success. Use `agent-goal block --reason ... --evidence ... --attempted ...
--unblock ...` only for an unavailable external dependency; ordinary difficulty
is not a blocker. The user can interrupt or pause; `agent-goal resume` resumes a
paused/blocked local contract. Use CLI `--help` for command details.
