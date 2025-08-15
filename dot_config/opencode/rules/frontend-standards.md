# Frontend Development Standards

## React Component Standards

### Component Structure and Naming

#### File Naming and Organization
- **kebab-case** for all file names with descriptive suffixes
- `.tsx` for React components
- `.test.tsx` for unit tests
- `.stories.tsx` for Storybook stories
- **PascalCase** for component names
- **Default exports** for all components

```typescript
// ✅ Good - Default export with PascalCase
export default function CarCard({ car, onEdit, onDelete }: CarCardProps) {
  return <Card>...</Card>;
}

// ❌ Bad - Named export
export function CarCard() { ... }
```

#### Props Interface Pattern
- Use `Props` suffix for interface names (e.g., `CarDetailsProps`)
- Define props interfaces before component definition
- Use optional props with default values when appropriate

```typescript
interface CarCardProps {
  car: Car;
  onEdit: (carId: string) => void;
  onDelete: (carId: string) => void;
  showActions?: boolean;
}

export default function CarCard({ car, onEdit, onDelete, showActions = true }: CarCardProps) {
  // Component implementation
}
```

### Import Organization

Follow this strict import order for all React/frontend files:

1. **React imports** (e.g., `react`, hooks)
2. **MUI imports** (e.g., `@mui/material`, `@mui/icons-material`)
3. **Third-party packages** (e.g., `@apollo/client`, external libraries)
4. **App directory imports with ~ alias** (e.g., `~/generated/graphql`, `~/utils/format`)
5. **Relative imports** (e.g., `./`, `../`)

```typescript
// 1. React imports first
import { useState, useEffect, useCallback } from 'react';

// 2. MUI imports
import { Button, Card, Typography, Grid2, Paper, Link } from '@mui/material';
import { Edit, Delete } from '@mui/icons-material';

// 3. Third-party packages
import { useQuery, useMutation } from '@apollo/client';

// 4. App directory with alias (auto-sorted alphabetically)
import { Car, CarType } from '~/generated/graphql';
import { formatCurrency } from '~/utils/format';
import { Loading } from '~/components/Loading';
import { ErrorMessage } from '~/components/ErrorMessage';

// 5. Relative imports
import './CarCard.styles.css';
import { CarCardProps } from './CarCard.types';
```

### Component Architecture

#### Functional Components with Hooks
- Use functional components with hooks over class components
- Keep components small and focused on single responsibility
- Extract custom hooks for reusable stateful logic

```typescript
export default function CarList({ filters }: CarListProps) {
  // Hooks at the top
  const [selectedCars, setSelectedCars] = useState<string[]>([]);
  const { data, loading, error } = useCarListQuery(filters);
  
  // Event handlers
  const handleCarSelect = useCallback((carId: string) => {
    setSelectedCars(prev => [...prev, carId]);
  }, []);
  
  // Early returns for loading/error states
  if (loading) return <Loading />;
  if (error) return <ErrorMessage error={error} />;
  
  // Main render
  return (
    <Grid2 container spacing={2}>
      {data?.cars?.map(car => (
        <Grid2 xs={12} md={6} key={car.id}>
          <CarCard car={car} onSelect={handleCarSelect} />
        </Grid2>
      ))}
    </Grid2>
  );
}
```

## React Router Standards

### Route Components
- **Prefer route arguments over useParams hook** in route components
- Use `Route.ComponentProps` interface for route components
- Pattern: `function Component({ params }: Route.ComponentProps)`

```typescript
// ✅ Good - Use route arguments
export default function CarDetails({ params }: Route.ComponentProps) {
  const { carId } = params;
  
  const { data: car } = useQuery(GET_CAR_QUERY, {
    variables: { id: carId }
  });

  return <div>{car?.title}</div>;
}

// ✅ Also good - useParams in non-route components
function CarStatusBadge() {
  const params = useParams<{ carId: string }>();
  const carId = params.carId;
  
  return <Badge carId={carId} />;
}
```

