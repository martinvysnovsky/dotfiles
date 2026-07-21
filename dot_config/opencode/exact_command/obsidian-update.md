---
description: Reconcile Obsidian documentation with the current state of the system
agent: documentation
subtask: true
---

Keep the Obsidian vault (`~/obsidian/`) accurate and useful: its notes should describe **how things currently work**, not log what changed. The goal is good documentation, not a change history.

Scope / focus (optional): $ARGUMENTS

## Step 1: Identify Affected Topics

Use git and the conversation **only to figure out which subjects the work touches** — then set the diff aside. You are looking for topics that may now be documented inaccurately or incompletely, not a list of edits.

- `git status -sb`, `git diff`, `git diff --staged`, `git log --oneline -10` — signals for *which subjects* changed
- The conversation — what area of the system was worked on

Produce a list of **topics/subjects** to review (e.g. "how the auth flow works", "the deployment setup"), not a change set. If `$ARGUMENTS` is provided, narrow to that topic.

## Step 2: Decide What Deserves Documentation

Document **durable subject matter** — how the system works, as standing facts:

- **How a pattern / convention works** and when to apply it
- **Architecture decisions** — the current approach and its rationale
- **Gotchas / constraints** that a future reader must know
- **Reference material** — commands, configs, setup as they stand today

**Skip:** anything that only makes sense as "what we did this session" — trivial edits, one-off debugging, and details that don't help someone understand the system later.

## Step 3: Search the Vault First (update-over-create)

For each topic, find the existing note before writing:

- `obsidian_search_notes` — find related notes by content/frontmatter
- `obsidian_list_directory` — check the right category folder

**Always prefer extending an existing note over creating a duplicate.**

## Step 4: Reconcile the Documentation with Reality

For each topic, compare what the note says against how the system now works, and make the note correct and complete:

- **Rewrite stale sections** to describe the **current state** — replace outdated descriptions rather than appending "now it does X".
- **Fill genuine gaps** where the system does something the docs don't cover.
- **If the existing note is already accurate, make no edit.** Do not touch a note just because related code changed.

Write **timelessly** — describe how things work as if they always have. **No** change logs, **no** before/after, **no** "we added / changed / removed", **no** session narrative or dates-of-change in the body. A reader with no knowledge of this session must not be able to tell an edit happened.

Apply with your Obsidian tools:

- **Edit an existing note** → `obsidian_patch_note`
- **New note** → `obsidian_write_note` in the correct category folder (`Programming/`, `Work/<project>/`, `Knowledge/`, `Tech/`, etc.)
  - Minimal frontmatter only: `tags: [relevant-tags]` and `created: YYYY-MM-DD`
  - Link related notes with `[[wiki-links]]`
- **Category index** → update the relevant `*MOC.md` when adding a new note
- **Never** write to `Zettelkasten/` — that folder is legacy

## Step 5: Report

Give a concise summary listing each note created or updated (with its vault path) and **what it now documents** — plus any topics you reviewed and deliberately left unchanged because they were already accurate.

## Relationship to `/learn`

This command keeps the vault's documentation **current with how the system works**, editing directly. `/learn` harvests **session insights/discoveries** and **delegates** to `@obsidian-knowledge-manager`. Use this one when the goal is accurate standing documentation, not capturing what happened in a session.
