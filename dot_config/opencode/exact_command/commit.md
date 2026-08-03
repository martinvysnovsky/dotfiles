---
description: Create a conventional commit with git-master
agent: git-master
subtask: true
---

Create a git commit for the current changes.

## Context from the developer (what we did and why)

$ARGUMENTS

Use the context above as the PRIMARY source of intent for the commit message
(type, scope, description, and body). Use `git diff` only to verify scope and
fill in details. If the context above is empty, fall back to inferring intent
from the diff alone.
