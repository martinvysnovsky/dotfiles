---
name: confluence
description: Confluence (Atlassian Cloud) content workflows via MCP. Use when (1) creating or updating Confluence pages, (2) choosing storage vs markdown content format, (3) navigating space page trees and moving pages, (4) adding comments/labels/attachments, (5) syncing local markdown to Confluence, (6) migrating external web content into Confluence.
---

# Confluence Content Management

This skill provides best-practice patterns for working with Confluence through the
`mcp-gateway_confluence_*` tools. Load the relevant section as needed.

## Instance & Authentication

- **Instance**: Atlassian Cloud — `https://ketler.atlassian.net`
- **Auth**: Cloud basic auth (username + API token). Do **not** rely on
  `CONFLUENCE_PERSONAL_TOKEN` (Server/DC Bearer auth) — on Cloud it conflicts with
  API-token auth and breaks the Confluence client. Cloud needs
  `CONFLUENCE_USERNAME` + `CONFLUENCE_API_TOKEN`.
- **Tools**: All operations use the `mcp-gateway_confluence_*` tool family.

## Content Formats

Confluence stores pages in **storage format** (XHTML-based). When authoring via MCP,
prefer the format that matches your input:

- **`markdown`** (default, recommended) — author/edit human-written content. The
  server converts markdown → storage format. Safest for most page bodies.
- **`storage`** — pass raw Confluence storage XHTML when you need macros, layouts,
  status lozenges, or precise structure markdown can't express.
- **`wiki`** — legacy wiki markup; avoid unless migrating old content.

Rule of thumb: write in **markdown**; drop to **storage** only for macros/layouts.

## Finding Pages

- **Search (CQL)** — examples:
  - `space = "DEV" AND title ~ "Onboarding"`
  - `type = page AND label = "runbook"`
  - `text ~ "deployment" AND space = "OPS" ORDER BY lastmodified DESC`
- **Page tree** — get the hierarchy of a space to locate parents before creating
  children (returns page IDs + nesting).
- **Get a page** — by **page ID** (stable, preferred) or by **title + space key**.
  Always capture the page ID and current **version number** before updating.

## Page CRUD

### Create
Required: `space_key`, `title`, `body`. Optional: `parent_id` (nest under a page),
content format. Set `parent_id` to build a clean tree instead of flat spaces.

### Update
1. Fetch the page first to get its current **version number**.
2. Submit the update with the next version (the server enforces optimistic locking).
3. Mark trivial edits as **minor** to avoid notification spam where supported.
4. On a version conflict, re-fetch and reapply — never blindly retry.

### Move / Delete
- **Move** changes the parent (re-parents the subtree). Verify the target parent ID
  via the page tree first.
- **Delete** is destructive — confirm the page ID and that no children depend on it.

## Collaboration

- **Comments** — add page comments or threaded replies (reply via parent comment ID).
- **Labels** — add/remove labels for discoverability and CQL filtering
  (e.g. `runbook`, `adr`, `meeting-notes`).
- **Attachments** — upload single or batch files; large files may need chunking.
  Note: ambiguous MIME types (`application/octet-stream`) may need an explicit
  content type / filename extension.

## Markdown → Confluence Sync

For syncing repo docs into Confluence, the documentation agent ships a
`sync-to-confluence.sh` pattern (pandoc-based). General flow:

1. Convert local markdown to storage format (pandoc) **or** pass markdown directly
   and let the MCP server convert it.
2. Resolve target `space_key` + `parent_id`.
3. Create the page if absent, else update with the current version number.
4. Re-apply labels and attachments after the body update.

Prefer letting the MCP `content_format: markdown` path do the conversion unless you
need macros — it avoids brittle pandoc → storage edge cases.

## Migrating External Content

Pair **Firecrawl** with Confluence to import external docs:

1. `firecrawl_scrape` / `firecrawl_extract` the source URL(s) → markdown.
2. Clean up headings/links so anchors resolve inside Confluence.
3. Create the page(s) with the markdown body under the right parent.
4. Add labels for provenance (e.g. `imported`, source domain).

## Gotchas

- **Version conflicts** — every update needs the current version; concurrent edits
  will reject. Always fetch-then-update.
- **Heading anchors** — Confluence auto-generates anchors from heading text; changing
  a heading breaks deep links. Keep headings stable or update links.
- **Storage vs markdown drift** — round-tripping markdown ↔ storage can lose macros;
  keep the source of truth in one format.
- **Attachment MIME** — set explicit filename/extension when the type is
  `application/octet-stream` so Confluence renders/links it correctly.
- **Cloud vs Server auth** — see Authentication above; mismatched token type is the
  most common reason Confluence tools silently fail to initialize.
