---
description: Update Confluence documentation (business-focused, client-facing) to reflect the changes we just made
agent: documentation
subtask: true
---

Update Confluence so its documentation reflects the changes we just made in this session. Confluence pages are **read by the client** — write for a business audience, lead with business value, and keep technical detail to a high-level overview.

Scope / focus (optional): $ARGUMENTS

## Step 0: Load the Confluence Skill

Invoke the `confluence` skill first. It carries the mandatory rules for content formats, macro safety, raw-literal titles, and the fetch-then-update flow. Follow it throughout.

## Step 1: Detect What Changed

Ground the update on the *actual* changes, not just recollection. Run read-only git inspection in the working directory and combine it with the conversation:

- `git status -sb` — modified/added/untracked files
- `git diff` and `git diff --staged` — the concrete edits
- `git log --oneline -10` — recent commits for context

Build a change set of what was actually done: features delivered, behaviour changed, capabilities added/removed, and decisions made. If `$ARGUMENTS` is provided, narrow the scope to that topic/feature (it may also name a space, parent, or page).

## Step 2: Determine the Target Space from Context

**There is no default space.** Infer the correct Confluence space from context:

- The repository / project name and remotes (`git remote -v`)
- Product or system names mentioned in the conversation and the code
- `$ARGUMENTS` if it names a space or page

Use `confluence_search` (CQL) and `confluence_get_space_page_tree` to confirm the space exists and to learn its structure before writing. If the space is genuinely ambiguous, ask the user which space to target rather than guessing.

## Step 3: Translate Changes into Business Value

This is the core of the command. Reframe every change from the **client's** perspective:

- **Lead with what it means for the business / user** — the outcome and value, not the implementation.
- **Keep it non-technical.** Only include technical content when the change *is* technical documentation — and even then as a **high-level overview / general approach**, never detailed code, function signatures, config snippets, or file-level specifics.
- **Skip internal churn** that has no client-visible meaning: refactors, test changes, linting, dependency bumps, formatting.
- **Match the house style** of the existing pages: a short lead paragraph → tables/bullets for structured facts → a **Related** section cross-linking sibling pages. Note callouts (e.g. "not yet exposed", "to be confirmed") where relevant.

## Step 4: Locate the Right Page (update-over-create)

- Use `confluence_search` and `confluence_get_space_page_tree` to find an existing page on the topic and its correct parent section (e.g. business vs. technical vs. integrator-facing sections).
- Capture the **page ID and current version number**.
- **Prefer extending an existing page.** Create a new page only when no existing page fits — and then always as a **child under the appropriate existing section**, never at the top level.

Be **proactive**: both update existing pages and create the missing ones the changes warrant.

## Step 5: Macro-Safety Precondition (mandatory)

Before editing **any existing page**, fetch it raw with `convert_to_markdown: false` and inspect the body:

- If it contains `<ac:structured-macro>`, `<ac:layout>`, `<ac:adf-*>`, status lozenges, or info/note/warning panels → edit with **`content_format: storage`**. A markdown update silently flattens these.
- Otherwise, markdown is fine.
- **New pages and plain prose → markdown.**

## Step 6: Apply the Update

- **Update** → fetch the page for its current version, then `confluence_update_page` with the next version. Mark trivial edits as **minor** to avoid notification spam. On a version conflict, re-fetch and reapply.
- **Create** → `confluence_create_page` with the correct `parent_id`. Pass `title` as a **raw literal string** — never HTML-escape `&`, accents, or emojis (see the skill's "Titles & Special Characters").
- Add or refresh **labels** for discoverability.
- After any edit, **re-fetch raw** (`convert_to_markdown: false`) and verify nothing was flattened or dropped — the tool reports success even when it silently strips content.

## Step 7: Report

Give a concise summary listing each page created or updated: title, URL, created-vs-updated, and the business framing you applied.

## Relationship to `/obsidian-update` and `/learn`

- **`/confluence-update`** (this command) → **client-facing, business-value** documentation in Confluence. Technical content only as high-level overview. Space is inferred from context.
- **`/obsidian-update`** → personal/technical notes in the local Obsidian vault, updated directly.
- **`/learn`** → harvests session insights and delegates to `@obsidian-knowledge-manager`.

Don't re-run these for the same content — use this one when the goal is "document what we shipped for the client."
