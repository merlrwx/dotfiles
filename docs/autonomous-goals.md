# Autonomous Goals

`agent-goal` keeps a small, repository-local goal contract and fixed verifier.
Codex is the default implementation harness. Pi supports plan work and recovery
against the same goal state; its extension continues an active goal but does not
spawn another agent on its own. The `parallel-work` skill can select Pi as a
worker when the user asks for delegation.

Run either harness on the host in its own Herdr session. When the user asks for
delegation, the `parallel-work` skill coordinates named Herdr workers in
isolated Git worktrees. The `agent-worker` helper activates the same goal
contract in each worker and records its workspace, branch, dependencies, and
result. DevPod remains an optional isolated environment when a project needs
its container tools; supported Git/SSH/Docker credentials are forwarded by
DevPod, while model sign-in remains separate. Homelab MCP is optional. See the
[README workflow guide](../README.md#workflow-modes) and
[parallel-work guide](parallel-work.md).

## Workflow

For a clear implementation task, start in Codex with:

```text
$autonomous-goal Implement <outcome>. Do not commit or deploy.
```

For a larger change, use ChatGPT to discuss the design and draft `PLAN.md`.
Review the repository, then run `$grill-me` in a separate session to identify
missing decisions, assumptions, risks, and acceptance criteria. Save the
revised plan and start a fresh implementation session with
`$autonomous-goal Implement PLAN.md` in Codex.

The plan is the handoff. Do not carry the brainstorming transcript into the
implementation session.

For planning, Pi can grill a draft before activation; Codex remains the default
implementation harness. Each active goal has one root implementation agent in
one Git worktree. Codex and Pi can resume the same goal format in separate
sessions, but must not run together in one active-goal worktree. Parallel work
is opt-in, capped at three workers, and must follow the task ownership and
integration rules in the `parallel-work` skill. Workers do not delegate
recursively by default.

## Goal contract

An active goal uses:

```text
repository/.agent/
├── GOAL.md
├── PROGRESS.md
├── VERIFY
├── ACTIVE
├── COMPLETE
├── PAUSE
└── BLOCKED.md
```

`GOAL.md` records the outcome, acceptance criteria, scope, invariants, and
verification. `PROGRESS.md` is a concise checkpoint. `ACTIVE` records the
fixed verifier and its SHA-256 digest. `agent-goal complete` refuses to finish
if that verifier changed, runs it, then records completion. The `.agent/`
directory is excluded through the worktree's local `.git/info/exclude`.

When repository checks do not cover goal-specific runtime requirements, create
an executable `.agent/VERIFY` wrapper before starting:

```bash
agent-goal start --verify .agent/VERIFY
```

Once activated, keep that verifier fixed. Extend its helper checks before
activation or choose a new goal for materially different acceptance criteria.

## Lifecycle

```bash
agent-goal status
agent-goal complete
agent-goal pause --reason "manual pause"
agent-goal resume
agent-goal block \
  --reason "required external service unavailable" \
  --evidence "connection timed out from the host" \
  --attempted "checked DNS and the fallback endpoint" \
  --unblock "restore service, then run agent-goal resume"
```

Only use `block` for an unavailable external dependency. A failed approach or
test is part of the work: fix it, update progress, and continue. Ctrl-C remains
available as an immediate manual interruption.

The Codex Stop hook continues an active implementation goal only while
`.agent/ACTIVE` is valid and no `COMPLETE`, `PAUSE`, or `BLOCKED.md` marker
exists. Pi's `agent_before_settle` extension is a recovery compatibility path:
it continues the goal only when Pi is deliberately opened in that active
worktree. This extension is part of the host Pi configuration; the lightweight
DevPod dotfiles install shared instructions and the Pi CLI but omits that
extension and host MCP settings. Do plan grilling before activation or in a
separate worktree. Pi also checks that the verifier remains inside the
repository and matches the activated digest.

Detaching an SSH client keeps the Herdr server's pane processes alive. A full
Herdr server restart may restore supported agent conversations, but interrupted
commands do not automatically resume. Check `agent-worker status`, the
worktree, `.agent/PROGRESS.md`, and lifecycle markers before continuing.

## Git and authority

The goal states whether commits, pushes, or deployments are authorized. They
are separate actions. When a commit is authorized, use a coherent Conventional
Commit. A verifier does not grant authority to access infrastructure, publish,
or modify credentials.

Keep `PROGRESS.md` short and rewrite it as work proceeds. Redirect large command
output to `.agent/` and read only the relevant result.
