# Autonomous Codex goals

This setup adds a thin persistence harness around Codex CLI. Codex still does
the implementation; the harness only stores the contract, runs a fixed
verifier, and prevents an active turn from ending prematurely.

It follows the useful part of Andrej Karpathy's
[`autoresearch`](https://github.com/karpathy/autoresearch) pattern: a focused
objective, narrow authority, verifier-change detection, short external state,
and an autonomous implementation/verification loop. It
does not reproduce the research-specific commit/reset loop or assume that every
engineering task should run on a branch.

## Components

```text
~/.codex/AGENTS.md
~/.codex/hooks.json
~/.codex/skills/autonomous-goal/SKILL.md
~/.local/bin/agent-goal

repository/.agent/
├── GOAL.md
├── PROGRESS.md
├── ACTIVE
├── COMPLETE
├── PAUSE
└── BLOCKED.md
```

The `.agent/` directory is runtime state. `agent-goal start` adds it to the
repository's local `.git/info/exclude`, so it remains untracked without changing
the repository's `.gitignore`. Each worktree therefore has independent state.

## Two ways to start

For a fuzzy or risky task, clarify it first:

```text
$grill-me
I want to redo monitoring ...

Prepare the agreed outcome as an autonomous goal for review.
```

That writes the contract without activating it. Review `.agent/GOAL.md`, then
start a fresh Codex session:

```text
$autonomous-goal
```

For a clear task, start immediately:

```text
$autonomous-goal Implement <outcome>. Do not commit or deploy.
```

The skill creates the contract, activates it, and begins implementation in the
same session. It asks a question only when an unresolved choice would materially
change the result, authority, or safety.

## Goal contract

Use observable acceptance criteria and name external authority explicitly:

```markdown
# Goal

## Outcome

Describe the desired end state.

## Acceptance criteria

- Repository verification passes.
- The requested behavior is observable.

## Scope

### May modify

- Paths the implementation may change.

### May operate

- Local build and test commands.
- Cluster, deployment, SSH, or other external systems only when authorized.

## Invariants

- Do not destroy irreplaceable data.
- Do not weaken security to make verification pass.
- Preserve unrelated work.

## Verification

Run `./scripts/verify`.

## Git workflow

- Create a task branch, use Conventional Commits, push it, and open an MR.
- Or explicitly authorize current-branch commits.
- Push and MR creation are separate permissions from committing.
```

`--yolo` removes tool approval prompts. It does not expand the authority stated
by the request and goal.

## Verification

The normal contract is one executable repository verifier:

```bash
./scripts/verify
```

`agent-goal start` records its SHA-256 digest. `agent-goal complete` refuses to
finish if that executable changed after activation, runs it, and writes
`.agent/COMPLETE` only when it exits successfully.

This catches accidental or obvious verifier replacement; it is not a security
boundary against a process with unrestricted write access. Keep important helper
checks outside the goal's writable scope or include them in the selected wrapper.

When an ordinary repository verifier cannot express goal-specific runtime
checks, prepare an executable `.agent/VERIFY` wrapper before starting:

```bash
agent-goal start --verify .agent/VERIFY
```

The wrapper can call `./scripts/verify` followed by focused health checks. Do not
create it for goals already covered by the repository verifier. If changing
`scripts/verify` is part of the work, use a separate stable wrapper as the active
evaluator.

## Lifecycle commands

```bash
agent-goal start                    # requires clean Git state
agent-goal start --allow-dirty      # deliberate exception
agent-goal status
agent-goal complete                 # runs the fixed verifier
agent-goal pause --reason "..."      # manual escape hatch
agent-goal resume
agent-goal clear                    # removes current runtime state
```

A genuine external blocker must include evidence and a recovery action:

```bash
agent-goal block \
  --reason "required service is unavailable" \
  --evidence "health endpoint times out from two networks" \
  --attempted "checked DNS, route, status page, and fallback" \
  --unblock "restore the service, then run agent-goal resume"
```

Do not use `block` because an implementation failed, tests failed, the task grew,
or another reasonable technical choice is needed.

## Stop hook and interruption

When `ACTIVE` exists without `COMPLETE`, `PAUSE`, or `BLOCKED.md`, the global
Codex `Stop` hook returns `decision: "block"`. Codex creates another continuation
prompt and the agent keeps working. The hook intentionally does not impose an
iteration limit; the goal's verifier and acceptance criteria are the stop
condition.

Ctrl-C still interrupts immediately. Codex's `Interrupt` lifecycle cannot be
blocked. Herdr uses the same Codex configuration, so restored Herdr sessions get
the same behavior.

Goal state belongs to the Git worktree, not to a Codex thread. Run only one root
Codex session against an active worktree; use another Git worktree when goals or
interactive sessions must run in parallel.

After installation or any hook command change, open `/hooks` in Codex and trust
the new `Stop` hook. Codex binds trust to the hook definition's hash and will ask
again after it changes. For a one-off automated smoke test only, Codex supports
`--dangerously-bypass-hook-trust`; do not make that the normal launcher.

## Progress and command output

Rewrite `.agent/PROGRESS.md`; do not append indefinitely. Keep it to roughly
30–60 lines:

```markdown
# Current

# Completed

# Current problem

# Next

# Failed approaches
```

Redirect output that would flood context into `.agent/`, then read back the
metric, error, or short tail needed for the next decision.

## Git workflows

The goal chooses the workflow; the harness does not silently choose one:

- **No Git workflow:** edit and verify only.
- **Current branch:** Conventional Commits may be created when authorized; push
  remains separate.
- **Branch + MR:** start clean, create a task branch, commit conventionally,
  push, open an MR, and include required remote CI in the acceptance criteria.

Karpathy's dedicated branch supports repeated experimental commits and resets.
For production development, a branch and MR instead provide review and CI. For a
personal repository, an explicitly authorized commit to `main` is also valid.

## Skill benchmark

Optional implementation skills must earn a default place. The initial pilot
compares four profiles on three historical tasks in disposable worktrees:

```text
A  Codex baseline
B  Codex + Caveman
C  Codex + Ponytail
D  Codex + Caveman + Ponytail
```

Runs pin the model and reasoning level, disable the autonomous Stop hook, avoid
live infrastructure and remotes, and use the same prompt and hidden verifier for
each arm. Score correctness first, then changed files/lines, dependencies, tool
activity, tokens, elapsed time, and unnecessary abstractions. One repetition is
a pilot, not a statistically strong conclusion; repeat close results before
changing the default profile.

Use `benchmark-codex-skills --help` for the reusable runner. Record later pilots
alongside their model, reasoning level, task mix, and verifier results.

### Initial pilot — 2026-09-21

The pilot used `gpt-5.6-sol` at medium reasoning on one shell/bootstrap task,
one Python validation task, and one TypeScript security-policy task. All 12
outputs passed the protected semantic checks.

| Profile | Passes | Changed LOC | Files | Tool calls | Input tokens | Output tokens | Time |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Baseline | 3/3 | 99 | 7 | 28 | 684,508 | 11,281 | 310s |
| Caveman | 3/3 | 100 | 6 | 28 | 765,318 | 13,215 | 356s |
| Ponytail | 3/3 | 194 | 8 | 34 | 936,024 | 15,369 | 438s |
| Combined | 3/3 | 162 | 8 | 36 | 1,014,713 | 13,761 | 366s |

The original setup-task evaluator accepted only the historical
`init --apply --source` spelling. It was corrected to accept equivalent local
`apply --source` forms, then the unchanged outputs were rescored. No arm received
another implementation attempt.

**Decision:** keep Caveman and Ponytail available on demand, but make neither a
default of autonomous execution. Baseline was equally correct and had the best
aggregate complexity, tool-use, token, and elapsed-time results. This is a
one-repetition pilot; repeat or expand it before treating the margins as a
general model claim.

## Installation and maintenance

Chezmoi manages all global files. Apply only these targets when testing changes
on an existing machine:

```bash
chezmoi -S /path/to/this/dotfiles/checkout apply \
  ~/.codex/AGENTS.md \
  ~/.codex/hooks.json \
  ~/.codex/skills/autonomous-goal \
  ~/.local/bin/agent-goal
```

Then review `chezmoi diff`, run `tests/check-agent-goal.sh` from the source
repository, and approve the hook through `/hooks`.
