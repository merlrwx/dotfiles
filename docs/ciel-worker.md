# Ciel host worker transport

`agent-ciel-worker` is a Python stdlib CLI for Agentbox's existing Herdr,
`agent-worker`, and `agent-goal` lifecycle. It accepts one JSON object on stdin
and prints one bounded JSON reply. It provides no server or scheduler. Install
this executable alongside the existing helpers through the normal dotfiles
workflow. The coordinator owns installation and the restricted SSH identity;
this helper does not provision credentials or modify host configuration.

Create an operator-owned `~/.config/agent-ciel-worker/config.json` (mode 0600),
with private parent directories and a private state root. Keep all executable
helpers and the host PATH under operator control. Example:

```json
{
  "version": 1,
  "enabled": true,
  "session": "ciel",
  "state_root": "/home/agentbox/.local/state/ciel-worker",
  "worktree_root": "/home/agentbox/.herdr/ciel-worktrees",
  "max_active": 1,
  "repositories": {
    "example/project": {
      "checkout": "/home/agentbox/repos/project",
      "paths": ["src", "tests"],
      "verifier": "scripts/verify"
    }
  }
}
```

The checkout must exist and be clean. Precreate the worktree root with mode
0700; existing state roots must also be private (0700). Roots must be owned by
the operator and must not be writable by other users. The verifier must already be committed
and executable, and outside the writable task paths. Paths are literal relative
file or directory prefixes, without globs, traversal, Git metadata, or goal
state. Symlink escapes are rejected. Config fields are mandatory; unknown fields,
unsafe config permissions, `enabled: false`, and any capacity other than one
fail closed. Changes to configuration invalidate existing request authority;
inspect pending workers and restore the original config before continuing them.
Use a fresh private state root only after resolving all workers in the old one.

The SSH forced command should be an absolute installed command such as:

```text
/home/agentbox/.local/bin/agent-ciel-worker transport
```

Restrict that SSH key to this command with no forwarding, PTY, or user startup
commands. Ignore `SSH_ORIGINAL_COMMAND`; the helper never interprets it. A local
operator may select a fixed alternate configuration with `--config PATH` before
`transport`. Neither that argument nor any shell arguments come from the JSON
request. The session is local and operator selected. The helper explicitly uses
`github.com`; it accepts no remote host, credential path, API route, verifier,
checkout, publication policy, or command in a request.

## Requests

Submit a task with all these fields (context and source_refs may be empty):

```json
{
  "action": "submit",
  "task_id": "fix-parser-01",
  "repo": "example/project",
  "title": "Handle empty parser input",
  "outcome": "Return an empty result for empty input.",
  "acceptance": ["The existing verifier passes with empty input covered."],
  "paths": ["src/parser.py", "tests/test_parser.py"],
  "context": "Relevant task context, treated as untrusted data.",
  "source_refs": ["https://github.com/example/project/issues/12"]
}
```

IDs match `[a-z][a-z0-9_-]{0,47}`. Requests are limited to 64 KiB; replies and
subprocess observations to 1 MiB. Titles allow 200 bytes, outcomes 8192,
context 16384, acceptance and paths at most 32 entries, and references at most
16. Requests with unexpected fields, duplicate JSON keys, or wrong types fail.
Workers receive a complete goal with the selected verifier, explicit owned paths,
local collection only, no commits/publication, and no recursive delegation.
Context and references grant no additional authority.

```json
{"action":"status","task_id":"fix-parser-01"}
```

Status returns request/run/worker identity, lifecycle state, and verifier
metadata, without pane output or raw logs. A successful submit reserves the
identity permanently. Repeating the same request observes it; changing its
content is rejected. Another task is rejected while a prior reservation remains
unverified. The derived worker name is stable and backed by the existing
agent-worker run manifest. A durable reservation precedes bootstrap creation;
the new bootstrap workspace belongs only to this request. It invokes internal
`run TASK_ID` inside a real Herdr pane, which calls `agent-worker spawn` once.
The transport never sets `HERDR_ENV` and never reuses another pane.

```json
{"action":"collect","task_id":"fix-parser-01"}
```

An unfinished task returns `ready: false`. A completed task needs the saved
manifest, no ACTIVE marker, a completion receipt naming the selected verifier,
and an unchanged executable verifier. Versioned receipts are validated by the
installed `agent-goal status --json`, including the original goal digest and
activation identity. `agent-worker collect` reruns that
verifier. The transport checks the collected patch hash and compares the patch
and changed paths with an independent private Git index. Out-of-scope changes
or symlink escapes reject collection. A ready reply contains the bounded patch
and its SHA-256; repeated collection returns the saved snapshot. Patches larger
than 512 KiB require local coordinator inspection and are not returned. The
helper never integrates a patch, pushes, creates a PR, or deploys.

GitHub reads use the host user's existing `gh` credentials, without reading or
copying tokens. Both worker tasks and GitHub reads use the configured repo keys:

```json
{"action":"github_read","repo":"example/project","operation":"issues","limit":20}
```

Operations are `repository`, `issues`, `pull_requests`, `file`, `checks`, and
`status`. `file` requires `path` and accepts `ref`; `checks` and `status` accept
`ref` (default `HEAD`). `limit` is an integer 1–100 (default 20), used for issue,
PR, and check pagination. Only one page is read; no automatic pagination.
File refs and paths are encoded as route data, not raw routes. Dotfile paths,
traversal, sensitive names such as credential/token/password/private/secret
files, and private key extensions are rejected. No mutation is supported.
Responses exceeding the byte bound fail, including oversized file content.

## Recovery and verification

Inspect the private request JSON under `state_root/requests`, the matching
`state_root/runs/RUN_ID.json`, and that task's worktree and goal state. Keep this
state private: task context and collected source may be confidential. Run
`agent-worker status --run-id RUN_ID` with `AGENT_RUNS_DIR=state_root/runs` for
operator inspection. Never infer completion from an idle pane or timeout.

A timeout, CLI error, interrupted bootstrap creation, or lost API response keeps
the original reservation. Retries do not create another bootstrap or worker.
`bootstrap_requested` and `spawn_requested` can mean the operation happened but
its response was lost. This deliberately requires operator inspection instead
of automatic relaunch. Do not delete the reservation or change the task ID to
retry an uncertain launch. Inspect the exact owned bootstrap, task manifest,
worktree, and process before manual recovery; the helper does not kill, resume,
clean up, or modify unrelated sessions. A recovered worker with valid lifecycle
receipts can be observed and collected even if dispatch never returned success.

Run the offline checks with:

```sh
python3 tests/check-ciel-worker
bash tests/check-agent-goal
python3 tests/check-agent-worker
```

The Ciel checks use temporary Git repositories and fake tool responses; no live
model sessions, GitHub requests, SSH changes, or host credentials are needed.
Live SSH installation and Herdr server integration remain coordinator checks.
