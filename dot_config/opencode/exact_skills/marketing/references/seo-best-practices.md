# SEO Best Practices

## On-Page SEO

### Title Tags

**Purpose:** Most important on-page SEO element. Appears in search results and browser tabs.

**Best Practices:**
- **Length:** 50-60 characters (512 pixels max)
- **Format:** `[Primary Keyword] - [Modifier] | [Brand]`
- **Keyword placement:** Front-load important keywords
- **Uniqueness:** Every page must have unique title
- **Compelling:** Write for clicks, not just keywords

**Examples:**
```html
<!-- ✅ Good -->
<title>SEO Services for SaaS Companies - Increase Traffic 150% | YourBrand</title>

<!-- ❌ Bad: Too long, keyword stuffing -->
<title>SEO Services, SEO Company, Best SEO Agency for SaaS Companies and Startups - Your Brand Name</title>

<!-- ❌ Bad: Too generic, no keywords -->
<title>Home - Welcome to Our Website</title>
```

**Title Tag Formula by Page Type:**

- **Homepage:** `[Brand] - [What You Do] | [Key Benefit]`
- **Product:** `[Product Name] - [Category] | [Brand]`
- **Blog Post:** `[Post Title] - [Year] Guide | [Brand]`
- **Category:** `[Category] + [Product Type] | [Brand]`
- **Local:** `[Service] in [City] | [Brand]`

### Meta Descriptions

**Purpose:** Influences click-through rate from search results (not a direct ranking factor).

**Best Practices:**
- **Length:** 150-160 characters (920 pixels max)
- **Format:** `[Value Proposition] + [Benefit] + [Call to Action]`
- **Keywords:** Include target keyword naturally
- **Compelling:** Create urgency or curiosity
- **Unique:** Every page needs unique description

**Examples:**
```html
<!-- ✅ Good -->
<meta name="description" content="Boost organic traffic by 150% with our proven SEO strategies for SaaS. Used by 500+ companies. Get a free audit and personalized roadmap today.">

<!-- ❌ Bad: Too short, no CTA -->
<meta name="description" content="We provide SEO services.">

<!-- ❌ Bad: Keyword stuffing, unnatural -->
<meta name="description" content="SEO, SEO services, best SEO, SEO company, SEO expert, SEO agency.">
```

**Meta Description Formula:**
1. **Hook** (first 20 chars): Grab attention
2. **Benefit** (next 60 chars): What user gets
3. **Proof** (next 40 chars): Social proof/stats
4. **CTA** (last 40 chars): Clear action

### Heading Structure (H1-H6)

**Purpose:** Organize content hierarchy for users and search engines.

**Best Practices:**
- **H1:** One per page, contains primary keyword, describes page topic
- **H2:** Major sections, use related keywords and variations
- **H3-H6:** Subsections, natural language
- **Hierarchy:** Never skip levels (no H1 → H3)
- **Logical:** Structure follows content flow

**Example Structure:**
```html
<h1>Complete Guide to SEO for SaaS Companies (2024)</h1>

<h2>Why SEO Matters for SaaS</h2>
  <h3>Lower Customer Acquisition Cost</h3>
  <h3>Compounding Returns Over Time</h3>

<h2>Technical SEO Fundamentals</h2>
  <h3>Site Speed Optimization</h3>
    <h4>Image Optimization</h4>
    <h4>Code Minification</h4>
  <h3>Mobile Responsiveness</h3>

<h2>On-Page SEO Strategies</h2>
  <h3>Keyword Research</h3>
  <h3>Content Optimization</h3>
```

### Content Optimization

**Keyword Usage:**
- **Primary keyword:** In H1, first 100 words, at least one H2
- **Keyword density:** 1-2% (natural, not stuffed)
- **LSI keywords:** Use related terms and synonyms
- **Long-tail variations:** Include question-based keywords

**Content Length Guidelines:**
- **Informational blog:** 1,500-2,500 words
- **Comprehensive guide:** 3,000-5,000+ words
- **Product pages:** 500-1,000 words (focus on unique content)
- **Category pages:** 300-500 words (above products)

