---
description: Fix git conflicts during rebase and continue
agent: git-master
---

Fix all merge conflicts in the current rebase and continue.

## Instructions

1. **Check rebase state** — Run `git status` to confirm a rebase is in progress and identify conflicted files
2. **Analyze each conflict** — For every conflicted file:
   - Read the file to find conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Use `git log --oneline -5` and branch context to understand the intent of both sides
   - Resolve intelligently — preserve functionality from both sides when possible
3. **Stage resolved files** — Run `git add <file>` for each resolved file
4. **Continue rebase** — Run `git rebase --continue`
5. **Repeat if needed** — If rebase hits another conflict, go back to step 1
6. **Report result** — Show the final `git log --oneline -5` after successful rebase

If no rebase is in progress, inform the user.

Additional context from user: $ARGUMENTS