### Navigation and Links
- **Always use MUI Link component** instead of React Router Link directly
- MUI Link works with React Router internally
- Use `useNavigate` for programmatic navigation

```typescript
import { Link } from '@mui/material';
import { useNavigate } from 'react-router-dom';

// ✅ Good - MUI Link
<Link href="/cars/123" color="primary">
  View Car Details
</Link>

// ✅ Good - Programmatic navigation
const navigate = useNavigate();
const handleEdit = () => navigate(`/cars/${carId}/edit`);

// ❌ Bad - Don't use React Router Link directly
import { Link as RouterLink } from 'react-router-dom';
<RouterLink to="/cars">Cars</RouterLink>
```

## Material-UI (MUI) Standards

### Grid System
- **Use Grid2 syntax** for all layouts
- Use **Paper** for containers
- Use **whole numbers only** for flex values (never decimals)

```typescript
// ✅ Good - Grid2 with whole numbers
<Paper sx={{ p: 3 }}>
  <Grid2 container spacing={3}>
    <Grid2 xs={12} md={6}>
      <CarDetails />
    </Grid2>
    <Grid2 xs={12} md={6}>
      <CarImages />
    </Grid2>
  </Grid2>
</Paper>

// ✅ Good - Flex with whole numbers
<Box sx={{ display: 'flex' }}>
  <Box sx={{ flex: 1 }}>Content 1</Box>
  <Box sx={{ flex: 2 }}>Content 2</Box>
</Box>

// ❌ Bad - Don't use decimals
<Box sx={{ flex: 0.8 }}>Content</Box>
```

### Table Standards
- **Always add `minWidth`** for proper column display
- **Extract column definitions as constants** outside components
- Use **`fullHeight`** for full-page tables

```typescript
// ✅ Good - Column definitions with minWidth
const CAR_COLUMNS: GridColDef[] = [
  {
    field: 'title',
    headerName: 'Title',
    minWidth: 200, // Always add minWidth
    flex: 1,
  },
  {
    field: 'price',
    headerName: 'Price',
    minWidth: 100,
    valueFormatter: (value) => formatPrice(value),
  },
  {
    field: 'registrationDate',
    headerName: 'Registration Date',
    minWidth: 100,
    ...dateColumn, // Use dateColumn for dates
  },
];
```

### Sizing Guidelines
- **Column widths**: dates (100px), prices (100px), text (120px), names (200px)
- **Table height**: Use `fullHeight` for full-page tables
- **Spacing**: Use consistent spacing values (1, 2, 3, etc.)

## GraphQL Client Standards

### Query Naming Convention
- **NO "Query" suffix** in GraphQL query names
- Use descriptive, clean names that describe the data being fetched

```graphql
# ✅ Good - Clean query names
query Cars($filters: CarFilters) {
  cars(filters: $filters) {
    id
    title
    price
  }
}

query CarDetails($id: ID!) {
  car(id: $id) {
    id
    title
    description
  }
}

# ❌ Bad - Don't add "Query" suffix
query CarsQuery { ... }
query CarDetailsQuery { ... }
```

### File Structure and Code Generation
- Use **`.generated.ts`** files for generated types and hooks
- Import from generated files, not raw GraphQL files
- Use Apollo Client's code generation for type safety

```typescript
// ✅ Good - Import from generated files
import { 
  Car, 
  useCarsQuery,
  useCreateCarMutation 
} from '~/graphql/cars.generated';

// File structure:
// app/graphql/
// ├── cars.graphql          # GraphQL operations
// ├── cars.generated.ts     # Generated types and hooks
// ├── schema.generated.ts   # Generated schema types
```

### Query Patterns
- Use **generated hooks** from codegen
- Handle loading and error states consistently
- Use **ErrorMessage component** for GraphQL errors

