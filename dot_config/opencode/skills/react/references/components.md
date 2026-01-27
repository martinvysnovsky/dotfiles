# React Component Patterns

## Import Order and Component Structure

### Proper Import Organization
```typescript
// 1. React imports first
import { useState, useEffect } from 'react';

// 2. MUI imports
import { Button, Card, Typography, Grid2, Paper, Link } from '@mui/material';

// 3. @ imports (external packages)
import { useQuery, useMutation } from '@apollo/client';

// 4. ~ imports (app directory with alias)
import { Car, CarType } from '~/generated/graphql';
import { formatCurrency } from '~/utils/format';
import { Loading } from '~/components/Loading';
import { ErrorMessage } from '~/components/ErrorMessage';

// 5. Relative imports
import './CarCard.styles.css';
import { CarCardProps } from './CarCard.types';

// ✅ Good - Default export with PascalCase
export default function CarCard({ car, onEdit, onDelete }: CarCardProps) {
  const [isLoading, setIsLoading] = useState(false);

  return (
    <Card className="car-card">
      {/* Component JSX here */}
    </Card>
  );
}
```

### Props Interface Pattern
```typescript
// ✅ Good - Props interface with Props suffix
interface CarCardProps {
  car: Car;
  onEdit: (carId: string) => void;
  onDelete: (carId: string) => void;
  showActions?: boolean;
}

// ✅ Good - Route component props
interface CarDetailsProps {
  params: { carId: string };
}

export default function CarDetails({ params }: Route.ComponentProps) {
  // Use params directly instead of useParams()
  const { carId } = params;
  
  return <div>Car ID: {carId}</div>;
}
```

## Material-UI (MUI) Patterns

### Grid2 Layout
```typescript
import { Grid2, Paper, Box } from '@mui/material';

export default function CarLayout() {
  return (
    <Paper sx={{ p: 3 }}>
      <Grid2 container spacing={3}>
        <Grid2 xs={12} md={6}>
          <CarDetails />
        </Grid2>
        <Grid2 xs={12} md={6}>
          <CarImages />
        </Grid2>
        <Grid2 xs={12}>
          <CarDescription />
        </Grid2>
      </Grid2>
    </Paper>
  );
}
```

### Flex Values (Whole Numbers Only)
```typescript
// ✅ Good - Use whole numbers for flex
<Box sx={{ display: 'flex' }}>
  <Box sx={{ flex: 1 }}>Content 1</Box>
  <Box sx={{ flex: 2 }}>Content 2</Box>
  <Box sx={{ flex: 1 }}>Content 3</Box>
</Box>

// ❌ Bad - Don't use decimals
<Box sx={{ flex: 0.8 }}>Content</Box>
```

### Table Patterns
```typescript
import { DataGrid, GridColDef } from '@mui/x-data-grid';

// ✅ Good - Extract column definitions as constants
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
    valueFormatter: (value) => formatPrice(value), // Returns empty string for null
  },
  {
    field: 'registrationDate',
    headerName: 'Registration Date',
    minWidth: 100,
    ...dateColumn, // Use dateColumn for dates (shows "-" for null)
  },
];

export default function CarTable({ cars }: CarTableProps) {
  return (
    <DataGrid
      rows={cars}
      columns={CAR_COLUMNS}
      fullHeight // Use fullHeight for full-page tables
      // Don't use useMemo for static columns
    />
  );
}
```

### Links Pattern
```typescript
import { Link } from '@mui/material';

// ✅ Good - Always use MUI Link (works with React Router internally)
<Link href="/cars/123" color="primary">
  View Car Details
</Link>

<Link href="/cars" underline="hover">
  Back to Cars
</Link>

// ❌ Bad - Don't use React Router Link directly
import { Link as RouterLink } from 'react-router-dom';
<RouterLink to="/cars">Cars</RouterLink>
```

## React Router Patterns

### Route Components
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

### Navigation Patterns
```typescript
import { useNavigate } from 'react-router-dom';
import { Link } from '@mui/material';

export default function CarActions({ carId }: CarActionsProps) {
  const navigate = useNavigate();

  const handleEdit = () => {
    navigate(`/cars/${carId}/edit`);
  };

  return (
    <Box sx={{ display: 'flex', gap: 2 }}>
      <Button onClick={handleEdit} variant="outlined">
        Edit
      </Button>
      <Link href={`/cars/${carId}`} color="primary">
        View Details
      </Link>
    </Box>
  );
}
```

## Data Formatting Patterns

