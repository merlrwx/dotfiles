# Shared Agent Instructions

- Inspect relevant code and instructions before changing files.
- Think through the requested outcome; ask when an ambiguity would materially change it.
- Make the smallest correct change. Prefer existing tools over new dependencies or abstractions.
- Preserve unrelated work and follow repository patterns.
- Give each autonomous agent its own Git worktree; never run two agents in one checkout.
- If a repository provides DevPod or a DevContainer, prefer it and use its `mise` tasks when available.
- Verify observable acceptance criteria with the repository's existing checks. Fix failures caused by your changes.
- When commits are authorized, use Conventional Commits and keep each commit coherent. Push or deploy only when explicitly authorized.
