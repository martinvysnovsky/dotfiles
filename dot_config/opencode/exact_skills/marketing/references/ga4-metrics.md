# Google Analytics 4 (GA4) Metrics

## Key Metric Categories

### 1. Acquisition Metrics
How users find your website.

#### Users
**Definition:** Total unique visitors (identified by Client ID or User ID)

**Benchmark:**
- **Growing:** +10-20% MoM for healthy sites
- **Seasonal:** Varies by industry

**Analysis:**
- Compare new vs. returning users
- Segment by channel to identify best sources
- Track growth trends over time

#### New Users
**Definition:** First-time visitors to your site

**Benchmark:**
- **Healthy mix:** 40-60% new users (depends on business model)
- **Too high (>80%):** Poor retention, focus on engagement
- **Too low (<20%):** Limited growth, need more acquisition

**Analysis:**
- High new users: Good for awareness, but check retention
- Low new users: Strong loyalty, but growth may be stagnant

#### Sessions
**Definition:** Group of user interactions within a 30-minute window

**Benchmark:**
- **Sessions per user:** 1.5-2.0 (varies by business type)
- **B2B sites:** Often higher (multiple research sessions)
- **Ecommerce:** Lower (quick purchases)

**Key metric formula:**
```
Sessions per User = Total Sessions / Total Users
```

#### User Acquisition
**Definition:** Where new users came from (first touch attribution)

**Top Channels:**
- **Organic Search** - SEO traffic (Google, Bing)
- **Paid Search** - Google Ads, Bing Ads
- **Direct** - Typed URL or bookmark
- **Referral** - Links from other websites
- **Social** - Facebook, LinkedIn, Twitter, etc.
- **Email** - Email campaigns
- **Organic Social** - Unpaid social media

**Analysis:**
- Identify most valuable acquisition channels
- Compare cost-per-acquisition by channel
- Optimize marketing spend based on data

#### Traffic Acquisition
**Definition:** Where all sessions came from (includes returning users)

**Difference from User Acquisition:**
- User Acquisition: First visit only (new users)
- Traffic Acquisition: All visits (new + returning)

**Use case:** Understanding ongoing traffic patterns vs. initial discovery

---

### 2. Engagement Metrics
How users interact with your content.

#### Engagement Rate
**Definition:** Percentage of sessions that were "engaged"

**Engaged session criteria (any of):**
- Lasted 10+ seconds
- Had 2+ page views
- Had 1+ conversion event

**Benchmark:**
- **Excellent:** >75%
- **Good:** 60-75%
- **Average:** 40-60%
- **Poor:** <40%

**Formula:**
```
Engagement Rate = Engaged Sessions / Total Sessions × 100
```

**Improvement strategies:**
- Improve content quality (keep users reading)
- Add internal links (encourage multi-page visits)
- Optimize page load speed (reduce bounces)
- Make CTAs more prominent (drive conversions)

#### Engaged Sessions per User
**Definition:** Average number of engaged sessions per user

**Benchmark:**
- **Good:** >1.2
- **Excellent:** >1.5

**Analysis:**
- Low value: Users don't return or don't engage deeply
- High value: Strong content and user loyalty

#### Average Engagement Time
**Definition:** Average time users actively interacted with your site (replaces session duration)

**What counts as engaged:**
- Page in focus (active tab)
- Scrolling, clicking, playing video
- Form interaction

**Benchmark:**
- **Blog/content sites:** 2-4 minutes
- **Ecommerce:** 3-5 minutes
- **SaaS product pages:** 1-3 minutes
- **News sites:** 1-2 minutes

**Note:** GA4's engaged time is more accurate than Universal Analytics "session duration" (which counted time even when tab was inactive)

#### Bounce Rate (GA4 Definition)
**Definition:** Percentage of sessions that were NOT engaged

**Formula:**
```
Bounce Rate = (1 - Engagement Rate) × 100
```

**Benchmark:**
- **Excellent:** <25%
- **Good:** 25-40%
- **Average:** 40-60%
- **Poor:** >60%

**Important:** GA4 bounce rate differs from Universal Analytics
- **UA:** Single pageview, no interaction
- **GA4:** Session <10s, single page, no conversion

**Improvement strategies:**
- Improve page relevance (match search intent)
- Speed up page load time
- Add engaging media (videos, interactive elements)
- Improve content quality and readability

#### Events
**Definition:** User interactions tracked (clicks, downloads, video plays, etc.)

**Types:**
- **Automatically collected:** page_view, session_start, first_visit
- **Enhanced measurement:** scroll, outbound_click, file_download, video_start
- **Recommended events:** purchase, sign_up, login (predefined by Google)
- **Custom events:** Any event you define

**Analysis:**
- Identify most common user actions
- Track conversion funnel events
- Optimize based on user behavior

#### Views per Session
**Definition:** Average number of pages/screens viewed per session

**Benchmark:**
- **Content sites:** 3-5 pages
- **Ecommerce:** 5-8 pages
- **One-page sites:** 1-2 pages (expected)

