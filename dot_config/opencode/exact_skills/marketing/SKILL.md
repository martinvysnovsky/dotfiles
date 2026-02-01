---
name: marketing
description: Marketing best practices for SEO, Google Analytics 4 (GA4), and Google Ads optimization. Use when (1) performing SEO audits and optimization, (2) analyzing GA4 metrics and user behavior, (3) optimizing Google Ads campaigns, (4) tracking conversions and attribution, (5) improving landing page performance, (6) developing content marketing strategies.
---

# Marketing

## Quick Reference

**SEO Optimization:**
- **[seo-best-practices.md](references/seo-best-practices.md)** - On-page SEO, technical SEO, schema markup, content optimization
- **[seo-checklists.md](references/seo-checklists.md)** - Page audit checklist, content optimization, technical SEO checklist

**Google Analytics 4:**
- **[ga4-metrics.md](references/ga4-metrics.md)** - Key metrics definitions, benchmarks, analysis patterns
- **[ga4-events.md](references/ga4-events.md)** - Event naming conventions, recommended events, custom events, ecommerce tracking

**Google Ads:**
- **[google-ads-optimization.md](references/google-ads-optimization.md)** - Campaign optimization, Quality Score improvement, bidding strategies
- **[google-ads-metrics.md](references/google-ads-metrics.md)** - Key performance indicators, benchmarks, troubleshooting

## Core Patterns

### SEO Optimization Flow

```markdown
1. **Technical SEO Audit**
   - Page speed and Core Web Vitals
   - Mobile-friendliness
   - SSL/HTTPS
   - XML sitemap and robots.txt
   - Schema markup implementation

2. **On-Page SEO Optimization**
   - Title tags (50-60 chars, keyword-rich)
   - Meta descriptions (150-160 chars, compelling CTA)
   - Heading structure (H1-H6 hierarchy)
   - Content optimization (1,500+ words for competitive topics)
   - Image alt text and optimization
   - Internal linking (3-5 relevant links per page)

3. **Content Strategy**
   - Keyword research and targeting
   - Content gap analysis
   - Competitor content analysis
   - Content refresh opportunities
   - Topic clustering and pillar pages

4. **Performance Monitoring**
   - Organic traffic trends
   - Keyword rankings
   - Click-through rates (CTR)
   - Conversion rates from organic
```

### GA4 Analysis Flow

```markdown
1. **Traffic Analysis**
   - User acquisition channels
   - Session sources and mediums
   - Landing page performance
   - Device and browser breakdown

2. **Engagement Analysis**
   - Engagement rate (target: >60%)
   - Average engagement time
   - Pages per session
   - Event counts and types

3. **Conversion Analysis**
   - Conversion rate by channel
   - Funnel drop-off analysis
   - Revenue and ecommerce metrics
   - Attribution modeling

4. **Audience Insights**
   - Demographics (age, gender, location)
   - Interests and affinity categories
   - New vs. returning users
   - User retention cohorts
```

### Google Ads Optimization Flow

```markdown
1. **Account Structure Review**
   - Campaign organization
   - Ad group relevance
   - Keyword grouping
   - Negative keyword lists

2. **Performance Analysis**
   - CTR by campaign/ad group (target: >2%)
   - Quality Score distribution (target: 7+)
   - Conversion rates
   - ROAS (target: >400%)

3. **Optimization Actions**
   - Pause low-performing keywords (QS <5)
   - Add negative keywords from search terms
   - Adjust bids based on performance
   - Test new ad copy variations
   - Refine audience targeting

4. **Budget Management**
   - Reallocate budget to top performers
   - Increase budget for limited-by-budget campaigns
   - Pause campaigns with CPA above target
```

## SEO Quick Wins

### Title Tag Optimization
```html
<!-- ❌ Bad: Generic, no keywords, too long -->
<title>Welcome to Our Website - The Best Company Ever - Home Page</title>

<!-- ✅ Good: Keyword-rich, compelling, proper length -->
<title>SEO Services for SaaS Companies | YourBrand</title>
```

### Meta Description Optimization
```html
<!-- ❌ Bad: Keyword stuffing, no CTA, too short -->
<meta name="description" content="SEO, SEO services, SEO company, best SEO">

<!-- ✅ Good: Natural keywords, value prop, CTA, proper length -->
<meta name="description" content="Boost organic traffic by 150% with our proven SEO strategies for SaaS. Get a free audit and personalized roadmap. Start ranking today.">
```

### Schema Markup Example
```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Product Name",
  "image": "https://example.com/product.jpg",
  "description": "Product description",
  "brand": {
    "@type": "Brand",
    "name": "Brand Name"
  },
  "offers": {
    "@type": "Offer",
    "price": "99.99",
    "priceCurrency": "EUR",
    "availability": "https://schema.org/InStock"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.5",
    "reviewCount": "128"
  }
}
```

## GA4 Event Tracking

