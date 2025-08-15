# GraphQL Patterns in React

## Query Naming Convention

### NO "Query" Suffix in GraphQL Query Names
```graphql
# ✅ Good - Clean query names
query Pricelist {
  pricelist {
    id
    name
    rates {
      carType
      dailyRate
    }
  }
}

query Cars($filters: CarFilters) {
  cars(filters: $filters) {
    id
    title
    price
    year
  }
}

query CarDetails($id: ID!) {
  car(id: $id) {
    id
    title
    description
    price
    images {
      url
      alt
    }
  }
}

# ❌ Bad - Don't add "Query" suffix
query PricelistQuery {
  pricelist { ... }
}

query CarsQuery {
  cars { ... }
}
```

## Code Generation

### File Structure
```
app/
├── graphql/
│   ├── cars.graphql          # GraphQL operations
│   ├── cars.generated.ts     # Generated types and hooks
│   ├── pricelist.graphql
│   ├── pricelist.generated.ts
│   └── schema.generated.ts   # Generated schema types
```

### Generated Types Usage
```typescript
// Import from .generated.ts files
import { 
  Car, 
  CarFilters, 
  useCarsQuery,
  useCarDetailsQuery,
  useCreateCarMutation 
} from '~/graphql/cars.generated';

export default function CarList() {
  // Use generated hooks
  const { data, loading, error } = useCarsQuery({
    variables: { 
      filters: { manufacturer: 'BMW' }
    }
  });

  if (loading) return <Loading />;
  if (error) return <ErrorMessage error={error} />;

  return (
    <div>
      {data?.cars?.map(car => (
        <CarCard key={car.id} car={car} />
      ))}
    </div>
  );
}
```

## Query Patterns

### Basic Query with Loading and Error States
```typescript
import { useCarsQuery } from '~/graphql/cars.generated';
import { Loading } from '~/components/Loading';
import { ErrorMessage } from '~/components/ErrorMessage';

export default function CarList({ filters }: CarListProps) {
  const { data, loading, error, refetch } = useCarsQuery({
    variables: { filters },
    errorPolicy: 'all', // Show partial data if available
  });

  if (loading) return <Loading />;
  if (error) return <ErrorMessage error={error} onRetry={refetch} />;

  const cars = data?.cars || [];

  return (
    <Grid2 container spacing={2}>
      {cars.map(car => (
        <Grid2 xs={12} md={6} key={car.id}>
          <CarCard car={car} />
        </Grid2>
      ))}
    </Grid2>
  );
}
```

### Query with Variables and Polling
```typescript
import { useCarDetailsQuery } from '~/graphql/cars.generated';

export default function CarDetails({ params }: Route.ComponentProps) {
  const { carId } = params;
  
  const { data, loading, error } = useCarDetailsQuery({
    variables: { id: carId },
    pollInterval: 30000, // Poll every 30 seconds
    skip: !carId, // Skip query if no carId
  });

  if (loading) return <Loading />;
  if (error) return <ErrorMessage error={error} />;
  if (!data?.car) return <div>Car not found</div>;

  const { car } = data;

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        {car.title}
      </Typography>
      <Typography variant="h5" color="primary">
        {formatPrice(car.price)}
      </Typography>
      <Typography variant="body1" sx={{ mt: 2 }}>
        {car.description}
      </Typography>
    </Paper>
  );
}
```

### Lazy Query Pattern
```typescript
import { useCarsLazyQuery } from '~/graphql/cars.generated';

export default function CarSearch() {
  const [searchCars, { data, loading, error }] = useCarsLazyQuery();

  const handleSearch = (searchTerm: string) => {
    searchCars({
      variables: {
        filters: { search: searchTerm }
      }
    });
  };

  return (
    <Box>
      <SearchInput onSearch={handleSearch} />
      
      {loading && <Loading />}
      {error && <ErrorMessage error={error} />}
      
      {data?.cars && (
        <CarGrid cars={data.cars} />
      )}
    </Box>
  );
}
```

## Mutation Patterns

### Basic Mutation with Optimistic Updates
```typescript
import { useCreateCarMutation, useCarsQuery } from '~/graphql/cars.generated';

export default function CreateCarForm() {
  const [createCar, { loading, error }] = useCreateCarMutation({
    // Refetch cars list after creation
    refetchQueries: [{ query: CarsDocument }],
    
    // Optimistic response
    optimisticResponse: (variables) => ({
      createCar: {
        __typename: 'Car',
        id: 'temp-id',
        ...variables.input,
        createdAt: new Date().toISOString(),
      }
    }),
    
    // Update cache manually
    update: (cache, { data }) => {
      if (!data?.createCar) return;
      
      const existingCars = cache.readQuery({ query: CarsDocument });
      if (existingCars?.cars) {
        cache.writeQuery({
          query: CarsDocument,
          data: {
            cars: [...existingCars.cars, data.createCar]
          }
        });
      }
    },
    
    onCompleted: (data) => {
      navigate(`/cars/${data.createCar.id}`);
    },
    
    onError: (error) => {
      console.error('Failed to create car:', error);
    }
  });

  const handleSubmit = async (formData: CarInput) => {
    await createCar({
      variables: { input: formData }
    });
  };

  return (
    <CarForm 
      onSubmit={handleSubmit}
      loading={loading}
      error={error}
    />
  );
}
```

