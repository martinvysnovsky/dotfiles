---
description: Run a marketing review for a project (Google Ads + GA4 + Obsidian)
agent: marketing-specialist
---

Run a comprehensive marketing review for **$1** and write the report to Obsidian.

Today's date: Use the current date for the review filename and frontmatter.

## Project Mapping

Identify the project from `$1` (case-insensitive). Map to the correct configuration:

| Alias | Project Name | Hub Note Path | Reviews Folder | GA4 Property ID | Google Ads Customer ID | Tags |
|---|---|---|---|---|---|---|
| `edencars` | EDENcars | `Work/EDENcars/Marketing/EDENcars/EDENcars Marketing.md` | `Work/EDENcars/Marketing/EDENcars/Reviews/` | `255986700` | `1831129538` | `work, edencars, marketing, review, google-ads, ga4` |
| `edenbazar` | EDENbazar | `Work/EDENcars/Marketing/EDENbazar/EDENbazar Marketing.md` | `Work/EDENcars/Marketing/EDENbazar/Reviews/` | `275387074` | `8461764582` | `work, edencars, edenbazar, marketing, review, google-ads, ga4` |
| `ketler` | Ketler | `Work/Ketler/Marketing/Ketler Marketing.md` | `Work/Ketler/Marketing/Reviews/` | `484532729` | `6937563952` | `google-ads, ketler, marketing, review` |

If `$1` doesn't match any known alias, scan Obsidian for `Work/*/Marketing/` folders to check if a new project exists. Read its hub note to extract GA4 property ID and Google Ads customer ID from the Accounts & Properties table. If still not found, ask the user.

Additional context from the user: $2

## Workflow

### Step 1: Read Previous Context

1. **Read the hub note** (path from mapping table) to get:
   - Google Ads account ID and GA4 property ID (use as source of truth over the mapping table — IDs may have been updated)
   - Current strategy, budget breakdown, active campaign list
   - List of all previous reviews with their dates

2. **Find and read the most recent review** from the Reviews folder:
   - Sort by filename (YYYY-MM-DD prefix) to find the latest
   - Read it fully to extract:
     - Previous period date range (for comparison baseline)
     - All metrics tables (for MoM delta calculations)
     - Every `- [ ]` action item (to check current status)
     - Previous recommendations (to assess follow-through)

3. **Determine the review period:**
   - Use **last 30 days** as the current period (today minus 30 days to today)
   - Use the **30 days before that** as the comparison period
   - If the previous review was done less than 14 days ago, note this and still use last 30 days for complete data

### Step 2: Pull Fresh Data from APIs

If you encounter authentication errors at any point, stop and instruct the user to run:
```
gcloud auth application-default login \
  --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/adwords" \
  --project=ketler-infrastructure
```

#### GA4 Reports

Use `run_report` with the project's GA4 property ID. Run all reports for **both** the current 30-day period and the previous 30-day period (two separate calls per report, or use comparison date ranges).

1. **Traffic by channel:**
   - dimensions: `sessionDefaultChannelGroup`
   - metrics: `sessions, totalUsers, newUsers, engagementRate, averageSessionDuration, ecommercePurchases, purchaseRevenue`

2. **Source / Medium breakdown:**
   - dimensions: `sessionSourceMedium`
   - metrics: `sessions, ecommercePurchases, purchaseRevenue`
   - limit: 20

3. **Key events:**
   - dimensions: `eventName`
   - metrics: `eventCount`
   - Pull all events and filter to the ones tracked in the previous review (e.g. `purchase`, `generate_lead`, `form_start`, `form_submit`, `view_item_list`, `contact_dialog_open`, `phone_link_click`, `cta_click`, `project_view`)

4. **Device breakdown:**
   - dimensions: `deviceCategory`
   - metrics: `sessions, ecommercePurchases, purchaseRevenue, engagementRate`

5. **Country breakdown:**
   - dimensions: `country`
   - metrics: `sessions, ecommercePurchases, purchaseRevenue, engagementRate`
   - limit: 15

6. **Landing pages:**
   - dimensions: `landingPagePlusQueryString`
   - metrics: `sessions, ecommercePurchases, purchaseRevenue, engagementRate`
   - limit: 15

**Adapt metrics to the project:**
- EDENcars → ecommerce revenue + purchase events are primary
- EDENbazar → `generate_lead`, `phone_link_click`, `contact_dialog_open` are primary; no ecommerce revenue
- Ketler → `form_submit`, `cta_click`, `project_view` are primary; no ecommerce

Always pull the same events that appear in the previous review — consistency enables trend tracking.

#### Google Ads Reports

Use `list_accessible_customers` first to confirm available accounts. Then use `search` with GAQL queries. Always use 10-digit numeric customer ID without dashes.

**1. Campaign performance — current period:**
```gaql
SELECT
  campaign.name,
  campaign.status,
  metrics.impressions,
  metrics.clicks,
  metrics.ctr,
  metrics.average_cpc,
  metrics.cost_micros,
  metrics.conversions,
  metrics.cost_per_conversion,
  metrics.search_impression_share,
  metrics.search_budget_lost_impression_share,
  metrics.search_rank_lost_impression_share
FROM campaign
WHERE campaign.status != 'REMOVED'
  AND segments.date DURING LAST_30_DAYS
```