**Formula:**
```
Views per Session = Total Views / Total Sessions
```

**Analysis:**
- Low value: Users not exploring site (improve internal linking)
- High value: Good content discovery (strong site architecture)

---

### 3. Conversion Metrics
Actions users take that drive business value.

#### Conversions
**Definition:** Total number of conversion events triggered

**Types:**
- **Macro conversions:** Purchases, sign-ups, leads
- **Micro conversions:** Newsletter subscribe, video watch, resource download

**Setup:** Mark important events as "conversions" in GA4 settings

**Analysis:**
- Track conversion trends over time
- Segment conversions by source/medium
- Calculate conversion value

#### Conversion Rate
**Definition:** Percentage of sessions that resulted in a conversion

**Benchmark:**
- **Excellent:** >5%
- **Good:** 2-5%
- **Average:** 1-2%
- **Poor:** <1%

*(Highly varies by industry and conversion type)*

**Formula:**
```
Conversion Rate = Conversions / Total Sessions × 100
```

**Ecommerce-specific benchmark:**
- **B2C ecommerce:** 2-3% average
- **Luxury products:** 0.5-1%
- **Niche/specialized:** 5-10%

#### Revenue (Ecommerce)
**Definition:** Total monetary value from purchases

**Metrics to track:**
- **Total Revenue:** All purchase revenue
- **Average Order Value (AOV):** Revenue / Transactions
- **Revenue per User:** Total Revenue / Users
- **Revenue per Session:** Total Revenue / Sessions

**AOV Benchmark:**
- Varies dramatically by industry
- Track your own baseline and trends

#### ROAS (Return on Ad Spend)
**Definition:** Revenue generated per dollar spent on advertising

**Formula:**
```
ROAS = Revenue from Ads / Ad Spend × 100
```

**Benchmark:**
- **Break-even:** ~100% (varies by margins)
- **Good:** 400% (4:1 return)
- **Excellent:** 800%+ (8:1 return)

**Example:**
- Ad spend: €1,000
- Revenue: €5,000
- ROAS: 500% (€5 for every €1 spent)

#### Purchase Revenue
**Definition:** Revenue specifically from ecommerce purchases (excludes refunds)

**Related metrics:**
- **Purchase to Detail Rate:** % of product views that lead to purchase
- **Cart to Purchase Rate:** % of add-to-cart events that convert

---

### 4. Retention Metrics
How well you keep users coming back.

#### User Retention
**Definition:** Percentage of users who return after first visit

**Benchmark:**
- **Day 1 retention:** 20-40%
- **Day 7 retention:** 10-20%
- **Day 30 retention:** 5-10%

**Varies by:**
- **Daily-use apps:** Much higher (50%+ day 1)
- **Infrequent-purchase ecommerce:** Lower (5-10% day 1)

**Analysis:**
- Low retention: Improve onboarding, email nurture
- High retention: Strong product-market fit

#### Cohort Analysis
**Definition:** Track behavior of users acquired in the same time period

**Use cases:**
- Compare retention by acquisition source
- Measure impact of product changes
- Identify valuable user segments

**Example insight:**
"Users acquired from organic search have 30% higher day-7 retention than paid social users"

#### Lifetime Value (LTV)
**Definition:** Predicted revenue from a user over their entire relationship

**Formula (simplified):**
```
LTV = Average Order Value × Purchase Frequency × Customer Lifespan
```

**Benchmark:**
- **SaaS:** $100-$10,000+ (varies by plan price)
- **Ecommerce:** $50-$500 (varies by product)

**Use case:**
Compare LTV to CAC (Customer Acquisition Cost)
- **Good ratio:** LTV:CAC of 3:1 or higher
- **Excellent:** LTV:CAC of 5:1 or higher

---

### 5. Audience Metrics
Who your users are.

#### Demographics
- **Age ranges:** 18-24, 25-34, 35-44, 45-54, 55-64, 65+
- **Gender:** Male, Female, Unknown

**Use case:**
- Tailor content to primary demographic
- Adjust ad targeting
- Identify unexpected audience segments

#### Interests
**Affinity Categories:** Long-term interests (Sports Fans, Tech Enthusiasts)
**In-Market Segments:** Actively researching products (In-market for software, travel)

**Use case:**
- Create content aligned with interests
- Target lookalike audiences in ads
- Discover cross-sell opportunities

#### Geographic
- **Country:** Where users are located
- **City:** Specific city-level data
- **Language:** Browser language setting

**Use case:**
- Localize content for top regions
- Adjust ad spend by location
- Identify expansion opportunities

#### Technology
- **Device category:** Desktop, mobile, tablet
- **Operating system:** Windows, macOS, iOS, Android
- **Browser:** Chrome, Safari, Firefox, Edge

**Benchmark (2024 general):**
- **Mobile:** 50-70% of traffic
- **Desktop:** 25-40%
- **Tablet:** 5-10%