### Recommended Event Structure
```javascript
// Generic event
dataLayer.push({
  event: 'event_name',
  event_category: 'Category',
  event_label: 'Label',
  value: 123
});

// GA4 recommended event (automatically tracked with enhanced measurement)
dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'T12345',
    value: 99.99,
    currency: 'EUR',
    tax: 8.99,
    shipping: 5.00,
    items: [{
      item_id: 'SKU123',
      item_name: 'Product Name',
      price: 85.00,
      quantity: 1
    }]
  }
});
```

### GA4 Recommended Events
- `page_view` - Automatically tracked
- `scroll` - User scrolled 90% of page
- `click` - Outbound link click
- `view_item` - Product page view
- `add_to_cart` - Item added to cart
- `begin_checkout` - Checkout initiated
- `purchase` - Purchase completed
- `sign_up` - User registration
- `login` - User login

## Google Ads Best Practices

### Quality Score Improvement
```markdown
**Target: 7+ Quality Score**

1. **Expected CTR** (most important factor)
   - Use highly relevant keywords
   - Write compelling ad copy
   - Use ad extensions (sitelinks, callouts)

2. **Ad Relevance**
   - Match ad copy to keywords
   - Use keywords in headlines
   - Create tightly themed ad groups (5-20 keywords)

3. **Landing Page Experience**
   - Match landing page content to ad copy
   - Fast page load (target: <3 seconds)
   - Mobile-friendly design
   - Clear call-to-action
   - Original, relevant content
```

### Ad Copy Formula
```
Headline 1: [Primary Keyword] + [Benefit]
Headline 2: [Secondary Benefit] + [Differentiator]
Headline 3: [Call to Action] + [Urgency]

Description 1: [Expand on benefit] + [Social proof]
Description 2: [Address objection] + [Strong CTA]
```

Example:
```
H1: SEO Services That Increase Traffic by 150%
H2: Proven Strategies Used by 500+ SaaS Companies
H3: Get Your Free Audit Today - Limited Spots

D1: Our data-driven SEO approach has helped companies like yours double organic traffic in 6 months. See real results fast.
D2: No long-term contracts. Cancel anytime. Start with a free personalized roadmap and see why clients rate us 4.9/5.
```

## Conversion Rate Optimization

### Landing Page Checklist
- [ ] Clear, benefit-driven headline (H1)
- [ ] Compelling subheadline explaining value prop
- [ ] Hero image or video (high quality, relevant)
- [ ] Social proof (testimonials, logos, ratings)
- [ ] Trust signals (security badges, guarantees)
- [ ] Single, clear call-to-action (above fold)
- [ ] Benefit-focused copy (not feature-focused)
- [ ] Minimal navigation/distractions
- [ ] Mobile-responsive design
- [ ] Fast page load (<3 seconds)
- [ ] Form optimization (fewer fields = higher conversion)

### A/B Testing Priorities
1. **Headline** - Biggest impact on conversion
2. **CTA button** - Text, color, position
3. **Hero image** - Visual appeal and relevance
4. **Form length** - Fewer fields often better
5. **Social proof** - Type, placement, quantity

## Key Metrics & Benchmarks

### SEO Metrics
| Metric | Good | Excellent |
|--------|------|-----------|
| Organic CTR (position 1) | 30% | 40%+ |
| Organic CTR (position 3) | 10% | 15%+ |
| Page Speed (mobile) | <3s | <2s |
| Core Web Vitals (CLS) | <0.1 | <0.05 |

### GA4 Metrics
| Metric | Good | Excellent |
|--------|------|-----------|
| Engagement Rate | 60% | 75%+ |
| Bounce Rate | <60% | <40% |
| Avg. Session Duration | 2 min | 3+ min |
| Pages per Session | 2.5 | 4+ |
| Conversion Rate | 2% | 5%+ |

### Google Ads Metrics
| Metric | Good | Excellent |
|--------|------|-----------|
| CTR (Search) | 2% | 5%+ |
| CTR (Display) | 0.5% | 1%+ |
| Quality Score | 7 | 9+ |
| Conversion Rate | 2% | 5%+ |
| ROAS | 400% | 800%+ |

## When to Load Reference Files

**Load seo-best-practices.md when:**
- Performing comprehensive SEO audits
- Optimizing page meta tags and content
- Implementing schema markup
- Improving technical SEO

**Load seo-checklists.md when:**
- Quick SEO audits needed
- Creating standardized audit reports
- Training teams on SEO basics
- Quality assurance before page publication

**Load ga4-metrics.md when:**
- Analyzing traffic and engagement
- Setting up custom reports
- Explaining metrics to stakeholders
- Comparing performance to benchmarks

**Load ga4-events.md when:**
- Implementing event tracking
- Setting up ecommerce tracking
- Creating custom events
- Debugging tracking issues

**Load google-ads-optimization.md when:**
- Optimizing underperforming campaigns
- Improving Quality Scores
- Refining bidding strategies
- Scaling successful campaigns

**Load google-ads-metrics.md when:**
- Analyzing campaign performance
- Troubleshooting low performance
- Creating performance reports
- Setting campaign benchmarks
