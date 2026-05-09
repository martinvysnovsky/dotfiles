---
description: Create or manage a git worktree for isolated development
---

Create or manage a git worktree using the opencode-worktree plugin.

## Your Task

### Determine the branch name

1. **If arguments provided with a full branch name** (e.g. `/worktree feature/my-branch main`): use it directly
2. **If a Jira ticket key is provided** (e.g. `/worktree EB-448`):
   - Fetch the issue summary using the Jira MCP tool
   - Build branch name as `<TICKET-KEY>-<slugified-summary>` (lowercase, spaces replaced with dashes, special chars removed)
   - Confirm the branch name with the user before creating
3. **If no arguments**: look at the conversation context for a Jira ticket key
   - If found, fetch the summary and build the branch name
   - Confirm with the user before creating
4. **If no ticket found anywhere**: ask the user for a branch name

### Execute

- **Delete**: if the user said "delete" — call `worktree_delete` with the reason
- **Create**: call `worktree_create` with the branch name and optional base branch (default: current branch)

### Post-create

After creating a worktree, check if `.opencode/worktree.jsonc` exists in the project. If not, suggest creating one based on the detected project type:
- **Node.js / pnpm**: copy `.env`, `.env.local`, symlink `node_modules`, run `pnpm install`
- **Docker**: copy `.env`, run `docker compose up -d` on create / `docker compose down` on delete
- **Other**: offer a blank config template