### Price Formatting
```typescript
// ✅ Good - Return empty string for null/undefined
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

### Date Column Pattern
```typescript
import { GridColDef } from '@mui/x-data-grid';

// ✅ Good - Use dateColumn for proper null handling
export const dateColumn: Partial<GridColDef> = {
  type: 'date',
  valueFormatter: (value: Date | null) => {
    if (!value || value.getTime() === 0) return '-';
    return format(value, 'dd.MM.yyyy');
  },
};

// Usage
const columns: GridColDef[] = [
  {
    field: 'registrationDate',
    headerName: 'Registration Date',
    minWidth: 100,
    ...dateColumn,
  },
];
```

## GraphQL Integration Patterns

### Query Pattern
```typescript
import { useQuery } from '@apollo/client';
import { GET_CARS } from '~/graphql/cars.generated'; // Note: .generated extension

export default function CarList() {
  const { data, loading, error } = useQuery(GET_CARS);

  if (loading) return <Loading />;
  if (error) return <ErrorMessage error={error} />;

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

### Mutation Pattern
```typescript
import { useMutation } from '@apollo/client';
import { CREATE_CAR, GET_CARS } from '~/graphql/cars.generated';

export default function CreateCarForm() {
  const [createCar, { loading, error }] = useMutation(CREATE_CAR, {
    refetchQueries: [{ query: GET_CARS }],
    onCompleted: () => {
      navigate('/cars');
    },
  });

  const handleSubmit = async (data: CarInput) => {
    await createCar({ variables: { input: data } });
  };

  if (error) return <ErrorMessage error={error} />;

  return (
    <CarForm 
      onSubmit={handleSubmit}
      loading={loading}
    />
  );
}
```

## Hook Patterns

### Custom Data Fetching Hook
```typescript
import { useState, useEffect } from 'react';
import { useQuery } from '@apollo/client';

import { GET_CARS_QUERY } from 'src/graphql/queries/cars';
import { Car, CarFilters } from 'src/generated/graphql';

interface UseCarListResult {
  cars: Car[];
  loading: boolean;
  error: Error | null;
  refetch: () => void;
  loadMore: () => void;
  hasMore: boolean;
}

export function useCarList(filters?: CarFilters): UseCarListResult {
  const [cars, setCars] = useState<Car[]>([]);
  const [hasMore, setHasMore] = useState(true);

  const { data, loading, error, refetch, fetchMore } = useQuery(GET_CARS_QUERY, {
    variables: { filters, first: 20 },
    notifyOnNetworkStatusChange: true,
  });

  useEffect(() => {
    if (data?.cars) {
      setCars(data.cars.edges.map(edge => edge.node));
      setHasMore(data.cars.pageInfo.hasNextPage);
    }
  }, [data]);

  const loadMore = async () => {
    if (!hasMore || loading) return;

    await fetchMore({
      variables: {
        after: data?.cars.pageInfo.endCursor,
      },
      updateQuery: (prev, { fetchMoreResult }) => {
        if (!fetchMoreResult?.cars) return prev;

        return {
          cars: {
            ...fetchMoreResult.cars,
            edges: [...prev.cars.edges, ...fetchMoreResult.cars.edges],
          },
        };
      },
    });
  };

  return {
    cars,
    loading,
    error,
    refetch,
    loadMore,
    hasMore,
  };
}
```

### Form Management Hook
```typescript
import { useState, useCallback } from 'react';

interface UseFormOptions<T> {
  initialValues: T;
  onSubmit: (values: T) => Promise<void>;
  validate?: (values: T) => Record<string, string>;
}

interface UseFormResult<T> {
  values: T;
  errors: Record<string, string>;
  isSubmitting: boolean;
  handleChange: (field: keyof T) => (value: any) => void;
  handleSubmit: (e: React.FormEvent) => Promise<void>;
  reset: () => void;
}

export function useForm<T extends Record<string, any>>({
  initialValues,
  onSubmit,
  validate,
}: UseFormOptions<T>): UseFormResult<T> {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = useCallback((field: keyof T) => (value: any) => {
    setValues(prev => ({ ...prev, [field]: value }));
    // Clear error when user starts typing
    if (errors[field as string]) {
      setErrors(prev => ({ ...prev, [field]: undefined }));
    }
  }, [errors]);

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validate if validation function provided
    if (validate) {
      const validationErrors = validate(values);
      if (Object.keys(validationErrors).length > 0) {
        setErrors(validationErrors);
        return;
      }
    }

    setIsSubmitting(true);
    try {
      await onSubmit(values);
      setValues(initialValues); // Reset form on successful submit
    } catch (error) {
      console.error('Form submission error:', error);
    } finally {
      setIsSubmitting(false);
    }
  }, [values, validate, onSubmit, initialValues]);

  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
    setIsSubmitting(false);
  }, [initialValues]);

  return {
    values,
    errors,
    isSubmitting,
    handleChange,
    handleSubmit,
    reset,
  };
}
```

## Component Organization Patterns

### Feature-Based Component
```typescript
// src/features/cars/components/CarList/CarList.tsx
import { useState } from 'react';

import { Grid, Pagination, Alert } from '@mui/material';

import { Car } from 'src/generated/graphql';

import { useCarList } from '../hooks/useCarList';
import { CarCard } from './CarCard/CarCard';
import { CarFilters } from './CarFilters/CarFilters';
import { CarListSkeleton } from './CarListSkeleton/CarListSkeleton';

import { CarListProps } from './CarList.types';

export function CarList({ initialFilters }: CarListProps) {
  const [filters, setFilters] = useState(initialFilters);
  const { cars, loading, error, refetch } = useCarList(filters);

  if (loading) return <CarListSkeleton />;
  if (error) return <Alert severity="error">Failed to load cars</Alert>;

  return (
    <div className="car-list">
      <CarFilters 
        filters={filters} 
        onChange={setFilters}
        onClear={() => setFilters({})}
      />
      
      <Grid container spacing={3}>
        {cars.map(car => (
          <Grid item xs={12} sm={6} md={4} key={car.id}>
            <CarCard 
              car={car}
              onEdit={() => handleEdit(car.id)}
              onDelete={() => handleDelete(car.id)}
            />
          </Grid>
        ))}
      </Grid>

      {cars.length === 0 && (
        <Alert severity="info">No cars found matching your criteria</Alert>
      )}
    </div>
  );
}
```

### Compound Component Pattern
```typescript
// CarCard compound component
export function CarCard({ children, car }: CarCardProps) {
  return (
    <Card className="car-card">
      {children}
    </Card>
  );
}

// Sub-components
CarCard.Header = function CarCardHeader({ car }: { car: Car }) {
  return (
    <CardHeader
      title={car.title}
      subheader={`${car.year} • ${car.manufacturer}`}
    />
  );
};

CarCard.Image = function CarCardImage({ car }: { car: Car }) {
  return (
    <CardMedia
      component="img"
      height="200"
      image={car.mainImageUrl || '/placeholder-car.jpg'}
      alt={car.title}
    />
  );
};

CarCard.Content = function CarCardContent({ car }: { car: Car }) {
  return (
    <CardContent>
      <Typography variant="h6" color="primary">
        {formatCurrency(car.price)}
      </Typography>
      <Typography variant="body2" color="text.secondary">
        {car.description}
      </Typography>
    </CardContent>
  );
};

CarCard.Actions = function CarCardActions({ 
  onEdit, 
  onDelete 
}: { 
  onEdit: () => void; 
  onDelete: () => void; 
}) {
  return (
    <CardActions>
      <Button size="small" onClick={onEdit}>
        Edit
      </Button>
      <Button size="small" color="error" onClick={onDelete}>
        Delete
      </Button>
    </CardActions>
  );
};

// Usage
<CarCard car={car}>
  <CarCard.Header car={car} />
  <CarCard.Image car={car} />
  <CarCard.Content car={car} />
  <CarCard.Actions onEdit={handleEdit} onDelete={handleDelete} />
</CarCard>
```

## State Management Patterns

### Local State with useState
```typescript
function CarForm({ car, onSubmit }: CarFormProps) {
  const [formData, setFormData] = useState({
    title: car?.title || '',
    price: car?.price || 0,
    manufacturer: car?.manufacturer || '',
    year: car?.year || new Date().getFullYear(),
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleInputChange = (field: string) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const value = event.target.type === 'number' 
      ? Number(event.target.value) 
      : event.target.value;
      
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.title.trim()) {
      newErrors.title = 'Title is required';
    }

    if (formData.price <= 0) {
      newErrors.price = 'Price must be greater than 0';
    }

    if (formData.year < 1900 || formData.year > new Date().getFullYear() + 1) {
      newErrors.year = 'Please enter a valid year';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    setIsSubmitting(true);
    try {
      await onSubmit(formData);
    } catch (error) {
      console.error('Form submission failed:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
    </form>
  );
}
```

### Context for Component Tree State
```typescript
// CarListContext.tsx
interface CarListContextValue {
  cars: Car[];
  filters: CarFilters;
  selectedCars: string[];
  setFilters: (filters: CarFilters) => void;
  selectCar: (carId: string) => void;
  deselectCar: (carId: string) => void;
  clearSelection: () => void;
}

const CarListContext = createContext<CarListContextValue | null>(null);

export function CarListProvider({ children }: { children: React.ReactNode }) {
  const [filters, setFilters] = useState<CarFilters>({});
  const [selectedCars, setSelectedCars] = useState<string[]>([]);
  const { cars } = useCarList(filters);

  const selectCar = (carId: string) => {
    setSelectedCars(prev => [...prev, carId]);
  };

  const deselectCar = (carId: string) => {
    setSelectedCars(prev => prev.filter(id => id !== carId));
  };

  const clearSelection = () => {
    setSelectedCars([]);
  };

  const value = {
    cars,
    filters,
    selectedCars,
    setFilters,
    selectCar,
    deselectCar,
    clearSelection,
  };

  return (
    <CarListContext.Provider value={value}>
      {children}
    </CarListContext.Provider>
  );
}

export function useCarListContext() {
  const context = useContext(CarListContext);
  if (!context) {
    throw new Error('useCarListContext must be used within CarListProvider');
  }
  return context;
}
```

## Performance Optimization Patterns

### Memoization with React.memo
```typescript
interface CarCardProps {
  car: Car;
  onEdit: (carId: string) => void;
  onDelete: (carId: string) => void;
  isSelected?: boolean;
}

export const CarCard = React.memo<CarCardProps>(({ 
  car, 
  onEdit, 
  onDelete, 
  isSelected 
}) => {
  const handleEdit = useCallback(() => {
    onEdit(car.id);
  }, [car.id, onEdit]);

  const handleDelete = useCallback(() => {
    onDelete(car.id);
  }, [car.id, onDelete]);

  return (
    <Card className={`car-card ${isSelected ? 'selected' : ''}`}>
      <CardHeader title={car.title} />
      <CardContent>
        <Typography variant="h6">
          {formatCurrency(car.price)}
        </Typography>
      </CardContent>
      <CardActions>
        <Button onClick={handleEdit}>Edit</Button>
        <Button onClick={handleDelete}>Delete</Button>
      </CardActions>
    </Card>
  );
}, (prevProps, nextProps) => {
  // Custom comparison function
  return (
    prevProps.car.id === nextProps.car.id &&
    prevProps.car.title === nextProps.car.title &&
    prevProps.car.price === nextProps.car.price &&
    prevProps.isSelected === nextProps.isSelected
  );
});

CarCard.displayName = 'CarCard';
```

### Virtual Scrolling for Large Lists
```typescript
import { FixedSizeList as List } from 'react-window';

interface VirtualCarListProps {
  cars: Car[];
  onEditCar: (carId: string) => void;
  onDeleteCar: (carId: string) => void;
}

const CarListItem = ({ index, style, data }: ListChildComponentProps) => {
  const { cars, onEditCar, onDeleteCar } = data;
  const car = cars[index];

  return (
    <div style={style}>
      <CarCard 
        car={car}
        onEdit={onEditCar}
        onDelete={onDeleteCar}
      />
    </div>
  );
};

export function VirtualCarList({ 
  cars, 
  onEditCar, 
  onDeleteCar 
}: VirtualCarListProps) {
  const itemData = {
    cars,
    onEditCar,
    onDeleteCar,
  };

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

## Error Boundary Pattern

```typescript
interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

export class CarListErrorBoundary extends Component<
  { children: React.ReactNode; fallback?: React.ComponentType<{ error: Error }> },
  ErrorBoundaryState
> {
  constructor(props: any) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('CarList error boundary caught an error:', error, errorInfo);
    // You could also log this to an error reporting service
  }

  render() {
    if (this.state.hasError) {
      const FallbackComponent = this.props.fallback || DefaultErrorFallback;
      return <FallbackComponent error={this.state.error!} />;
    }

    return this.props.children;
  }
}

function DefaultErrorFallback({ error }: { error: Error }) {
  return (
    <Alert severity="error">
      <AlertTitle>Something went wrong</AlertTitle>
      <Typography variant="body2">
        {error.message}
      </Typography>
      <Button 
        variant="contained" 
        onClick={() => window.location.reload()}
        sx={{ mt: 2 }}
      >
        Reload Page
      </Button>
    </Alert>
  );
}

// Usage
<CarListErrorBoundary>
  <CarList />
</CarListErrorBoundary>
```


For React component testing patterns, see `/guides/testing/`.
