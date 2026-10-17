---
name: parallel-work
description: Coordinate explicitly requested parallel or delegated coding and bounded reviews through Herdr and Git, including organization goals spanning repositories. Do not activate for ordinary single-agent work.
---

# Parallel work

Require `HERDR_ENV=1` before Herdr control and read its installed `herdr` skill.
Inspect instructions, Git status and existing run state. Preserve unrelated
sessions and work. Delegate only when the user explicitly asks, including the
standing request for bounded per-repository delegation in multi-repository
autonomous implementation goals. Other work stays single-agent by default.
Workers must not delegate recursively or adopt sibling goals.

## Choose the mode

### Interactive parallel

For short supervised tasks, prefer two workers and cap at three. Shared checkout
edits require the user's explicit choice, non-overlapping ownership, and no
active autonomous goal. Otherwise use isolated worktrees. Preserve user focus.

### Isolated autonomous

Use for substantial delegated implementation. The coordinator owns the overall
outcome, task graph, integration and publishing. Each worker owns one goal in one
worktree. Select independent tasks and clear verification before launch.

For an organization parent, run `agent-worker discover PARENT`, select the repos
in scope, and deduplicate by Git common-directory identity. Keep contracts and
the plan under `~/.local/state/agent-runs/<run>/`; the parent does not need Git or
`.agent`. Never create sibling worktree directories beside source repositories.

Record outcome, acceptance criteria, scope, invariants, verification and existing
Git authority in each contract. Keep pushes, PRs and deployments with the
coordinator; workers may commit only when their contract allows it. Permission
profiles control tool access, not publishing authority.

Use `agent-worker plan --run-id RUN --file PLAN.json` to queue multiple tasks,
then `agent-worker launch --run-id RUN --jobs 2` to start ready work, capped at
three. Use `agent-worker spawn --repo REPO --run-id RUN --name TASK --goal FILE
--verify PATH --permission-profile full-access` for one task. Select the recorded
profile deliberately; do not assume parent permissions are inherited. Read the
CLI help for supported profiles and runtimes. Herdr configuration controls the
central root; resource names and paths include repository, run and task identity.

Inspect with `agent-worker status` and `agent-worker inspect`. Herdr's terminal
status alone does not prove verification. After completion, `collect` rechecks
the goal and saves a patch. Review/apply it in the appropriate integration
checkout, run combined checks, and create an authorized integration commit.
Then use `agent-worker integrated TASK --run-id RUN --at HEAD --checkout REPO
--verify PATH`. Integration validates the collected digest and patch contents.

Same-repository prerequisites must be ancestors of the dependent's base.
Cross-repository prerequisites require verified integration and explicit
artifact/version assertions in the dependent's contract where applicable.
Launch the next ready batch after recording integration. Do not silently reuse
a stale base or turn missing commit authority into an unapproved commit.

Use `retry`/`resume` for recorded workers so their policy and identity are checked.
After a timeout, inspect before retrying; never send duplicate prompts blindly.
Use `cleanup` after integration. Preserve late changes, ignored files, goal logs
and recovery state; do not bypass a refusal with manual force removal.

## Deliberation

For a requested review, use two or three visible read-only agents with distinct
questions. No implementation goals or worktrees are needed for read-only work.
Gather evidence and recommendations in a bounded round, then close only the
panes you created. Implement only if the user has already requested it.
