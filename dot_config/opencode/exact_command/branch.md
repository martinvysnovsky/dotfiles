---
description: Create and push a branch from a Jira ticket
agent: build
---

Create a new git branch from a Jira ticket and push it to origin.

## Instructions

1. **Get the Jira ticket key** — Use `$ARGUMENTS` if provided (e.g. `/branch EB-448`). If no arguments, look at the conversation context for a Jira ticket key. If not found, ask the user for a ticket key.
2. **Fetch issue summary** — Use `jira_get_issue` to get the ticket summary
3. **Build branch name** — Format: `<TICKET-KEY>-<slugified-summary>` (lowercase, spaces → dashes, remove special chars, max ~60 chars total)
4. **Confirm with user** — Show the proposed branch name before creating
5. **Create and push** — Run `git checkout -b <branch-name>` then `git push --set-upstream origin HEAD`

Additional context from user: $ARGUMENTS
