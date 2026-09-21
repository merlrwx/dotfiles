# Global Codex instructions

## Execution

- Inspect existing code and configuration before modifying it.
- Make the smallest coherent change that satisfies the requested outcome.
- Use only relevant skills; do not introduce speculative abstractions or dependencies.

## Verification

- Never claim completion without running the available verification.
- Fix failures caused by your changes and inspect the final diff.

## Autonomous goals

When `.agent/ACTIVE` exists:

- Read `.agent/GOAL.md` and `.agent/PROGRESS.md`.
- Continue autonomously through implementation and verification failures.
- Keep `.agent/PROGRESS.md` concise and current.
- Redirect very large command output to `.agent/` and read back only relevant results.
- Complete only through `agent-goal complete`.
- Use `agent-goal block` only for a genuine unavailable external dependency.
- Treat `--yolo` as tool access, not additional authority beyond the goal.

## Context

- Avoid flooding context with large command output or repeatedly reading unchanged large files.

## Git commits

- Before creating or amending any Git commit, invoke and follow `$conventional-commits`.
- Use the Conventional Commits 1.0.0 format for every commit message.
- Base the message on the staged diff and do not include unrelated unstaged work.
- Treat commit and push operations as separate external mutations; perform only those the user authorized.
