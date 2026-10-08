---
name: parallel-work
description: Coordinate explicitly requested parallel, delegated, or multi-agent coding work through Herdr and Git. Use when the user asks to delegate, split work into agents, parallelize tasks, run independent workers, coordinate phases, or convene a bounded review. Do not activate for ordinary single-agent coding.
---

# Parallel work

Use this skill only after the user asks for delegation or parallel work. Keep
ordinary coding single-agent. Herdr owns visible processes, Git owns worktree
isolation, and `agent-goal` owns each autonomous worker's verifier loop.

Before controlling Herdr, confirm the coordinator is in a Herdr pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If this fails, do not inspect or control a Herdr session from outside it. Ask
the user to continue from a Herdr-managed pane. Read the installed `herdr` skill
for command details. Prefer explicit IDs returned by Herdr and `--no-focus` for
background workers.

## Choose a mode

### Interactive parallel

Use for small, short tasks that the user wants to supervise live.

- Start with two workers; use at most three.
- Shared-checkout work is allowed only when the user explicitly chooses it.
- Before using a shared checkout, require no active `.agent/ACTIVE` goal and
  assign non-overlapping file ownership. If ownership overlaps, serialize or
  use isolated worktrees.
- Split a sibling pane, start a named Codex or Pi agent, and send a narrow task
  prompt. Do not create a worktree unless requested.
- Workers inspect Git status and stage only files in their scope. Do not stage,
  reset, restore, or clean another worker's files. Do not auto-commit.

### Isolated autonomous

Use for multi-phase plans, longer work, or whenever workers need independent
verification. This is the default mode for delegated implementation.

1. Read the plan and repository instructions. Split it into small tasks with
   observable acceptance criteria and file ownership hints.
2. Draw task dependencies before launching anything. Mark uncertain edges and
   ask the user to confirm them before they affect parallel execution.
3. Prefer two ready workers initially and cap the run at three. Launch only
   tasks whose dependencies have been integrated and verified.
4. Prepare a complete task contract for each worker. Save it under a
   coordinator-local path such as `.agent/parallel/<run-id>/<task>.md`. Include
   outcome, acceptance criteria, scope, verification, invariants, and Git
   authority. Keep push, PR, and deployment authority absent unless the user
   explicitly grants each one.
5. Use one task ID for the Herdr name and branch suffix. IDs must match
   `[a-z][a-z0-9_-]{0,31}`. Use a common run ID matching
   `[a-z][a-z0-9_-]{0,47}`.
6. Launch each ready task from a clean integration commit:

   ```bash
   agent-worker spawn \
     --repo "$PWD" \
     --run-id feature-upgrade \
     --name phase-01 \
     --goal .agent/parallel/feature-upgrade/phase-01.md \
     --kind codex \
     --base HEAD
   ```

   Add one `--depends-on task-id` for each prerequisite. Pass `--verify PATH`
   for a task-specific verifier; a coordinator-local or external verifier is
   copied into that worker's `.agent/VERIFY` before activation. The helper
   refuses unmet dependencies, dirty source checkouts, duplicate branches or worktrees,
   invalid goal contracts, and more than three active autonomous workers. Use
   `--kind pi` to select Pi. Do not run Codex and Pi in one active-goal worktree.
7. Record the returned workspace, root pane, branch, base commit, and task ID in
   the run manifest. Inspect progress with:

   ```bash
   agent-worker status --run-id feature-upgrade
   agent-worker inspect phase-01 --run-id feature-upgrade
   ```

   Herdr `done` is a terminal state only. A worker is ready to collect only
   after its own `.agent/COMPLETE` exists and `.agent/ACTIVE` is gone; that
   marker is written after the fixed verifier passes.
8. Collect one verified task at a time. Review its summary and patch path:

   ```bash
   agent-worker collect phase-01 --run-id feature-upgrade
   ```

   Apply the saved patch in a separate integration worktree or branch. Inspect
   ownership and the full diff, resolve conflicts in the coordinator, and run
   the combined repository verification. Stop and report substantive design
   conflicts instead of letting workers take over sibling tasks.
9. After combined verification, record integration at the commit containing
   the collected patch:

   ```bash
   agent-worker integrated phase-01 --run-id feature-upgrade --at HEAD \
     --checkout "$PWD" --verify scripts/verify
   ```

   The helper checks that the task verifier completed, the integration commit
   descends from the recorded base, and the collected patch is present there.
   Dependent tasks must use that integration commit as `--base`; the helper
   checks that each dependency is integrated and included in the base.
10. Start newly ready tasks and repeat. Keep integration commits local and
    create them only when the user's task contract authorizes commits. A
    dependent autonomous worker needs a commit representing the verified
    integration. If that authority is absent, stop before launching dependent
    work and ask the user to authorize the local integration commit or choose a
    serial workflow.
11. Clean up only after integration. `agent-worker cleanup` refuses dirty
    worktrees and never force-removes them. Keep the run manifest and branches
    as recovery evidence.

Each task owns only its own `.agent/GOAL.md` and active goal in its worktree.
The prompt must tell the worker not to discover or adopt sibling goals and not
to delegate recursively. Each active goal has one root implementation agent.

## Deliberation

Use only when the user asks for research, alternatives, or independent review
before implementation.

- Launch two or three named, read-only agents with distinct questions or
  evaluation angles.
- Ask each for evidence, assumptions, risks, and a recommendation in a short
  structured response. Tell them not to edit files, run implementation, or
  start other agents.
- Collect results with Herdr, then synthesize one decision in the coordinator.
  Do not run an open-ended agent-to-agent discussion.
- Record a meaningful decision or rejected alternative in project docs when
  the task calls for it. Start implementation only after the decision is made.

## Recovery and Git boundaries

- Use the manifest under `~/.local/state/agent-runs/` after coordinator
  interruption. Re-check Herdr, each worktree, `.agent/PROGRESS.md`, and
  `.agent/ACTIVE` before retrying a command.
- Do not infer that a timed-out prompt was not delivered. Inspect the target
  before resending.
- Do not reuse a branch, task name, or worktree from a prior run. Do not delete
  dirty worktrees or discard unrelated changes.
- Workers must inspect `git status` before staging or committing and stage only
  task-owned paths. Pushes, PRs, and deployments always require separate user
  authority.
- Use a reviewer only for significant or sensitive changes, not every small
  task.