```typescript
export default function CarList() {
  const { data, loading, error, refetch } = useCarsQuery();

  if (loading) return <Loading />;
  if (error) return <ErrorMessage error={error} onRetry={refetch} />;

  return (
    <Grid2 container spacing={2}>
      {data?.cars?.map(car => (
        <Grid2 xs={12} md={6} key={car.id}>
          <CarCard car={car} />
        </Grid2>
      ))}
    </Grid2>
  );
}
```

### Mutation Patterns
- Use **optimistic updates** for better UX
- Update cache properly after mutations
- Handle errors with proper feedback

```typescript
const [createCar, { loading, error }] = useCreateCarMutation({
  refetchQueries: [{ query: CarsDocument }],
  optimisticResponse: (variables) => ({
    createCar: {
      __typename: 'Car',
      id: 'temp-id',
      ...variables.input,
    }
  }),
  onCompleted: () => navigate('/cars'),
});
```

### Error Handling
- Use **ErrorMessage component** for GraphQL errors
- Handle network errors and validation errors separately
- Provide retry functionality where appropriate

```typescript
// ✅ Good - Use ErrorMessage component
if (error) return <ErrorMessage error={error} onRetry={refetch} />;

// ✅ Good - Handle specific error types in mutations
onError: (error) => {
  if (error.networkError) {
    toast.error('Network error - please check your connection');
  } else if (error.graphQLErrors.length > 0) {
    // Handle validation errors in form
  }
}
```

## Form Handling Standards

### React Hook Form Integration
- Use **form components from `~/components/form/`** instead of raw MUI
- Components automatically integrate with react-hook-form
- Use **Zod schemas** for validation

```typescript
// ✅ Good - Use form components
import { TextFieldElement, DatePickerElement } from '~/components/form';

<TextFieldElement
  name="title"
  label="Car Title"
  required
  fullWidth
/>

// ❌ Bad - Don't use raw MUI with manual register
<TextField
  {...register('title')}
  label="Car Title"
  error={!!errors.title}
  helperText={errors.title?.message}
/>
```

### Form Structure Pattern
```typescript
const carSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  price: z.number().min(0, 'Price must be positive'),
  registrationDate: z.date().nullable(),
});

type CarFormData = z.infer<typeof carSchema>;

export default function CarForm({ car, onSubmit }: CarFormProps) {
  const methods = useForm<CarFormData>({
    resolver: zodResolver(carSchema),
    defaultValues: car || {},
  });

  const handleSubmit = methods.handleSubmit(async (data) => {
    await onSubmit(data);
  });

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit}>
        <Grid2 container spacing={3}>
          <Grid2 xs={12} md={6}>
            <TextFieldElement name="title" label="Title" required fullWidth />
          </Grid2>
          <Grid2 xs={12} md={6}>
            <DatePickerElement name="registrationDate" label="Registration Date" />
          </Grid2>
        </Grid2>
      </form>
    </FormProvider>
  );
}
```

### Validation Standards
- Use **Zod schemas** for form validation
- Provide clear, descriptive error messages
- Handle server-side validation errors

```typescript
const carSchema = z.object({
  title: z.string().min(1, 'Title is required').max(100, 'Title too long'),
  vin: z.string()
    .length(17, 'VIN must be exactly 17 characters')
    .regex(/^[A-HJ-NPR-Z0-9]{17}$/, 'Invalid VIN format'),
  email: z.string().email('Invalid email format').optional().or(z.literal('')),
});
```

## Performance Optimization Standards

### Memoization
- Use **React.memo** for expensive component renders
- Use **useMemo** for expensive calculations
- Use **useCallback** for stable function references

```typescript
// Component memoization
export const CarCard = React.memo<CarCardProps>(({ car, onEdit, onDelete }) => {
  const handleEdit = useCallback(() => onEdit(car.id), [car.id, onEdit]);
  const handleDelete = useCallback(() => onDelete(car.id), [car.id, onDelete]);

  return <Card>...</Card>;
});

// Custom comparison for complex props
export const CarCard = React.memo(Component, (prevProps, nextProps) => {
  return (
    prevProps.car.id === nextProps.car.id &&
    prevProps.car.title === nextProps.car.title
  );
});
```

