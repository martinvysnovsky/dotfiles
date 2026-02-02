# GTM Setup & Installation

## SPA Setup Checklist

For SPAs (Remix, React Router, Next.js), complete these steps:

- [ ] Install GTM library or add script manually
- [ ] Initialize GTM in root component
- [ ] **Create GA4 Measurement ID variable** (best practice - see below)
- [ ] **Create History Change trigger in GTM** (critical for SPAs)
- [ ] Add History Change trigger to: Google Tag, Cookie Consent, Conversion Linker
- [ ] Test with GTM Tag Assistant - verify tags fire on navigation

See [spa-tracking.md](spa-tracking.md) for detailed History Change trigger configuration.

## GA4 Measurement ID Variable (Required)

**Why:** Instead of typing your GA4 Measurement ID (G-XXXXXXXXXX) in every tag, create a reusable Constant variable. This reduces errors and makes updates easier.

1. Navigate to **Variables** in the left sidebar
2. Scroll to **User-Defined Variables** → click **New**
3. Name your variable at the top: "GA4 Measurement ID"
4. In the **Variable Configuration** panel, select **Constant**
5. In the **Value** field, enter your Measurement ID (e.g., `G-XXXXXXXXXX`)
6. Click **Save**

**Usage:** In any tag requiring a Measurement ID, use `{{GA4 Measurement ID}}` instead of typing the ID directly.

## GTM Container Structure

```
Google Tag Manager Account
└── Container (GTM-XXXXXXX)
    ├── Tags (what to track: GA4, Facebook Pixel, etc.)
    ├── Triggers (when to fire: page view, clicks, custom events, History Change)
    └── Variables (data to use: dataLayer values, URL, etc.)
```

## Environment Variables

```bash
# .env.local (Next.js)
NEXT_PUBLIC_GTM_ID=GTM-XXXXXXX

# .env (Vite/Remix/React Router)
VITE_GTM_ID=GTM-XXXXXXX

# Production only pattern
VITE_GTM_ID=GTM-K4XGP5F3  # Only in .env.production
```

## Installation by Framework

### React Router v7 / Remix (react-gtm-module)

```bash
npm install react-gtm-module
npm install -D @types/react-gtm-module
```

```typescript
// app/utils/gtm.ts
import TagManager from "react-gtm-module";

export function initializeGTM() {
  const gtmId = import.meta.env.VITE_GTM_ID;

  if (gtmId && typeof window !== "undefined") {
    TagManager.initialize({
      gtmId,
      dataLayerName: "dataLayer",
    });
  }
}

export function trackEvent(
  eventName: string,
  parameters?: Record<string, unknown>,
) {
  if (typeof window === "undefined") return;
  
  TagManager.dataLayer({
    dataLayer: {
      event: eventName,
      ...parameters,
    },
  });
}
```

```typescript
// app/root.tsx
import { useEffect } from "react";
import { Outlet } from "react-router";
import { initializeGTM } from "~/utils/gtm";

export default function App() {
  useEffect(() => {
    initializeGTM();
  }, []);

  return (
    <html>
      <head>{/* ... */}</head>
      <body>
        <Outlet />
        {/* NoScript fallback */}
        <noscript>
          <iframe
            src={`https://www.googletagmanager.com/ns.html?id=${import.meta.env.VITE_GTM_ID}`}
            height="0"
            width="0"
            style={{ display: "none", visibility: "hidden" }}
          />
        </noscript>
      </body>
    </html>
  );
}
```

### Next.js (App Router with @next/third-parties)

```bash
npm install @next/third-parties
```

```typescript
// app/layout.tsx
import { GoogleTagManager } from "@next/third-parties/google";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <GoogleTagManager gtmId="GTM-XXXXXXX" />
      <body>{children}</body>
    </html>
  );
}
```

```typescript
// Client component for events
"use client";
import { sendGTMEvent } from "@next/third-parties/google";

export function TrackButton() {
  return (
    <button onClick={() => sendGTMEvent({ event: "button_click", value: "xyz" })}>
      Track Me
    </button>
  );
}
```

### Next.js (Pages Router with react-gtm-module)

```typescript
// pages/_app.tsx
import { useEffect } from "react";
import TagManager from "react-gtm-module";

export default function App({ Component, pageProps }) {
  useEffect(() => {
    TagManager.initialize({ gtmId: process.env.NEXT_PUBLIC_GTM_ID! });
  }, []);

  return <Component {...pageProps} />;
}
```

### Manual Implementation (Any Framework)

```typescript
// GTM Script injection
export function GTMScript({ gtmId }: { gtmId: string }) {
  if (!gtmId) return null;

  return (
    <script
      dangerouslySetInnerHTML={{
        __html: `
          (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
          new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
          j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
          'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
          })(window,document,'script','dataLayer','${gtmId}');
        `,
      }}
    />
  );
}

// NoScript fallback
export function GTMNoScript({ gtmId }: { gtmId: string }) {
  if (!gtmId) return null;

  return (
    <noscript>
      <iframe
        src={`https://www.googletagmanager.com/ns.html?id=${gtmId}`}
        height="0"
        width="0"
        style={{ display: "none", visibility: "hidden" }}
      />
    </noscript>
  );
}
```

## Multiple Environments (Dev/Staging/Prod)

```typescript
// Different containers per environment
TagManager.initialize({
  gtmId: "GTM-XXXXXXX",
  auth: "abc123",      // Environment auth string
  preview: "env-1",    // Environment preview name
});
```

## Debug Mode

Enable GTM Preview mode:
1. Go to GTM → Preview
2. Enter your site URL
3. Tag Assistant will connect

```typescript
// Force debug in development
if (process.env.NODE_ENV === "development") {
  TagManager.initialize({
    gtmId: "GTM-XXXXXXX",
    dataLayerName: "dataLayer",
    // Preview mode params automatically added when using GTM Preview
  });
}
```

## Common Issues

### Script not loading

```typescript
// ❌ Missing window check
TagManager.initialize({ gtmId });

// ✅ SSR-safe
if (typeof window !== "undefined") {
  TagManager.initialize({ gtmId });
}
```

### Double initialization

```typescript
// ❌ Can cause duplicate events
useEffect(() => {
  TagManager.initialize({ gtmId });
}); // Missing dependency array!

// ✅ Initialize once
useEffect(() => {
  TagManager.initialize({ gtmId });
}, []); // Empty array = run once
```

### GTM ID missing

```typescript
// ✅ Guard against missing env var
const gtmId = import.meta.env.VITE_GTM_ID;
if (gtmId && typeof window !== "undefined") {
  TagManager.initialize({ gtmId });
}
```
