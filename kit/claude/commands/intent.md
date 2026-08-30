---
description: Stage 1 — capture an idea, problem or finding as a committed intent.md
argument-hint: "[short description of the problem, or a path to notes]"
allowed-tools: Read, Write, Glob, Grep, Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*)
---

Capture intent for: **$ARGUMENTS**

Use the `intent-capture` skill. In short:

1. **Interview first.** Ask what is genuinely unclear — the problem with a concrete recent instance,
   who feels it, the outcome as a state of the world, the constraints, how we would know it worked.
   Three to six questions in conversation. Do not write the file from the opening message.
2. **Write** `sdlc/<slug>/intent.md` from `sdlc/templates/intent.md`.
3. **Show the draft and let them correct it.** This is where misunderstandings are cheapest to fix.
4. **Commit it on its own** — the timestamp is the Stage 1 metric, so do not bundle it.

Then stop. Say that it needs the product owner to accept or close it, and that Stage 2 does not start
until they do. **Do not write a spec**, even if asked in the same breath — that gate is the one part of
Stage 1 that must not be automated away.