### Update Mutation with Cache Updates
```typescript
import { useUpdateCarMutation } from '~/graphql/cars.generated';

export default function EditCarForm({ carId }: EditCarFormProps) {
  const [updateCar, { loading, error }] = useUpdateCarMutation({
    update: (cache, { data }) => {
      if (!data?.updateCar) return;
      
      // Update the car in cache
      cache.writeFragment({
        id: cache.identify(data.updateCar),
        fragment: gql`
          fragment UpdatedCar on Car {
            id
            title
            price
            description
            updatedAt
          }
        `,
        data: data.updateCar
      });
    }
  });

  const handleSubmit = async (formData: UpdateCarInput) => {
    await updateCar({
      variables: { 
        id: carId,
        input: formData 
      }
    });
  };

  return (
    <CarForm 
      onSubmit={handleSubmit}
      loading={loading}
      error={error}
    />
  );
}
```

### Delete Mutation with Cache Cleanup
```typescript
import { useDeleteCarMutation } from '~/graphql/cars.generated';

export default function DeleteCarButton({ carId }: DeleteCarButtonProps) {
  const [deleteCar, { loading }] = useDeleteCarMutation({
    variables: { id: carId },
    
    update: (cache) => {
      // Remove car from cache
      cache.evict({ 
        id: cache.identify({ __typename: 'Car', id: carId }) 
      });
      cache.gc(); // Garbage collect
    },
    
    onCompleted: () => {
      navigate('/cars');
    }
  });

  const handleDelete = async () => {
    if (window.confirm('Are you sure you want to delete this car?')) {
      await deleteCar();
    }
  };

  return (
    <Button 
      onClick={handleDelete}
      disabled={loading}
      color="error"
      variant="outlined"
    >
      {loading ? 'Deleting...' : 'Delete Car'}
    </Button>
  );
}
```

## Error Handling Patterns

### Using ErrorMessage Component
```typescript
import { ErrorMessage } from '~/components/ErrorMessage';
import { useCarsQuery } from '~/graphql/cars.generated';

export default function CarList() {
  const { data, loading, error, refetch } = useCarsQuery();

  if (loading) return <Loading />;
  
  // Use ErrorMessage component for GraphQL errors
  if (error) {
    return <ErrorMessage error={error} onRetry={refetch} />;
  }

  return <CarGrid cars={data?.cars || []} />;
}
```

### Custom Error Handling
```typescript
export default function CarForm() {
  const [createCar, { loading, error }] = useCreateCarMutation({
    errorPolicy: 'all', // Get partial data even with errors
    
    onError: (error) => {
      // Handle specific error types
      if (error.networkError) {
        toast.error('Network error - please check your connection');
      } else if (error.graphQLErrors.length > 0) {
        const validationErrors = error.graphQLErrors.filter(
          err => err.extensions?.code === 'VALIDATION_ERROR'
        );
        
        if (validationErrors.length > 0) {
          // Handle validation errors in form
          validationErrors.forEach(err => {
            if (err.extensions?.field) {
              setError(err.extensions.field, {
                message: err.message
              });
            }
          });
        }
      }
    }
  });

  return (
    <form>
      {/* Form fields */}
      
      {error && !error.graphQLErrors.some(e => e.extensions?.field) && (
        <ErrorMessage error={error} />
      )}
    </form>
  );
}
```

## Subscription Patterns

### Real-time Updates
```typescript
import { useCarUpdatesSubscription } from '~/graphql/cars.generated';

export default function CarDetails({ carId }: CarDetailsProps) {
  const { data: queryData } = useCarDetailsQuery({ 
    variables: { id: carId } 
  });

  // Subscribe to real-time updates
  const { data: subscriptionData } = useCarUpdatesSubscription({
    variables: { carId },
    skip: !carId,
  });

  // Use subscription data if available, fallback to query data
  const car = subscriptionData?.carUpdated || queryData?.car;

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h4">{car?.title}</Typography>
      <Chip 
        label={car?.status} 
        color={car?.status === 'AVAILABLE' ? 'success' : 'default'}
      />
    </Paper>
  );
}
```

## Fragment Patterns

### Reusable Fragments
```typescript
// fragments/car.graphql
fragment CarBasic on Car {
  id
  title
  price
  year
  status
}

fragment CarDetailed on Car {
  ...CarBasic
  description
  mileage
  registrationDate
  images {
    id
    url
    alt
  }
}

// Usage in queries
query Cars {
  cars {
    ...CarBasic
  }
}

query CarDetails($id: ID!) {
  car(id: $id) {
    ...CarDetailed
  }
}
```

### Fragment Composition in Components
```typescript
import { CarBasicFragment, CarDetailedFragment } from '~/graphql/fragments.generated';

interface CarCardProps {
  car: CarBasicFragment;
}

export function CarCard({ car }: CarCardProps) {
  return (
    <Card>
      <CardContent>
        <Typography variant="h6">{car.title}</Typography>
        <Typography variant="h5" color="primary">
          {formatPrice(car.price)}
        </Typography>
      </CardContent>
    </Card>
  );
}

interface CarDetailsProps {
  car: CarDetailedFragment;
}

export function CarDetails({ car }: CarDetailsProps) {
  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h4">{car.title}</Typography>
      <Typography variant="body1">{car.description}</Typography>
      {car.images.map(image => (
        <img key={image.id} src={image.url} alt={image.alt} />
      ))}
    </Paper>
  );
}
```