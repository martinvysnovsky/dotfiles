---
description: Reconcile Confluence documentation with the current state of the system (business-focused, client-facing)
agent: documentation
subtask: true
---

Keep Confluence accurate and useful: its pages should describe **how the system currently works** for a business audience — not log what changed. Confluence pages are **read by the client**, so lead with business value and keep technical detail to a high-level overview. The goal is good documentation, not a change history.

Scope / focus (optional): $ARGUMENTS

## Step 0: Load the Confluence Skill

Invoke the `confluence` skill first. It carries the mandatory rules for content formats, macro safety, raw-literal titles, and the fetch-then-update flow. Follow it throughout.

## Step 1: Identify Affected Topics

Use git and the conversation **only to figure out which subjects the work touches** — then set the diff aside. You are looking for pages that may now be documented inaccurately or incompletely, not a list of edits.

- `git status -sb`, `git diff`, `git diff --staged`, `git log --oneline -10` — signals for *which subjects* changed
- The conversation — what capability or area of the product was worked on

Produce a list of **topics/subjects** to review (e.g. "how subscriptions renew", "what the API exposes"), not a change set. If `$ARGUMENTS` is provided, narrow to that topic (it may also name a space, parent, or page).

## Step 2: Determine the Target Space from Context

**There is no default space.** Infer the correct Confluence space from context:

- The repository / project name and remotes (`git remote -v`)
- Product or system names mentioned in the conversation and the code
- `$ARGUMENTS` if it names a space or page

Use `confluence_search` (CQL) and `confluence_get_space_page_tree` to confirm the space exists and to learn its structure before writing. If the space is genuinely ambiguous, ask the user which space to target rather than guessing.

## Step 3: Describe the Current State in Business Terms

Write each page as a **standing description of how the system works today**, for the client:

- **Lead with business value** — what the capability means for the business / user, not how it is implemented.
- **Keep it non-technical.** Include technical content only when the page *is* technical documentation — and even then as a **high-level overview / general approach**, never detailed code, function signatures, config snippets, or file-level specifics.
- **Write timelessly.** Describe how things work as if they always have. **No** before/after, **no** "now supports / newly added / recently changed", **no** release-note or changelog phrasing.
- **Match the house style** of the existing pages: a short lead paragraph → tables/bullets for structured facts → a **Related** section cross-linking sibling pages. Use note callouts (e.g. "not yet exposed", "to be confirmed") where relevant.

## Step 4: Locate the Right Page (update-over-create)

- Use `confluence_search` and `confluence_get_space_page_tree` to find the existing page on the topic and its correct parent section (e.g. business vs. technical vs. integrator-facing sections).
- Capture the **page ID and current version number**.
- **Prefer extending an existing page.** Create a new page only when no existing page covers the topic — and then always as a **child under the appropriate existing section**, never at the top level.

Be **proactive**: both update pages that are now inaccurate and create genuinely missing ones.

## Step 5: Macro-Safety Precondition (mandatory)

Before editing **any existing page**, fetch it raw with `convert_to_markdown: false` and inspect the body:

- If it contains `<ac:structured-macro>`, `<ac:layout>`, `<ac:adf-*>`, status lozenges, or info/note/warning panels → edit with **`content_format: storage`**. A markdown update silently flattens these.
- Otherwise, markdown is fine.
- **New pages and plain prose → markdown.**

## Step 6: Reconcile the Page with Reality

For each topic, compare what the page says against how the system now works, and make it correct and complete:

- **Rewrite stale sections** to describe the **current state** — replace outdated descriptions rather than appending a "what changed" note.
- **Fill genuine gaps** where the product does something the page doesn't cover.
- **If the page is already accurate, make no edit.** Do not touch a page just because related code changed. A client reading the result should see a coherent description of the system, not a release note.

Apply:

- **Update** → fetch the page for its current version, then `confluence_update_page` with the next version. Mark trivial edits as **minor** to avoid notification spam. On a version conflict, re-fetch and reapply.
- **Create** → `confluence_create_page` with the correct `parent_id`. Pass `title` as a **raw literal string** — never HTML-escape `&`, accents, or emojis (see the skill's "Titles & Special Characters").
- Add or refresh **labels** for discoverability.
- After any edit, **re-fetch raw** (`convert_to_markdown: false`) and verify nothing was flattened or dropped — the tool reports success even when it silently strips content.

## Step 7: Report

Give a concise summary listing each page created or updated: title, URL, created-vs-updated, and **what it now documents** — plus any pages you reviewed and deliberately left unchanged because they were already accurate.

## Relationship to `/obsidian-update` and `/learn`

- **`/confluence-update`** (this command) → **client-facing, business-value** documentation in Confluence, kept current with how the system works. Technical content only as high-level overview. Space is inferred from context.
- **`/obsidian-update`** → personal/technical notes in the local Obsidian vault, kept current and edited directly.
- **`/learn`** → harvests session insights and delegates to `@obsidian-knowledge-manager`.

Use this one when the goal is accurate standing documentation for the client — not capturing what happened in a session.
