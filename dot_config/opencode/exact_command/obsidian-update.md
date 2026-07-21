---
description: Update Obsidian documentation to reflect the changes we just made
agent: documentation
subtask: true
---

Update the Obsidian vault (`~/obsidian/`) so its documentation reflects the changes we just made in this session.

Scope / focus (optional): $ARGUMENTS

## Step 1: Detect What Changed

Ground the update on the *actual* changes, not just recollection. Run read-only git inspection in the working directory and combine it with the conversation:

- `git status -sb` — see modified/added/untracked files
- `git diff` and `git diff --staged` — see the concrete edits
- `git log --oneline -10` — see recent commits for context

Build a change set of what was actually done: files added/modified, features implemented, configs changed, commands introduced, and decisions made. If `$ARGUMENTS` is provided, narrow the scope to that topic/feature.

## Step 2: Filter for Doc-Worthy Content

Keep durable knowledge worth documenting:

- **New patterns / conventions** established during the work
- **Architecture decisions** — what was chosen and why
- **Gotchas / solutions** — non-obvious problems and their fixes
- **Reusable commands / snippets** — reference material
- **Setup / config steps** — how something is wired up

**Skip:** trivial edits, one-off debugging steps, obvious changes, and transient context that won't be useful later.

## Step 3: Search the Vault First (update-over-create)

Before writing anything, locate existing notes for each topic:

- Use `obsidian_search_notes` to find related notes by content/frontmatter
- Use `obsidian_list_directory` to check the right category folder

**Always prefer extending an existing note over creating a duplicate.**

## Step 4: Apply Updates Directly

Use your own Obsidian tools to update the vault directly:

- **Small edits to an existing note** → `obsidian_patch_note`
- **New note** → `obsidian_write_note` in the correct category folder (`Programming/`, `Work/<project>/`, `Knowledge/`, `Tech/`, etc.)
  - Minimal frontmatter only: `tags: [relevant-tags]` and `created: YYYY-MM-DD`
  - Link related notes with `[[wiki-links]]`
- **Category index** → update the relevant `*MOC.md` when adding a new note to a category
- **Never** write to `Zettelkasten/` — that folder is legacy

## Step 5: Report

Give a concise summary listing each note created or updated (with its vault path) and what was captured.

## Relationship to `/learn`

This command maintains **documentation from concrete changes** and works on the vault **directly**. `/learn` harvests **session insights/discoveries** and **delegates** to `@obsidian-knowledge-manager`. Don't re-run both for the same content — use this one when the goal is "document what we just changed."
