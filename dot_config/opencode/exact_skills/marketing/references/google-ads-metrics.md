# Google Ads Metrics & KPIs

## Core Performance Metrics

### Impressions
**Definition:** Number of times your ad was shown

**Good for:** Brand awareness, reach

**Analysis:**
- **High impressions, low clicks:** Poor ad copy or irrelevance
- **Low impressions:** Low bids, narrow targeting, or low search volume
- **Impression share <50%:** Missing opportunities (increase budget or bids)

**Not a success metric alone** - impressions without clicks don't drive results.

---

### Clicks
**Definition:** Number of times users clicked your ad

**Formula:**
```
Clicks = Total ad clicks
```

**Analysis:**
- **High clicks, low conversions:** Landing page problem
- **Low clicks, high impressions:** CTR problem (ad or keyword relevance)

---

### CTR (Click-Through Rate)
**Definition:** Percentage of impressions that resulted in clicks

**Formula:**
```
CTR = (Clicks / Impressions) × 100
```

**Benchmark:**
| Ad Type | Average CTR | Good CTR | Excellent CTR |
|---------|-------------|----------|---------------|
| **Search Ads** | 2-3% | 5-8% | 10%+ |
| **Display Ads** | 0.5% | 1% | 2%+ |
| **Shopping Ads** | 0.8-1% | 1.5% | 2%+ |
| **Video Ads** | 0.3% | 0.5% | 1%+ |

**What affects CTR:**
- Ad relevance to keyword
- Ad copy quality
- Ad position
- Ad extensions
- Offer/value proposition

**Improvement strategies:**
- Improve ad copy (benefits, CTAs)
- Add ad extensions
- Tighten keyword targeting
- Improve Quality Score (better position)

---

### CPC (Cost Per Click)
**Definition:** Average amount paid for each click

**Formula:**
```
CPC = Total Cost / Total Clicks
```

**Benchmark:** (highly variable by industry)
| Industry | Average CPC | Competitive CPC |
|----------|-------------|-----------------|
| **Legal** | €5-10 | €20+ |
| **Insurance** | €3-8 | €15+ |
| **SaaS/Software** | €2-5 | €10+ |
| **Ecommerce** | €0.50-2 | €5+ |
| **Local Services** | €1-4 | €8+ |

**What affects CPC:**
- **Quality Score** (higher QS = lower CPC)
- **Competition** (more advertisers = higher CPC)
- **Ad Rank** (higher rank can sometimes lower CPC)
- **Match type** (exact < phrase < broad)
- **Device/location** (mobile often cheaper)

**How to lower CPC:**
1. Improve Quality Score (most impactful)
2. Use exact/phrase match (not broad)
3. Add negative keywords (filter irrelevant clicks)
4. Target long-tail keywords (less competitive)
5. Adjust device/location bids (pause poor performers)

---

### Conversions
**Definition:** Number of times users completed your goal action

**Examples:**
- **Ecommerce:** Purchases
- **Lead gen:** Form submissions, calls
- **SaaS:** Trial signups, demo requests

**Setup required:** Conversion tracking must be implemented

**Formula:**
```
Conversions = Total conversion actions
```

**Analysis:**
- **High clicks, low conversions:** Landing page or offer problem
- **Low conversions, high CPA:** Need better targeting or lower CPC

---

### Conversion Rate
**Definition:** Percentage of clicks that resulted in conversions

**Formula:**
```
Conversion Rate = (Conversions / Clicks) × 100
```

**Benchmark:** (varies dramatically by industry and conversion type)
| Conversion Type | Average | Good | Excellent |
|-----------------|---------|------|-----------|
| **Ecommerce purchase** | 1-2% | 3-5% | 5-10% |
| **Lead form** | 2-5% | 5-10% | 10-15% |
| **Free trial signup** | 5-10% | 10-20% | 20%+ |
| **Phone call** | 5-10% | 10-15% | 15-20% |

**What affects conversion rate:**
- Landing page quality
- Offer strength
- Form length/complexity
- Page load speed
- Trust signals
- Mobile-friendliness

**Improvement strategies:**
- Optimize landing page (clear value prop, strong CTA)
- Reduce form fields
- Add trust signals (reviews, security badges)
- Improve page speed (<3s load time)
- A/B test offers

---

### CPA (Cost Per Acquisition)
**Definition:** Average cost to acquire one customer/lead

**Formula:**
```
CPA = Total Cost / Total Conversions
```

**Benchmark:** Depends entirely on your customer lifetime value (LTV)

