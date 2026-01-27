# Custom Hook Testing

Patterns for testing React custom hooks with Testing Library.

## Basic Hook Testing

### Using renderHook

```typescript
import { describe, expect, it } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('should initialize with default value', () => {
    const { result } = renderHook(() => useCounter());
    expect(result.current.count).toBe(0);
  });

  it('should initialize with provided value', () => {
    const { result } = renderHook(() => useCounter(10));
    expect(result.current.count).toBe(10);
  });

  it('should increment count', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

### Testing with Dependencies

```typescript
describe('useFilter', () => {
  it('should update when items change', () => {
    const initialItems = [{ id: 1, name: 'A' }];
    const { result, rerender } = renderHook(
      ({ items }) => useFilter(items),
      { initialProps: { items: initialItems } },
    );

    expect(result.current.filteredItems).toHaveLength(1);

    const newItems = [
      { id: 1, name: 'A' },
      { id: 2, name: 'B' },
    ];
    rerender({ items: newItems });

    expect(result.current.filteredItems).toHaveLength(2);
  });
});
```

## Testing Async Hooks

### Hooks with API Calls

```typescript
import { waitFor } from '@testing-library/react';

describe('useFetchCar', () => {
  it('should fetch car data', async () => {
    const mocks = [
      buildQueryMock(GetCarDocument, {
        variables: { id: 'car-123' },
        data: { car: buildCar({ id: 'car-123' }) },
      }),
    ];

    const wrapper = ({ children }) => (
      <MockedProvider mocks={mocks}>
        {children}
      </MockedProvider>
    );

    const { result } = renderHook(() => useFetchCar('car-123'), { wrapper });

    expect(result.current.loading).toBe(true);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.car).toBeDefined();
    expect(result.current.car.id).toBe('car-123');
  });
});
```

### Hooks with Timers

```typescript
import { vi } from 'vitest';

describe('useDebounce', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('should debounce value updates', () => {
    const { result, rerender } = renderHook(
      ({ value }) => useDebounce(value, 500),
      { initialProps: { value: 'initial' } },
    );

    expect(result.current).toBe('initial');

    rerender({ value: 'updated' });

    // Value shouldn't change immediately
    expect(result.current).toBe('initial');

    // Fast-forward time
    act(() => {
      vi.advanceTimersByTime(500);
    });

    expect(result.current).toBe('updated');
  });
});
```

## Testing Hooks with Context

### Wrapping with Providers

```typescript
import { AuthProvider } from '~/context/AuthContext';

describe('useAuth', () => {
  const wrapper = ({ children }) => (
    <AuthProvider>{children}</AuthProvider>
  );

  it('should provide auth state', () => {
    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.isLoggedIn).toBe(false);
    expect(result.current.user).toBeNull();
  });

  it('should handle login', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper });

    await act(async () => {
      await result.current.login({ email: 'test@example.com', password: 'password' });
    });

    expect(result.current.isLoggedIn).toBe(true);
  });
});
```

### Combined Providers

```typescript
const createWrapper = (mocks = []) => {
  return function Wrapper({ children }) {
    return (
      <ThemeProvider theme={theme}>
        <MockedProvider mocks={mocks}>
          <AuthProvider>
            {children}
          </AuthProvider>
        </MockedProvider>
      </ThemeProvider>
    );
  };
};

it('should work with multiple providers', () => {
  const { result } = renderHook(
    () => useCarData(),
    { wrapper: createWrapper([carMock]) },
  );

  // assertions
});
```

## Testing State Updates

### Multiple State Changes

```typescript
describe('useForm', () => {
  it('should handle multiple field updates', () => {
    const { result } = renderHook(() =>
      useForm({ name: '', email: '' }),
    );

    act(() => {
      result.current.setField('name', 'John');
    });

    act(() => {
      result.current.setField('email', 'john@example.com');
    });

    expect(result.current.values).toEqual({
      name: 'John',
      email: 'john@example.com',
    });
  });

  it('should reset form', () => {
    const { result } = renderHook(() =>
      useForm({ name: '', email: '' }),
    );

    act(() => {
      result.current.setField('name', 'John');
      result.current.reset();
    });

    expect(result.current.values).toEqual({ name: '', email: '' });
  });
});
```

## Error Handling

### Testing Error States

```typescript
describe('useFetch', () => {
  it('should handle fetch errors', async () => {
    const errorMock = buildQueryMock(GetCarDocument, {
      error: new Error('Network error'),
    });

    const { result } = renderHook(
      () => useFetchCar('car-123'),
      { wrapper: createWrapper([errorMock]) },
    );

    await waitFor(() => {
      expect(result.current.error).toBeDefined();
    });

    expect(result.current.error.message).toBe('Network error');
    expect(result.current.car).toBeNull();
  });
});
```

## Best Practices

### Do's

- Use `act()` for all state updates
- Use `waitFor` for async operations
- Test the hook's return values, not internal implementation
- Provide required context via wrapper option
- Clean up timers after tests

### Don'ts

- Don't test hooks that just wrap other libraries
- Don't access internal state directly
- Don't forget to await async operations
- Don't use real timers for time-based hooks
