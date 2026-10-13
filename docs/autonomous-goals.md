# Autonomous goals

The workflow has three independent parts: a task contract, verification, and
continuation. `agent-goal` owns the first two. Codex native goals or Pi's small
extension own continuation. `agent-worker` coordinates explicitly delegated
work through Herdr; see [parallel work](parallel-work.md).

## State and commands

One Git worktree can have one active `.agent` goal and one root implementation
agent. Multiple worktrees of one repository may each have a goal. `AGENTS.md`
contains standing instructions; skills contain workflow instructions. Neither
launches processes by itself. The custom executables are `agent-goal` and
`agent-worker`; `herdr agent` controls visible processes, while Codex `/agent`
refers to Codex's own agents.

| File | Purpose |
| --- | --- |
| `.agent/GOAL.md` | Outcome, acceptance criteria, scope, invariants, verifier and authority |
| `.agent/PROGRESS.md` | Short checkpoint rewritten at meaningful milestones |
| `.agent/VERIFY` | Optional goal-specific executable verifier |
| `.agent/ACTIVE` | Goal identity, continuation owner, verifier digest/mode and pinned inputs |
| `.agent/COMPLETE` | Structured receipt written after verification |
| `.agent/PAUSE`, `.agent/BLOCKED.md` | Intentional suspension and recovery information |

State stays local via Git's exclude file. A normal single-agent task can use its
existing dedicated checkout; invoking the skill does not inherently create
another folder. Only additional isolated workers need worktrees.

```bash
agent-goal start --continuation native --verify scripts/verify \
  --verify-input scripts/check-contract
agent-goal status --json
agent-goal complete
agent-goal pause --reason "manual pause"
agent-goal resume
agent-goal block --reason "external service unavailable" \
  --evidence "connection failed" --attempted "checked DNS and fallback" \
  --unblock "restore the service, then resume"
```

`start` requires a clean checkout unless dirty work was deliberately authorized.
The selected verifier is immutable while active. Repeat `--verify-input` for
helper files whose contents and modes form fixed acceptance criteria. Pin an
explicit inventory: hashing a wrapper does not freeze dynamically discovered
checks. If the task changes tests, use independent fixed assertions and review
the changed checks. The CLI checks inputs both before and after verification.

`status --json` is the shared lifecycle API used by worker collection, the Codex
hook, and Pi. Its `status` is active, paused, blocked, complete, inactive or invalid;
`continue` is true only for valid active state. Empty, conflicting, escaped or
malformed markers are invalid, not proof of completion. Completion receipts
bind the goal and verification inputs; a matching receipt recovers an interrupted
final ACTIVE removal. This is consistency validation, not a cryptographic boundary
against an agent that can rewrite all local files.

Legacy ACTIVE records can finish through the new CLI. Old plain-text COMPLETE
markers are unverified: preserve them as historical evidence and explicitly
reverify before relying on them. Do not silently relabel them as validated.

## Codex persistence

Use `$autonomous-goal` to prepare the local contract and activate the native goal
with the same outcome. In the CLI this is `/goal <objective>`; the native tool is
also available to agents. Require a successful `agent-goal complete` before the
native goal is declared achieved. `--continuation native` records ownership and
suppresses the custom Stop hook; it does not activate a native goal by itself.

Native goals were verified as enabled in installed Codex 0.162.1 during this
workflow upgrade. Fresh configs seed `features.goals = true`. Existing configs
are preserved; use `codex features list` to inspect the installed capability.
See [native goals](https://learn.chatgpt.com/docs/use-cases/follow-goals).

The old `--continuation hook` mode remains for compatibility. Its repeat-stop
guard allows a reminder and avoids repeated hook injection. It is not the
persistent implementation loop. Native goals are the default for managed Codex
workers; their launcher submits the `/goal` command explicitly.

## Pi, Claude, and skill routing

Pi's `agent_before_settle` extension invokes `agent-goal status --json`; it no
longer maintains a second validator. Install the CLI and extension together.
Use `--continuation pi` when starting in Pi. Switch harnesses only after the
previous implementation agent has stopped; do not run two against one active goal.
The lightweight DevPod installer includes this portable core and adapter, but
does not configure host MCP or install a Herdr server.

Pi loads its standalone `~/.pi/agent/skills/grill-me` entry. In a repository it
reads existing docs and records settled decisions using the project's conventions.
It does not call a Codex Skill tool or depend on a versioned plugin cache.
The Codex GrillMe plugin's entry already selects grill-with-docs in a repository;
invoking its leaf skill directly can bypass that route. Do not edit plugin caches
to establish durable local behavior.

Pi supports Anthropic providers: authenticate with `/login` and select an
available model with `/model`. Claude in Pi uses Pi's tools and extension.
Claude Code is a separate process Herdr can launch; this custom autonomous
workflow has not added a Claude Code continuation adapter. Model sign-in stays
local and is never copied between harnesses.

## Organization goals and authority

Start the coordinator in the parent directory using a native goal. Select child
repositories and keep the run manifest/contracts under the agent state directory.
The parent does not need to be turned into a Git repository. Each implementation
worker receives its own local contract and worktree. This setup records the user's
standing request to delegate these multi-repository autonomous implementation
goals, so the user need not repeat a parallel-work permission each time. See the
multi-repository example in [parallel work](parallel-work.md).

Record authority once and carry it into assigned contracts. Full filesystem
access and disabled command approvals do not grant commit, push, PR or deployment
authority. Resuming a session must not add authority. A failed check calls for
further implementation; block only for an unavailable external dependency with
evidence and a recovery action. User interruption and pause remain available.
