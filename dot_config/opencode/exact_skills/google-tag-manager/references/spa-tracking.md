# SPA Pageview Tracking

## The Problem

SPAs don't trigger traditional page loads. Without proper setup, GTM only tracks the initial page load.

```
Traditional Site: User clicks → Full page load → GTM fires page_view
SPA:              User clicks → JS updates URL → No page load → GTM misses it
```

## Three Solutions

### 1. History Change Trigger (GTM-based)

GTM detects `pushState`/`replaceState` automatically. No code changes needed.

**GTM Setup:**
1. Triggers → New → History Change
2. Name: "History Change - All Pages"
3. Trigger fires on: All History Changes
4. Use this trigger for your GA4 Page View tag

**Pros:** No code changes, works with any framework
**Cons:** May fire on hash changes, requires GTM config

### 2. Custom dataLayer.push (Code-based) - Recommended

Push virtual pageview events from your router.

**React Router v7 / Remix:**

```typescript
// app/hooks/usePageTracking.ts
import { useLocation } from "react-router";
import { useEffect } from "react";
import TagManager from "react-gtm-module";

export function usePageTracking() {
  const location = useLocation();

  useEffect(() => {
    // Skip initial load (GTM handles it)
    if (typeof window === "undefined") return;

    TagManager.dataLayer({
      dataLayer: {
        event: "virtualPageview",
        page: location.pathname + location.search,
        pageTitle: document.title,
      },
    });
  }, [location.pathname, location.search]);
}

// app/root.tsx
export default function App() {
  usePageTracking();
  
  return <Outlet />;
}
```

**GTM Setup:**
1. Trigger → New → Custom Event
2. Event name: `virtualPageview`
3. Use this trigger for GA4 Page View tag

### 3. GA4 Enhanced Measurement

GA4 can track page views automatically via Enhanced Measurement.

**Enable in GA4:**
Admin → Data Streams → Web → Enhanced Measurement → Page views (toggle on)

**Pros:** Zero code, automatic
**Cons:** Less control, may miss some SPA navigations

## Next.js Specific

### App Router

```typescript
// app/components/PageTracker.tsx
"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { useEffect } from "react";
import { sendGTMEvent } from "@next/third-parties/google";

export function PageTracker() {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  useEffect(() => {
    const url = pathname + (searchParams?.toString() ? `?${searchParams}` : "");
    
    sendGTMEvent({
      event: "virtualPageview",
      page: url,
    });
  }, [pathname, searchParams]);

  return null;
}

// app/layout.tsx
import { GoogleTagManager } from "@next/third-parties/google";
import { PageTracker } from "./components/PageTracker";

export default function RootLayout({ children }) {
  return (
    <html>
      <GoogleTagManager gtmId="GTM-XXXXXXX" />
      <body>
        <PageTracker />
        {children}
      </body>
    </html>
  );
}
```

### Pages Router

```typescript
// pages/_app.tsx
import { useRouter } from "next/router";
import { useEffect } from "react";
import TagManager from "react-gtm-module";

export default function App({ Component, pageProps }) {
  const router = useRouter();

  useEffect(() => {
    TagManager.initialize({ gtmId: process.env.NEXT_PUBLIC_GTM_ID! });
  }, []);

  useEffect(() => {
    const handleRouteChange = (url: string) => {
      TagManager.dataLayer({
        dataLayer: {
          event: "virtualPageview",
          page: url,
        },
      });
    };

    router.events.on("routeChangeComplete", handleRouteChange);
    return () => router.events.off("routeChangeComplete", handleRouteChange);
  }, [router.events]);

  return <Component {...pageProps} />;
}
```

## SSR Hydration Issues

### Problem: Double Tracking

Initial SSR render + client hydration can fire pageview twice.

```typescript
// ❌ Fires on SSR and hydration
useEffect(() => {
  trackPageView(); // Runs twice!
});

// ✅ Track only on route changes, not initial load
const location = useLocation();
const isInitialMount = useRef(true);

useEffect(() => {
  if (isInitialMount.current) {
    isInitialMount.current = false;
    return; // Skip initial mount
  }
  
  trackPageView(location.pathname);
}, [location.pathname]);
```

### Better Pattern: Let GTM Handle Initial Load

```typescript
// Let GTM's Page View trigger handle initial load
// Only push virtualPageview on subsequent navigations

export function usePageTracking() {
  const location = useLocation();
  const previousPath = useRef(location.pathname);

  useEffect(() => {
    // Only track if path actually changed
    if (previousPath.current !== location.pathname) {
      previousPath.current = location.pathname;
      
      TagManager.dataLayer({
        dataLayer: {
          event: "virtualPageview",
          page: location.pathname,
        },
      });
    }
  }, [location.pathname]);
}
```

## GTM Configuration for SPA

### Create Variables

**Data Layer Variable - Page Path:**
- Variable Type: Data Layer Variable
- Data Layer Variable Name: `page`
- Default Value: `{{Page Path}}`

### Create Trigger

**Custom Event - Virtual Pageview:**
- Trigger Type: Custom Event
- Event Name: `virtualPageview`
- This trigger fires on: All Custom Events

### Create GA4 Tag

**GA4 Event - Page View:**
- Tag Type: Google Analytics: GA4 Event
- Event Name: `page_view`
- Trigger: Virtual Pageview (custom event)
- Parameters:
  - `page_location`: `{{Page URL}}`
  - `page_title`: `{{Page Title}}`

## Debugging SPA Tracking

```typescript
// Add logging in development
export function trackPageView(page: string) {
  if (process.env.NODE_ENV === "development") {
    console.log("[GTM] Virtual pageview:", page);
  }
  
  TagManager.dataLayer({
    dataLayer: {
      event: "virtualPageview",
      page,
    },
  });
}
```

**GTM Preview Mode:**
1. Open GTM → Preview
2. Navigate your SPA
3. Each route change should show `virtualPageview` event
4. Check that your GA4 tag fires on each event

## Common Issues

### Missing pageviews

1. Check if `virtualPageview` event appears in GTM Preview
2. Verify trigger is set to Custom Event, not Page View
3. Ensure event name matches exactly (case-sensitive)

### Duplicate pageviews

1. Check for multiple tracking implementations
2. Disable GA4 Enhanced Measurement if using custom tracking
3. Verify useEffect dependencies are correct

### Wrong page URL

```typescript
// ✅ Include search params
const page = location.pathname + location.search;

// ❌ Missing search params
const page = location.pathname; // Loses ?query=value
```
