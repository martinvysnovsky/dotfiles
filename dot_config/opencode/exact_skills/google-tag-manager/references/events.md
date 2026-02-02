# Custom Events & GA4 Tracking

## DataLayer Basics

```typescript
// The dataLayer is a global array that GTM reads
window.dataLayer = window.dataLayer || [];

// Push events to it
window.dataLayer.push({
  event: "button_click",
  button_name: "signup",
});
```

## TypeScript Types

```typescript
// types/gtm.d.ts
declare global {
  interface Window {
    dataLayer: DataLayerEvent[];
  }
}

interface DataLayerEvent {
  event: string;
  [key: string]: unknown;
}

// Specific event types
interface GTMPageViewEvent {
  event: "virtualPageview";
  page: string;
  pageTitle?: string;
}

interface GTMCustomEvent {
  event: string;
  eventCategory: string;
  eventAction: string;
  eventLabel?: string;
  eventValue?: number;
}

interface GTMEcommerceEvent {
  event: string;
  ecommerce: {
    currency?: string;
    value?: number;
    items: GTMEcommerceItem[];
    [key: string]: unknown;
  };
}

interface GTMEcommerceItem {
  item_id: string;
  item_name: string;
  price?: number;
  quantity?: number;
  item_category?: string;
  item_brand?: string;
  [key: string]: unknown;
}

export type { GTMPageViewEvent, GTMCustomEvent, GTMEcommerceEvent, GTMEcommerceItem };
```

## Event Tracking Utilities

```typescript
// utils/gtm.ts
import TagManager from "react-gtm-module";

// Generic event
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

// Structured event (GA Universal style)
export interface EventParams {
  category: string;
  action: string;
  label?: string;
  value?: number;
}

export function trackStructuredEvent({ category, action, label, value }: EventParams) {
  trackEvent("event", {
    eventCategory: category,
    eventAction: action,
    eventLabel: label,
    eventValue: value,
  });
}
```

## Real-World Event Examples

### Phone/Email Click Tracking

```typescript
export function trackPhoneClick(location: string) {
  trackEvent("event", {
    eventCategory: "PhoneLink",
    eventAction: "Click",
    eventLabel: location, // e.g., "header", "footer", "contact-page"
  });
}

export function trackEmailClick(location: string) {
  trackEvent("event", {
    eventCategory: "EmailLink",
    eventAction: "Click",
    eventLabel: location,
  });
}

// Usage in component
<a href="tel:+1234567890" onClick={() => trackPhoneClick("header")}>
  Call Us
</a>
```

### Form Submission

```typescript
export function trackFormSubmission(formName: string, formValue?: number) {
  trackEvent("event", {
    eventCategory: "Form",
    eventAction: "Submit",
    eventLabel: formName,
    eventValue: formValue,
  });
}

// Usage
const handleSubmit = async (data: FormData) => {
  await submitForm(data);
  trackFormSubmission("contact-form");
};
```

### Modal/Popup Views

```typescript
export function trackModalView(modalName: string) {
  trackEvent("modal_view", {
    modal_name: modalName,
  });
}

// Usage
const openModal = () => {
  setIsOpen(true);
  trackModalView("product-gallery");
};
```

### Filter/Search Changes

```typescript
export function trackFilterChange(filterType: string, filterValue: string) {
  trackEvent("filter_change", {
    filter_type: filterType,
    filter_value: filterValue,
  });
}

export function trackSearch(searchTerm: string, resultsCount: number) {
  trackEvent("search", {
    search_term: searchTerm,
    results_count: resultsCount,
  });
}
```

### File Downloads

```typescript
export function trackDownload(fileName: string, fileType: string) {
  trackEvent("file_download", {
    file_name: fileName,
    file_extension: fileType,
  });
}
```

### Table Exports

```typescript
export function trackTableExport(
  tableName: string,
  exportFormat: "csv" | "xlsx" | "pdf" | "print",
  rowCount: number,
) {
  trackEvent("table_export", {
    table_name: tableName,
    export_format: exportFormat,
    row_count: rowCount,
  });
}
```