**Readability:**
- **Sentences:** Average 15-20 words
- **Paragraphs:** 2-4 sentences max
- **Subheadings:** Every 300-400 words
- **Lists:** Use bullets and numbered lists
- **Formatting:** Bold, italics for emphasis
- **Reading level:** 8th-10th grade (Flesch-Kincaid)

### Internal Linking

**Purpose:** Helps search engines discover content, distributes page authority, keeps users engaged.

**Best Practices:**
- **Quantity:** 3-5 relevant internal links per page
- **Anchor text:** Descriptive, keyword-rich (not "click here")
- **Relevance:** Link to related, helpful content
- **Strategic:** Link from high-authority pages to important pages
- **Orphan pages:** Ensure every page has inbound links

**Link Types:**
- **Contextual links:** Within content body (most powerful)
- **Navigation links:** Header/footer menus
- **Breadcrumbs:** Hierarchical navigation
- **Related posts:** Sidebar or footer modules

**Example:**
```html
<!-- ✅ Good: Descriptive anchor text -->
<p>Learn more about <a href="/keyword-research">how to do keyword research for SaaS</a> before creating content.</p>

<!-- ❌ Bad: Generic anchor text -->
<p>To learn more, <a href="/keyword-research">click here</a>.</p>
```

### Image Optimization

**Alt Text:**
```html
<!-- ✅ Good: Descriptive, includes context -->
<img src="seo-strategy-flowchart.jpg" alt="SEO strategy flowchart showing keyword research, on-page optimization, and link building steps">

<!-- ❌ Bad: Keyword stuffing -->
<img src="image.jpg" alt="SEO services SEO company best SEO">

<!-- ❌ Bad: Too generic -->
<img src="image.jpg" alt="Image">
```

**Image Technical SEO:**
- **Format:** WebP for photos, SVG for graphics/logos
- **Size:** Compress images (target: <200KB)
- **Dimensions:** Serve responsive sizes with `srcset`
- **Lazy loading:** `loading="lazy"` for below-fold images
- **File names:** Descriptive, hyphen-separated (`keyword-description.jpg`)

### URL Structure

**Best Practices:**
- **Short:** 3-5 words ideal
- **Descriptive:** Indicates page content
- **Hyphens:** Use hyphens, not underscores
- **Lowercase:** All lowercase letters
- **Keywords:** Include target keyword
- **No parameters:** Avoid `?id=123` when possible

**Examples:**
```
✅ Good: https://example.com/seo-services-saas
✅ Good: https://example.com/blog/keyword-research-guide
✅ Good: https://example.com/products/email-marketing-tool

❌ Bad: https://example.com/page?id=12345&cat=seo
❌ Bad: https://example.com/SEO_Services_For_SaaS_Companies
❌ Bad: https://example.com/services/category1/subcategory2/item
```

## Technical SEO

### Page Speed Optimization

**Core Web Vitals (Google ranking signals):**

1. **LCP (Largest Contentful Paint)** - Loading performance
   - **Good:** <2.5 seconds
   - **Needs Improvement:** 2.5-4 seconds
   - **Poor:** >4 seconds

2. **FID (First Input Delay)** - Interactivity
   - **Good:** <100ms
   - **Needs Improvement:** 100-300ms
   - **Poor:** >300ms

3. **CLS (Cumulative Layout Shift)** - Visual stability
   - **Good:** <0.1
   - **Needs Improvement:** 0.1-0.25
   - **Poor:** >0.25

**Optimization Techniques:**
- **Image optimization:** Compress, use WebP, lazy load
- **Minification:** Minify CSS, JS, HTML
- **Caching:** Browser caching, CDN
- **Critical CSS:** Inline critical CSS, defer non-critical
- **JavaScript:** Defer/async non-critical JS
- **Server:** Use HTTP/2, upgrade hosting
- **Fonts:** Preload fonts, use font-display: swap

### Mobile-Friendliness

**Requirements:**
- **Responsive design:** Adapts to all screen sizes
- **Touch targets:** Minimum 48x48 pixels
- **Text size:** Minimum 16px (no zooming needed)
- **Viewport:** `<meta name="viewport" content="width=device-width, initial-scale=1">`
- **No Flash:** Use HTML5 instead
- **Tap targets:** Adequate spacing (8px minimum)