**Target CPA formula:**
```
Max CPA = Customer LTV × Profit Margin × % of Revenue to Marketing

Example:
LTV = €1,000
Profit margin = 50%
Marketing budget = 20% of revenue
Max CPA = €1,000 × 0.50 × 0.20 = €100
```

**Good CPA:**
- **LTV:CPA ratio >3:1** (healthy)
- **LTV:CPA ratio >5:1** (excellent)

**Example:**
- CPA: €50
- Customer LTV: €300
- Ratio: 6:1 (excellent)

**How to lower CPA:**
1. Improve conversion rate (same clicks, more conversions)
2. Lower CPC (improve Quality Score, better targeting)
3. Better audience targeting (higher-intent users)
4. Optimize landing page
5. Improve offer/value proposition

---

### ROAS (Return on Ad Spend)
**Definition:** Revenue generated for every dollar spent on ads

**Formula:**
```
ROAS = Revenue from Ads / Ad Spend × 100

Example:
Ad spend: €1,000
Revenue: €5,000
ROAS = €5,000 / €1,000 × 100 = 500% (5:1 ratio)
```

**Benchmark:**
| Business Type | Break-Even ROAS | Good ROAS | Excellent ROAS |
|---------------|-----------------|-----------|----------------|
| **Low margin (10-20%)** | 500-1000% | 800%+ | 1200%+ |
| **Medium margin (30-50%)** | 200-300% | 400%+ | 600%+ |
| **High margin (60%+)** | 150-200% | 300%+ | 500%+ |

**Calculation from margin:**
```
Break-even ROAS = 100% / Profit Margin

Example (30% profit margin):
Break-even ROAS = 100% / 30% = 333%
Target ROAS = 333% × 1.5 = 500% (to be profitable)
```

**How to improve ROAS:**
1. Increase average order value (AOV)
2. Improve conversion rate
3. Lower CPC
4. Better audience targeting
5. Upsell/cross-sell

---

### AOV (Average Order Value)
**Definition:** Average amount spent per order

**Formula:**
```
AOV = Total Revenue / Number of Orders
```

**Benchmark:** Varies by industry (€50-€500+)

**How to increase AOV:**
- Product bundling
- Free shipping threshold ("Free shipping over €50")
- Upsells at checkout
- Recommended products
- Volume discounts

**Impact on ROAS:**
```
Scenario 1 (low AOV):
AOV = €50, CPA = €10, ROAS = 500%

Scenario 2 (high AOV):
AOV = €75, CPA = €10, ROAS = 750%

25% increase in AOV = 50% increase in ROAS!
```

---

## Quality Score Metrics

### Quality Score (QS)
**Definition:** Google's rating (1-10) of keyword, ad, and landing page quality

**Components:**
1. **Expected CTR** (40% weight)
2. **Ad Relevance** (30% weight)
3. **Landing Page Experience** (30% weight)

**Benchmark:**
- **1-3:** Poor (very expensive, low ad rank)
- **4-6:** Average (room for improvement)
- **7-8:** Good (competitive)
- **9-10:** Excellent (maximum savings)

**Impact on CPC:**
| Quality Score | Est. CPC Impact |
|---------------|-----------------|
| 1 | +400% |
| 3 | +150% |
| 5 | +50% |
| 7 | Baseline |
| 9 | -30% |
| 10 | -50% |

**Example:**
- Baseline CPC: €2.00
- QS = 5: Actual CPC = €3.00
- QS = 9: Actual CPC = €1.40

