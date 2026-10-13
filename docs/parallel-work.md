# Parallel work with Herdr

Use parallel work when explicitly requested. The standing preference in this
setup counts a multi-repository autonomous implementation goal as a request for
bounded per-repository delegation; repeating `parallel-work` is unnecessary.
Other tasks remain single-agent unless delegation is requested. Herdr owns visible
processes, Git owns isolation, `agent-goal` validates each task, and the coordinator
reviews and integrates results. Start two ready workers; the maximum is three per run. There
is no background scheduler: the coordinator launches another batch when ready.

For short supervised work, use sibling panes. Shared-checkout edits require
explicit user choice and disjoint ownership with no active autonomous goal.
Read-only reviewers need neither new worktrees nor goal state. Substantial
implementation uses the isolated workflow below. Workers do not delegate.

## Worktree placement and authority

The helper reads `[worktrees].directory` from `HERDR_CONFIG_PATH`, otherwise
`$XDG_CONFIG_HOME/herdr/config.toml` (default `~/.config/herdr/config.toml`). The
fallback is `~/.herdr/worktrees`; `--worktree-root` is a deliberate per-task
override. Generated paths use `<repo-key>/<run>/<task>`. The repository key
includes canonical Git common-directory identity, so same-basename repositories
and linked integration checkouts are handled correctly. New runs use new branch
and Herdr resource names even when logical task names are reused.
Roots must be nonempty absolute paths (including `~/...`); relative or malformed
configuration is rejected rather than resolved beside the coordinator checkout.

One existing dedicated checkout is sufficient for a single root agent. Worktree
folders are for isolated workers, not an unavoidable side effect of every goal.
The helper does not create sibling directories beside source repositories.
Existing older worktrees are left alone until inspected and integrated.

Codex workers have a recorded `--permission-profile`: `full-access` (the host
workflow default), `workspace-write`, or `read-only`. Choose it once; retry and
resume reuse it. Full access disables command approvals and exposes the host
account's available filesystem/network access. A Git worktree is file/branch
isolation, not a sandbox or credential boundary. Read-only workers are useful for
review; they cannot finish an implementation requiring file writes.

The Bash wrapper no longer adds `--yolo` on `codex resume`. Herdr's automatic
conversation restoration is distinct from a managed `agent-worker resume`;
use the latter when the saved worker policy must be reapplied explicitly. No
claim is made that arbitrary Herdr-restored sessions inherit coordinator access.
Managed resume starts an absent process with the saved flags. It will not prompt
an already-live idle process whose effective permissions Herdr cannot attest;
exit that process first, then resume. An already-working task is left running.
Pi uses its own runtime policy; unsupported profile/runtime combinations fail
rather than silently applying a different policy.

Folder trust is separate again. Codex can ask once for an unfamiliar repository
even with `approval_policy="never"`; a trusted ancestor is not a guarantee that
a new repository/worktree will skip onboarding. Review that repository in Codex
before launching unattended workers. The helper does not approve trust dialogs
or automatically trust the entire worktree root. After onboarding, exit the
owned process and use `retry` to restart with the recorded policy.

Record commit, push, PR and deployment authority in the coordinator contract.
Workers receive scoped local commit authority only when granted; integration
and any authorized publishing stay with the coordinator. No permission needs to
be re-requested when the user already granted it for the active task.

## One task

Run inside a Herdr-managed pane, after inspecting project instructions and Git
status. Prepare a contract with outcome, acceptance criteria, scope, invariants,
verification and Git authority. Start from a clean repository checkout:

```bash
agent-worker spawn --repo "$PWD" --run-id api-upgrade --name api \
  --goal /path/to/api-goal.md --verify scripts/verify \
  --permission-profile full-access
agent-worker status --run-id api-upgrade
agent-worker inspect api --run-id api-upgrade
```

The default verifier is executable `scripts/verify`. A coordinator-local or
external verifier is copied to `.agent/VERIFY` in the new worktree. Keep its
acceptance assertions fixed. Repeat `--verify-input PATH` to pin helper files
from the task's Git base (JSON plans use `verify_input: ["path", ...]`).
Codex workers receive a native `/goal` prompt; Pi
workers use their installed continuation extension. The [goal guide](autonomous-goals.md)
explains the distinction between persistence and verification.

## Organization run from a parent folder

The parent does not need Git. Discover repositories without creating anything:

```bash
agent-worker discover /path/to/organization
```

