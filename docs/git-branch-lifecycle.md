# Git branches and worktrees

This guide explains how branches relate to pull requests and worktrees, and how to clean up branches after work is integrated.

## What a branch is

A Git branch is a movable name for a commit. It is not a separate copy of the repository. A local branch is stored in your clone; a remote-tracking branch such as `origin/main` records the last version fetched from GitHub. A branch on GitHub is a separate remote ref, updated by pushing.

A worktree is a separate checkout connected to the same local Git repository. It can have its own branch and working files. This makes parallel work safer because each worker edits files in its own directory. The branch records committed work; uncommitted edits and untracked files exist only in that worktree until committed or collected.

## How work reaches `main`

1. Start a task branch from the current `main` and make focused changes.
2. Commit the changes on that branch. Push it to publish the branch on GitHub.
3. Open a pull request with `main` as the base. Review the diff and run the project's checks.
4. Merge the pull request. The branch's commits are then included in `main` (or GitHub creates a merge/squash commit containing their changes).
5. Delete the remote task branch after merge. Delete the local branch after its worktree has been removed or switched to another branch.

A branch is **merged** when its changes are part of the target branch. Its name can remain on GitHub or in a local clone after that; deleting the ref is a separate cleanup step. An unmerged branch with commits not in `main` still contains work that needs review, integration, or an explicit decision to abandon it.

## Checking a branch before cleanup

Fetch first so local remote-tracking refs are current:

```bash
git fetch --all --prune
```

Compare a branch to `main`:

```bash
git log --oneline main..origin/task-branch
git diff --stat main...origin/task-branch
```

If the log is empty, the branch has no commits ahead of `main`; it may already be merged or simply behind. Check the reverse direction and compare status before deleting:

```bash
git log --oneline origin/task-branch..main
git rev-list --left-right --count main...origin/task-branch
```

A branch that is behind `main` and has no commits ahead is stale. A branch that is ahead, or diverged, has commits to inspect. Look for its pull request and review its diff before merging or deleting it. Do not assume that a branch is safe to delete just because it has no open pull request.

For a pull request, GitHub's merged state is authoritative about whether it was merged. After confirming its changes are in the base branch, the remote branch can be removed:

```bash
git push origin --delete task-branch
```

GitHub may delete a pull request's branch automatically, depending on repository settings. Directly pushed branches without a pull request, worker branches, release branches, and automation branches can remain until someone explicitly cleans them up.

## Worktree cleanup

List worktrees and inspect each checkout before removing anything:

```bash
git worktree list
git -C /path/to/worktree status --short --branch
```

A local branch checked out in a worktree cannot be deleted until that worktree is detached, switched, or removed. The worktree cleanup command refuses to remove uncommitted changes by default. Preserve or integrate dirty and untracked files before cleanup; do not force removal just to clear a branch name.

For delegated work, first verify and integrate the worker's patch into the coordinator branch. Keep the worker checkout while it contains changes that have not been collected or committed. Once it is clean and no longer needed, remove the worktree, then delete its local branch.

## Practical rule

Merge or explicitly abandon the work represented by a branch before deleting it. Remove merged branch names to keep branch lists readable, and preserve dirty worktrees until their contents are accounted for.
