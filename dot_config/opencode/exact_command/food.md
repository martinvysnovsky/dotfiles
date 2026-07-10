---
description: Log a food/symptom event to the digestion diary in Obsidian
---

Log a food entry (and any symptom) into the digestion diary in the Obsidian vault (`~/obsidian/Health/`).

The goal is to find food intolerances by tracking meals over time. A single meal has many ingredients, so one event never isolates a trigger — confidence comes from **overlap across many events**. The Suspected Triggers table in `[[Digestion problem]]` is what surfaces the culprit over time. Logging **good meals** (no symptom) matters too: an ingredient's *absence* during symptom-free meals strengthens the correlation.

What was eaten / when / any symptom: $ARGUMENTS

## Step 1: Extract the meal info

From `$ARGUMENTS` and any **attached photos**, determine:

- **Foods / drinks** — each product's brand + name, full **ingredient list**, and **allergens**. Read labels in the photos carefully.
- **Timestamp** — prefer the photo's filename/EXIF time (e.g. `PXL_20260709_122554008` → `2026-07-09 12:25`); otherwise use the time the user gives, or now.
- **Symptom** (if any) — type (diarrhea, bloating, cramps…) and **onset gap** (time between eating and symptom, e.g. `~30 min`, `~2 h`). If the user reports no problem, treat it as a **good meal** (no symptom).

## Step 2: Delegate to the Knowledge Manager

Hand off to `@obsidian-knowledge-manager` with a structured message. Instruct it to follow this exact workflow (all writes go through that agent):

```
@obsidian-knowledge-manager

## Digestion diary event

**Date:** YYYY-MM-DD
**Time:** ~HH:MM
**Symptom:** <symptom + onset gap>  |  or: "None (good meal)"
**Foods / drinks:** <list, with per-item ingredients & allergens extracted from photos/text>
**Notes:** <eaten together/separately, quantity, anything relevant>

Follow the workflow in Health/Digestion problem.md:

1. Append ONE row to the **Event Log** table in `Health/Digestion problem.md`
   (bottom, chronological). For a good meal, put "None" in the Symptom column:
   | YYYY-MM-DD | ~HH:MM | <Symptom or None> | [[Food A]], [[Food B]] | ~<gap or —> | <notes> |

2. Ensure each food has a note in `Health/`:
   - Missing → create it using `Health/Pesto alla Genovese.md` as the template:
     ingredient list, **allergens bolded**, a `## Symptom events` section linking
     back to [[Digestion problem]], and `## Related Notes` → [[Health MOC]] + [[Digestion problem]].
   - Exists → append this event to its `## Symptom events` list (note "no symptom"
     for good meals).

3. Update the **Suspected Triggers** table in `Health/Digestion problem.md`
   (only when a symptom occurred). For each ingredient in the bad meal:
   - Already listed → increment `# events` and bump confidence if it keeps recurring.
   - New → add a row at **Low** confidence.

4. Add it to that day's daily note `Daily/YYYY-MM-DD.md` under a `## Health` section,
   linking [[Digestion problem]] and the foods.

Also update `Health MOC.md` "Foods & Ingredients" with any newly created food notes.
```

## Step 3: Delete processed photos

After the meal info has been captured into notes, **delete the source photo file(s)** from the vault (they are not archived) — e.g. `~/obsidian/PXL_*.jpg`. Only delete photos that were provided for this entry and whose information has been recorded.

## Step 4: Report

Confirm concisely: the Event Log row added, which food notes were created/updated, any Suspected Triggers changes, the daily-note entry, and which photos were deleted.
