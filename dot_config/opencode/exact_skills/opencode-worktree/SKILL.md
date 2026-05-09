---
name: opencode-worktree
description: Manage git worktrees in OpenCode. Use when (1) creating isolated feature branches with worktree_create, (2) cleaning up worktrees with worktree_delete, (3) configuring .opencode/worktree.jsonc for a project, (4) setting up file sync and lifecycle hooks for worktrees.
version: 1.0.0
---

# OpenCode Worktree Plugin

Zero-friction git worktrees — each worktree automatically spawns its own terminal with OpenCode running inside.

## Tools

| Tool | Purpose |
|------|---------|
| `worktree_create(branch, baseBranch?)` | Create isolated git worktree + spawn new terminal with OpenCode |
| `worktree_delete(reason)` | Auto-commit changes, remove worktree, clean up session |

### worktree_create

```
worktree_create:
  branch: "feature/dark-mode"
  baseBranch: "main"  # optional, defaults to HEAD
```

What happens:
1. Creates git worktree at `~/.local/share/opencode/worktree/<project-id>/<branch>/`
2. Syncs files based on `.opencode/worktree.jsonc` config
3. Runs `postCreate` hooks (e.g. `pnpm install`)
4. Opens new Kitty window with OpenCode running

### worktree_delete

```
worktree_delete:
  reason: "Feature complete, merging to main"
```

What happens:
1. Runs `preDelete` hooks (e.g. `docker compose down`)
2. Commits all changes with snapshot message
3. Removes git worktree with `--force`
4. Cleans up session state

## Configuration

Create `.opencode/worktree.jsonc` in each project root. Auto-created on first `worktree_create` if missing.

```jsonc
{
  "$schema": "https://registry.kdco.dev/schemas/worktree.json",

  "sync": {
    // Files to copy from main worktree into each new worktree
    "copyFiles": [],

    // Directories to symlink (avoids duplicating large dirs)
    "symlinkDirs": [],

    // Patterns to exclude from sync
    "exclude": []
  },

  "hooks": {
    // Commands to run after worktree creation
    "postCreate": [],

    // Commands to run before worktree deletion
    "preDelete": []
  }
}
```

## Common Configurations

### Node.js / pnpm project

```jsonc
{
  "sync": {
    "copyFiles": [".env", ".env.local"],
    "symlinkDirs": ["node_modules"]
  },
  "hooks": {
    "postCreate": ["npm install", "tmux-dev --panes"]
  }
}
```

### Docker-based project

```jsonc
{
  "sync": {
    "copyFiles": [".env"]
  },
  "hooks": {
    "postCreate": ["docker compose up -d", "tmux-dev --panes"],
    "preDelete": ["docker compose down"]
  }
}
```

### NestJS + React monorepo

```jsonc
{
  "sync": {
    "copyFiles": [".env", ".env.local", ".env.development"],
    "symlinkDirs": ["node_modules"]
  },
  "hooks": {
    "postCreate": ["npm install", "tmux-dev --panes"]
  }
}
```

## Key Details

- **Worktree location**: `~/.local/share/opencode/worktree/<project-id>/<branch>/` (outside the repo)
- **Terminal**: Auto-detects Kitty on Linux — spawns new Kitty window per worktree
- **Multiple worktrees**: Fully supported, each gets its own terminal and OpenCode session
- **Standard git**: Worktrees are normal git worktrees — `git worktree list` shows them, branches merge normally
- **Forgotten worktrees**: Changes remain in the worktree directory and branch until manually cleaned up

## Installation

Installed globally via OCX — available in all projects:

```bash
ocx init --global
ocx registry add https://registry.kdco.dev --name kdco --global
ocx add kdco/worktree --global
```
