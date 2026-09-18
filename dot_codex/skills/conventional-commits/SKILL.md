---
name: conventional-commits
description: Create, edit, review, or validate Git commit messages using Conventional Commits 1.0.0. Use whenever preparing, suggesting, amending, reviewing, or running a Git commit.
---

# Conventional Commits

Inspect the staged diff before choosing a message. Describe the committed change, not the surrounding conversation or unstaged work.

Use this structure:

```text
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

- Use `feat` for a new feature and `fix` for a bug fix.
- Use another consistent type when appropriate, such as `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, or `test`.
- Add a short noun scope only when it materially locates the change.
- Write a concise imperative description without a trailing period.
- Add a body when the reason, behavior, migration, or tradeoff is not clear from the subject.
- Mark a breaking change with `!` before the colon or a `BREAKING CHANGE: <description>` footer.
- Put issue references and other metadata in Git-style footers.
- Recommend separate commits when staged changes contain multiple independent intents.

Validate the final message against the [Conventional Commits 1.0.0 specification](https://www.conventionalcommits.org/en/v1.0.0/). This skill does not authorize creating, amending, or pushing a commit; retain the authorization boundary from the user request.
