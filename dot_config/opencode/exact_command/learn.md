---
description: Capture findings and knowledge from current session into Obsidian
agent: obsidian-knowledge-manager
subtask: true
---

Review the current conversation and capture any valuable knowledge, findings, or patterns into the Obsidian vault.

Topic focus or specific findings to capture: $ARGUMENTS

## What to Capture

Analyze the full conversation (and user-specified topic if `$ARGUMENTS` provided) for:

- **Technical discoveries** — patterns, gotchas, solutions, configurations
- **Problem-solution pairs** — errors encountered and how they were fixed
- **Architecture decisions** — why a specific approach was chosen over alternatives
- **Useful commands/snippets** — reference material worth preserving
- **New tool/library knowledge** — capabilities, limitations, setup steps

**Skip:** trivial changes, obvious things, temporary debugging steps, user-specific context that won't be useful later.

## Process

1. **Identify** all distinct pieces of knowledge worth preserving from the conversation
2. **Search** the vault for each topic — check if existing notes already cover it
3. **Update** existing notes with new information (preferred over creating new), OR create new notes where nothing exists
4. **Reorganize** — if you encounter related notes that are duplicated, misplaced, or messy, fix them proactively
5. **Link** — ensure wiki-links connect related notes in both directions
6. **Update MOCs** — if new notes were added to categories that have Maps of Content
7. **Report** — print a clear summary of all vault changes made

## Output Format

After all changes are made, print:

```
📝 Knowledge captured:

  ✅ Created:  Programming/New Topic.md
  ✏️  Updated:  Programming/Docker.md  (added volume mount gotcha)
  🔀 Moved:    Knowledge/Docker.md → Programming/Docker.md
  🗑️  Merged:   Programming/Docker Containers.md → Programming/Docker.md
  📋 MOC:      Programming MOC.md  (+1 entry)
  🔗 Linked:   Docker.md ↔ Terraform.md

  ℹ️  No changes: [topic] already well-documented in [note]
```

## Guidelines

- **Quality over quantity** — only capture genuinely reusable knowledge
- **Atomic notes** — one clear topic per note; don't fragment excessively
- **Practical focus** — include code examples, commands, configs when relevant
- **Update > Create** — always prefer extending existing notes over creating new ones for the same topic
