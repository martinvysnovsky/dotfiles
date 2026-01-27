# Component Testing

Patterns for testing React components with Testing Library.

## Basic Component Tests

### Rendering and Assertions

```typescript
import { describe, expect, it } from 'vitest';
import { screen } from '@testing-library/react';
import { render } from 'test/test-utils';
import { CarInfo } from './CarInfo';
import { buildCar } from 'test/factories';

describe('CarInfo', () => {
  it('should render car information', () => {
    const car = buildCar({
      fullName: 'Škoda Octavia',
      vin: 'TMBJJ7NE5E0123456',
    });

    render(<CarInfo car={car} />);

    expect(screen.getByText('Škoda Octavia')).toBeInTheDocument();
    expect(screen.getByText('TMBJJ7NE5E0123456')).toBeInTheDocument();
  });

  it('should return null when car is not provided', () => {
    const { container } = render(<CarInfo car={null} />);
    expect(container.firstChild).toBeNull();
  });
});
```

### Testing with User Events

```typescript
import userEvent from '@testing-library/user-event';

it('should call onChange when option is selected', async () => {
  const user = userEvent.setup();
  const onChange = vi.fn();

  render(<CarSelect value={null} onChange={onChange} />);

  const input = screen.getByLabelText('Vozidlo');
  await user.click(input);

  await waitFor(() => {
    expect(screen.getByRole('option', { name: 'ABC123' })).toBeInTheDocument();
  });

  await user.click(screen.getByRole('option', { name: 'ABC123' }));
  expect(onChange).toHaveBeenCalledWith('ABC123');
});
```

## Mocking Components

### Simple Component Mock

```typescript
vi.mock('~/components/CarStatusBadge', () => ({
  default: ({ status }: { status: string }) => (
    <div data-testid="car-status-badge">{status}</div>
  ),
}));
```

### Complex Component Mock with Props

```typescript
vi.mock('~/components/EditableSelectCell', () => ({
  default: ({
    children,
    value,
    options,
    onChange,
  }: {
    children: React.ReactNode;
    value: string;
    options: Array<{ id: string; label: string }>;
    onChange: (data: { valueName: string; value: string }) => void;
  }) => (
    <td data-testid="editable-select-cell" data-value={value}>
      {children}
      <select
        data-testid="status-select"
        value={value}
        onChange={(e) =>
          onChange({ value: e.target.value, valueName: 'status' })
        }
      >
        {options.map((opt) => (
          <option key={opt.id} value={opt.id}>
            {opt.label}
          </option>
        ))}
      </select>
    </td>
  ),
}));
```

## Querying Elements

### Preferred Queries (by priority)

1. **getByRole** - Best for accessibility
2. **getByLabelText** - Form inputs
3. **getByText** - Non-interactive content
4. **getByTestId** - Fallback when others don't work

```typescript
// By role (preferred)
screen.getByRole('button', { name: 'Submit' });
screen.getByRole('textbox', { name: 'Email' });
screen.getByRole('option', { name: 'Option 1' });

// By label (forms)
screen.getByLabelText('Vozidlo');

// By text
screen.getByText('Škoda Octavia');
screen.getByText(/error/i); // Case-insensitive regex

// By test ID (fallback)
screen.getByTestId('car-status-badge');
```

### Query Variants

```typescript
// Throws if not found (use for assertions)
screen.getByText('Hello');

// Returns null if not found (use for absence checks)
screen.queryByText('Hello');

// Returns promise, waits for element (use for async)
await screen.findByText('Hello');

// Get all matching elements
screen.getAllByRole('option');
```

## Async Testing

### Using waitFor

```typescript
it('should load and display data', async () => {
  render(<CarList />);

  await waitFor(() => {
    expect(screen.getByText('Škoda Octavia')).toBeInTheDocument();
  });
});
```

### Using findBy Queries

```typescript
it('should show error message', async () => {
  render(<CarSelect />);

  // findBy is equivalent to waitFor + getBy
  const error = await screen.findByText(/Network error/i);
  expect(error).toBeInTheDocument();
});
```

### Waiting for Element Removal

```typescript
import { waitForElementToBeRemoved } from '@testing-library/react';

it('should hide loading indicator', async () => {
  render(<CarList />);

  await waitForElementToBeRemoved(() => screen.queryByText('Loading...'));
  expect(screen.getByText('Results')).toBeInTheDocument();
});
```

## Testing Form Interactions

### Typing in Inputs

```typescript
it('should handle form input', async () => {
  const user = userEvent.setup();

  render(<SearchForm />);

  const input = screen.getByRole('textbox', { name: /search/i });
  await user.type(input, 'test query');

  expect(input).toHaveValue('test query');
});
```

### Selecting Options

```typescript
it('should handle select change', async () => {
  const user = userEvent.setup();

  render(<CarFilter />);

  const select = screen.getByRole('combobox');
  await user.selectOptions(select, 'active');

  expect(select).toHaveValue('active');
});
```

### Form Submission

```typescript
it('should submit form', async () => {
  const user = userEvent.setup();
  const onSubmit = vi.fn();

  render(<CarForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText('VIN'), 'ABC123');
  await user.click(screen.getByRole('button', { name: 'Save' }));

  expect(onSubmit).toHaveBeenCalledWith(
    expect.objectContaining({ vin: 'ABC123' }),
  );
});
```

## Testing Edge Cases

### Null/Undefined Handling

```typescript
describe('Null/Undefined Handling', () => {
  it('should display "-" for null engine volume', () => {
    const car = buildCar({ engineVolume: null });
    render(<CarInfo car={car} />);

    const cells = screen.getAllByRole('cell');
    const engineVolumeCell = cells.find(
      (cell) =>
        cell.previousElementSibling?.textContent?.includes('Objem motora'),
    );
    expect(engineVolumeCell).toHaveTextContent('-');
  });

  it('should handle empty array', async () => {
    const mocks = [
      buildQueryMock(GetCarsDocument, { data: { cars: [] } }),
    ];

    render(<CarSelect />, { mocks });

    await waitFor(() => {
      expect(screen.getByText(/No options/i)).toBeInTheDocument();
    });
  });
});
```

### Testing Table Structure

```typescript
it('should render table with correct structure', () => {
  render(<CarInfo car={car} />);

  const table = screen.getByRole('table', { name: 'car basic info table' });
  expect(table).toHaveAttribute('aria-label', 'car basic info table');

  const headerCells = screen.getAllByRole('rowheader');
  headerCells.forEach((header) => {
    expect(header).toHaveAttribute('scope', 'row');
  });
});
```

## Best Practices

### Do's

- Use `userEvent.setup()` for all user interactions
- Prefer `getByRole` for better accessibility testing
- Use `waitFor` for async assertions
- Test user-visible behavior, not implementation details
- Use descriptive test names that explain the expected behavior

### Don'ts

- Don't test implementation details (state, hooks internals)
- Don't use `container.querySelector` when queries exist
- Don't forget `await` with userEvent methods
- Don't use `act()` directly - Testing Library handles it
- Don't test library code (MUI, Apollo)
