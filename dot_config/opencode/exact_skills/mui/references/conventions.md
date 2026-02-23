# Team MUI Conventions

## Contents
- Import order
- Link patterns
- Flex value rules
- Form components
- Loading and error states
- Navigation patterns
- Common anti-patterns

## Import Order

Always follow this order in React components:

```typescript
// 1. React imports first
import { useState, useEffect } from 'react';

// 2. MUI imports
import { Button, Card, Typography, Grid, Paper, Link } from '@mui/material';
import { DataGridPro, GridColDef } from '@mui/x-data-grid-pro';
import { DatePicker } from '@mui/x-date-pickers-pro';
import { Add, Delete, Edit } from '@mui/icons-material';

// 3. @ imports (external packages)
import { useQuery, useMutation } from '@apollo/client';
import { useForm } from 'react-hook-form';

// 4. ~ imports (app directory with alias)
import { Car, CarType } from '~/generated/graphql';
import { formatCurrency } from '~/utils/format';
import { Loading } from '~/components/Loading';
import { ErrorMessage } from '~/components/ErrorMessage';

// 5. Relative imports
import './CarCard.styles.css';
import { CarCardProps } from './CarCard.types';
```

## Link Patterns

Always use MUI `Link` component. Never use React Router's `Link` directly.

```typescript
import { Link } from '@mui/material';

// ✅ Good - MUI Link (integrates with React Router internally)
<Link href="/cars/123" color="primary">
  View Car Details
</Link>

<Link href="/cars" underline="hover">
  Back to Cars
</Link>

// ✅ Good - Link in table cells
<Link href={`/cars/${row.id}`} color="primary" underline="hover">
  {row.title}
</Link>

// ❌ Bad - React Router Link directly
import { Link as RouterLink } from 'react-router-dom';
<RouterLink to="/cars">Cars</RouterLink>

// ❌ Bad - Anchor tag
<a href="/cars">Cars</a>
```

## Flex Value Rules

Always use whole numbers for flex values. No decimals.

```typescript
// ✅ Good - Whole numbers
<Box sx={{ display: 'flex' }}>
  <Box sx={{ flex: 1 }}>Content 1</Box>
  <Box sx={{ flex: 2 }}>Content 2</Box>
  <Box sx={{ flex: 1 }}>Content 3</Box>
</Box>

// ❌ Bad - Decimal flex values
<Box sx={{ flex: 0.8 }}>Content</Box>
<Box sx={{ flex: 1.5 }}>Content</Box>
```

## Form Components

Always use form element components from `~/components/form/` for forms with react-hook-form. These components auto-integrate with react-hook-form and handle Zod validation errors.

### Available Form Components

```typescript
import {
  TextFieldElement,
  DatePickerElement,
  SelectElement,
  // Other form elements from ~/components/form/
} from '~/components/form';
```

### TextFieldElement (not raw TextField)

```typescript
// ✅ Good - TextFieldElement with react-hook-form
<TextFieldElement
  name="title"
  label="Car Title"
  required
  fullWidth
/>

// ✅ Good - Number input
<TextFieldElement
  name="price"
  label="Price"
  type="number"
  fullWidth
  InputProps={{
    startAdornment: <InputAdornment position="start">€</InputAdornment>,
  }}
/>

// ✅ Good - Multiline
<TextFieldElement
  name="description"
  label="Description"
  multiline
  rows={4}
  fullWidth
/>

// ❌ Bad - Raw TextField with manual register
<TextField
  {...register('title')}
  label="Car Title"
  error={!!errors.title}
  helperText={errors.title?.message}
/>
```

### DatePickerElement (not raw DatePicker)

```typescript
// ✅ Good - DatePickerElement
<DatePickerElement
  name="registrationDate"
  label="Registration Date"
  format="DD.MM.YYYY"
/>

// ✅ Good - Month/year picker
<DatePickerElement
  name="productionDate"
  label="Production Month"
  format="MM/YYYY"
  openTo="month"
  views={['year', 'month']}
/>

// ✅ Good - With constraints
<DatePickerElement
  name="purchaseDate"
  label="Purchase Date"
  minDate={new Date('2020-01-01')}
  maxDate={new Date()}
  disableFuture
/>

// ❌ Bad - Raw DatePicker with manual value/onChange
<DatePicker
  value={value}
  onChange={onChange}
  label="Registration Date"
/>
```

### Form Layout Pattern

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Box, Button, Grid, Paper } from '@mui/material';
import { TextFieldElement, DatePickerElement } from '~/components/form';

const carSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  price: z.number().min(0, 'Price must be positive'),
  registrationDate: z.date().nullable(),
});

type CarFormData = z.infer<typeof carSchema>;

