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
1. Reads `.opencode/worktree.jsonc` config
2. Copies files (`sync.copyFiles`) and symlinks dirs (`sync.symlinkDirs`) from main worktree
3. Runs `postCreate` hooks (e.g. `npm install`) in the worktree directory
4. Creates git worktree at `~/.local/share/opencode/worktree/<project-id>/<branch>/`
5. Opens new Kitty/tmux window with OpenCode running

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

Create `.opencode/worktree.jsonc` in each project root **before** calling `worktree_create` — hooks and sync only apply if the config exists at creation time.

```jsonc
{
  "$schema": "https://registry.kdco.dev/schemas/worktree.json",

  "sync": {
    // Files to copy from main worktree into each new worktree (e.g. .env)
    "copyFiles": [],

    // Directories to symlink (avoids duplicating large dirs like node_modules)
    "symlinkDirs": [],

    // Patterns to exclude from sync
    "exclude": []
  },

  "hooks": {
    // Shell commands to run in the worktree dir after creation (e.g. npm install)
    // Note: postCreate runs BEFORE the terminal spawns — do not use tmux commands here
    "postCreate": [],

    // Commands to run before worktree deletion
    "preDelete": []
  }
}
```

## Common Configurations

### Node.js / npm project

```jsonc
{
  "sync": {
    "copyFiles": [".env", ".env.local"],
    "symlinkDirs": ["node_modules"]
  },
  "hooks": {
    "postCreate": ["npm install"]
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
    "postCreate": ["docker compose up -d"],
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
    "postCreate": ["npm install"]
  }
}
```

## 3-Pane Layout (tmux-dev --panes)

After `worktree_create` returns, apply the standard golden ratio 3-pane layout to the new tmux window by sending a command to it:

```bash
# Send tmux-dev --panes to the newly created worktree window
tmux send-keys -t "$(tmux list-windows -F '#{window_index}' | tail -1)" 'tmux-dev --panes' Enter
```

This applies the layout **after** the terminal is ready, avoiding timing issues with `postCreate`.

## Key Details

- **Worktree location**: `~/.local/share/opencode/worktree/<project-id>/<branch>/` (outside the repo)
- **Config must exist before create**: `.opencode/worktree.jsonc` is read at `worktree_create` time
- **postCreate timing**: hooks run before the terminal spawns — no tmux commands there
- **Terminal**: Auto-detects Kitty on Linux — spawns new Kitty window per worktree; inside tmux creates new tmux window
- **Multiple worktrees**: Fully supported, each gets its own terminal and OpenCode session
- **Standard git**: Worktrees are normal git worktrees — `git worktree list` shows them, branches merge normally

## Installation

Installed globally via OCX — available in all projects:

```bash
ocx init --global
ocx registry add https://registry.kdco.dev --name kdco --global
ocx add kdco/worktree --global
```
