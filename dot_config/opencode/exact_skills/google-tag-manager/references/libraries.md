# GTM Libraries Comparison

## Quick Selection Guide

| Framework | Recommended | Alternative |
|-----------|-------------|-------------|
| **Next.js (App Router)** | `@next/third-parties` | `react-gtm-module` |
| **Next.js (Pages Router)** | `react-gtm-module` | Manual |
| **Remix** | `react-gtm-module` | Manual |
| **React Router v7** | `react-gtm-module` | Manual |
| **Vite + React** | `react-gtm-module` | Manual |
| **Performance critical** | `@builder.io/partytown` | - |

## react-gtm-module

Most popular standalone GTM library. Works with any React framework.

**Install:**
```bash
npm install react-gtm-module
npm install -D @types/react-gtm-module
```

**Basic Usage:**
```typescript
import TagManager from "react-gtm-module";

// Initialize (call once in root component)
TagManager.initialize({
  gtmId: "GTM-XXXXXXX",
  dataLayerName: "dataLayer",
});

// Push events
TagManager.dataLayer({
  dataLayer: {
    event: "custom_event",
    customParam: "value",
  },
});
```

**Full Configuration:**
```typescript
TagManager.initialize({
  gtmId: "GTM-XXXXXXX",
  dataLayerName: "dataLayer",
  auth: "abc123",           // Environment auth string
  preview: "env-1",         // Environment preview name
  dataLayer: {              // Initial dataLayer values
    userType: "guest",
  },
});
```

**Pros:**
- Simple API
- Well-documented
- 2.2M+ monthly downloads
- Works with any React framework

**Cons:**
- No built-in TypeScript types (use @types/react-gtm-module)
- Limited recent maintenance
- No SSR optimization

## @next/third-parties (Next.js)

Official Next.js solution for Google services. Optimized for performance.

**Install:**
```bash
npm install @next/third-parties
```

**App Router Usage:**
```typescript
// app/layout.tsx
import { GoogleTagManager } from "@next/third-parties/google";

export default function RootLayout({ children }) {
  return (
    <html>
      <GoogleTagManager gtmId="GTM-XXXXXXX" />
      <body>{children}</body>
    </html>
  );
}
```

**Send Events:**
```typescript
"use client";
import { sendGTMEvent } from "@next/third-parties/google";

export function TrackButton() {
  return (
    <button onClick={() => sendGTMEvent({ event: "button_click", value: "xyz" })}>
      Click Me
    </button>
  );
}
```

**Configuration Options:**
```typescript
<GoogleTagManager
  gtmId="GTM-XXXXXXX"           // Required
  dataLayer={{ userType: "member" }}  // Initial data
  dataLayerName="customDataLayer"     // Custom name
  auth="abc123"                       // Environment auth
  preview="env-1"                     // Environment preview
/>
```

**Pros:**
- Official Next.js integration
- Optimized loading (after hydration)
- Full TypeScript support
- Server-side tagging support
- Active maintenance

**Cons:**
- Next.js only
- Still marked "experimental"

## Manual Implementation

Full control, no dependencies. Recommended for Remix when you need SSR control.

**GTM Script Component:**
```typescript
// components/GTMScript.tsx
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

**DataLayer Utility:**
```typescript
// utils/gtm.ts
declare global {
  interface Window {
    dataLayer: Record<string, unknown>[];
  }
}

export function pushEvent(event: string, data?: Record<string, unknown>) {
  if (typeof window === "undefined") return;
  
  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push({ event, ...data });
}
```

**Remix Usage:**
```typescript
// app/root.tsx
import { GTMScript, GTMNoScript } from "~/components/GTMScript";

export default function App() {
  const gtmId = "GTM-XXXXXXX";

  return (
    <html>
      <head>
        <GTMScript gtmId={gtmId} />
      </head>
      <body>
        <GTMNoScript gtmId={gtmId} />
        <Outlet />
      </body>
    </html>
  );
}
```

**Pros:**
- Zero dependencies
- Full SSR control
- Works everywhere
- Maximum flexibility

**Cons:**
- More code to maintain
- No standardized API

## @builder.io/partytown

Moves third-party scripts (including GTM) to a web worker. Best for performance-critical apps.

**Install:**
```bash
npm install @builder.io/partytown
```

**Usage:**
```typescript
import { Partytown } from "@builder.io/partytown/react";

export default function Root() {
  return (
    <html>
      <head>
        <Partytown forward={["dataLayer.push"]} />
        <script
          type="text/partytown"
          dangerouslySetInnerHTML={{
            __html: `
              (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
              new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
              j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
              'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
              })(window,document,'script','dataLayer','GTM-XXXXXXX');
            `,
          }}
        />
      </head>
      <body>{/* ... */}</body>
    </html>
  );
}
```

**Key Configuration:**
```typescript
<Partytown
  forward={["dataLayer.push"]}  // Forward these calls to worker
  debug={process.env.NODE_ENV === "development"}
/>
```

**Pros:**
- Moves GTM off main thread
- Significant performance improvement
- Works with any framework

**Cons:**
- Complex setup
- Some GTM features may not work
- Service worker complexity
- Debugging is harder

## @analytics/google-tag-manager

Part of the analytics library ecosystem. Use if you need multiple analytics providers.

**Install:**
```bash
npm install analytics @analytics/google-tag-manager
```

**Usage:**
```typescript
import Analytics from "analytics";
import googleTagManager from "@analytics/google-tag-manager";

const analytics = Analytics({
  app: "my-app",
  plugins: [
    googleTagManager({
      containerId: "GTM-XXXXXXX",
    }),
  ],
});

// Track page view
analytics.page();

// Track event
analytics.track("buttonClick", { label: "signup" });
```

**Pros:**
- Unified API for multiple providers
- Easy to swap providers
- TypeScript support

**Cons:**
- Extra abstraction layer
- Two packages required
- Overkill for GTM-only

## Comparison Table

| Feature | react-gtm-module | @next/third-parties | Manual | Partytown |
|---------|-----------------|---------------------|--------|-----------|
| **Downloads/mo** | 2.2M | 4.8M | N/A | 1.1M |
| **TypeScript** | @types | Built-in | DIY | Built-in |
| **SSR Safe** | Manual check | Automatic | Manual | Automatic |
| **Performance** | Standard | Optimized | Standard | Best |
| **Maintenance** | Low | Active | N/A | Active |
| **Complexity** | Low | Low | Medium | High |
| **Framework** | Any React | Next.js only | Any | Any |

## Migration Guide

### From react-gtm-module to @next/third-parties

```typescript
// Before (react-gtm-module)
import TagManager from "react-gtm-module";
TagManager.initialize({ gtmId: "GTM-XXX" });
TagManager.dataLayer({ dataLayer: { event: "custom" } });

// After (@next/third-parties)
import { GoogleTagManager, sendGTMEvent } from "@next/third-parties/google";
<GoogleTagManager gtmId="GTM-XXX" />
sendGTMEvent({ event: "custom" });
```

### From any library to Manual

```typescript
// Create utils/gtm.ts
export function pushEvent(event: string, data?: Record<string, unknown>) {
  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push({ event, ...data });
}

// Replace all TagManager.dataLayer() calls with pushEvent()
```
