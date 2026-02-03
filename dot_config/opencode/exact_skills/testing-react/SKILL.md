# React Testing Skill

Testing React components with Vitest and Testing Library.

## Stack

- **Vitest** - Test runner (Jest-compatible)
- **@testing-library/react** - Component testing utilities
- **@testing-library/user-event** - User interaction simulation
- **@apollo/client/testing** - GraphQL mock provider
- **jsdom** - Browser environment simulation

## CI Configuration

For CI pipelines, configure Vitest to fail fast:

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    // Fail fast in CI to save pipeline minutes
    bail: process.env.CI ? 1 : undefined,
    // ... other config
  },
});
```

Add CI-specific script:
```json
{
  "scripts": {
    "test:ci": "vitest run --bail 1"
  }
}
```

## Quick Start

### Basic Component Test

```typescript
import { describe, expect, it, vi } from 'vitest';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { render } from 'test/test-utils';
import { MyComponent } from './MyComponent';

describe('MyComponent', () => {
  it('should render correctly', () => {
    render(<MyComponent title="Hello" />);
    expect(screen.getByText('Hello')).toBeInTheDocument();
  });

  it('should handle user interaction', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();

    render(<MyComponent onClick={onClick} />);

    await user.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalled();
  });
});
```

### With GraphQL Mocks

```typescript
import { buildQueryMock, buildCar } from 'test/factories';
import { GetCarDocument } from './GetCar.generated';

it('should fetch and display car', async () => {
  const car = buildCar({ fullName: 'Škoda Octavia' });
  const mock = buildQueryMock(GetCarDocument, {
    variables: { id: car.id },
    data: { car },
  });

  render(<CarDetail carId={car.id} />, { mocks: [mock] });

  await waitFor(() => {
    expect(screen.getByText('Škoda Octavia')).toBeInTheDocument();
  });
});
```

## Key Patterns

### Custom Render with Providers

Use `render` from `test/test-utils` - it wraps components with required providers:

```typescript
// test/test-utils.tsx
function customRender(
  ui: ReactElement,
  { mocks = [], apolloProviderProps = {}, ...renderOptions } = {},
) {
  function Wrapper({ children }) {
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
```

### Module Mocking with vi.mock

```typescript
// Mock entire module
vi.mock('~/components/CarStatusBadge', () => ({
  default: ({ status }) => <div data-testid="status-badge">{status}</div>,
}));

// Mock with implementation
vi.mock('~/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: '1', name: 'Test User' }, isLoggedIn: true }),
}));
```

### User Events Setup

Always use `userEvent.setup()` for realistic user interactions:

```typescript
it('should type in input', async () => {
  const user = userEvent.setup();

  render(<SearchInput />);

  const input = screen.getByRole('textbox');
  await user.type(input, 'search term');

  expect(input).toHaveValue('search term');
});
```

## Test Data Factories

Use `buildCar`, `buildCarType`, `buildQueryMock` from `test/factories`:

```typescript
// Build entity with overrides
const car = buildCar({
  id: 'car-123',
  fullName: 'VW Passat',
  status: CarState.Active,
});

// Build GraphQL mock
const mock = buildQueryMock(GetCarsDocument, {
  data: { cars: [car] },
});
```

## References

- [components.md](references/components.md) - Component testing patterns
- [hooks.md](references/hooks.md) - Custom hook testing
- [graphql.md](references/graphql.md) - GraphQL query/mutation mocking
- [setup.md](references/setup.md) - Vitest configuration and browser mocks
