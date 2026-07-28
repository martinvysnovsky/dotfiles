---
description: Format a prepared estimation into a Google Sheets–ready TSV + summary
agent: plan
---

Format an **already-prepared** estimation into output that can be pasted straight into Google Sheets, plus a written summary.

This command does **not** create estimates. The estimation is prepared up front by the user. Your job is only to **format** the given numbers — never invent, re-estimate, or change them.

Estimation source / notes reference: $ARGUMENTS

## Step 1: Source the estimation data

Get the estimation numbers in this priority order:

1. **Conversation context** — use the estimation already discussed in the current session.
2. **Notes** — if `$ARGUMENTS` points to a file or Obsidian note (e.g. a path under `~/obsidian/Work/`), read it to extract the categories, features, comments, and Min / Most likely / Max day values.
3. **Ask** — if neither context nor notes contain enough information, ask the user. Do **not** fabricate or re-estimate numbers.

## Step 2: Emit the TSV table

Output a **tab-separated** block inside a code block (so it pastes cleanly into separate Google Sheets columns). Use this EXACT header row (tab-separated):

```
Category	Feature	Comment	Min [days]	Most likely [days]	Max [days]
```

Rules:
- One row per feature, grouped by Category (repeat the Category value on each of its rows).
- Values are in **days**; decimals allowed and MUST use a **comma** as the decimal separator (e.g. `0,5`), not a dot — so they paste as numbers into Google Sheets (locale with comma decimals).
- Preserve the user's provided numbers exactly — only structure/format them.
- Add a final **Total** row that sums each of the three estimate columns (Min, Most likely, Max). Leave Comment blank on the Total row.

## Step 3: Risk uplift recommendation (internal — not for the client)

This section is an **internal note for us**, not part of what is sent to the client. Review the estimated feature rows and identify which specific rows warrant a **risk uplift** — do NOT blanket-apply it to the Total or to every row. Flag a row only when it carries real uncertainty, e.g.:

- a wide spread between Min and Max,
- unfamiliar tech / external dependencies / third-party integrations,
- vague or incomplete scope, or a comment signalling unknowns.

For each flagged row, output a short recommendation naming the **Category → Feature**, a suggested uplift (a % or a rough extra-days range), and a one-line reason why it is risky. If no rows are risky, state clearly that no risk uplift is needed. This is advisory only — do not change the numbers in the TSV table.

## Step 4: Written summary (client-facing)

After the risk note, add a summary with these four sections. **This summary is sent to the client together with the estimation**, so write it for a client audience: use plain business language, focus on value and scope, and include **only information relevant to the client**. Do **not** include technical implementation details, internal notes, tech-stack choices, or the risk-uplift reasoning from Step 3.

- **Overview** — one short paragraph describing what is being delivered, in business terms.
- **What's included** — bullet list of in-scope deliverables, phrased as client-facing outcomes.
- **What's not included** — bullet list of what is explicitly out of scope, so expectations are clear.
- **Assumptions** — bullet list of the assumptions the estimate depends on (e.g. inputs, access, or decisions expected from the client).

Derive these sections from the prepared estimation context/notes — do not introduce new scope or new guesses.
