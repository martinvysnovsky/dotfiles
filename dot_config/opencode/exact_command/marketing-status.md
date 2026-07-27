---
description: Post a simple client-facing marketing status comment to a Jira ticket
agent: marketing-specialist
---

Post a short marketing status update as a comment on Jira ticket **$1**.

`$1` can be an issue key (e.g. `EB-354`) or a full URL — parse it accordingly.

What to emphasize / context from the user: $2

## Audience & Tone

- **Audience: the client** (non-technical). Write for them, not for internal use.
- Keep it **simple and short** — a few sentences per section, no jargon, no raw metric dumps.
- Match the client's language (Slovak for EDENcars/EDENbazar/Ketler unless told otherwise).

## Workflow

1. **Read the ticket** — Use `jira_get_issue` on `$1` for context (subject, prior comments) so the update fits the conversation and avoids repeating what's already there.
2. **Build the summary from context** — Use the current conversation context (recent review, notes, or details provided in `$2`) as the source. Do NOT pull fresh GA4/Ads data — keep it lightweight. If there is no usable context, ask the user for it.
3. **Write the comment** with three short parts:
   - **Current status** — one or two plain-language sentences on how marketing is going.
   - **What we changed** — a few bullets of concrete actions taken this period.
   - **Recommendations** — a few bullets of what we suggest next and why (client benefit).
4. **Post it directly** — Use `jira_add_comment` on `$1` with the drafted text (no approval step). Then print the posted comment back to the user for reference.

## Guidelines

- Plain Markdown; short bullets over long paragraphs.
- Frame everything in terms of client value (more leads, better visibility, lower cost).
- No internal IDs, no cost_micros, no acronyms without a plain-language gloss.
- If the ticket or project is ambiguous, ask the user rather than guessing.