Discovery considers that directory and its immediate children, deduplicating
linked worktrees. Select the repositories relevant to the request; pass another
explicit parent for deeper layouts. Do not recursively scan all of a home folder.

Store contracts and a JSON plan under `~/.local/state/agent-runs/<run>/` (or the
configured `AGENT_RUNS_DIR`). Paths below are illustrative absolute paths:

```json
{
  "tasks": [
    {
      "name": "api",
      "repo": "/path/to/organization/api",
      "goal": "/path/to/contracts/api.md",
      "verify": "scripts/verify",
      "permission_profile": "full-access"
    },
    {
      "name": "web",
      "repo": "/path/to/organization/web",
      "goal": "/path/to/contracts/web.md",
      "verify": "scripts/verify",
      "depends_on": ["api"],
      "permission_profile": "full-access"
    }
  ]
}
```

```bash
agent-worker plan --run-id org-upgrade --file /path/to/plan.json
agent-worker launch --run-id org-upgrade --jobs 2
agent-worker status --run-id org-upgrade
```

`plan` stores queued contracts without launching agents. A run may span multiple
repositories; each task records its repository and checkout independently.
`launch` starts ready work within the selected concurrency limit. Invoke it again
after integrating prerequisite tasks. Unknown dependencies and cycles are errors.

Within a repository, prerequisites must be integrated commits included in the
dependent's launch base. Across repositories, prerequisites are verified integration
gates. Specify artifact/version compatibility in the dependent's verifier when a
commit in another repository alone is insufficient. Fixed base commits cannot
include later integration. Queued symbolic bases such as `HEAD` are resolved at
first launch, requiring a clean checkout, ancestry from the initial base and
unchanged verifier inputs. Retries retain the resolved base; they do not rebase a
worker that has already started. A deliberately pinned stale hash remains queued.

## Collect and integrate

```bash
agent-worker collect api --run-id org-upgrade
# Review and apply the returned patch in the API integration checkout.
# Run combined checks, then create the authorized integration commit.
agent-worker integrated api --run-id org-upgrade --at HEAD \
  --checkout /path/to/api-integration --verify scripts/verify
agent-worker launch --run-id org-upgrade --jobs 2
```

Collection uses the shared lifecycle validator and reruns the verifier. It saves
staged, unstaged and untracked changes through a temporary index; the worker's
real index is unchanged. Herdr's done indicator is not verification evidence.
Integration validates the saved patch digest, checks containment at the specified
commit, requires the recorded base ancestry and a clean checkout, and runs the
combined verifier. Changing or truncating a collected patch invalidates it.

Serialize overlapping scopes. The coordinator resolves design conflicts rather
than allowing workers to take over sibling tasks. Inspect Git status before
staging, and stage only task-owned files.

## Recovery and cleanup

```bash
agent-worker retry api --run-id org-upgrade
agent-worker resume api --run-id org-upgrade
agent-worker cleanup api --run-id org-upgrade
```

Inspect status/output after a timeout before resubmitting anything. Retry checks
actual repository, branch, worktree, workspace, agent and session identity.
A missing response is not proof that a command never ran. Resume uses recorded
policy; uncertain session identity requires reconciliation rather than a blind
second prompt. A server restart does not guarantee interrupted commands finish.

Cleanup requires verified integration and the exact unchanged worker patch, or
a pristine explicitly abandoned task. It can retire an integrated uncommitted
patch: it preserves a central recovery archive including ignored files and goal
logs before removing the worktree. Late changes or a live/uncertain worker cause
a refusal. Archives, branches and run manifests remain available; the helper
reports the archive path. This trades recoverability for retained central storage;
review archives before deleting them separately. No automatic deletion of old
user worktrees or branches is performed.

Partial cleanup recovery requires durable pre-removal proof. A missing worktree
without that proof is not assumed safe, and saved server-local workspace IDs
must not be reused blindly after a server change.

## Installation and runtime differences

Chezmoi manages the CLI files and skill instructions separately: matching skills
do not prove matching executables. Review a targeted `chezmoi diff`, apply the
affected files, and check the installed commands. Pi settings are merged so local
provider/model preferences and unrelated settings survive; managed skill paths
are corrected and stale Codex plugin-cache entries are removed.

Herdr's skill is refreshed from the installed binary. Existing sessions keep
running; do not restart the server just to apply dotfiles. Refer to the installed
CLI `--help` and [Herdr documentation](https://herdr.dev/docs/agent-automation/)
for release-specific terminal controls.