**Test Tools:**
- Google Mobile-Friendly Test
- Lighthouse mobile audit
- Real device testing

### HTTPS / SSL

**Requirements:**
- **SSL certificate:** Valid, not expired
- **Mixed content:** No HTTP resources on HTTPS pages
- **Redirects:** 301 redirect HTTP → HTTPS
- **HSTS:** HTTP Strict Transport Security header
- **Canonical:** Use HTTPS in canonical tags

### XML Sitemap

**Best Practices:**
- **Location:** `https://example.com/sitemap.xml`
- **Submit:** To Google Search Console and Bing Webmaster Tools
- **Size:** Max 50MB or 50,000 URLs per sitemap
- **Split:** Use sitemap index for large sites
- **Include:** Only indexable, canonical pages
- **Exclude:** Noindex pages, duplicates, redirects
- **Update:** Automatically when content changes
- **Priority:** Not critical (Google ignores it mostly)
- **Change frequency:** Not critical (Google ignores it)

**Example:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-15</lastmod>
  </url>
  <url>
    <loc>https://example.com/seo-services</loc>
    <lastmod>2024-01-14</lastmod>
  </url>
</urlset>
```

### Robots.txt

**Best Practices:**
- **Location:** `https://example.com/robots.txt`
- **Allow by default:** Don't block important pages
- **Block strategically:** Admin areas, search results, private sections
- **Sitemap:** Include sitemap location
- **Test:** Use robots.txt tester in Search Console

**Example:**
```
User-agent: *
Disallow: /admin/
Disallow: /search?
Disallow: /cart/
Allow: /

Sitemap: https://example.com/sitemap.xml
```

### Canonical Tags

**Purpose:** Prevents duplicate content issues by specifying preferred URL.

**When to Use:**
- Multiple URLs for same content (sorting, filtering)
- HTTP and HTTPS versions
- www and non-www versions
- Syndicated content
- Paginated series

**Example:**
```html
<!-- On: https://example.com/products?sort=price -->
<link rel="canonical" href="https://example.com/products">

<!-- Self-referencing canonical (best practice for all pages) -->
<link rel="canonical" href="https://example.com/seo-services">
```

## Schema Markup (Structured Data)

### Why Use Schema?

- **Rich results:** Featured snippets, rich cards
- **Better CTR:** Enhanced search listings
- **Voice search:** Better understanding for assistants
- **Knowledge graph:** Appear in knowledge panels

### Priority Schema Types

#### 1. Product Schema
```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Email Marketing Software",
  "image": "https://example.com/product.jpg",
  "description": "All-in-one email marketing platform",
  "brand": {
    "@type": "Brand",
    "name": "YourBrand"
  },
  "offers": {
    "@type": "Offer",
    "price": "49.00",
    "priceCurrency": "EUR",
    "availability": "https://schema.org/InStock",
    "url": "https://example.com/products/email-marketing"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.7",
    "reviewCount": "342"
  }
}
```

#### 2. Article Schema (Blog Posts)
```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Complete Guide to SEO for SaaS",
  "image": "https://example.com/blog-image.jpg",
  "author": {
    "@type": "Person",
    "name": "John Smith"
  },
  "publisher": {
    "@type": "Organization",
    "name": "YourBrand",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  },
  "datePublished": "2024-01-15",
  "dateModified": "2024-01-20"
}
```

#### 3. FAQ Schema
```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is SEO?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "SEO (Search Engine Optimization) is the practice of improving your website to increase visibility in search engine results."
      }
    },
    {
      "@type": "Question",
      "name": "How long does SEO take?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "SEO typically takes 3-6 months to see significant results, though some improvements may be visible sooner."
      }
    }
  ]
}
```

#### 4. Breadcrumb Schema
```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://example.com"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Services",
      "item": "https://example.com/services"
    },
    {
      "@type": "ListItem",
      "position": 3,
      "name": "SEO",
      "item": "https://example.com/services/seo"
    }
  ]
}
```

