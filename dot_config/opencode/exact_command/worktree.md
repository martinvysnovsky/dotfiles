---
description: Create or manage a git worktree for isolated development
agent: build
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

- **Create** (in this exact order):
  1. **Ensure `.opencode/worktree.jsonc` exists** — if not, create it based on the detected project type. Use `sync.copyFiles` for env files and `sync.symlinkDirs` for large directories — do NOT put file copying in `postCreate` hooks:
     - **Node.js / npm**: `copyFiles: [".env", ".env.local"]`, `symlinkDirs: ["node_modules"]`, `postCreate: ["npm install", "npm run prepare --if-present", "git push --set-upstream origin HEAD"]`
     - **Docker**: `copyFiles: [".env"]`, `postCreate: ["docker compose up -d", "git push --set-upstream origin HEAD"]`, `preDelete: ["docker compose down"]`
     - **Other**: blank config with `postCreate: ["git push --set-upstream origin HEAD"]`
  2. **Call `worktree_create`** with the branch name and optional base branch (default: current branch)
