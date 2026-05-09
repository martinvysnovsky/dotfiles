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
- **Create**:
  1. **Before calling `worktree_create`**, ensure `.opencode/worktree.jsonc` exists. If it doesn't, create it based on the detected project type — this is critical so `postCreate` hooks run when the worktree is spawned. Always include `tmux-dev --panes` as the last `postCreate` hook:
     - **Node.js / npm**: copy `.env`, `.env.local`, symlink `node_modules`, run `npm install`, then `tmux-dev --panes`
     - **Docker**: copy `.env`, run `docker compose up -d` on create / `docker compose down` on delete, then `tmux-dev --panes`
     - **Other**: blank config with `postCreate: ["tmux-dev --panes"]`
  2. Call `worktree_create` with the branch name and optional base branch (default: current branch)
