# Shared Agent Instructions

- Inspect relevant code and instructions before changing files.
- Think through the requested outcome; ask when an ambiguity would materially change it.
- Make the smallest correct change. Prefer existing tools over new dependencies or abstractions.
- Preserve unrelated work and follow repository patterns.
- Give each autonomous implementation agent its own Git worktree. An active
  `.agent/ACTIVE` goal has exactly one root implementation agent; never run
  Codex, Claude Code, or Pi together in that worktree.
- Delegate only when the user explicitly asks. Workers must stay within their assigned task and must not delegate recursively by default.
- The user has explicitly requested bounded per-repository delegation for
  autonomous implementation goals spanning multiple selected repositories.
  Treat that as standing delegation authority for those goals; it does not
  grant commit, push, PR, or deployment authority.
- Before staging or committing, inspect `git status`; stage only task-owned paths.
  Never broadly reset, restore, clean, or remove another worker's changes.
- Commits require explicit authority in the task contract. Pushes, PRs, and deployments require separate explicit authority.
- If a repository provides DevPod or a DevContainer, prefer it and use its `mise` tasks when available.
- Start every new repository with the shared `project-scaffold` skill: generate
  it with `new-project` from the latest DevOps template release, selecting only
  features that fit the inspected requirements (`generic` when no listed stack
  applies). Hand-build only when the user asks or Copier cannot run; say why.
- Verify observable acceptance criteria with the repository's existing checks;
  run `mise run check` when the repository defines it. Fix the root cause of
  failures caused by your changes instead of adding suppressions or skips.
- When commits are authorized, use Conventional Commits and keep each commit coherent. Push or deploy only when explicitly authorized.
