# Ecommerce Tracking

## Contents

- [GA4 Ecommerce Funnel](#ga4-ecommerce-funnel)
- [Item Object Structure](#item-object-structure)
- [TypeScript Types](#typescript-types)
- [Tracking Functions](#tracking-functions)
  - [clearEcommerce()](#clearecommerce)
  - [trackViewItemList()](#trackviewitemlist)
  - [trackSelectItem()](#trackselectitem)
  - [trackViewItem()](#trackviewitem)
  - [trackAddToCart()](#trackaddtocart)
  - [trackRemoveFromCart()](#trackremovefromcart)
  - [trackViewCart()](#trackviewcart)
  - [trackBeginCheckout()](#trackbegincheckout)
  - [trackAddShippingInfo()](#trackaddshippinginfo)
  - [trackAddPaymentInfo()](#trackaddpaymentinfo)
  - [trackPurchase()](#trackpurchase)
  - [trackRefund()](#trackrefund)
- [Usage Examples](#usage-examples)
  - [Product List Page](#product-list-page)
  - [Product Detail Page](#product-detail-page)
  - [Checkout Flow](#checkout-flow)
  - [Order Confirmation](#order-confirmation)
- [GTM Configuration](#gtm-configuration)
- [Important: Clear Ecommerce Data](#important-clear-ecommerce-data)
- [Debugging](#debugging)

## GA4 Ecommerce Funnel

```
view_item_list → select_item → view_item → add_to_cart → view_cart
    → begin_checkout → add_shipping_info → add_payment_info → purchase
```

## Item Object Structure

```typescript
interface EcommerceItem {
  item_id: string;           // Required: SKU or product ID
  item_name: string;         // Required: Product name
  price?: number;            // Price per unit
  quantity?: number;         // Quantity (default: 1)
  item_brand?: string;       // Brand name
  item_category?: string;    // Primary category
  item_category2?: string;   // Sub-category
  item_category3?: string;   // Sub-sub-category
  item_variant?: string;     // Variant (color, size)
  item_list_id?: string;     // List ID where shown
  item_list_name?: string;   // List name
  index?: number;            // Position in list
  discount?: number;         // Discount amount
  coupon?: string;           // Applied coupon
}
```

## TypeScript Types

```typescript
// types/ecommerce.ts
export interface EcommerceItem {
  item_id: string;
  item_name: string;
  price?: number;
  quantity?: number;
  item_brand?: string;
  item_category?: string;
  item_variant?: string;
  index?: number;
  discount?: number;
}

export interface EcommerceEvent {
  event: string;
  ecommerce: {
    currency?: string;
    value?: number;
    items: EcommerceItem[];
    transaction_id?: string;
    shipping?: number;
    tax?: number;
    coupon?: string;
  };
}
```

## Tracking Functions

```typescript
// utils/ecommerce.ts
import TagManager from "react-gtm-module";
import type { EcommerceItem } from "~/types/ecommerce";

function clearEcommerce() {
  // Clear previous ecommerce data to prevent contamination
  TagManager.dataLayer({ dataLayer: { ecommerce: null } });
}

export function trackViewItemList(
  items: EcommerceItem[],
  listId: string,
  listName: string,
) {
  clearEcommerce();
  TagManager.dataLayer({
    dataLayer: {
      event: "view_item_list",
      ecommerce: {
        item_list_id: listId,
        item_list_name: listName,
        items: items.map((item, index) => ({
          ...item,
          item_list_id: listId,
          item_list_name: listName,
          index,
        })),
      },
    },
  });
}

export function trackSelectItem(item: EcommerceItem, listId: string, listName: string) {
  clearEcommerce();
  TagManager.dataLayer({
    dataLayer: {
      event: "select_item",
      ecommerce: {
        item_list_id: listId,
        item_list_name: listName,
        items: [{ ...item, item_list_id: listId, item_list_name: listName }],
      },
    },
  });
}

export function trackViewItem(item: EcommerceItem, currency: string = "EUR") {
  clearEcommerce();
  TagManager.dataLayer({
    dataLayer: {
      event: "view_item",
      ecommerce: {
        currency,
        value: item.price,
        items: [item],
      },
    },
  });
}

export function trackAddToCart(
  item: EcommerceItem,
  quantity: number = 1,
  currency: string = "EUR",
) {
  clearEcommerce();
  const itemWithQty = { ...item, quantity };
  TagManager.dataLayer({
    dataLayer: {
      event: "add_to_cart",
      ecommerce: {
        currency,
        value: (item.price || 0) * quantity,
        items: [itemWithQty],
      },
    },
  });
}

export function trackRemoveFromCart(
  item: EcommerceItem,
  quantity: number = 1,
  currency: string = "EUR",
) {
  clearEcommerce();
  TagManager.dataLayer({
    dataLayer: {
      event: "remove_from_cart",
      ecommerce: {
        currency,
        value: (item.price || 0) * quantity,
        items: [{ ...item, quantity }],
      },
    },
  });
}

export function trackViewCart(items: EcommerceItem[], currency: string = "EUR") {
  clearEcommerce();
  const value = items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);
  TagManager.dataLayer({
    dataLayer: {
      event: "view_cart",
      ecommerce: {
        currency,
        value,
        items,
      },
    },
  });
}

export function trackBeginCheckout(items: EcommerceItem[], currency: string = "EUR") {
  clearEcommerce();
  const value = items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);
  TagManager.dataLayer({
    dataLayer: {
      event: "begin_checkout",
      ecommerce: {
        currency,
        value,
        items,
      },
    },
  });
}

export function trackAddShippingInfo(
  items: EcommerceItem[],
  shippingTier: string,
  currency: string = "EUR",
) {
  clearEcommerce();
  const value = items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);
  TagManager.dataLayer({
    dataLayer: {
      event: "add_shipping_info",
      ecommerce: {
        currency,
        value,
        shipping_tier: shippingTier,
        items,
      },
    },
  });
}

export function trackAddPaymentInfo(
  items: EcommerceItem[],
  paymentType: string,
  currency: string = "EUR",
) {
  clearEcommerce();
  const value = items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);
  TagManager.dataLayer({
    dataLayer: {
      event: "add_payment_info",
      ecommerce: {
        currency,
        value,
        payment_type: paymentType,
        items,
      },
    },
  });
}

export function trackPurchase(
  transactionId: string,
  items: EcommerceItem[],
  options: {
    currency?: string;
    shipping?: number;
    tax?: number;
    coupon?: string;
  } = {},
) {
  clearEcommerce();
  const { currency = "EUR", shipping = 0, tax = 0, coupon } = options;
  const itemsValue = items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);
  const value = itemsValue + shipping + tax;

  TagManager.dataLayer({
    dataLayer: {
      event: "purchase",
      ecommerce: {
        transaction_id: transactionId,
        currency,
        value,
        shipping,
        tax,
        coupon,
        items,
      },
    },
  });
}

export function trackRefund(
  transactionId: string,
  items?: EcommerceItem[],
  currency: string = "EUR",
) {
  clearEcommerce();
  const value = items?.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);
  TagManager.dataLayer({
    dataLayer: {
      event: "refund",
      ecommerce: {
        transaction_id: transactionId,
        currency,
        value,
        items,
      },
    },
  });
}
```

## Usage Examples

### Product List Page

```typescript
// components/ProductList.tsx
import { useEffect } from "react";
import { trackViewItemList, trackSelectItem } from "~/utils/ecommerce";

export function ProductList({ products, categorySlug }) {
  useEffect(() => {
    const items = products.map((p) => ({
      item_id: p.sku,
      item_name: p.name,
      price: p.price,
      item_brand: p.brand,
      item_category: p.category,
    }));
    
    trackViewItemList(items, categorySlug, `Category: ${categorySlug}`);
  }, [products, categorySlug]);

  const handleProductClick = (product, index) => {
    trackSelectItem(
      {
        item_id: product.sku,
        item_name: product.name,
        price: product.price,
        index,
      },
      categorySlug,
      `Category: ${categorySlug}`,
    );
  };

  return (
    <div>
      {products.map((product, index) => (
        <ProductCard
          key={product.id}
          product={product}
          onClick={() => handleProductClick(product, index)}
        />
      ))}
    </div>
  );
}
```

### Product Detail Page

```typescript
// components/ProductDetail.tsx
import { useEffect } from "react";
import { trackViewItem, trackAddToCart } from "~/utils/ecommerce";

export function ProductDetail({ product }) {
  useEffect(() => {
    trackViewItem({
      item_id: product.sku,
      item_name: product.name,
      price: product.price,
      item_brand: product.brand,
      item_category: product.category,
    });
  }, [product]);

  const handleAddToCart = (quantity: number) => {
    trackAddToCart(
      {
        item_id: product.sku,
        item_name: product.name,
        price: product.price,
      },
      quantity,
    );
    // Add to cart logic...
  };

  return (
    <div>
      <h1>{product.name}</h1>
      <button onClick={() => handleAddToCart(1)}>Add to Cart</button>
    </div>
  );
}
```

### Checkout Flow

```typescript
// pages/checkout.tsx
import { trackBeginCheckout, trackAddShippingInfo, trackAddPaymentInfo } from "~/utils/ecommerce";

function CheckoutPage() {
  const { items } = useCart();

  useEffect(() => {
    trackBeginCheckout(items);
  }, []);

  const handleShippingSelected = (method: string) => {
    trackAddShippingInfo(items, method);
  };

  const handlePaymentSelected = (method: string) => {
    trackAddPaymentInfo(items, method);
  };

  return (
    <CheckoutForm
      onShippingChange={handleShippingSelected}
      onPaymentChange={handlePaymentSelected}
    />
  );
}
```

### Order Confirmation

```typescript
// pages/order-confirmation.tsx
import { useEffect } from "react";
import { trackPurchase } from "~/utils/ecommerce";

function OrderConfirmation({ order }) {
  useEffect(() => {
    trackPurchase(order.id, order.items, {
      shipping: order.shippingCost,
      tax: order.taxAmount,
      coupon: order.couponCode,
    });
  }, [order]);

  return <div>Thank you for your order!</div>;
}
```

## GTM Configuration

### Enable GA4 Ecommerce

In GA4 Config tag:
1. Enable "Send e-commerce data"
2. Data source: Data Layer

### Create Ecommerce Trigger

For each ecommerce event:
1. Triggers → New → Custom Event
2. Event name: `view_item|add_to_cart|purchase|...`
3. Use regex to match multiple events

### Or Use Built-in Variables

Enable built-in ecommerce variables:
- Variables → Configure → Check ecommerce variables

## Important: Clear Ecommerce Data

Always clear previous ecommerce data before pushing new events:

```typescript
// ✅ Good - Clear before each event
TagManager.dataLayer({ dataLayer: { ecommerce: null } });
TagManager.dataLayer({ dataLayer: { event: "purchase", ecommerce: {...} } });

// ❌ Bad - Can contaminate events
TagManager.dataLayer({ dataLayer: { event: "purchase", ecommerce: {...} } });
```

## Debugging

1. **GTM Preview**: Check ecommerce object in each event
2. **GA4 DebugView**: Verify events appear with correct parameters
3. **GA4 Realtime**: See transactions in real-time
4. **GA4 Monetization Reports**: Check after 24-48 hours
