# Google Ads Optimization

## Campaign Structure Best Practices

### Account Hierarchy
```
Account
└── Campaigns (budget, targeting, location)
    └── Ad Groups (keywords, ads)
        ├── Keywords
        ├── Ads
        └── Audience targeting
```

### Ideal Structure

**Campaign level:**
- 5-10 campaigns per account (for small-medium advertisers)
- Organize by: Product category, goal, location, or budget

**Ad group level:**
- 5-20 ad groups per campaign
- Tightly themed (5-20 related keywords per ad group)
- 3-5 ads per ad group (for testing)

**Example structure (SaaS company):**
```
Campaign: Email Marketing Software
├── Ad Group: Email Automation
│   ├── Keywords: email automation, automated email marketing
│   └── Ads: 3 variations focusing on automation
├── Ad Group: Email Analytics
│   ├── Keywords: email analytics, email tracking
│   └── Ads: 3 variations focusing on analytics
└── Ad Group: Email Templates
    ├── Keywords: email templates, email design
    └── Ads: 3 variations focusing on templates
```

---

## Keyword Optimization

### Match Types

| Match Type | Symbol | Example Keyword | Will Match | Won't Match |
|------------|--------|-----------------|------------|-------------|
| **Broad** | none | email marketing | email marketing, marketing via email, digital marketing | seo marketing |
| **Phrase** | "quotes" | "email marketing" | email marketing software, best email marketing | marketing email |
| **Exact** | [brackets] | [email marketing] | email marketing | email marketing software |

**Recommendation:**
- **Start with Phrase or Exact** for control and relevance
- **Use Broad cautiously** (wastes budget on irrelevant searches)
- **Monitor Search Terms Report** to find new keyword opportunities

### Keyword Research Process

1. **Seed keywords:** Brainstorm 5-10 core terms
2. **Keyword Planner:** Use Google Keyword Planner for ideas and volume
3. **Competitor research:** See what competitors bid on (SpyFu, SEMrush)
4. **Customer language:** Use terms customers actually search
5. **Long-tail keywords:** Target specific, lower-competition phrases

**Keyword types to include:**
- **Branded:** Your brand name, competitors
- **Generic:** Broad category terms (high volume, competitive)
- **Long-tail:** Specific phrases (lower volume, higher intent)
- **Question-based:** "how to...", "what is...", "best..."

### Negative Keywords (Critical!)

**Purpose:** Prevent ads from showing for irrelevant searches

**Examples (for "email marketing software"):**
- `free` - If you don't offer free plan
- `job` - Blocks "email marketing jobs"
- `course` - Blocks "email marketing course"
- `tutorial` - If you're not educational content
- `[competitor name]` - If you don't want to bid on competitors

**Where to add:**
- **Campaign level:** Applies to entire campaign
- **Ad group level:** Specific to ad group
- **Shared lists:** Reusable across campaigns

**Sources for negative keywords:**
1. **Search Terms Report:** Review weekly, add irrelevant terms
2. **Common sense:** "free", "cheap", "job", "DIY", "how to"
3. **Competitor terms:** If not targeting competitor keywords

### Keyword Bidding Strategies

#### Manual CPC
- Full control over individual keyword bids
- Best for: Small budgets, testing, experienced advertisers
- Requires: Active management and optimization

#### Enhanced CPC (ECPC)
- Manual bids + Google's automatic adjustments (±30%)
- Increases bids for likely conversions, decreases for unlikely
- Best for: Accounts with some conversion data

#### Maximize Clicks
- Automated bidding to get most clicks within budget
- Best for: Brand awareness, early testing
- Downside: May not drive conversions

#### Target CPA (Cost Per Acquisition)
- Google optimizes for conversions at target cost
- Best for: Accounts with 30+ conversions/month
- Requires: Conversion tracking set up

#### Target ROAS (Return on Ad Spend)
- Optimizes for revenue at target return percentage
- Best for: Ecommerce with transaction value tracking
- Requires: 50+ conversions/month, conversion values tracked

**Recommendation for most businesses:**
1. **Start:** Manual CPC or Enhanced CPC
2. **Once 30+ conversions/month:** Switch to Target CPA
3. **Ecommerce:** Target ROAS once sufficient data