export default function CarForm({ car, onSubmit }: CarFormProps) {
  const methods = useForm<CarFormData>({
    resolver: zodResolver(carSchema),
    defaultValues: {
      title: car?.title || '',
      price: car?.price || 0,
      registrationDate: car?.registrationDate || null,
    },
  });

  return (
    <Paper sx={{ p: 3 }}>
      <form onSubmit={methods.handleSubmit(onSubmit)}>
        <Grid container spacing={3}>
          <Grid size={{ xs: 12, md: 6 }}>
            <TextFieldElement name="title" label="Car Title" required fullWidth />
          </Grid>
          <Grid size={{ xs: 12, md: 6 }}>
            <TextFieldElement name="price" label="Price" type="number" required fullWidth />
          </Grid>
          <Grid size={{ xs: 12, md: 6 }}>
            <DatePickerElement name="registrationDate" label="Registration Date" format="DD.MM.YYYY" />
          </Grid>
          <Grid size={12}>
            <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
              <Button type="button" variant="outlined">Cancel</Button>
              <Button type="submit" variant="contained" disabled={methods.formState.isSubmitting}>
                {methods.formState.isSubmitting ? 'Saving...' : 'Save'}
              </Button>
            </Box>
          </Grid>
        </Grid>
      </form>
    </Paper>
  );
}
```

## Loading and Error States

Use project-level Loading and ErrorMessage components consistently.

```typescript
import { Loading } from '~/components/Loading';
import { ErrorMessage } from '~/components/ErrorMessage';
import { Alert } from '@mui/material';

// Loading state
if (loading) return <Loading />;

// Error state with retry
if (error) return <ErrorMessage error={error} onRetry={refetch} />;

// Empty state
if (cars.length === 0) {
  return <Alert severity="info">No cars found</Alert>;
}
```

## Navigation Patterns

```typescript
import { useNavigate } from 'react-router-dom';
import { Link, Button, Box } from '@mui/material';

export default function CarActions({ carId }: { carId: string }) {
  const navigate = useNavigate();

  // ✅ Programmatic navigation for actions
  const handleEdit = () => navigate(`/cars/${carId}/edit`);

  // ✅ MUI Link for hyperlinks
  return (
    <Box sx={{ display: 'flex', gap: 2 }}>
      <Button onClick={handleEdit} variant="outlined">Edit</Button>
      <Link href={`/cars/${carId}`} color="primary">View Details</Link>
    </Box>
  );
}
```

### Route Components

```typescript
// ✅ Good - Use Route.ComponentProps for route components
export default function CarDetails({ params }: Route.ComponentProps) {
  const { carId } = params;
  return <div>Car ID: {carId}</div>;
}

// ✅ Good - useParams in non-route components
import { useParams } from 'react-router-dom';

function CarStatusBadge() {
  const { carId } = useParams<{ carId: string }>();
  return <Badge carId={carId} />;
}
```

## Common Anti-Patterns

### Layout
```typescript
// ❌ Grid2 (deprecated in v7)
import { Grid2 } from '@mui/material';

// ❌ GridLegacy
import { Grid } from '@mui/material'; // with xs, sm, md props directly
<Grid item xs={12} md={6}>  // "item" prop is legacy

// ❌ Grid with direction="column"
<Grid container direction="column">  // Use Stack instead

// ✅ Correct
import { Grid, Stack } from '@mui/material';
<Grid container spacing={2}>
  <Grid size={{ xs: 12, md: 6 }}>Content</Grid>
</Grid>
<Stack spacing={2}>
  <Item>Row 1</Item>
  <Item>Row 2</Item>
</Stack>
```

### Styling
```typescript
// ❌ Inline styles
<Box style={{ padding: 16 }}>

// ❌ Targeting state class alone
'& .Mui-disabled': { opacity: 0.5 }

// ✅ sx prop with theme values
<Box sx={{ p: 2 }}>

// ✅ State class with component class
'& .MuiButton-root.Mui-disabled': { opacity: 0.5 }
```

### Components
```typescript
// ❌ Raw HTML elements for MUI equivalents
<table>...</table>          // Use Table or DataGridPro
<a href="/cars">Cars</a>   // Use Link
<button>Click</button>     // Use Button

// ❌ Mixing MUI and non-MUI form elements
<input type="text" />      // Use TextField/TextFieldElement
<select>...</select>        // Use Select/SelectElement
```

## Price Formatting

```typescript
// ✅ Return empty string for null/undefined
export function formatPrice(price: number | null | undefined): string {
  if (price == null) return '';
  return new Intl.NumberFormat('sk-SK', {
    style: 'currency',
    currency: 'EUR',
  }).format(price);
}

// Usage in Typography
<Typography variant="h6">{formatPrice(car.price)}</Typography>
```
