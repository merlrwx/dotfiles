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

## Teach workspaces

When using Engineering Suite Teach or another stateful teaching skill, treat the current project as read-only context. Resolve the canonical Git worktree root when inside a repository; otherwise use the canonical current directory. Store all teaching state outside the project in a persistent per-context directory, named with the context directory and a short SHA-256 digest of its canonical path:

- Linux/macOS: `${XDG_DATA_HOME:-$HOME/.local/share}/engineering-suite-teach/<context>-<path-hash>`
- Windows: `%LOCALAPPDATA%\Engineering-Suite-Teach\<context>-<path-hash>`

Call this directory `TEACH_WORKSPACE`. Resolve its path including symlinks and verify it is outside the Git worktree before writing. If that cannot be verified, ask the user; never fall back to the project. Keep every mission, lesson, note, resource, reference, learning record, and asset there. Do not create, edit, delete, move, or symlink teaching files in the repository, even if ignored; do not change `.gitignore`, `.git/info/exclude`, or `.git/` to hide them. If legacy Teach files already exist in a project, leave them untouched and ask before importing them.

## Git commits

- Before creating or amending any Git commit, invoke and follow `$conventional-commits`.
- Use the Conventional Commits 1.0.0 format for every commit message.
- Base the message on the staged diff and do not include unrelated unstaged work.
- Treat commit and push operations as separate external mutations; perform only those the user authorized.
