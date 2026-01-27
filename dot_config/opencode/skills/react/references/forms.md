# React Form Patterns

## Form Element Standards

### Use Form Components from `~/components/form/`

Always use form element components from `~/components/form/` instead of raw MUI components. These components automatically integrate with react-hook-form and handle validation errors from Zod schemas.

## TextFieldElement

```typescript
import { TextFieldElement } from '~/components/form';

// ✅ Good - Use TextFieldElement
<TextFieldElement
  name="title"
  label="Car Title"
  required
  fullWidth
/>

// ❌ Bad - Don't use raw TextField with manual register
<TextField
  {...register('title')}
  label="Car Title"
  error={!!errors.title}
  helperText={errors.title?.message}
  required
  fullWidth
/>
```

### TextFieldElement Examples

```typescript
// Basic text input
<TextFieldElement
  name="title"
  label="Car Title"
  required
  fullWidth
/>

// Multiline text
<TextFieldElement
  name="description"
  label="Description"
  multiline
  rows={4}
  fullWidth
/>

// Number input
<TextFieldElement
  name="price"
  label="Price"
  type="number"
  InputProps={{
    startAdornment: <InputAdornment position="start">€</InputAdornment>,
  }}
  fullWidth
/>

// With helper text
<TextFieldElement
  name="vin"
  label="VIN Number"
  helperText="17-character vehicle identification number"
  fullWidth
/>
```

## DatePickerElement

### Use DatePickerElement for All Date Inputs

```typescript
import { DatePickerElement } from '~/components/form';

// ✅ Good - Use DatePickerElement
<DatePickerElement
  name="registrationDate"
  label="Registration Date"
  required
/>

// ❌ Bad - Don't use raw DatePicker
<DatePicker
  value={value}
  onChange={onChange}
  label="Registration Date"
  renderInput={(params) => <TextField {...params} />}
/>
```

### DatePickerElement Configuration

```typescript
// Full date picker (default)
<DatePickerElement
  name="registrationDate"
  label="Registration Date"
  format="DD.MM.YYYY"
  openTo="day"
  views={['year', 'month', 'day']}
/>

// Month/Year picker
<DatePickerElement
  name="productionDate"
  label="Production Month"
  format="MM/YYYY"
  openTo="month"
  views={['year', 'month']}
/>

// Year only picker
<DatePickerElement
  name="modelYear"
  label="Model Year"
  format="YYYY"
  openTo="year"
  views={['year']}
/>

// Date range constraints
<DatePickerElement
  name="purchaseDate"
  label="Purchase Date"
  minDate={new Date('2020-01-01')}
  maxDate={new Date()}
  disableFuture
/>
```

## Form Layout Patterns

### Basic Form Structure

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Box, Button, Grid2, Paper } from '@mui/material';
import { TextFieldElement, DatePickerElement } from '~/components/form';

const carSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  price: z.number().min(0, 'Price must be positive'),
  year: z.number().min(1900).max(new Date().getFullYear() + 1),
  registrationDate: z.date().nullable(),
  description: z.string().optional(),
});

type CarFormData = z.infer<typeof carSchema>;

export default function CarForm({ car, onSubmit }: CarFormProps) {
  const methods = useForm<CarFormData>({
    resolver: zodResolver(carSchema),
    defaultValues: {
      title: car?.title || '',
      price: car?.price || 0,
      year: car?.year || new Date().getFullYear(),
      registrationDate: car?.registrationDate || null,
      description: car?.description || '',
    },
  });

  const handleSubmit = methods.handleSubmit(async (data) => {
    await onSubmit(data);
  });

  return (
    <Paper sx={{ p: 3 }}>
      <form onSubmit={handleSubmit}>
        <Grid2 container spacing={3}>
          <Grid2 xs={12} md={6}>
            <TextFieldElement
              name="title"
              label="Car Title"
              required
              fullWidth
            />
          </Grid2>
          
          <Grid2 xs={12} md={6}>
            <TextFieldElement
              name="price"
              label="Price"
              type="number"
              required
              fullWidth
              InputProps={{
                startAdornment: <InputAdornment position="start">€</InputAdornment>,
              }}
            />
          </Grid2>
          
          <Grid2 xs={12} md={6}>
            <TextFieldElement
              name="year"
              label="Model Year"
              type="number"
              required
              fullWidth
            />
          </Grid2>
          
          <Grid2 xs={12} md={6}>
            <DatePickerElement
              name="registrationDate"
              label="Registration Date"
              format="DD.MM.YYYY"
              fullWidth
            />
          </Grid2>
          
          <Grid2 xs={12}>
            <TextFieldElement
              name="description"
              label="Description"
              multiline
              rows={4}
              fullWidth
            />
          </Grid2>
          
          <Grid2 xs={12}>
            <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
              <Button type="button" variant="outlined">
                Cancel
              </Button>
              <Button 
                type="submit" 
                variant="contained"
                disabled={methods.formState.isSubmitting}
              >
                {methods.formState.isSubmitting ? 'Saving...' : 'Save'}
              </Button>
            </Box>
          </Grid2>
        </Grid2>
      </form>
    </Paper>
  );
}
```

### Advanced Form Patterns

#### Conditional Fields

```typescript
export default function CarForm() {
  const { watch } = useFormContext<CarFormData>();
  const carType = watch('type');

  return (
    <Grid2 container spacing={3}>
      <Grid2 xs={12} md={6}>
        <SelectElement
          name="type"
          label="Car Type"
          options={[
            { value: 'new', label: 'New Car' },
            { value: 'used', label: 'Used Car' },
          ]}
          required
        />
      </Grid2>

      {carType === 'used' && (
        <>
          <Grid2 xs={12} md={6}>
            <TextFieldElement
              name="mileage"
              label="Mileage"
              type="number"
              InputProps={{
                endAdornment: <InputAdornment position="end">km</InputAdornment>,
              }}
              fullWidth
            />
          </Grid2>
          
          <Grid2 xs={12} md={6}>
            <DatePickerElement
              name="previousOwnershipDate"
              label="Previous Ownership Date"
              format="DD.MM.YYYY"
            />
          </Grid2>
        </>
      )}
    </Grid2>
  );
}
```

#### Form with Dynamic Arrays

```typescript
import { useFieldArray } from 'react-hook-form';
import { IconButton } from '@mui/material';
import { Add, Delete } from '@mui/icons-material';

