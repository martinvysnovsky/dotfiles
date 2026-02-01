# GA4 Event Tracking

## Event Structure

Every GA4 event consists of:
- **Event name** (e.g., `purchase`, `sign_up`)
- **Event parameters** (additional context like `value`, `currency`, `item_id`)

```javascript
// Basic event structure
dataLayer.push({
  event: 'event_name',
  parameter_1: 'value',
  parameter_2: 123
});
```

---

## Automatically Collected Events

GA4 collects these events automatically (no configuration needed):

| Event | Trigger | Parameters |
|-------|---------|------------|
| `first_visit` | User's first visit to site | - |
| `session_start` | New session begins | - |
| `page_view` | Page loads | `page_location`, `page_title` |
| `user_engagement` | Page in focus for 1+ second | `engagement_time_msec` |

**No action required** - These work out of the box.

---

## Enhanced Measurement Events

Enable in GA4 Admin → Data Streams → Configure → Enhanced Measurement

| Event | Trigger | Auto-tracked? | Parameters |
|-------|---------|---------------|------------|
| `scroll` | User scrolls 90% of page | ✅ Yes | `percent_scrolled` |
| `click` | Outbound link click | ✅ Yes | `link_url`, `link_domain` |
| `view_search_results` | Site search performed | ✅ Yes (if configured) | `search_term` |
| `video_start` | Embedded video starts | ✅ Yes (YouTube, Vimeo) | `video_url`, `video_title` |
| `video_progress` | 10%, 25%, 50%, 75% milestones | ✅ Yes | `video_percent` |
| `video_complete` | Video finishes | ✅ Yes | `video_url` |
| `file_download` | .pdf, .xlsx, .docx, etc. | ✅ Yes | `file_name`, `file_extension` |
| `form_start` | User interacts with form | ❌ Optional | `form_id` |
| `form_submit` | Form submitted | ❌ Optional | `form_id` |

**Configuration:** Toggle switches in Enhanced Measurement settings.

---

## Recommended Events

Google-defined events with standardized parameters. Use these instead of custom events when possible.

### General Recommended Events

#### Sign Up
```javascript
dataLayer.push({
  event: 'sign_up',
  method: 'email' // or 'google', 'facebook', etc.
});
```

#### Login
```javascript
dataLayer.push({
  event: 'login',
  method: 'email' // authentication method
});
```

#### Search
```javascript
dataLayer.push({
  event: 'search',
  search_term: 'running shoes'
});
```

#### Share
```javascript
dataLayer.push({
  event: 'share',
  method: 'twitter', // 'facebook', 'email', etc.
  content_type: 'article',
  item_id: 'blog-post-123'
});
```

#### Select Content
```javascript
dataLayer.push({
  event: 'select_content',
  content_type: 'product',
  item_id: 'SKU12345'
});
```

---

### Ecommerce Recommended Events

**Critical for ecommerce tracking.** These events create complete purchase funnel in GA4.

#### 1. View Item List (Product Listing Page)
```javascript
dataLayer.push({
  event: 'view_item_list',
  ecommerce: {
    item_list_id: 'related_products',
    item_list_name: 'Related Products',
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        item_category: 'Footwear',
        item_category2: 'Athletic',
        price: 99.99,
        index: 0 // position in list
      },
      {
        item_id: 'SKU456',
        item_name: 'Hiking Boots',
        item_category: 'Footwear',
        price: 149.99,
        index: 1
      }
    ]
  }
});
```

#### 2. Select Item (Product Click)
```javascript
dataLayer.push({
  event: 'select_item',
  ecommerce: {
    item_list_id: 'search_results',
    item_list_name: 'Search Results',
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        item_category: 'Footwear',
        price: 99.99,
        index: 0
      }
    ]
  }
});
```

