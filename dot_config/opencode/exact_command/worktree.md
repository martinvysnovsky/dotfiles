---
description: Create or manage a git worktree for isolated development
agent: general
subtask: true
---

Create or manage a git worktree using the opencode-worktree plugin.

## Your Task

### Determine the branch name

1. **If arguments provided**: use them directly (e.g. `/worktree delete` or `/worktree feature/my-branch main`)
2. **If no arguments**: look at the conversation context for a Jira ticket key (e.g. `EB-448`, `PROJ-123`)
   - If found, fetch the Jira issue summary using the Jira MCP tool
   - Build branch name as `<TICKET-KEY>-<slugified-summary>` (lowercase, spaces replaced with dashes, special chars removed)
   - Confirm the branch name with the user before creating
3. **If no ticket found in context**: ask the user for a branch name

### Execute

- **Delete**: if the user said "delete" — call `worktree_delete` with the reason
- **Create**: call `worktree_create` with the branch name and optional base branch (default: current branch)

### Post-create

After creating a worktree, check if `.opencode/worktree.jsonc` exists in the project. If not, suggest creating one based on the detected project type:
- **Node.js / pnpm**: copy `.env`, `.env.local`, symlink `node_modules`, run `pnpm install`
- **Docker**: copy `.env`, run `docker compose up -d` on create / `docker compose down` on delete
- **Other**: offer a blank config template