**Improvement:** See [google-ads-optimization.md](google-ads-optimization.md#quality-score-optimization)

---

### Expected CTR
**Definition:** Likelihood of ad being clicked (relative to competitors)

**Status:**
- **Above Average** ✅
- **Average** ⚠️
- **Below Average** ❌

**How to improve:**
- Write compelling ad copy
- Include primary keyword in headline
- Add ad extensions
- Test multiple ad variations
- Ensure keyword relevance

---

### Ad Relevance
**Definition:** How well ad matches keyword intent

**How to improve:**
- Include keyword in headline
- Create tightly themed ad groups (5-20 related keywords)
- Match ad messaging to keyword intent
- Use dynamic keyword insertion (sparingly)

---

### Landing Page Experience
**Definition:** Quality and relevance of landing page

**How to improve:**
- Match landing page content to ad promise
- Fast page load (<3s)
- Mobile-friendly design
- Clear CTA
- Easy navigation
- Trust signals (reviews, security badges)
- Original, relevant content

---

## Impression Share Metrics

### Impression Share (IS)
**Definition:** Percentage of impressions you received out of total eligible impressions

**Formula:**
```
Impression Share = (Impressions / Total Eligible Impressions) × 100
```

**Benchmark:**
- **<30%:** Missing most opportunities
- **30-60%:** Moderate visibility
- **60-80%:** Good visibility
- **>80%:** Dominant visibility

**Analysis:**
- **Low IS + Lost IS (Budget):** Increase budget
- **Low IS + Lost IS (Rank):** Increase bids or improve Quality Score

---

### Search Impression Share (Search IS)
**Definition:** Impression share specifically for search ads

**Target:** 70%+ for brand keywords, 30-50% for generic keywords

---

### Search Lost IS (Budget)
**Definition:** Percentage of impressions lost because daily budget ran out

**Benchmark:**
- **0-10%:** Budget sufficient
- **10-30%:** Moderate budget constraint
- **>30%:** Significantly budget-limited

**Solutions:**
- Increase daily budget
- Lower bids (get more clicks for same budget)
- Focus budget on top performers
- Use shared budgets

---

### Search Lost IS (Rank)
**Definition:** Percentage of impressions lost due to low Ad Rank

**Causes:**
- Low bids
- Low Quality Score
- Both

**Solutions:**
- Increase bids
- Improve Quality Score (see optimization guide)

---

### Top Impression Share
**Definition:** Percentage of impressions in top positions (above organic results)

**Benchmark:**
- **Brand keywords:** Target 90%+ (own your brand)
- **High-intent keywords:** Target 50-70%
- **Generic keywords:** Target 20-40%

---

### Absolute Top Impression Share
**Definition:** Percentage of impressions in position #1

**Use case:**
- Brand protection (own position 1 for your brand)
- High-value keywords (dominate competitive terms)

**Note:** Position 1 isn't always most profitable (can overpay)

---

## Auction Metrics

### Average Position (Deprecated)
**Note:** Google removed this metric in 2020. Use impression share metrics instead.

---

### Outranking Share
**Definition:** How often your ad ranked higher than a competitor's ad

**Found in:** Auction Insights report

**Use case:** Competitive analysis (am I winning against competitor X?)

---

### Top of Page Rate
**Definition:** Percentage of impressions shown above organic results

**Target:** >50% for important keywords

---

### Absolute Top of Page Rate
**Definition:** Percentage of impressions in #1 position

---

## Time-Based Metrics

### Hour of Day Performance
**Analysis:**
- Identify high-converting hours
- Adjust bids by time of day (+20-50% during peak)
- Pause ads during non-converting hours

**Example (B2B SaaS):**
- Peak: 9am-5pm weekdays
- Low: Nights and weekends
- Strategy: +30% bids 9am-5pm, -50% nights/weekends

---

### Day of Week Performance
**Analysis:**
- Compare conversion rates by day
- Adjust bids or pause low-performing days

**Example (Ecommerce):**
- Peak: Friday-Sunday (leisure browsing)
- Low: Monday-Tuesday
- Strategy: +20% bids Friday-Sunday

---

## Geographic Metrics

### Location Performance
**Metrics to analyze:**
- CTR by location
- Conversion rate by location
- CPA by location

**Actions:**
- Increase bids for top-performing locations (+30-50%)
- Decrease bids for poor performers (-30-50%)
- Exclude locations with 0 conversions after 100+ clicks

---

## Device Metrics

### Device Performance
**Metrics to compare:**
| Device | Typical CTR | Typical Conv. Rate | Typical CPC |
|--------|-------------|-------------------|-------------|
| **Desktop** | Higher | Higher | Higher |
| **Mobile** | Lower | Lower | Lower |
| **Tablet** | Lowest | Lowest | Medium |

**Common patterns:**
- **Research-heavy purchases:** Desktop converts better (B2B, high-ticket)
- **Impulse purchases:** Mobile converts well (food, local services)
- **Tablets:** Often underperform (consider excluding)

**Bid adjustments:**
- Desktop: Baseline (0%)
- Mobile: -20% to +30% (depends on performance)
- Tablet: -30% to -100% (often pause)

---

## Advanced Metrics

### Search Terms Performance
**Where:** Search Terms Report (Insights & Reports → Search terms)

**What to analyze:**
- Which actual searches trigger ads
- CTR by search term
- Conversion rate by search term
- Irrelevant searches (add as negatives)

**Actions:**
1. Add high-performing search terms as keywords
2. Add irrelevant terms as negative keywords
3. Identify new keyword themes

---

### Interaction Rate
**Definition:** Percentage of impressions that resulted in interactions (clicks, calls, etc.)

**Formula:**
```
Interaction Rate = (Interactions / Impressions) × 100
```

**Use case:** Better than CTR for campaigns with call extensions (counts both clicks and calls)

---

### View-Through Conversions (VTC)
**Definition:** Conversions from users who saw (but didn't click) your display/video ad, then later converted

**Typical attribution window:** 1-30 days

**Use case:** Measure brand awareness impact of display/video campaigns

---

### Assisted Conversions
**Definition:** Number of conversions where this campaign was involved (but not the final click)

**Found in:** Attribution Reports

**Use case:** Understand campaign's role in customer journey (even if it didn't get "credit" for final conversion)

---

## Ecommerce-Specific Metrics

### Product Performance
**Metrics:**
- Impressions by product
- Clicks by product
- Conversion rate by product
- ROAS by product

**Actions:**
- Increase bids for high-ROAS products
- Pause products with <2% conversion rate
- Create separate campaigns for best sellers

---

### Shopping Ad Metrics

**Benchmark (Shopping Ads):**
- **CTR:** 0.8-1.5%
- **Conversion rate:** 1-3%
- **ROAS:** 400-800%

---

## Lead Generation Metrics

### Form Completion Rate
**Definition:** Percentage of landing page visitors who complete form

**Formula:**
```
Form Completion Rate = (Form Submissions / Landing Page Visits) × 100
```

**Benchmark:**
- **Long form (10+ fields):** 10-20%
- **Medium form (5-9 fields):** 20-40%
- **Short form (2-4 fields):** 40-60%

**Improvement:**
- Reduce form fields
- Add trust signals
- Use multi-step forms
- Offer value (whitepaper, demo) in exchange

---

### Call Conversions
**Definition:** Conversions from phone calls (call extensions)

**Tracking required:** Google Ads call tracking

**Benchmark:**
- **Call duration >60 seconds:** Usually qualified lead
- **Call duration <30 seconds:** Often wrong number or spam

---

## Calculated Metrics

### Profit Per Click
**Formula:**
```
Profit Per Click = (Revenue Per Conversion × Conversion Rate) - CPC

Example:
Revenue per conversion: €100
Conversion rate: 5%
CPC: €2
Profit per click = (€100 × 0.05) - €2 = €3
```

**Use case:** Identify most profitable keywords (higher is better)

---

### Lifetime Value to CPA Ratio (LTV:CPA)
**Formula:**
```
LTV:CPA = Customer Lifetime Value / Cost Per Acquisition

Example:
LTV = €500
CPA = €50
Ratio = 10:1 (excellent)
```

**Benchmark:**
- **<2:1:** Unprofitable (spending too much to acquire)
- **3:1:** Break-even to slightly profitable
- **5:1:** Healthy
- **10:1+:** Excellent (scale aggressively)

---

## Reporting Metrics Priority

### Essential (Report Weekly)
1. Conversions
2. CPA
3. ROAS (if ecommerce)
4. CTR
5. Quality Score

### Important (Report Monthly)
6. Conversion rate
7. Impression share
8. Search terms performance
9. Budget utilization
10. Competitive insights (Auction Insights)

### Nice to Have (Report Quarterly)
11. Assisted conversions
12. Device/location performance
13. Time of day performance
14. Landing page performance
15. Audience performance

---

## Red Flags to Monitor

**Critical issues:**
- ❌ **CTR <1%** (for search ads) → Poor ad relevance
- ❌ **Quality Score <5** → Overpaying for clicks
- ❌ **Conversion rate <1%** (for most industries) → Landing page problem
- ❌ **CPA increasing >20% WoW** → Investigate immediately
- ❌ **Impression share <30%** → Missing opportunities
- ❌ **Lost IS (Budget) >50%** → Need more budget
- ❌ **0 conversions after 100+ clicks** → Tracking or landing page issue

**Warning signs:**
- ⚠️ **CTR declining >10% WoW** → Competitor activity or ad fatigue
- ⚠️ **CPC increasing >15% WoW** → Increased competition
- ⚠️ **ROAS <300%** (for typical margins) → Unprofitable
- ⚠️ **Bounce rate >70%** → Landing page mismatch

---

## Metrics to Ignore (Usually)

- **Impressions** - Vanity metric without context
- **Average position** - Deprecated by Google
- **Broad match impressions** - Often irrelevant
- **Top IS >90%** - Likely overpaying for #1 position
- **CTR for Display** - Naturally low (<0.5%)

**Focus on business outcomes (conversions, revenue, profit), not vanity metrics (impressions, clicks without conversions).**
