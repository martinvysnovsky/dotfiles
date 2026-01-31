# Vitest Setup

Configuration and setup for React testing with Vitest.

## Vitest Configuration

### vitest.config.ts

```typescript
import tsconfigPaths from 'vite-tsconfig-paths';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    coverage: {
      exclude: [
        '**/*.config.*',
        '**/*.generated.*',
        '**/node_modules/**',
        '**/test/**',
        'app/entry.client.tsx',
        'app/entry.server.tsx',
        'app/root.tsx',
      ],
      provider: 'v8',
      reporter: ['text', 'html', 'json'],
    },
    css: true,
    environment: 'jsdom',
    globals: true,
    server: {
      deps: {
        // Inline packages that have issues with ESM
        inline: ['@mui/x-data-grid', '@mui/x-data-grid-pro', '@toolpad/core'],
      },
    },
    setupFiles: ['./test/setup-vitest.ts'],
  },
});
```

## Setup File

### test/setup-vitest.ts

```typescript
import { vi } from 'vitest';
import { configure } from '@testing-library/react';
import '@testing-library/jest-dom';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Configure Testing Library
configure({ asyncUtilTimeout: 10000 });

// Set timezone for consistent date handling
process.env.TZ = 'UTC';
```

## Browser API Mocks

### IntersectionObserver

Used by lazy loading, virtualization, and infinite scroll:

```typescript
global.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  disconnect() {}
  observe() {}
  takeRecords() {
    return [];
  }
  unobserve() {}
} as unknown as typeof global.IntersectionObserver;
```

### ResizeObserver

Used by responsive components, charts, and tables:

```typescript
global.ResizeObserver = class ResizeObserver {
  constructor() {}
  disconnect() {}
  observe() {}
  unobserve() {}
} as unknown as typeof global.ResizeObserver;
```

### matchMedia

Used for responsive design and media queries:

```typescript
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(), // deprecated
    removeListener: vi.fn(), // deprecated
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});
```

## Mocking CSS Imports

For packages that import CSS files:

```typescript
// Mock MUI CSS imports
vi.mock('@mui/x-data-grid/esm/index.css', () => ({}));
vi.mock('@mui/x-data-grid-pro/esm/index.css', () => ({}));
```

## Suppressing Console Warnings

Filter out known warnings that don't affect tests:

```typescript
const originalError = console.error;
const originalWarn = console.warn;

console.error = (...args: unknown[]) => {
  const message = String(args[0]);

  // Filter out known warnings
  if (
    message.includes('Not implemented: HTMLFormElement.prototype.requestSubmit') ||
    message.includes('openTo') ||
    message.includes('inputProps')
  ) {
    return;
  }

  originalError.call(console, ...args);
};

console.warn = (...args: unknown[]) => {
  const message = String(args[0]);

  if (message.includes('React does not recognize')) {
    return;
  }

  originalWarn.call(console, ...args);
};
```

## Custom Render with Providers

### test/test-utils.tsx

```typescript
import { createTheme, ThemeProvider } from '@mui/material/styles';
import type { MockedResponse } from '@apollo/client/testing';
import { MockedProvider } from '@apollo/client/testing/react';
import type { RenderOptions } from '@testing-library/react';
import { render } from '@testing-library/react';
import { NotificationsProvider } from '@toolpad/core/useNotifications';
import type { ReactElement } from 'react';

// Re-export everything from Testing Library
export * from '@testing-library/react';

const theme = createTheme();

interface ExtendedRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  mocks?: readonly MockedResponse[];
  apolloProviderProps?: Record<string, unknown>;
}

function customRender(
  ui: ReactElement,
  {
    mocks = [],
    apolloProviderProps = {},
    ...renderOptions
  }: ExtendedRenderOptions = {},
) {
  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <ThemeProvider theme={theme}>
        <NotificationsProvider>
          <MockedProvider mocks={mocks} {...apolloProviderProps}>
            {children}
          </MockedProvider>
        </NotificationsProvider>
      </ThemeProvider>
    );
  }

  return render(ui, { wrapper: Wrapper, ...renderOptions });
}

export { customRender as render };
```

## Licensed Component Setup

For MUI X premium components:

```typescript
import { LicenseInfo } from '@mui/x-license';

const licenseKey = process.env.MUI_LICENSE_KEY;

if (licenseKey) {
  LicenseInfo.setLicenseKey(licenseKey);
}
```

## Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage",
    "test:ui": "vitest --ui"
  }
}
```

## Common Issues and Solutions

### ESM Module Issues

If a package fails to load, add it to `server.deps.inline`:

```typescript
test: {
  server: {
    deps: {
      inline: ['problematic-package'],
    },
  },
}
```

### CSS Import Errors

Mock CSS files that cause "Unknown file extension .css" errors:

```typescript
vi.mock('package/style.css', () => ({}));
```

### Timeout Issues

Increase timeout for slow tests:

```typescript
configure({ asyncUtilTimeout: 10000 });

// Or per-test
it('slow test', async () => {
  // ...
}, 15000);
```

### Act Warnings

Usually fixed by proper async handling:

```typescript
// Wrong
fireEvent.click(button);
expect(something).toBe(true);

// Right
await user.click(button);
await waitFor(() => expect(something).toBe(true));
```
