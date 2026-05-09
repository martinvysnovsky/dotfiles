---
description: Create or manage a git worktree for isolated development
---

Create or manage a git worktree using the opencode-worktree plugin.

## Your Task

If the user passed arguments:
- **`/worktree delete [reason]`** → call `worktree_delete` with the provided reason (or "Done" if no reason given)
- **`/worktree <branch> [baseBranch]`** → call `worktree_create` with the branch name and optional base branch

If no arguments were provided, ask the user:
- What branch name to use (e.g. `feature/dark-mode`)
- Whether to base it off a specific branch (optional, defaults to HEAD)

After creating a worktree, check if `.opencode/worktree.jsonc` exists in the project. If it doesn't, suggest creating one based on the detected project type:

- **Node.js / pnpm**: copy `.env`, `.env.local`, symlink `node_modules`, run `pnpm install`
- **Docker**: copy `.env`, run `docker compose up -d` on create / `docker compose down` on delete
- **Other**: offer a blank config template
