# Parallel work with Herdr

Parallel work is opt-in. Ordinary Codex and Pi sessions remain single-agent.
Start a coordinator inside Herdr, then ask it to delegate, parallelize, or
coordinate independent phases. Herdr keeps the workers visible, Git worktrees
isolate their files and branches, and `agent-goal` checks each autonomous
worker's result.

The host CLI profile provisions Herdr's release-matched `herdr` skill into
Codex and Pi. That skill only allows Herdr control from a Herdr-managed pane.
The `parallel-work` skill supplies the task planning and integration workflow.
Herdr's own [agent automation guide](https://herdr.dev/docs/agent-automation/)
and [CLI reference](https://herdr.dev/docs/cli-reference/) describe the
underlying commands.

## Ask for delegated work

For a multi-phase plan:

```text
$autonomous-goal Implement PLAN.md. Use isolated parallel mode for independent
phases, begin with two Codex workers, and keep push and deployment disabled.
You may make local integration commits after combined verification so dependent
phases can start.
```

For a small set of changes to supervise live:

```text
Use interactive parallel mode to handle the independent documentation and
configuration updates. Give each worker explicit file ownership and show me
the results before integrating anything.
```

For alternatives or a review before implementation:

```text
Run a bounded read-only round-table with three agents: one check compatibility,
one identify operational risks, and one propose the smallest design. Summarize
the evidence and wait before implementing.
```

The coordinator first checks project instructions and Git state. It splits a
plan into independently verifiable tasks, identifies prerequisites, and starts
only ready tasks. Uncertain dependencies are confirmed before they affect the
launch order. Two workers is the normal starting point; three is the limit.

## Execution modes

### Interactive parallel

Use for short work under close supervision. Each worker gets a visible Herdr
pane, a unique name, a narrow prompt, and file ownership. A shared checkout is
allowed only when the user explicitly chooses it, there is no active
`.agent/ACTIVE` goal, and the scopes do not overlap. If any condition fails,
use separate worktrees or work serially. Workers do not stage, commit, revert,
or clean changes outside their assigned paths.

### Isolated autonomous

Use for substantial tasks and multi-phase plans. Each worker gets:

- a unique Herdr workspace and Git branch under `~/.herdr/worktrees/`;
- one task-specific `.agent/GOAL.md` and fixed verifier state;
- a run manifest with its task ID, dependencies, workspace and pane IDs, base
  commit, branch, patch, and integration result.

The coordinator creates the task contracts under a local path such as
`.agent/parallel/<run-id>/`. A task contract includes outcome, observable
acceptance criteria, owned files, verification, invariants, and Git authority.
Workers do not adopt sibling goals or delegate recursively. Choose `--kind
codex` or `--kind pi`; never run both in one worktree with an active goal.

The installed `agent-worker` helper wraps the Herdr CLI:

```bash
agent-worker spawn \
  --repo "$PWD" \
  --run-id api-upgrade \
  --name phase-01 \
  --goal .agent/parallel/api-upgrade/phase-01.md \
  --kind codex \
  --base HEAD

agent-worker spawn \
  --repo "$PWD" \
  --run-id api-upgrade \
  --name phase-02 \
  --goal .agent/parallel/api-upgrade/phase-02.md \
  --kind codex \
  --base HEAD
```

Use `--depends-on phase-01` for a dependent task, and pass the verified
integration commit as `--base`. The helper refuses a dirty source checkout,
duplicate task names or branches, an existing worktree path, missing verifier,
unmet dependencies, and more than three active workers. It records run state at
`~/.local/state/agent-runs/<run-id>.json`. Recovery commands are:

The default verifier is the project's executable `scripts/verify`. Pass
`--verify PATH` for a worker-specific verifier. A verifier under coordinator
`.agent/` or outside the project is copied into the new worktree as
`.agent/VERIFY` before the goal is activated.

```bash
agent-worker status --run-id api-upgrade
agent-worker inspect phase-01 --run-id api-upgrade
agent-worker collect phase-01 --run-id api-upgrade
```

`collect` requires `.agent/COMPLETE` and `.agent/ACTIVE` to be absent in the
worker checkout. It saves the worker's full patch, including staged, unstaged,
and untracked files, without staging anything in the worker's real Git index.
Herdr's `done` indicator alone is not verification evidence.

Apply collected patches in a separate integration worktree or branch. Inspect
the whole diff, resolve conflicts as coordinator, and run combined repository
verification. Only then mark the task integrated:

```bash
agent-worker integrated phase-01 --run-id api-upgrade --at HEAD \
  --checkout "$PWD" --verify scripts/verify
```

The helper checks that the integration commit descends from the worker's base
and contains the collected patch. Dependent workers must use a base commit that
includes each integrated prerequisite. Creating that commit requires local
commit authority in the user's task contract. Without it, do not start the
dependent phase; ask whether the user authorizes a local integration commit or
prefers serial work in the existing checkout. Push, PR, and deployment rights
are always separate.

Cleanup keeps branches and manifests for recovery and refuses dirty worktrees:

```bash
agent-worker cleanup phase-01 --run-id api-upgrade
```

Workers normally leave uncommitted edits in their worktrees, so cleanup will
refuse until the worktree is clean. Preserve those files after patch integration
unless the task explicitly authorized a worker commit; never force cleanup.

### Deliberation

Launch two or three visible agents with different read-only questions. Ask for
evidence, assumptions, risks, and a recommendation. Agents must not edit files,
start implementation, or launch more agents. The coordinator gathers their
responses, writes a concise synthesis, and waits for the user's decision when
implementation was not already requested. Keep the exchange bounded; workers
do not debate each other indefinitely.

## Recovery and integration rules

- Detaching SSH leaves Herdr's existing server and pane processes running.
- A full Herdr server restart can restore supported agent conversations, but
  an interrupted command is not guaranteed to resume. Re-check the worktree,
  Herdr state, `.agent/PROGRESS.md`, and goal markers before continuing.
- Run `agent-worker status` after coordinator interruption. Do not resend a
  prompt merely because a previous CLI call timed out; inspect the worker first.
- A worker is complete only after its fixed verifier passes and
  `agent-goal complete` writes `.agent/COMPLETE`. A completed worker is not
  integrated until the coordinator reviews its patch and combined verification
  passes.
- Serialize overlapping file ownership. Stop and report substantive design
  conflicts rather than making workers take over each other's tasks.
- Inspect `git status` before staging or committing. Stage only task-owned
  paths. Never use broad reset, restore, or cleanup commands in a shared
  checkout.
- Use a reviewer agent only for significant or sensitive changes.

Provisioning updates the Herdr configuration and agent skill files without
editing, closing, or migrating an existing Herdr workspace. Apply the dotfiles
from a maintenance shell only after reviewing the Chezmoi diff; existing
sessions keep their running processes. The skill is refreshed from the
installed Herdr binary on each Chezmoi apply, so its command details match that
release.
