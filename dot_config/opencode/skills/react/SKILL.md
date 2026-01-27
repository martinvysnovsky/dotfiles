---
name: react
description: React patterns for components, forms, and GraphQL integration with MUI and Apollo Client. Use when (1) creating React components, (2) implementing forms with validation, (3) integrating GraphQL queries/mutations, (4) working with MUI components, (5) managing component state, (6) handling route parameters, (7) implementing error/loading states, (8) optimizing component performance.
---

# React Patterns

## Quick Reference

**Components & UI:**
- **[components.md](references/components.md)** - Component structure, MUI patterns, routing, hooks, state management, performance optimization

**Forms:**
- **[forms.md](references/forms.md)** - Form elements, react-hook-form, Zod validation, dynamic arrays, error handling

**Data Fetching:**
- **[graphql.md](references/graphql.md)** - Apollo Client queries, mutations, subscriptions, cache management, fragments

## Core Component Structure

### Import Order
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
```

### Component Pattern
```typescript
// ✅ Good - Default export with PascalCase
interface CarCardProps {
  car: Car;
  onEdit: (carId: string) => void;
  onDelete: (carId: string) => void;
  showActions?: boolean;
}

export default function CarCard({ car, onEdit, onDelete }: CarCardProps) {
  const [isLoading, setIsLoading] = useState(false);

  return (
    <Card className="car-card">
      {/* Component JSX here */}
    </Card>
  );
}
```

## MUI Essential Patterns

### Grid2 Layout
```typescript
import { Grid2, Paper } from '@mui/material';

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
```

### Flex Values (Whole Numbers Only)
```typescript
// ✅ Good - Use whole numbers for flex
<Box sx={{ display: 'flex' }}>
  <Box sx={{ flex: 1 }}>Content 1</Box>
  <Box sx={{ flex: 2 }}>Content 2</Box>
</Box>

// ❌ Bad - Don't use decimals
<Box sx={{ flex: 0.8 }}>Content</Box>
```

### Links Pattern
```typescript
import { Link } from '@mui/material';

// ✅ Good - Always use MUI Link (works with React Router internally)
<Link href="/cars/123" color="primary">
  View Car Details
</Link>

// ❌ Bad - Don't use React Router Link directly
import { Link as RouterLink } from 'react-router-dom';
<RouterLink to="/cars">Cars</RouterLink>
```

## Basic Form Usage

### Use Form Components from `~/components/form/`
```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { TextFieldElement, DatePickerElement } from '~/components/form';

const carSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  price: z.number().min(0, 'Price must be positive'),
  registrationDate: z.date().nullable(),
});

type CarFormData = z.infer<typeof carSchema>;

export default function CarForm({ onSubmit }: CarFormProps) {
  const methods = useForm<CarFormData>({
    resolver: zodResolver(carSchema),
  });

  return (
    <form onSubmit={methods.handleSubmit(onSubmit)}>
      <TextFieldElement
        name="title"
        label="Car Title"
        required
        fullWidth
      />
      
      <TextFieldElement
        name="price"
        label="Price"
        type="number"
        fullWidth
      />
      
      <DatePickerElement
        name="registrationDate"
        label="Registration Date"
        format="DD.MM.YYYY"
      />
      
      <Button type="submit" variant="contained">
        Save
      </Button>
    </form>
  );
}
```

## Basic GraphQL

### Query Pattern
```typescript
import { useQuery } from '@apollo/client';
import { GET_CARS } from '~/graphql/cars.generated'; // Note: .generated extension

export default function CarList() {
  const { data, loading, error, refetch } = useQuery(GET_CARS);

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

## Loading and Error States

```typescript
import { Loading } from '~/components/Loading';
import { ErrorMessage } from '~/components/ErrorMessage';

// Loading pattern
if (loading) return <Loading />;

// Error pattern with retry
if (error) return <ErrorMessage error={error} onRetry={refetch} />;

// Empty state
if (cars.length === 0) {
  return <Alert severity="info">No cars found</Alert>;
}
```

## Route Patterns

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

### Navigation
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

## When to Load Reference Files

**Load components.md when:**
- Setting up component structure and props
- Working with MUI components (Grid2, Paper, DataGrid, tables)
- Implementing custom hooks
- Managing component state (useState, useContext)
- Optimizing performance (React.memo, virtual scrolling)
- Creating error boundaries
- Need compound component patterns

**Load forms.md when:**
- Building forms with TextFieldElement, DatePickerElement
- Setting up react-hook-form with Zod validation
- Implementing conditional fields
- Working with dynamic field arrays
- Handling form validation and errors
- Managing form state (isDirty, isSubmitting)

**Load graphql.md when:**
- Writing GraphQL queries and mutations
- Working with Apollo Client hooks (useQuery, useMutation)
- Implementing optimistic updates
- Managing Apollo cache (writeFragment, evict)
- Setting up subscriptions for real-time data
- Creating reusable fragments
- Handling GraphQL errors

Note: For React component testing patterns, see `/guides/testing/`.
