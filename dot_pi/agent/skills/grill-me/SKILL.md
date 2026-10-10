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
shared understanding. Record the revised plan and acceptance criteria when
requested. Implementation requires a separate request.