#### 3. View Item (Product Detail Page)
```javascript
dataLayer.push({
  event: 'view_item',
  ecommerce: {
    currency: 'EUR',
    value: 99.99,
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        item_category: 'Footwear',
        item_variant: 'Red',
        item_brand: 'Nike',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

#### 4. Add to Wishlist
```javascript
dataLayer.push({
  event: 'add_to_wishlist',
  ecommerce: {
    currency: 'EUR',
    value: 99.99,
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

#### 5. Add to Cart
```javascript
dataLayer.push({
  event: 'add_to_cart',
  ecommerce: {
    currency: 'EUR',
    value: 99.99,
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        item_category: 'Footwear',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

#### 6. Remove from Cart
```javascript
dataLayer.push({
  event: 'remove_from_cart',
  ecommerce: {
    currency: 'EUR',
    value: 99.99,
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

#### 7. View Cart
```javascript
dataLayer.push({
  event: 'view_cart',
  ecommerce: {
    currency: 'EUR',
    value: 149.98,
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        price: 99.99,
        quantity: 1
      },
      {
        item_id: 'SKU456',
        item_name: 'Socks',
        price: 49.99,
        quantity: 1
      }
    ]
  }
});
```

#### 8. Begin Checkout
```javascript
dataLayer.push({
  event: 'begin_checkout',
  ecommerce: {
    currency: 'EUR',
    value: 149.98,
    coupon: 'SUMMER10', // if coupon applied
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

#### 9. Add Shipping Info
```javascript
dataLayer.push({
  event: 'add_shipping_info',
  ecommerce: {
    currency: 'EUR',
    value: 149.98,
    shipping_tier: 'Express', // Ground, Express, Overnight
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

#### 10. Add Payment Info
```javascript
dataLayer.push({
  event: 'add_payment_info',
  ecommerce: {
    currency: 'EUR',
    value: 149.98,
    payment_type: 'credit_card', // 'paypal', 'apple_pay', etc.
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

#### 11. Purchase (Most Important!)
```javascript
dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'T12345', // Unique order ID
    value: 154.98, // Total revenue (including tax, shipping)
    tax: 9.00,
    shipping: 5.00,
    currency: 'EUR',
    coupon: 'SUMMER10',
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        item_category: 'Footwear',
        item_variant: 'Red',
        item_brand: 'Nike',
        price: 99.99,
        quantity: 1
      },
      {
        item_id: 'SKU789',
        item_name: 'Running Socks',
        item_category: 'Accessories',
        price: 14.99,
        quantity: 2
      }
    ]
  }
});
```

**Critical parameters:**
- `transaction_id`: Must be unique (prevents duplicate purchases)
- `value`: Total transaction value (GA4 uses this for revenue)
- `currency`: ISO 4217 code (EUR, USD, GBP)
- `items`: Array of purchased products

#### 12. Refund
```javascript
dataLayer.push({
  event: 'refund',
  ecommerce: {
    transaction_id: 'T12345', // Match original purchase
    value: 154.98,
    currency: 'EUR',
    items: [
      {
        item_id: 'SKU123',
        item_name: 'Running Shoes',
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

---

## Custom Events

When recommended events don't fit your needs, create custom events.

### Naming Conventions

**Best practices:**
- **Lowercase:** `button_click` not `Button_Click`
- **Underscores:** `video_complete` not `videoComplete` or `video-complete`
- **Descriptive:** `cta_signup_clicked` not `click`
- **Consistent:** Use same naming pattern across all events

**Examples:**
```javascript
// ✅ Good
dataLayer.push({
  event: 'newsletter_signup',
  location: 'footer'
});

// ❌ Bad
dataLayer.push({
  event: 'NewsLetterSignUp', // should be lowercase
  loc: 'footer' // should be descriptive
});
```

### Common Custom Events

#### CTA Click
```javascript
dataLayer.push({
  event: 'cta_click',
  cta_text: 'Get Started',
  cta_location: 'hero_section'
});
```

#### Video Interaction (Custom)
```javascript
dataLayer.push({
  event: 'video_interaction',
  video_title: 'Product Demo',
  action: 'play', // 'pause', 'complete'
  video_duration: 120 // seconds
});
```

#### Calculator Used
```javascript
dataLayer.push({
  event: 'calculator_used',
  calculator_type: 'pricing',
  result_value: 49.99
});
```

#### Tab Interaction
```javascript
dataLayer.push({
  event: 'tab_click',
  tab_name: 'Features',
  section: 'product_overview'
});
```

#### Filter Applied
```javascript
dataLayer.push({
  event: 'filter_applied',
  filter_type: 'price_range',
  filter_value: '50-100'
});
```

#### PDF Download
```javascript
// If not auto-tracked by enhanced measurement
dataLayer.push({
  event: 'file_download',
  file_name: 'whitepaper.pdf',
  file_type: 'whitepaper'
});
```

---

## Event Parameters

### Standard Parameters

Google-defined parameters (use these when applicable):

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `currency` | string | ISO 4217 currency code | `'EUR'` |
| `value` | number | Monetary value | `99.99` |
| `transaction_id` | string | Unique transaction ID | `'T12345'` |
| `search_term` | string | Search query | `'running shoes'` |
| `method` | string | Method used | `'email'`, `'google'` |
| `content_type` | string | Type of content | `'product'`, `'article'` |
| `item_id` | string | Product/item ID | `'SKU123'` |

### Item Parameters

Used within `items` array in ecommerce events:

| Parameter | Required? | Description |
|-----------|-----------|-------------|
| `item_id` | ✅ Yes | Product SKU or ID |
| `item_name` | ✅ Yes | Product name |
| `item_category` | No | Primary category |
| `item_category2` | No | Secondary category |
| `item_category3` | No | Tertiary category |
| `item_variant` | No | Product variant (color, size) |
| `item_brand` | No | Product brand |
| `price` | No | Product price |
| `quantity` | No | Quantity (default: 1) |
| `index` | No | Position in list |

### Custom Parameters

You can add up to 25 custom parameters per event:

```javascript
dataLayer.push({
  event: 'product_review_submitted',
  item_id: 'SKU123',
  rating: 5, // custom parameter
  review_length: 'long', // custom parameter
  verified_purchase: true // custom parameter
});
```

**Register custom parameters:**
GA4 Admin → Custom Definitions → Create Custom Dimension/Metric

---

## User Properties

Set persistent user attributes (not event-specific):

```javascript
dataLayer.push({
  user_properties: {
    user_type: 'premium', // 'free', 'trial', 'premium'
    membership_level: 'gold',
    account_age_days: 365
  }
});
```

**Use cases:**
- User segmentation (free vs. paid)
- Personalization tracking
- Lifetime cohort analysis

**Limit:** 25 custom user properties per GA4 property

---

## Debugging Events

### GA4 DebugView

1. Install Google Analytics Debugger extension (Chrome)
2. GA4 → Admin → DebugView
3. Navigate your site
4. See events in real-time with full parameter details

### dataLayer Inspection

```javascript
// In browser console, check what's in dataLayer
console.table(window.dataLayer);

// Watch for new dataLayer pushes
window.dataLayer.push = function() {
  console.log('New dataLayer event:', arguments);
  Array.prototype.push.apply(window.dataLayer, arguments);
};
```

### Google Tag Assistant

Chrome extension that validates GTM/GA4 implementation:
- Shows which tags fire
- Displays event parameters
- Identifies configuration errors

---

## Event Tracking Best Practices

### 1. Event Naming
- **Descriptive:** `newsletter_signup` not `click`
- **Consistent:** Use same naming convention across site
- **Lowercase with underscores:** `button_click` not `ButtonClick`
- **Action-oriented:** `form_submitted` not `form`

### 2. Parameter Usage
- **Use standard parameters first:** Before creating custom ones
- **Descriptive names:** `cta_location` not `loc`
- **Consistent types:** Always string, always number
- **Avoid PII:** Don't send emails, names, addresses

### 3. Event Volume
- **Don't over-track:** 25-50 unique event types is plenty for most sites
- **Focus on value:** Track events that drive business decisions
- **Consolidate similar events:** Use parameters to differentiate

**Example:**
```javascript
// ❌ Bad: Too many similar events
dataLayer.push({ event: 'hero_cta_click' });
dataLayer.push({ event: 'sidebar_cta_click' });
dataLayer.push({ event: 'footer_cta_click' });

// ✅ Good: One event with parameter
dataLayer.push({
  event: 'cta_click',
  location: 'hero' // 'sidebar', 'footer'
});
```

### 4. Ecommerce Accuracy
- **Track full funnel:** view_item → add_to_cart → purchase
- **Unique transaction IDs:** Never reuse transaction_id
- **Accurate values:** Include tax, shipping in purchase value
- **Currency consistency:** Always specify currency parameter

### 5. Test Before Launch
- **Use DebugView:** Verify events fire correctly
- **Check parameters:** Ensure all data is captured
- **Test edge cases:** Empty cart, failed purchase, etc.
- **Multiple devices:** Test mobile, tablet, desktop

---

## Common Implementation Patterns

### React/Next.js
```javascript
// utils/analytics.ts
export function trackEvent(eventName: string, params?: Record<string, any>) {
  if (typeof window !== 'undefined' && window.dataLayer) {
    window.dataLayer.push({
      event: eventName,
      ...params
    });
  }
}

// Component usage
import { trackEvent } from '@/utils/analytics';

export function ProductCard({ product }) {
  const handleAddToCart = () => {
    trackEvent('add_to_cart', {
      ecommerce: {
        currency: 'EUR',
        value: product.price,
        items: [
          {
            item_id: product.id,
            item_name: product.name,
            price: product.price,
            quantity: 1
          }
        ]
      }
    });
    
    // Then add to cart logic
  };
  
  return <button onClick={handleAddToCart}>Add to Cart</button>;
}
```

### TypeScript Types
```typescript
// types/analytics.ts
export interface GA4Event {
  event: string;
  [key: string]: any;
}

export interface EcommerceItem {
  item_id: string;
  item_name: string;
  item_category?: string;
  item_variant?: string;
  item_brand?: string;
  price: number;
  quantity?: number;
  index?: number;
}

export interface EcommerceData {
  currency: string;
  value: number;
  items: EcommerceItem[];
  transaction_id?: string;
  tax?: number;
  shipping?: number;
  coupon?: string;
}

export interface PurchaseEvent extends GA4Event {
  event: 'purchase';
  ecommerce: EcommerceData & {
    transaction_id: string;
  };
}

// Usage with type safety
function trackPurchase(data: PurchaseEvent) {
  window.dataLayer.push(data);
}
```

---

## Migration from Universal Analytics

| UA Event | GA4 Equivalent |
|----------|----------------|
| `event: 'event'`, `eventCategory`, `eventAction`, `eventLabel` | Just use `event: 'event_name'` with parameters |
| `pageview` | `page_view` (automatic) |
| Enhanced Ecommerce `detail` | `view_item` |
| Enhanced Ecommerce `add` | `add_to_cart` |
| Enhanced Ecommerce `purchase` | `purchase` |

**Key difference:** UA used category/action/label. GA4 uses event name + parameters (simpler, more flexible).