### Avoiding Re-renders
- Split components to minimize re-render scope
- Use proper dependency arrays in hooks
- Avoid creating objects/functions in render

```typescript
// ✅ Good - Stable references
const handleClick = useCallback(() => {
  onClick(id);
}, [onClick, id]);

const memoizedValue = useMemo(() => {
  return expensiveCalculation(data);
}, [data]);

// ❌ Bad - Creates new function on every render
<Button onClick={() => onClick(id)}>Click</Button>
```

### Virtual Scrolling
- Use **react-window** for large lists (1000+ items)
- Implement proper item sizing and caching

```typescript
import { FixedSizeList as List } from 'react-window';

export function VirtualCarList({ cars }: VirtualCarListProps) {
  const itemData = { cars, onEditCar, onDeleteCar };

  return (
    <List
      height={600}
      itemCount={cars.length}
      itemSize={200}
      itemData={itemData}
    >
      {CarListItem}
    </List>
  );
}
```

## Data Formatting Standards

### Price Formatting
- **Return empty string for null/undefined** values
- Use consistent currency formatting

```typescript
// ✅ Good - Return empty string for null
export function formatPrice(price: number | null | undefined): string {
  if (price == null) return '';
  return new Intl.NumberFormat('sk-SK', {
    style: 'currency',
    currency: 'EUR'
  }).format(price);
}

// Usage in components
<Typography variant="h6">
  {formatPrice(car.price)}
</Typography>
```

### Date Formatting
- Use **dateColumn** for proper null date display in tables
- Shows "-" for null dates instead of invalid date strings

```typescript
// ✅ Good - Use dateColumn for tables
export const dateColumn: Partial<GridColDef> = {
  type: 'date',
  valueFormatter: (value: Date | null) => {
    if (!value || value.getTime() === 0) return '-';
    return format(value, 'dd.MM.yyyy');
  },
};

// Usage in column definitions
{
  field: 'registrationDate',
  headerName: 'Registration Date',
  minWidth: 100,
  ...dateColumn,
}
```

## Error Handling Standards

### Component Error Boundaries
- Implement error boundaries for component trees
- Provide fallback UI for error states
- Log errors for debugging

```typescript
export class CarListErrorBoundary extends Component {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('CarList error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <DefaultErrorFallback error={this.state.error} />;
    }
    return this.props.children;
  }
}
```

### Loading States
- Show appropriate loading indicators
- Use skeleton screens for better perceived performance
- Handle loading states consistently

```typescript
const [data, setData] = useState(null);
const [isLoading, setIsLoading] = useState(true);
const [error, setError] = useState(null);

// Early returns for states
if (isLoading) return <CarListSkeleton />;
if (error) return <ErrorMessage error={error} />;
if (!data?.cars?.length) return <EmptyState />;
```

## Testing Standards

### Component Testing
- Use **Testing Library** for React component tests
- Test user interactions, not implementation details
- Use proper assertions and meaningful test descriptions

```typescript
describe('CarCard', () => {
  it('renders car information correctly', () => {
    render(<CarCard car={mockCar} onEdit={vi.fn()} onDelete={vi.fn()} />);
    
    expect(screen.getByText('BMW X5')).toBeInTheDocument();
    expect(screen.getByText('€50,000')).toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', async () => {
    const user = userEvent.setup();
    const onEdit = vi.fn();
    
    render(<CarCard car={mockCar} onEdit={onEdit} onDelete={vi.fn()} />);
    
    await user.click(screen.getByRole('button', { name: /edit/i }));
    
    expect(onEdit).toHaveBeenCalledWith('car-123');
  });
});
```

### GraphQL Testing
- Use **MockedProvider** for Apollo Client testing
- Mock GraphQL operations with realistic data
- Test loading, error, and success states