---

## Quality Score Optimization

### What is Quality Score?

**Definition:** Google's rating (1-10) of your keywords, ads, and landing pages.

**Why it matters:**
- Higher QS = Lower CPC (save money)
- Higher QS = Better ad position
- Higher QS = More impressions

**Target:** 7+ (10 is best, 1 is worst)

### Three Components

#### 1. Expected CTR (40% weight)
**Definition:** Likelihood your ad will be clicked

**How to improve:**
- Write compelling ad copy (include keywords, benefits, CTAs)
- Use ad extensions (sitelinks, callouts, structured snippets)
- Ensure keyword relevance to ad
- Test multiple ad variations
- Pause low-performing keywords (CTR <1% for search)

#### 2. Ad Relevance (30% weight)
**Definition:** How well ad matches keyword intent

**How to improve:**
- Include keyword in ad headline (preferably Headline 1)
- Create tightly themed ad groups (5-20 related keywords)
- Use Dynamic Keyword Insertion sparingly (`{KeyWord:Default}`)
- Match ad messaging to search intent
- Avoid generic ad copy

**Example:**
```
Keyword: "email automation software"

✅ Good ad:
Headline 1: Email Automation Software
Headline 2: Save 10 Hours Per Week
Description: Automate your email campaigns with powerful workflows...

❌ Bad ad:
Headline 1: Marketing Platform
Headline 2: All-In-One Solution
Description: We offer various marketing tools...
```

#### 3. Landing Page Experience (30% weight)
**Definition:** How relevant and useful your landing page is

**How to improve:**
- **Relevance:** Landing page content matches ad and keyword
- **Clarity:** Clear value proposition above the fold
- **Transparency:** Easy to understand what you offer
- **Easy navigation:** Clear CTA, minimal distractions
- **Mobile-friendly:** Responsive design
- **Fast loading:** <3 seconds page load
- **Original content:** Unique, valuable content
- **Trustworthiness:** Privacy policy, contact info, testimonials

**Landing page checklist:**
- [ ] Headline includes keyword from ad
- [ ] Content expands on ad promise
- [ ] Single, clear CTA
- [ ] Mobile-optimized
- [ ] Loads in <3 seconds
- [ ] HTTPS secure
- [ ] Contact information visible
- [ ] Trust signals (testimonials, reviews, badges)

### Quality Score Analysis

**How to check:**
1. Google Ads → Keywords tab
2. Columns → Modify columns → Quality Score
3. Add: Quality Score, Exp. CTR, Ad Relevance, Landing Page Exp.

**Interpreting scores:**
- **Above Average:** Great, keep it up
- **Average:** Room for improvement
- **Below Average:** Needs immediate attention

**Optimization priority:**
1. Fix "Below Average" factors first
2. Focus on lowest QS keywords (1-4)
3. Consider pausing keywords with QS <3 (too expensive)

---

## Ad Copy Optimization

### Responsive Search Ads (RSA) Best Practices

**Structure:**
- 3-15 headlines (Google tests combinations)
- 2-4 descriptions
- Google shows best-performing combinations

**Headline guidelines:**
- **Headline 1:** Include primary keyword + benefit
- **Headline 2:** Secondary benefit or differentiator
- **Headline 3:** Call-to-action or urgency
- **30 characters max** per headline

**Description guidelines:**
- **Description 1:** Expand on value proposition, include keyword
- **Description 2:** Address objection or add social proof
- **90 characters max** per description

