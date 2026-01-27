# GraphQL Testing

Mocking Apollo Client queries and mutations with MockedProvider.

## MockedProvider Setup

### Basic Usage

```typescript
import { MockedProvider } from '@apollo/client/testing';
import type { MockedResponse } from '@apollo/client/testing';
import { render } from 'test/test-utils'; // Uses MockedProvider internally

// Custom render already includes MockedProvider
render(<CarList />, { mocks: [mock1, mock2] });
```

### buildQueryMock Helper

Use `buildQueryMock` from `test/factories` for type-safe mock creation:

```typescript
import { buildQueryMock, buildCar } from 'test/factories';
import { GetCarDocument } from './GetCar.generated';

const mock = buildQueryMock(GetCarDocument, {
  variables: { id: 'car-123' },
  data: { car: buildCar({ id: 'car-123' }) },
});

render(<CarDetail carId="car-123" />, { mocks: [mock] });
```

## Testing Queries

### Basic Query Test

```typescript
describe('CarSelect', () => {
  it('should load and display cars', async () => {
    const mockCars = [
      buildCar({ id: '1', numbers: ['ABC123'] }),
      buildCar({ id: '2', numbers: ['XYZ789'] }),
    ];

    const mock = buildQueryMock(CarsForCarSelectDocument, {
      data: { cars: mockCars },
    });

    render(<CarSelect value={null} onChange={vi.fn()} />, {
      apolloProviderProps: { addTypename: false },
      mocks: [mock],
    });

    await waitFor(() => {
      expect(screen.getByLabelText('Vozidlo')).toBeInTheDocument();
    });
  });
});
```

### Testing Loading State

```typescript
it('should show loading state', () => {
  const mocks: MockedResponse[] = [
    {
      delay: Infinity, // Never resolves - stays in loading
      request: { query: GetCarsDocument },
      result: { data: { cars: [] } },
    },
  ];

  render(<CarList />, { mocks });

  expect(screen.getByText('Loading...')).toBeInTheDocument();
});
```

### Testing Error States

```typescript
it('should display error message when query fails', async () => {
  const mock = buildQueryMock(GetCarsDocument, {
    error: new Error('Network error'),
  });

  render(<CarList />, { mocks: [mock] });

  await waitFor(() => {
    expect(screen.getByText(/Network error/i)).toBeInTheDocument();
  });
});
```

### Testing GraphQL Errors

```typescript
import { GraphQLError } from 'graphql';

it('should display GraphQL error', async () => {
  const mocks: MockedResponse[] = [
    {
      request: { query: GetCarDocument, variables: { id: '123' } },
      result: {
        errors: [new GraphQLError('Car not found')],
      },
    },
  ];

  render(<CarDetail carId="123" />, { mocks });

  await waitFor(() => {
    expect(screen.getByText(/Car not found/i)).toBeInTheDocument();
  });
});
```

## Testing Mutations

### Basic Mutation Test

```typescript
import { UpdateCarDocument } from './UpdateCar.generated';

it('should update car status', async () => {
  const user = userEvent.setup();

  const updateMock = buildQueryMock(UpdateCarDocument, {
    variables: {
      id: 'car-123',
      data: { status: CarState.Sold },
    },
    data: {
      updateCar: buildCar({ id: 'car-123', status: CarState.Sold }),
    },
  });

  render(<CarInfo car={baseCar} />, { mocks: [updateMock] });

  const select = screen.getByTestId('status-select');
  await user.selectOptions(select, CarState.Sold);

  await waitFor(() => {
    expect(screen.getByText('Status updated')).toBeInTheDocument();
  });
});
```

### Testing Mutation Errors

```typescript
it('should show error on mutation failure', async () => {
  const user = userEvent.setup();

  const errorMock = {
    request: {
      query: UpdateCarDocument,
      variables: { id: 'car-123', data: { status: CarState.Sold } },
    },
    error: new Error('Failed to update'),
  };

  render(<CarInfo car={baseCar} />, { mocks: [errorMock] });

  await user.selectOptions(screen.getByTestId('status-select'), CarState.Sold);

  await waitFor(() => {
    expect(screen.getByText(/Failed to update/i)).toBeInTheDocument();
  });
});
```

## Advanced Patterns

### Multiple Mocks for Same Query

```typescript
it('should refetch data after mutation', async () => {
  const initialMock = buildQueryMock(GetCarsDocument, {
    data: { cars: [buildCar({ status: CarState.Active })] },
  });

  const refetchMock = buildQueryMock(GetCarsDocument, {
    data: { cars: [buildCar({ status: CarState.Sold })] },
  });

  // Mocks are consumed in order
  render(<CarList />, { mocks: [initialMock, refetchMock] });

  // Initial load
  await waitFor(() => {
    expect(screen.getByText('Active')).toBeInTheDocument();
  });

  // After refetch
  await user.click(screen.getByRole('button', { name: 'Refresh' }));

  await waitFor(() => {
    expect(screen.getByText('Sold')).toBeInTheDocument();
  });
});
```

### Testing with Variables

```typescript
it('should fetch car by ID', async () => {
  const carId = 'specific-car-123';

  const mock = buildQueryMock(GetCarDocument, {
    variables: { id: carId }, // Must match exactly
    data: { car: buildCar({ id: carId }) },
  });

  render(<CarDetail carId={carId} />, { mocks: [mock] });

  await waitFor(() => {
    expect(screen.getByText(carId)).toBeInTheDocument();
  });
});
```

### Disabling __typename

For simpler mock data without Apollo's automatic __typename:

```typescript
render(<Component />, {
  apolloProviderProps: { addTypename: false },
  mocks: [mock],
});
```

## Test Data Factories

### buildQueryMock Implementation

```typescript
// test/factories.ts
export function buildQueryMock<TData, TVariables>(
  document: DocumentNode,
  { data, error, variables }: {
    data?: TData;
    error?: Error;
    variables?: TVariables;
  } = {},
): MockedResponse<TData, TVariables> {
  return {
    request: {
      query: document,
      variables: variables ?? ({} as TVariables),
    },
    result: error
      ? { errors: [{ message: error.message }] }
      : { data: data as TData },
  };
}
```

### Entity Factories

```typescript
// Build car with overrides
const car = buildCar({
  id: 'car-123',
  fullName: 'Škoda Octavia',
  status: CarState.Active,
});

// Build with fragment type
const carInfo = buildCar<CarInfoFragment>({
  id: '1',
  notes: 'Test notes',
});
```

## Best Practices

### Do's

- Use `buildQueryMock` for type-safe mocks
- Test loading, success, and error states
- Match variables exactly in mocks
- Use `apolloProviderProps: { addTypename: false }` when needed
- Build test data with factories

### Don'ts

- Don't forget to await async assertions
- Don't assume mock order matches query order
- Don't hardcode response data inline (use factories)
- Don't test Apollo Client internals