**2. Campaign performance — previous period** (for MoM comparison):
Use explicit date range: `segments.date BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'`

**3. Campaign budgets:**
```gaql
SELECT
  campaign.name,
  campaign_budget.amount_micros,
  campaign.bidding_strategy_type,
  campaign.target_cpa.target_cpa_micros,
  campaign.target_roas.target_roas
FROM campaign
WHERE campaign.status != 'REMOVED'
```

**4. Search terms** (skip for PMax-only accounts):
```gaql
SELECT
  search_term_view.search_term,
  campaign.name,
  metrics.clicks,
  metrics.cost_micros,
  metrics.conversions,
  metrics.impressions
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
  AND metrics.cost_micros > 1000000
ORDER BY metrics.cost_micros DESC
LIMIT 50
```

**5. Ad group performance:**
```gaql
SELECT
  ad_group.name,
  campaign.name,
  ad_group.status,
  metrics.impressions,
  metrics.clicks,
  metrics.ctr,
  metrics.average_cpc,
  metrics.cost_micros,
  metrics.conversions
FROM ad_group
WHERE campaign.status != 'REMOVED'
  AND segments.date DURING LAST_30_DAYS
```

**6. Quality Scores** (for projects with Search campaigns):
```gaql
SELECT
  ad_group_criterion.keyword.text,
  ad_group_criterion.keyword.match_type,
  ad_group_criterion.quality_info.quality_score,
  ad_group_criterion.quality_info.creative_quality_score,
  ad_group_criterion.quality_info.post_click_quality_score,
  ad_group_criterion.quality_info.search_predicted_ctr,
  campaign.name,
  ad_group.name,
  metrics.impressions
FROM keyword_view
WHERE campaign.status != 'REMOVED'
  AND ad_group_criterion.status != 'REMOVED'
  AND segments.date DURING LAST_30_DAYS
LIMIT 100
```

Convert all `cost_micros` values by dividing by 1,000,000 to get EUR amounts.

### Step 3: Check Previous Action Items

For every `- [ ]` item in the most recent review, evaluate against the fresh data:

- **Confirmed complete** → Change to `- [x]` and append ` ✅ Done {today's date}` or a brief data-backed note (e.g., `✅ Done 2026-04-21 — IS improved to 24%`)
- **Partially done / in progress** → Keep `- [ ]`, add inline note: `*(in progress — {observation})*`
- **Not done** → Keep `- [ ]` as-is; it will be carried forward as an open item in the new review

Collect the full status of all items — you will need this for the "Previous Action Items Status Check" section in the new review.

### Step 4: Write the New Review Note

Create a new Markdown file in the Reviews folder. Use the Obsidian MCP `write_note` tool or the file `write` tool targeting `~/obsidian/{reviews-folder}/YYYY-MM-DD {Project} Marketing Review.md`.

**Filename format:** `YYYY-MM-DD {Project} Marketing Review.md`
- EDENcars example: `2026-05-21 EDENcars Marketing Review.md`
- EDENbazar example: `2026-05-21 EDENbazar Marketing Review.md`
- Ketler example: `2026-05-21 Ketler Campaign Review.md` (matches existing convention)

#### Frontmatter

```yaml
---
created: 'YYYY-MM-DD'
tags:
  - tag1
  - tag2
  (use project tags from mapping table, one per line)
type: note
---
```

#### Content Structure

Match the EXACT structure of the most recent review for this project. The structure is project-specific:

**EDENcars structure:**
1. `# EDENcars Marketing Review - {Month} {Year}` + metadata block (Date, Period, Comparison, Scope)
2. `## Executive Summary` — Key Wins (bullets) + Key Concerns (bullets)
3. `## GA4 Performance — edencars.sk`
   - Traffic by Channel table
   - Key Source/Medium Breakdown table
   - Event Tracking Status table
   - Device Performance table
   - Top Countries table
   - Landing Page Performance table
4. `## Google Ads — edencars.sk (Account: XXX-XXX-XXXX)`
   - Campaign Performance table (Impressions, Clicks, CTR, Avg CPC, Spend, Conv, CPA, Search IS, Budget Lost IS, Rank Lost IS)
   - Month-over-Month Comparison table
   - Budget Allocation table
5. `## {Previous Review Date} Action Items — Status Check` (two sub-tables: This Week / This Month)
6. `## Search Term Analysis`
   - Wasted Spend table (zero/low conversion terms)
   - Top Converting Terms table
7. `## Key Issues & Recommendations` (numbered, each with Problem → Evidence → Actions)
8. `## Budget Summary & ROAS`
9. `## Budget Reallocation` (only if changes were made or recommended)
10. `## Action Items Checklist`
    - `### This Week (by {date+7})`
    - `### This Month (by {date+30})`
    - `### Next Quarter`
11. `## Related Notes` (wiki-links)

