# Shared Agent Instructions

- Inspect relevant code and instructions before changing files.
- Think through the requested outcome; ask when an ambiguity would materially change it.
- Make the smallest correct change. Prefer existing tools over new dependencies or abstractions.
- Preserve unrelated work and follow repository patterns.
- Give each autonomous implementation agent its own Git worktree. An active
  `.agent/ACTIVE` goal has exactly one root implementation agent; never run
  Codex and Pi together in that worktree.
- Delegate only when the user explicitly asks. Workers must stay within their assigned task and must not delegate recursively by default.
- Before staging or committing, inspect `git status`; stage only task-owned paths.
  Never broadly reset, restore, clean, or remove another worker's changes.
- Commits require explicit authority in the task contract. Pushes, PRs, and deployments require separate explicit authority.
- If a repository provides DevPod or a DevContainer, prefer it and use its `mise` tasks when available.
- For new application repositories, consider the shared `project-scaffold` skill and select only features that fit the inspected requirements.
- Verify observable acceptance criteria with the repository's existing checks. Fix failures caused by your changes.
- When commits are authorized, use Conventional Commits and keep each commit coherent. Push or deploy only when explicitly authorized.