#### 5. Organization Schema (Homepage)
```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "YourBrand",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": [
    "https://twitter.com/yourbrand",
    "https://linkedin.com/company/yourbrand"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+1-555-1234",
    "contactType": "Customer Service"
  }
}
```

### Implementation

```html
<!-- JSON-LD (Recommended) -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  ...
}
</script>
```

**Testing:**
- Google Rich Results Test: https://search.google.com/test/rich-results
- Schema.org Validator: https://validator.schema.org/

## Content Strategy

### Keyword Research

**Process:**
1. **Seed keywords:** Brainstorm 5-10 core topics
2. **Keyword tools:** Use Ahrefs, SEMrush, or free tools (Google Keyword Planner, Ubersuggest)
3. **Competition analysis:** Check what competitors rank for
4. **Long-tail keywords:** Find specific, less competitive phrases
5. **Search intent:** Understand what users want (informational, navigational, transactional)

**Keyword Metrics:**
- **Search volume:** Monthly searches (aim for 100+ for new sites)
- **Keyword difficulty:** Competition level (start with KD <30)
- **CPC:** Indicates commercial intent (higher = more valuable)
- **SERP features:** Rich snippets, featured snippets, local pack

**Search Intent Types:**
- **Informational:** "how to", "what is", "guide" → Blog posts
- **Navigational:** "brand name", "login" → Brand pages
- **Commercial:** "best", "review", "compare" → Comparison pages
- **Transactional:** "buy", "pricing", "demo" → Product pages

### Content Gap Analysis

**Process:**
1. Analyze competitor content (top 3-5 competitors)
2. Identify topics they rank for that you don't
3. Prioritize based on relevance and search volume
4. Create better, more comprehensive content

**Tools:**
- Ahrefs Content Gap
- SEMrush Keyword Gap
- Manual SERP analysis

### Content Refresh Strategy

**When to Refresh:**
- Content older than 12 months
- Declining traffic or rankings
- Outdated information or statistics
- Competitors ranking with newer content

**How to Refresh:**
1. Update statistics and data
2. Add new sections for recent developments
3. Improve formatting and readability
4. Add more images, videos, or examples
5. Expand content length (target 20-30% more)
6. Update title and meta description
7. Add/update internal links
8. Change published date (if substantive update)

## Link Building (Off-Page SEO)

### Link Quality Factors

**High-Quality Links:**
- From high-authority domains (DR 50+)
- Topically relevant to your site
- Natural, editorial placement
- Surrounded by relevant content
- DoFollow (passes authority)

**Low-Quality Links (Avoid):**
- From spammy or low-quality sites
- Site-wide links (footer, sidebar)
- Exact-match anchor text (overuse)
- Paid links without rel="sponsored"
- Link farms or PBNs

### Link Building Strategies

1. **Guest posting:** Write for relevant blogs
2. **Broken link building:** Find broken links, suggest your content
3. **Resource page links:** Get listed on "best resources" pages
4. **Digital PR:** Create newsworthy content, get media coverage
5. **Competitor backlink analysis:** Replicate competitor links
6. **Content promotion:** Share great content, earn natural links

### Anchor Text Distribution

**Ideal Mix:**
- **Branded (40%):** "YourBrand", "example.com"
- **Naked URL (20%):** "https://example.com"
- **Generic (15%):** "click here", "learn more"
- **Partial match (15%):** "SEO guide from YourBrand"
- **Exact match (10%):** "SEO services" (use sparingly)

## Local SEO (If Applicable)

### Google Business Profile Optimization

- **Complete profile:** All fields filled
- **Categories:** Choose most relevant primary category
- **Photos:** Add 10+ high-quality photos
- **Posts:** Weekly updates
- **Reviews:** Encourage and respond to all reviews
- **Q&A:** Monitor and answer questions
- **Products/Services:** List all offerings

### Local Citations

- **NAP consistency:** Name, Address, Phone identical everywhere
- **Major directories:** Yelp, Yellow Pages, Facebook, Apple Maps
- **Industry directories:** Relevant to your business
- **Local chambers:** Business associations

### Local Content

- **Location pages:** Separate page for each location
- **Local keywords:** "[service] in [city]"
- **Local events:** Blog about local happenings
- **Local backlinks:** Partner with local businesses
