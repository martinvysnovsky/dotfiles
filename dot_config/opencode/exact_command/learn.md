---
description: Capture findings and knowledge from current session into Obsidian
---

Review the current conversation and identify knowledge worth preserving.

Topic focus or specific findings to capture: $ARGUMENTS

## Step 1: Extract Knowledge

Analyze the full conversation (and `$ARGUMENTS` topic if provided) for:

- **Technical discoveries** — patterns, gotchas, solutions, configurations
- **Problem-solution pairs** — errors encountered and how they were fixed
- **Architecture decisions** — why a specific approach was chosen over alternatives
- **Useful commands/snippets** — reference material worth preserving
- **New tool/library knowledge** — capabilities, limitations, setup steps

**Skip:** trivial changes, obvious things, temporary debugging steps, user-specific context that won't be useful later.

## Step 2: Delegate to Knowledge Manager

Format the extracted findings as a structured handoff and invoke `@obsidian-knowledge-manager` with this message:

```
@obsidian-knowledge-manager

## Findings to Capture

### 1. [Topic Name]
**Category:** Programming | Work | Knowledge | Health | etc.
**Content:**
[Concise, self-contained description with code examples or commands if relevant]
**Related to:** [existing concepts, technologies, or notes that might be connected]

### 2. [Topic Name]
...

Please search the vault for existing notes on each topic, update them if they exist, or create new ones if they don't. Actively reorganize if you encounter duplicates or misplaced notes. Update MOCs as needed.
```

The knowledge manager handles all vault operations — it knows the vault structure, MOC conventions, tag taxonomy, and reorganization logic.

## Step 3: Report

After the knowledge manager finishes, confirm to the user what was captured with a brief summary.