## GA4 Recommended Events

Use these event names for better GA4 integration:

| Event | When to Use | Required Parameters |
|-------|-------------|---------------------|
| `login` | User logs in | `method` |
| `sign_up` | User registers | `method` |
| `search` | User searches | `search_term` |
| `share` | User shares content | `method`, `content_type`, `item_id` |
| `select_content` | User selects item | `content_type`, `item_id` |
| `view_item` | User views product | `items` array |
| `add_to_cart` | User adds to cart | `items` array |
| `purchase` | User completes purchase | `transaction_id`, `value`, `items` |

```typescript
// Login event
trackEvent("login", {
  method: "email", // or "google", "facebook"
});

// Sign up event
trackEvent("sign_up", {
  method: "email",
});

// Search event
trackEvent("search", {
  search_term: "blue shoes",
});

// Share event
trackEvent("share", {
  method: "twitter",
  content_type: "product",
  item_id: "SKU123",
});
```

## React Hook for Tracking

```typescript
// hooks/useGTM.ts
import { useCallback } from "react";
import { trackEvent, trackStructuredEvent, type EventParams } from "~/utils/gtm";

export function useGTM() {
  const track = useCallback((eventName: string, params?: Record<string, unknown>) => {
    trackEvent(eventName, params);
  }, []);

  const trackStructured = useCallback((params: EventParams) => {
    trackStructuredEvent(params);
  }, []);

  return {
    trackEvent: track,
    trackStructuredEvent: trackStructured,
  };
}

// Usage in component
function ContactForm() {
  const { trackEvent } = useGTM();

  const handleSubmit = () => {
    trackEvent("form_submit", { form_name: "contact" });
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

## GTM Configuration for Custom Events

### Create Custom Event Trigger

1. Navigate to **Triggers** in the left sidebar → click **New**
2. Name your trigger at the top (e.g., "Custom - Form Submit")
3. In the **Trigger Configuration** panel, select **Custom Event**
4. In the **Event name** field, enter your event name (e.g., `form_submit`)
5. For multiple events, use regex matching: `form_submit|button_click|modal_view`
6. Click **Save**

### Create Data Layer Variables

For each dataLayer parameter you want to use in tags:

1. Navigate to **Variables** in the left sidebar
2. Scroll to **User-Defined Variables** → click **New**
3. Name your variable at the top (e.g., "DLV - eventCategory")
4. In the **Variable Configuration** panel, select **Data Layer Variable**
5. Enter the variable name exactly as pushed to dataLayer (e.g., `eventCategory`)
6. Set Data Layer Version to **Version 2**
7. Click **Save**

### Create GA4 Event Tag

1. Navigate to **Tags** in the left sidebar → click **New**
2. Name your tag at the top (e.g., "GA4 Event - Form Submit")
3. In the **Tag Configuration** panel, select **Google Analytics: GA4 Event**
4. For **Measurement ID**, use the `{{GA4 Measurement ID}}` variable (see setup.md for creating this)
5. Set **Event Name** using `{{Event}}` variable or hardcode the event name
6. Expand **Event Parameters** to add custom parameters from your Data Layer Variables
7. In the **Triggering** section, select your custom event trigger
8. Click **Save**

## Debugging Events

```typescript
// Development logging
export function trackEvent(eventName: string, parameters?: Record<string, unknown>) {
  if (process.env.NODE_ENV === "development") {
    console.log("[GTM Event]", eventName, parameters);
  }

  TagManager.dataLayer({
    dataLayer: {
      event: eventName,
      ...parameters,
    },
  });
}
```

**GTM Preview Mode:**
1. Open GTM → Preview
2. Perform action that should trigger event
3. Verify event appears in Tag Assistant
4. Check that correct tags fire
5. Verify event parameters are passed correctly

**GA4 DebugView:**
1. GA4 → Admin → DebugView
2. See events in real-time
3. Click event to see parameters
