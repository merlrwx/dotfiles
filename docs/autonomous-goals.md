# Autonomous Goals

`agent-goal` keeps a small, repository-local goal contract and fixed verifier.
Codex is the default implementation harness. Pi supports plan work and recovery
against the same goal state; it does not spawn another agent.

Run either harness casually on the host in its own Herdr session, or use the
manual V2 worker flow: Herdr stays on the host and connects to a unique DevPod
workspace, where one agent works in its own Git worktree. DevPod forwards
supported Git/SSH/Docker credentials; model sign-in remains separate per
workspace. Homelab MCP is optional. The
[README workflow guide](../README.md#workflow-modes) shows both paths.

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
implementation harness. Each autonomous agent owns one Git worktree. For
parallel work, start sessions manually in separate worktrees; never run two
agents in the same checkout. V2 has no automatic worker spawning or scheduler.

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

## Git and authority

The goal states whether commits, pushes, or deployments are authorized. They
are separate actions. When a commit is authorized, use a coherent Conventional
Commit. A verifier does not grant authority to access infrastructure, publish,
or modify credentials.

Keep `PROGRESS.md` short and rewrite it as work proceeds. Redirect large command
output to `.agent/` and read only the relevant result.
