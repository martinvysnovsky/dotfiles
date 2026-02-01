# SPA Pageview Tracking

## Contents

- [The Problem](#the-problem)
- [Solution: GTM History Change Trigger](#solution-gtm-history-change-trigger)
- [GTM Configuration Steps](#gtm-configuration-steps)
- [Tags That Need History Change Trigger](#tags-that-need-history-change-trigger)
- [What NOT To Do](#what-not-to-do)
- [Debugging SPA Tracking](#debugging-spa-tracking)
- [Event Types Explained](#event-types-explained)
- [SSR Considerations](#ssr-considerations)

## The Problem

GTM's default **"All Pages"** trigger only fires on full page loads (browser navigation with refresh). It does **NOT** fire on SPA client-side navigations (History API pushState/replaceState).

```
Full Page Load:  Browser → Server → HTML → GTM fires ✅
SPA Navigation:  JS updates URL via History API → GTM silent ❌
```

**Result without fix:**
- Tags fire on initial page load ✅
- Tags never fire on subsequent SPA route changes ❌
- Lost analytics data for most of user session

## Solution: GTM History Change Trigger

GTM has a **built-in History Change listener** that automatically detects SPA navigations. No custom code needed.

When the browser's History API is used (pushState/replaceState), GTM automatically creates `gtm.historyChange-v2` events. Configure a trigger to listen for them.

**This is the recommended approach** - standard industry practice, no code maintenance, works with all SPA frameworks (Remix, React Router, Next.js, etc.).

## GTM Configuration Steps

### 1. Create History Change Trigger

1. Go to **Triggers** → **New**
2. Trigger Configuration → **History Change**
3. Name: `History Change - All Pages`
4. This trigger fires on: **All History Changes**
5. Save

### 2. Add Trigger to Tags

For each tag that should fire on navigation, add the History Change trigger **in addition to** existing triggers.

Example for Google Tag (GA4):
- Triggering → Add Trigger
- Select `History Change - All Pages`
- Keep existing "All Pages" trigger (for initial load)

### 3. Publish Changes

Preview and test before publishing to production.

## Tags That Need History Change Trigger

Add History Change trigger to **all** navigation-related tags:

| Tag Type | Why |
|----------|-----|
| **Google Tag (GA4)** | Track pageviews on navigation |
| **Cookie Consent** | Re-check consent on new pages |
| **Conversion Linker** | Maintain conversion tracking across pages |
| **Facebook Pixel** | Track page views for retargeting |
| **Any pageview-based tag** | Same reason |

**Common mistake:** Only adding History Change to GA4 tag but forgetting Consent and Conversion Linker tags.

## What NOT To Do

### ❌ Don't Mix Custom Code with GTM's Built-in Listener

```typescript
// ❌ BAD - Creates duplicate events
useEffect(() => {
  window.dataLayer?.push({
    event: "virtualPageview",
    page: location.pathname,
  });
}, [location.pathname]);
```

This creates **duplicate tracking** because:
1. Your code pushes `virtualPageview`
2. GTM's built-in listener pushes `gtm.historyChange-v2`
3. Result: 2-3 events per navigation, potential double-counting

### ❌ Don't Assume "All Pages" Covers SPAs

```
// ❌ BAD - "All Pages" only fires on full page loads
Trigger: All Pages
Result: Tags fire once on initial load, never again
```

### ❌ Don't Forget Non-GA4 Tags

```
// ❌ BAD - Only GA4 has History Change trigger
Google Tag: All Pages + History Change ✅
Cookie Consent: All Pages only ❌
Conversion Linker: All Pages only ❌
```

## Debugging SPA Tracking

### Using GTM Tag Assistant

1. Open GTM → **Preview**
2. Enter your site URL
3. Navigate between SPA pages
4. In Tag Assistant, verify:

| Check | Expected |
|-------|----------|
| `gtm.historyChange-v2` event appears | Yes, on each navigation |
| Tags fire on this event | Yes, not "Tags Not Fired" |
| Events per navigation | ONE event, not multiple |
| Tags in "Tags Fired" section | GA4, Consent, Linker all present |

### Common Debug Issues

**No `gtm.historyChange-v2` events:**
- SPA might use hash routing (`#/page`) instead of History API
- Check if framework uses `pushState`/`replaceState`

**Tags show "Tags Not Fired":**
- History Change trigger not added to tag
- Trigger conditions not met (check filters)

**Multiple events per navigation:**
- Custom code running alongside GTM's listener
- Remove custom `dataLayer.push` for pageviews

## Event Types Explained

| Event | Source | When It Fires |
|-------|--------|---------------|
| `gtm.js` | GTM initialization | Initial page load only |
| `gtm.dom` | GTM DOM ready | Initial page load only |
| `gtm.historyChange-v2` | GTM built-in | History API (pushState/replaceState) |
| `gtm.load` | GTM window load | Initial page load only |

**For SPA tracking, rely on `gtm.historyChange-v2`** - it's automatically created by GTM when the browser's History API is used.

## SSR Considerations

### Initial Load vs Client Navigation

```
1. User visits /products (SSR)
   → Server renders HTML
   → GTM loads, fires "All Pages" triggers
   → Tags fire ✅

2. User clicks to /products/123 (Client navigation)
   → React/Remix updates DOM via History API
   → GTM detects history change
   → GTM fires "History Change" triggers
   → Tags fire ✅
```

### Hydration

No special handling needed. GTM's History Change listener only activates **after** initial load, so hydration doesn't cause duplicate events.

### Framework-Specific Notes

**Remix / React Router v7:**
- Uses History API by default → GTM History Change works automatically
- No custom tracking code needed in `root.tsx`

**Next.js (App Router):**
- Uses soft navigation → GTM History Change works automatically
- `@next/third-parties` handles this internally

**Next.js (Pages Router):**
- Uses `next/router` with History API → GTM History Change works automatically
- No need for `router.events` listener if using GTM

## Summary Checklist

- [ ] Created History Change trigger in GTM
- [ ] Added trigger to Google Tag (GA4)
- [ ] Added trigger to Cookie Consent tag
- [ ] Added trigger to Conversion Linker tag
- [ ] Added trigger to other navigation-related tags
- [ ] Removed any custom `dataLayer.push` for pageviews
- [ ] Tested with Tag Assistant - ONE event per navigation
- [ ] Verified all tags fire on `gtm.historyChange-v2`