**EDENbazar structure:**
1. `# EDENbazar Marketing Review - {Month} {Year}` + metadata
2. `## Executive Summary` (bullet points with bold lead-ins)
3. `## Google Analytics — Live Data (Last 30 Days vs Previous 30 Days)`
   - Overall Site Performance table
   - Traffic by Channel table
   - Conversion Events table
   - Device table
   - Country table
   - Top Pages table
4. `## Google Ads — edenbazar.sk`
   - Campaign Performance table
   - Ad Group Performance table
   - Search Term Analysis (wasted spend + top converters)
   - Budget Allocation table
5. `## SEO Analysis` (if there are SEO updates)
6. `## Previous Action Items — Status Check`
7. `## Key Issues & Recommendations` (priority-ordered with 🔴🟡🟢)
8. `## Action Items` (This Week / Short-Term / Medium-Term)
9. `## Related Notes`

**Ketler structure:**
1. `# Ketler Campaign Review - {Month} {Year}` + metadata (Date, Company wiki-link, Period, Previous Review wiki-link)
2. `## Executive Summary` — narrative paragraph + **Key Findings** bullet list with 🔴🟡🟢 indicators
3. `## Google Ads Performance`
   - Campaign Summary table
   - Ad Group Performance table
   - Comparison vs Previous Review table
   - Quality Score Status table
4. `## GA4 Website Analytics`
   - Traffic Overview table
   - Top Pages table
   - Country Breakdown table
   - Device Breakdown table
   - Conversion Events table
5. `## Cumulative Performance` (all-time totals since campaign start)
6. `## Critical Issues (Priority Order)` — numbered with 🔴🟡 headers
7. `## Positive Developments` — numbered list
8. `## Recommended Actions`
   - `### Immediate (This Week)` — checkbox list
   - `### Short-Term ({Month})` — checkbox list
   - `### Medium-Term (Next Month)` — checkbox list
   - `### Long-Term (Further out)` — checkbox list
9. `## Mobile Performance Audit` (if Lighthouse was run)
10. `## Performance Targets` table
11. `## Progress on Previous Review Actions` — checkbox lists by review date
12. `## Related Notes`

#### Writing Guidelines

- Use markdown tables for all data — consistent column order matching previous reviews
- Calculate MoM delta percentages: `((current - previous) / previous * 100)`, format as `+15%` or `-8%`
- **Bold** significant changes; use 🔴 (critical/negative), 🟡 (caution/mixed), 🟢 (positive)
- Every identified issue must have a concrete, specific recommendation with expected impact
- Action items use `- [ ]` checkbox format
- Internal links use `[[Note Title]]` or `[[path/to/Note Title|Display Text]]` Obsidian wiki-link format
- Include specific euro amounts, percentages, and counts — never vague qualitative descriptions
- The Executive Summary should be scannable in 60 seconds: record highs/lows, biggest win, biggest concern, total spend, ROAS/CPA

### Step 5: Update the Previous Review

Using the Obsidian MCP `patch_note` tool or the file `edit` tool on the previous review file:

1. For each completed action item (identified in Step 3), change `- [ ]` to `- [x]` and append the completion note
2. If there is meaningful new data context for a partially-done item (e.g., a metric improved), add a brief inline note
3. Do NOT change any other content, headings, or data tables in the previous review

### Step 6: Update the Hub Note

Using the Obsidian MCP `patch_note` tool or the file `edit` tool on the hub note:

1. **Add new review to the Reviews table** — insert a row at the top with:
   - Date (YYYY-MM-DD)
   - Wiki-link to the new review: `[[YYYY-MM-DD {Project} Marketing Review]]`
   - Brief one-line description (e.g., "Full marketing review — revenue €X, ROAS Yx")

2. **Update Key Metrics section** (if the hub tracks current metrics) — replace the previous values with the current period's numbers

3. **Update Current Strategy** — if any budget changes, campaign pauses, or strategy shifts are documented in the new review, reflect them in the hub note's strategy section

### Step 7: Print Terminal Summary

After all files are written, output a concise summary:

```
✅ Marketing Review Complete: {Project} — {Date}

📊 Key Metrics ({period}):
  Revenue/Leads: {primary metric} ({delta}% MoM)
  Ad Spend:      €{amount} ({delta}% MoM)
  ROAS/CPA:      {value}

🎯 Top 3 Findings:
  1. {most important finding}
  2. {second finding}
  3. {third finding}

⚠️  Open Action Items: {N} carried forward, {N} new this review

📝 Obsidian updated:
  ✅ Created:  {reviews-folder}/{new review filename}
  ✅ Updated:  {reviews-folder}/{previous review filename} ({N} items checked off)
  ✅ Updated:  {hub note filename}
```

## Error Handling

- **Auth errors from GA4 or Google Ads** → Print the gcloud auth command above and stop — do not attempt to write partial reports
- **No previous review exists** → Create the first review without MoM comparison; note "First review — no baseline comparison available"
- **Unknown project alias** → List the known aliases and ask the user to specify or confirm the new project's hub note path
- **GA4 returns empty data** → Note the issue in the review (e.g., "GA4 data unavailable for this period") and proceed with Google Ads data only
- **Google Ads returns no campaigns** → Verify customer ID from the hub note; try `list_accessible_customers` to confirm available accounts