export default function CarFeaturesForm() {
  const { control } = useFormContext<CarFormData>();
  const { fields, append, remove } = useFieldArray({
    control,
    name: 'features',
  });

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Features
      </Typography>
      
      {fields.map((field, index) => (
        <Grid2 container spacing={2} key={field.id} sx={{ mb: 2 }}>
          <Grid2 xs={10}>
            <TextFieldElement
              name={`features.${index}.name`}
              label="Feature Name"
              fullWidth
            />
          </Grid2>
          <Grid2 xs={2}>
            <IconButton 
              onClick={() => remove(index)}
              color="error"
              sx={{ mt: 1 }}
            >
              <Delete />
            </IconButton>
          </Grid2>
        </Grid2>
      ))}
      
      <Button
        startIcon={<Add />}
        onClick={() => append({ name: '' })}
        variant="outlined"
      >
        Add Feature
      </Button>
    </Box>
  );
}
```

## Form Validation Patterns

### Zod Schema Examples

```typescript
import { z } from 'zod';

// Basic car schema
const carSchema = z.object({
  title: z.string().min(1, 'Title is required').max(100, 'Title too long'),
  price: z.number().min(0, 'Price must be positive'),
  year: z.number()
    .min(1900, 'Year must be after 1900')
    .max(new Date().getFullYear() + 1, 'Year cannot be in the future'),
  mileage: z.number().min(0, 'Mileage cannot be negative').optional(),
  description: z.string().max(500, 'Description too long').optional(),
});

// Advanced validation with custom refinements
const carSchemaAdvanced = z.object({
  title: z.string().min(1),
  price: z.number().min(0),
  year: z.number(),
  registrationDate: z.date().nullable(),
  firstRegistrationDate: z.date().nullable(),
}).refine((data) => {
  if (data.registrationDate && data.firstRegistrationDate) {
    return data.registrationDate >= data.firstRegistrationDate;
  }
  return true;
}, {
  message: 'Registration date must be after first registration date',
  path: ['registrationDate'],
});

// Conditional validation
const carSchemaConditional = z.object({
  type: z.enum(['new', 'used']),
  mileage: z.number().optional(),
  previousOwners: z.number().optional(),
}).refine((data) => {
  if (data.type === 'used') {
    return data.mileage !== undefined && data.mileage > 0;
  }
  return true;
}, {
  message: 'Mileage is required for used cars',
  path: ['mileage'],
});
```

### Custom Validation Messages

```typescript
const carSchema = z.object({
  vin: z.string()
    .length(17, 'VIN must be exactly 17 characters')
    .regex(/^[A-HJ-NPR-Z0-9]{17}$/, 'Invalid VIN format'),
  
  email: z.string()
    .email('Invalid email format')
    .optional()
    .or(z.literal('')),
    
  phone: z.string()
    .regex(/^\+?[1-9]\d{1,14}$/, 'Invalid phone number format')
    .optional(),
    
  website: z.string()
    .url('Invalid website URL')
    .optional()
    .or(z.literal('')),
});
```

## Error Handling in Forms

### Display Validation Errors

```typescript
export default function CarForm() {
  const methods = useForm<CarFormData>({
    resolver: zodResolver(carSchema),
  });

  const { formState: { errors, isSubmitting }, setError } = methods;

  const handleSubmit = methods.handleSubmit(async (data) => {
    try {
      await onSubmit(data);
    } catch (error) {
      // Handle server validation errors
      if (error.graphQLErrors) {
        error.graphQLErrors.forEach((gqlError) => {
          if (gqlError.extensions?.field) {
            setError(gqlError.extensions.field, {
              message: gqlError.message,
            });
          }
        });
      }
    }
  });

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
      
      {/* Display general form errors */}
      {errors.root && (
        <Alert severity="error" sx={{ mt: 2 }}>
          {errors.root.message}
        </Alert>
      )}
    </form>
  );
}
```

### Form State Management

```typescript
export default function CarForm() {
  const methods = useForm<CarFormData>();
  const { formState, reset, watch } = methods;

  // Watch for changes to show unsaved changes warning
  const watchedValues = watch();
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);

  useEffect(() => {
    const subscription = watch((value, { name, type }) => {
      if (type === 'change') {
        setHasUnsavedChanges(true);
      }
    });
    return () => subscription.unsubscribe();
  }, [watch]);

  // Reset form when data changes
  useEffect(() => {
    if (car) {
      reset(car);
      setHasUnsavedChanges(false);
    }
  }, [car, reset]);

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit}>
        {/* Form content */}
        
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 3 }}>
          <Button 
            type="submit" 
            variant="contained"
            disabled={formState.isSubmitting || !formState.isDirty}
          >
            Save Changes
          </Button>
          
          {hasUnsavedChanges && (
            <Typography variant="body2" color="warning.main">
              You have unsaved changes
            </Typography>
          )}
        </Box>
      </form>
    </FormProvider>
  );
}
```