**RSA best practices:**
- Write at least 10 headlines, 4 descriptions (more variations = better)
- Include keywords in 2-3 headlines
- Pin Headline 1 if brand name must show first
- Use different messaging angles (benefits, features, price, social proof)
- Avoid redundant headlines (don't repeat same message)

**Example RSA (Email Marketing Software):**

**Headlines:**
1. Email Marketing Software (keyword)
2. Automate Your Email Campaigns (benefit)
3. Used by 50,000+ Companies (social proof)
4. Free 14-Day Trial (offer)
5. No Credit Card Required (objection handler)
6. Increase Email ROI by 300% (result)
7. AI-Powered Email Optimization (differentiator)
8. Get Started in 5 Minutes (ease)
9. 24/7 Customer Support (trust)
10. Top-Rated on G2 (social proof)

**Descriptions:**
1. Send targeted email campaigns with powerful automation. Drag-and-drop builder, advanced segmentation, and analytics.
2. Join 50,000+ companies increasing email ROI. Free trial, no credit card required. Cancel anytime.

### Ad Copy Formula

**PAS (Problem-Agitate-Solution):**
```
Headline 1: [Problem] - "Struggling with Email Marketing?"
Headline 2: [Agitation] - "Stop Wasting Time on Manual Sends"
Description: [Solution] - "Automate your campaigns and boost open rates by 40%"
```

**BAB (Before-After-Bridge):**
```
Headline 1: [Before] - "Manual Email Campaigns?"
Headline 2: [After] - "Automate & Scale Effortlessly"
Description: [Bridge] - "Our platform helps you automate workflows, segment audiences, and track results"
```

**4 U's (Useful, Urgent, Unique, Ultra-specific):**
```
Headline 1: [Useful + Urgent] - "Double Email ROI in 30 Days"
Headline 2: [Unique] - "AI-Powered Email Optimization"
Description: [Ultra-specific] - "Join 5,000+ SaaS companies using our platform to send 2M emails/month"
```

### Ad Extensions (Critical for CTR)

**Sitelink Extensions** (additional links below ad)
```
Get Started | Pricing | Features | Customer Stories
```
- Add 4+ sitelinks
- Use different landing pages
- Include CTAs in sitelink text

**Callout Extensions** (short bullet points)
```
✓ Free 14-Day Trial  ✓ No Credit Card  ✓ 24/7 Support  ✓ Cancel Anytime
```
- Add 6-10 callouts
- Highlight key benefits, offers, differentiators

**Structured Snippet Extensions** (predefined categories)
```
Services: Email Automation, A/B Testing, Analytics, Segmentation
```
- Choose relevant header (Services, Features, Types, Brands)
- List 3+ items

**Call Extensions** (phone number)
- Include for businesses that accept calls
- Track calls as conversions

**Location Extensions** (address)
- Essential for local businesses
- Link Google Business Profile

**Price Extensions** (product/service pricing)
- Shows pricing upfront (filters non-buyers)
- Increases transparency and trust

**Promotion Extensions** (sales, offers)
- Highlight limited-time offers
- Adds urgency

---

## Bidding & Budget Optimization

### Budget Allocation

**By performance:**
```
High-performing campaigns (ROAS >400%): 60% of budget
Medium-performing (ROAS 200-400%): 30% of budget
Testing/new campaigns: 10% of budget
```

**By funnel stage:**
```
Bottom-funnel (high intent, brand, competitor): 50%
Mid-funnel (solution-aware): 30%
Top-funnel (problem-aware, discovery): 20%
```

### Bid Adjustments

**Device bid adjustments:**
- Desktop: Baseline (0%)
- Mobile: +20% if mobile converts better
- Tablet: -30% if tablet underperforms

**Location bid adjustments:**
- Top-performing cities: +30%
- Underperforming regions: -50% or exclude
- Target locations only (not "interested in")

**Time of day/day of week:**
- Increase bids during high-conversion hours
- Decrease bids during low-performing times
- Analyze conversion data by hour/day

**Audience bid adjustments:**
- Remarketing audiences: +50% (they're warmer leads)
- In-market audiences: +20%
- Similar audiences: 0% (test first)

### When to Pause/Adjust

**Pause keywords when:**
- Quality Score <3 (after optimization attempts)
- CTR <1% (for search ads)
- CPA >3x target (and not improving)
- No conversions after 100+ clicks

**Increase bids when:**
- Avg. position >3 (you're missing impressions)
- Impression share <50% (due to rank, not budget)
- CPA below target (scale winning keywords)

**Decrease bids when:**
- Avg. position = 1 (often overpaying)
- CPA above target
- Low conversion rate despite high clicks

---

## Conversion Tracking Setup

### What to Track

**Ecommerce:**
- Purchases (transaction_id, value, currency)
- Add to cart
- Begin checkout

**Lead generation:**
- Form submissions
- Phone calls
- Chat initiations
- Demo requests

**SaaS:**
- Free trial signups
- Account creations
- Feature usage
- Upgrades

### Conversion Actions Setup

1. Google Ads → Goals → Conversions → New Conversion Action
2. Choose source: Website, App, Phone calls, Import
3. Category: Purchase, Lead, Sign-up, etc.
4. Value: Assign fixed value or use transaction value
5. Count: One (recommended) or Every (for repeat actions)
6. Attribution: Data-driven (recommended) or Last Click

### Enhanced Conversions

**Purpose:** Improves conversion measurement accuracy using first-party data

**How it works:**
- Sends hashed customer data (email) with conversion
- Google matches to signed-in users
- Improves attribution across devices

**Implementation:**
```javascript
// Example with GTM
gtag('set', 'user_data', {
  email: 'user@example.com', // Hashed automatically
  phone_number: '+1234567890',
  address: {
    first_name: 'John',
    last_name: 'Doe',
    city: 'New York',
    country: 'US'
  }
});

gtag('event', 'conversion', {
  'send_to': 'AW-CONVERSION_ID/CONVERSION_LABEL',
  'value': 99.99,
  'currency': 'EUR',
  'transaction_id': 'T12345'
});
```

---

## Performance Analysis

### Key Reports

**Search Terms Report**
- See actual searches triggering your ads
- Find new keyword opportunities
- Identify negative keywords

**Auction Insights**
- Compare performance vs. competitors
- Identify impression share opportunities
- Analyze competitive landscape

**Ad Performance**
- Compare ad variations
- Identify winning ad copy
- Pause underperforming ads

### What to Monitor Weekly

- [ ] **Search Terms Report** → Add negatives, find new keywords
- [ ] **Quality Scores** → Optimize keywords <7
- [ ] **Ad performance** → Pause CTR <1%, test new ads
- [ ] **Budget pacing** → Ensure not limited by budget
- [ ] **Conversion trends** → Identify drops or spikes
- [ ] **Competitor activity** → Auction Insights report

### What to Monitor Monthly

- [ ] **Campaign ROAS** → Reallocate budget
- [ ] **Landing page performance** → A/B test pages
- [ ] **Audience performance** → Adjust bid adjustments
- [ ] **Device/location performance** → Adjust bids
- [ ] **Keyword expansion** → Add new keywords
- [ ] **Account structure** → Reorganize if needed

---

## Common Issues & Fixes

### Low CTR (<1% search, <0.3% display)

**Causes:**
- Irrelevant keywords
- Generic ad copy
- Poor ad position (page 2+)

**Fixes:**
- Tighten keyword match types
- Improve ad copy (add benefits, CTAs)
- Increase bids for better position
- Add ad extensions

### High CPC

**Causes:**
- Low Quality Score
- Highly competitive keywords
- Broad match keywords

**Fixes:**
- Improve Quality Score (see section above)
- Target long-tail keywords (less competitive)
- Use phrase/exact match
- Add negative keywords

### Low Conversion Rate (<1%)

**Causes:**
- Wrong target audience
- Poor landing page
- Weak offer/value prop
- Form too long

**Fixes:**
- Refine targeting (keywords, audiences, locations)
- Improve landing page (clear CTA, faster load, mobile-friendly)
- Test stronger offer (discount, free trial, demo)
- Simplify form (fewer fields)

### High CPA (Above Target)

**Causes:**
- Low Quality Score (paying too much per click)
- Low conversion rate (too many clicks, few conversions)
- Wrong keywords (not purchase-intent)

**Fixes:**
- Improve Quality Score → Lower CPC
- Improve landing page → Higher conversion rate
- Target bottom-funnel keywords (higher intent)
- Add negative keywords (filter bad traffic)

### Limited by Budget

**Symptoms:**
- "Limited by budget" status in campaign
- High impression share lost due to budget

**Fixes:**
- Increase daily budget
- Lower bids (get more clicks for same budget)
- Pause underperforming campaigns
- Focus budget on top performers
- Use shared budgets across campaigns

### Low Impression Share

**Causes:**
- Low budget (lost IS - budget)
- Low bids/Quality Score (lost IS - rank)

**Fixes:**
- If lost to budget: Increase budget or lower bids
- If lost to rank: Increase bids or improve Quality Score
- Target less competitive keywords

---

## Advanced Strategies

### Remarketing (RLSA)

**Audiences to create:**
- **All website visitors** (30-90 days)
- **Cart abandoners** (30 days) - Increase bids +50%
- **Past converters** (180 days) - Upsell/cross-sell
- **Long-time visitors** (5+ pageviews) - High intent

**Strategy:**
- Create separate campaigns for remarketing
- Higher bids (they're warmer leads)
- Different ad copy (acknowledge they visited)

### Competitor Targeting

**Pros:**
- Steal competitor traffic
- Lower CPC (less competitive than generic terms)

**Cons:**
- Ethical concerns
- May trigger competitor retaliation

**Best practices:**
- Don't use competitor name in ad copy (trademark violation)
- Focus on differentiation in ad
- Send to comparison landing page

**Example:**
```
Keyword: [competitor name]

Ad:
Headline 1: Better Alternative to [Generic Category]
Headline 2: Rated #1 by G2 Users
Description: See why companies switch from [competitor] to us
```

### Dayparting (Ad Scheduling)

**Process:**
1. Analyze conversion data by hour/day
2. Identify high-performing time periods
3. Increase bids during peak times (+20-50%)
4. Decrease bids during low times (-30-50%)
5. Or completely pause ads during non-converting hours

**Example:**
- B2B: Pause nights/weekends (people don't convert)
- B2C: Increase bids evenings/weekends (leisure browsing)

### Smart Bidding Strategies

**Target CPA:**
- Best for: Lead generation, consistent conversion values
- Requires: 30+ conversions/month

**Target ROAS:**
- Best for: Ecommerce, variable order values
- Requires: 50+ conversions/month, transaction values

**Maximize Conversions:**
- Spends entire budget to get most conversions
- Best for: When you want volume, not efficiency

**Maximize Conversion Value:**
- Optimizes for highest revenue within budget
- Best for: Ecommerce with varying order values

---

## Testing Framework

### What to Test

**Ad copy:**
- Headlines (benefit vs. feature vs. question)
- Descriptions (short vs. long, different CTAs)
- Offers (discount vs. free trial vs. demo)

**Landing pages:**
- Headlines
- CTAs (text, color, placement)
- Form length
- Images/videos
- Social proof placement

**Bidding:**
- Manual vs. automated
- Different bid strategies
- Bid adjustments

### Testing Process

1. **Hypothesis:** "Adding urgency to headlines will increase CTR by 10%"
2. **Create variation:** New ad with urgency messaging
3. **Run test:** Wait for statistical significance (typically 2-4 weeks)
4. **Analyze:** Compare CTR, conversion rate, CPA
5. **Implement winner:** Pause loser, create new test

**Statistical significance:**
- Wait for 100+ clicks per variation minimum
- Use Google Ads experiment feature
- Don't end tests too early

---

## Optimization Checklist

### Weekly Tasks
- [ ] Review search terms, add negative keywords
- [ ] Check for disapproved ads
- [ ] Monitor budget pacing
- [ ] Pause low-performing ads (CTR <1%)
- [ ] Respond to performance alerts

### Monthly Tasks
- [ ] Analyze Quality Scores, optimize low scores
- [ ] Review and optimize bids
- [ ] Test new ad copy
- [ ] Expand keyword lists
- [ ] Analyze competitor activity (Auction Insights)
- [ ] Review audience performance
- [ ] Optimize landing pages
- [ ] Adjust device/location bids
- [ ] Review conversion tracking accuracy

### Quarterly Tasks
- [ ] Restructure campaigns if needed
- [ ] Review and update negative keyword lists
- [ ] Analyze year-over-year trends
- [ ] Set new performance goals
- [ ] Competitive research
- [ ] Test new ad formats (video, discovery)