**Use case:**
- Prioritize mobile optimization if >60% mobile
- Test browser-specific issues
- Optimize for dominant platforms

---

### 6. Behavior Metrics

#### Landing Pages
**Definition:** First page users see in a session

**Key metrics:**
- **Sessions:** How many sessions started here
- **Engagement rate:** % of engaged sessions from this page
- **Conversions:** Conversions attributed to landing on this page

**Analysis:**
- Identify best-performing landing pages
- Optimize underperforming high-traffic pages
- Create more content like top performers

#### Exit Pages
**Definition:** Last page users view before leaving

**High exit rate concerns:**
- **Checkout pages:** Friction in purchase flow
- **Blog posts:** Natural endpoint (less concerning)
- **Pricing pages:** Too expensive or unclear value

**Analysis:**
- Exit rate vs. avg: Identify problem pages
- Optimize CTAs on high-exit pages
- Add internal links to keep users engaged

#### Site Search (if configured)
**Definition:** What users search for on your site

**Key metrics:**
- **Search terms:** What people look for
- **% of sessions with search:** How many users search
- **Search exits:** Users who search then leave (indicates unfound content)

**Use case:**
- Identify content gaps (high-volume unfound searches)
- Improve navigation (reduce need to search)
- Understand user intent

---

## Custom Metrics & Dimensions

### Custom Events
Create custom events for business-specific actions:

**B2B SaaS examples:**
- `trial_started`
- `feature_used`
- `pricing_viewed`
- `contact_sales_clicked`

**Ecommerce examples:**
- `wishlist_added`
- `coupon_applied`
- `review_submitted`
- `size_guide_viewed`

### Custom Dimensions
Add extra context to events:

**Examples:**
- **User type:** Free, trial, paid, enterprise
- **Product category:** Electronics, clothing, home
- **Content type:** Blog, guide, case study
- **Membership level:** Basic, premium, VIP

---

## GA4 Reports to Monitor

### Real-Time Report
- Current active users
- Traffic sources (last 30 min)
- Trending events
- Top pages

**Use case:** Monitor campaign launches, site outages

### Life Cycle Reports

#### Acquisition
- **User acquisition:** Where new users come from
- **Traffic acquisition:** Where all traffic comes from

#### Engagement
- **Events:** Most triggered events
- **Conversions:** Conversion event counts
- **Pages and screens:** Top-performing content
- **Landing pages:** Entry point analysis

#### Monetization
- **Ecommerce purchases:** Revenue, transactions, products
- **Publisher ads:** Ad revenue (if using AdSense)
- **In-app purchases:** App monetization

#### Retention
- **User retention:** Cohort retention rates
- **User engagement:** Engagement over time
- **Lifetime value:** LTV by user segment

### User Reports
- **User attributes:** Demographics, interests, tech
- **Tech details:** Browser, OS, device details

---

## Comparing GA4 to Universal Analytics

| Metric | Universal Analytics | GA4 Equivalent | Key Difference |
|--------|---------------------|----------------|----------------|
| **Pageviews** | Pageviews | Views | Similar concept |
| **Session Duration** | Avg. Session Duration | Average Engagement Time | GA4 only counts active time |
| **Bounce Rate** | % with 1 pageview | % not engaged (1 - engagement rate) | GA4 definition much stricter |
| **Goals** | Goal Completions | Conversions (events marked as conversions) | More flexible in GA4 |
| **Users** | Users | Users | More accurate cross-device in GA4 |

---

## Analysis Patterns

### Traffic Drop Investigation
```
1. Check Overview → Identify drop magnitude and timing
2. Acquisition → User/Traffic Acquisition → Identify affected channels
3. Engagement → Pages and Screens → Check if specific pages affected
4. Compare → Previous period → Understand if seasonal
5. Real-Time → Check if ongoing issue
```

### Conversion Optimization
```
1. Monetization → Conversions → Identify conversion rate baseline
2. Exploration → Funnel → Build conversion funnel (identify drop-offs)
3. Engagement → Events → Analyze events leading to conversion
4. User → Demographics/Tech → Segment high-converting users
5. Acquisition → Compare conversion rate by channel
```

### Content Performance
```
1. Engagement → Pages and Screens → Top pages by views
2. Add secondary dimension: Session source → Identify traffic drivers
3. Filter by page path contains "/blog/" → Blog-specific analysis
4. Sort by Average Engagement Time → Find most engaging content
5. Add Conversions metric → Identify revenue-driving content
```

---

## Key Takeaways

1. **Engagement Rate** is the new Bounce Rate (inverse)
2. **Engaged Time** is more accurate than Session Duration
3. **Events** are central to GA4 (everything is an event)
4. **Conversions** are events you mark as important
5. **Cross-device tracking** is better in GA4
6. **Reporting** is more flexible (Explorations vs. standard reports)

**Focus metrics for most businesses:**
- Users, Sessions (acquisition)
- Engagement Rate, Avg. Engagement Time (engagement)
- Conversion Rate, Revenue (conversions)
- User Retention (retention)