```typescript
const mocks = [
  {
    request: { query: GET_CARS_QUERY },
    result: { data: { cars: [mockCar] } },
  },
];

test('displays cars from GraphQL query', async () => {
  render(
    <MockedProvider mocks={mocks}>
      <CarList />
    </MockedProvider>
  );

  await waitFor(() => {
    expect(screen.getByText('BMW X5')).toBeInTheDocument();
  });
});
```

## Build Commands and Tooling

### Frontend-Specific Scripts
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "typecheck": "tsc --noEmit",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build",
    "graphql:generate": "graphql-codegen --config codegen.ts",
    "graphql:watch": "graphql-codegen --config codegen.ts --watch"
  }
}
```

### Development Tools Configuration
- **ESLint**: Use React and TypeScript presets with strict rules
- **Prettier**: Enforce consistent code formatting
- **TypeScript**: Strict mode enabled with proper path mapping
- **Vite**: Fast build tool with HMR for development

### GraphQL Codegen Setup
```typescript
// codegen.ts
import type { CodegenConfig } from '@graphql-codegen/cli';

const config: CodegenConfig = {
  schema: 'http://localhost:3000/graphql',
  documents: ['app/**/*.graphql'],
  generates: {
    'app/generated/': {
      preset: 'client',
      config: {
        useTypeImports: true,
      },
    },
    'app/graphql/': {
      preset: 'near-operation-file',
      presetConfig: {
        extension: '.generated.ts',
        baseTypesPath: '~/generated/graphql.ts',
      },
      plugins: ['typescript-react-apollo'],
    },
  },
};
```

## File Organization Standards

### Project Structure
```
app/
├── components/           # Reusable UI components
│   ├── form/            # Form elements (TextFieldElement, etc.)
│   ├── Loading/         # Loading components
│   └── ErrorMessage/    # Error handling components
├── features/            # Feature-specific components
│   ├── cars/
│   │   ├── components/  # Car-specific components
│   │   ├── hooks/       # Car-specific hooks
│   │   └── types/       # Car-specific types
├── graphql/             # GraphQL operations and generated files
│   ├── cars.graphql
│   ├── cars.generated.ts
│   └── schema.generated.ts
├── utils/               # Utility functions
│   ├── format.ts        # Formatting functions
│   └── validation.ts    # Validation schemas
└── types/               # Global type definitions
```

### Custom Hooks Organization
- Extract reusable logic into custom hooks
- Use descriptive names starting with "use"
- Return objects for multiple values, arrays for ordered pairs

```typescript
// Custom hook example
interface UseCarListResult {
  cars: Car[];
  loading: boolean;
  error: Error | null;
  refetch: () => void;
  loadMore: () => void;
  hasMore: boolean;
}

export function useCarList(filters?: CarFilters): UseCarListResult {
  // Hook implementation
  return { cars, loading, error, refetch, loadMore, hasMore };
}
```

## Implementation Examples

For detailed implementation examples and patterns, see:

- **Component patterns**: `/guides/react/component-patterns.md`
- **Form handling**: `/guides/react/form-patterns.md`
- **GraphQL integration**: `/guides/react/graphql-patterns.md`
- **Testing patterns**: `/guides/testing/` directory
- **Error handling**: `/guides/error-handling/` directory

## Project Configuration

### No React Imports Required
- JSX transform is enabled - no need to import React in components
- TypeScript strict mode with proper path aliases (`~/*` for app directory)
- All application code should be under `app/` directory

### Path Aliases
- Use `~/*` for app directory imports
- Enables clean imports and better refactoring
- Configured in both TypeScript and build tools

```typescript
// ✅ Good - Use path aliases
import { Car } from '~/generated/graphql';
import { formatPrice } from '~/utils/format';

// ❌ Bad - Relative paths for app code
import { Car } from '../../../generated/graphql';
```