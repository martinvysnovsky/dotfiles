---
name: google-tag-manager
description: Google Tag Manager integration for React, Remix, React Router v7, and Next.js applications. Use when (1) setting up GTM in React/SSR apps, (2) implementing pageview tracking in SPAs, (3) sending custom events to GA4/GTM, (4) tracking ecommerce funnels, (5) handling dataLayer in SSR/hydration, (6) choosing GTM libraries for different frameworks.
---

# Google Tag Manager

## Quick Reference

**Setup & Libraries:**
- **[setup.md](references/setup.md)** - Installation, initialization, environment config, SSR considerations
- **[libraries.md](references/libraries.md)** - Library comparison: react-gtm-module, @next/third-parties, manual implementation

**Tracking:**
- **[spa-tracking.md](references/spa-tracking.md)** - SPA pageview tracking, History Change trigger, virtual pageviews, SSR hydration
- **[events.md](references/events.md)** - Custom events, GA4 recommended events, dataLayer patterns, TypeScript types
- **[ecommerce.md](references/ecommerce.md)** - Full ecommerce funnel: view_item → add_to_cart → purchase

## Critical: SPA Pageview Tracking

For SPAs (Remix, React Router, Next.js), **GTM's "All Pages" trigger only fires on full page loads**. You MUST configure a **History Change trigger** in GTM for client-side navigations.

**No custom code needed** - GTM's built-in History Change listener handles SPA tracking automatically. See [spa-tracking.md](references/spa-tracking.md) for configuration steps.

## Core Pattern (react-gtm-module)

```typescript
// utils/gtm.ts
import TagManager from "react-gtm-module";

export function initializeGTM() {
  const gtmId = import.meta.env.VITE_GTM_ID; // or process.env.NEXT_PUBLIC_GTM_ID

  if (gtmId && typeof window !== "undefined") {
    TagManager.initialize({ gtmId, dataLayerName: "dataLayer" });
  }
}

// For custom events only - NOT for pageviews (use GTM History Change trigger instead)
export function trackEvent(event: string, data?: Record<string, unknown>) {
  TagManager.dataLayer({ dataLayer: { event, ...data } });
}
```

```typescript
// root.tsx or _app.tsx - Initialize only, no pageview tracking code needed
import { useEffect } from "react";
import { initializeGTM } from "~/utils/gtm";

export default function App() {
  useEffect(() => {
    initializeGTM();
  }, []);

  return <Outlet />;
}
```

## SSR Safety Check

Always guard GTM calls for SSR environments:

```typescript
// ✅ Good - SSR safe
if (typeof window !== "undefined" && gtmId) {
  TagManager.initialize({ gtmId });
}

// ❌ Bad - Will crash on server
TagManager.initialize({ gtmId }); // ReferenceError: window is not defined
```

## DataLayer Event Pattern

```typescript
// Generic event
TagManager.dataLayer({
  dataLayer: {
    event: "button_click",
    button_name: "signup",
    page_location: window.location.href,
  },
});

// GA4 recommended event
TagManager.dataLayer({
  dataLayer: {
    event: "purchase",
    ecommerce: {
      transaction_id: "T12345",
      value: 99.99,
      currency: "EUR",
      items: [{ item_id: "SKU123", item_name: "Product", price: 99.99 }],
    },
  },
});
```

## Library Quick Selection

| Framework | Recommended Library | Why |
|-----------|-------------------|-----|
| **Next.js** | `@next/third-parties` | Official, optimized, SSR-native |
| **Remix** | Manual or `react-gtm-module` | Full SSR control |
| **React Router v7** | `react-gtm-module` | Simple, well-supported |
| **Vite + React** | `react-gtm-module` | Works out of the box |
| **Performance critical** | `@builder.io/partytown` | Moves GTM to web worker |

## When to Load Reference Files

**Load setup.md when:**
- Setting up GTM for the first time
- Configuring environment variables
- Understanding container/account structure
- Handling multiple environments (dev/staging/prod)

**Load libraries.md when:**
- Choosing a GTM library for your framework
- Migrating between libraries
- Comparing @next/third-parties vs react-gtm-module
- Setting up Partytown for performance

**Load spa-tracking.md when:**
- Implementing pageview tracking in SPAs
- Debugging missing pageviews
- Setting up History Change trigger in GTM
- Handling SSR hydration and double-tracking issues

**Load events.md when:**
- Implementing custom event tracking
- Using GA4 recommended events
- Setting up TypeScript types for dataLayer
- Creating reusable tracking utilities

**Load ecommerce.md when:**
- Implementing product impressions/clicks
- Tracking add to cart, checkout, purchase
- Setting up GA4 ecommerce events
- Debugging ecommerce tracking issues
