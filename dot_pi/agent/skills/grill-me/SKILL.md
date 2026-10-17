---
name: grill-me
description: Stress-test a plan, design, or decision through a detailed interview. Use when the user asks to be grilled, says "grill me", or wants to sharpen a plan before implementation.
---

# GrillMe

Interview the user until you reach a shared understanding of the plan. Map the
decisions as a design tree: each decision unlocks the decisions that depend on it.

Read the user's plan and inspect relevant repository files with Pi's available
tools. Look up facts yourself; ask the user to make decisions. Follow the shared
agent instructions when deciding whether to delegate an investigation.

In a working repository, default to grilling with docs: inspect existing plans,
README, CONTEXT.md and relevant design records before questioning the user.
Read files directly with Pi's tools; do not call a Codex `Skill` tool or load
instructions from a versioned Codex plugin cache.

Record settled terminology in the existing CONTEXT.md and consequential decisions
in the repository's existing ADR or design-document convention. Update existing
documents instead of creating a parallel set. Keep unresolved choices marked as
open; do not record an unaccepted recommendation as a decision. Create a document
only when there is useful settled content to retain. Outside a repository, or
when the user explicitly requests conversation only, keep the interview in chat.

Work in rounds. Ask the frontier of questions whose prerequisites are already
settled, numbering each question and giving your recommended answer. Questions
that depend on unanswered questions belong in a later round.

Format each question like this:

```text
Q1 — <question title>: <question and relevant choices>
Recommended: <answer and brief reason>
```

Wait for the user's answers, then update the decision tree and recompute the
frontier. Continue until the branches are resolved and the user confirms the
shared understanding. Keep the agreed plan and observable acceptance criteria
in the selected document. Implementation requires a separate request.
