# NestJS GraphQL Resolver Patterns

> **Related Skills:** For GraphQL schema design patterns, see `graphql/schema-design`. For detailed DataLoader implementation and N+1 prevention, see `graphql/dataloaders`. For GraphQL Code Generator configuration, see `graphql/codegen`.

## Basic Resolver Structure

```typescript
import { Resolver, Query, Mutation, Args, ResolveField, Parent } from '@nestjs/graphql';
import { UseGuards } from '@nestjs/common';

import { Car, CarType, HistoryEvent } from 'src/generated/graphql';

import { GqlAuthGuard } from 'src/common/guards/gql-auth.guard';
import { CurrentUser } from 'src/common/decorators/current-user.decorator';

import { CarService } from './car.service';
import { CarTypeService } from '../car-type/car-type.service';

import { CreateCarInput, UpdateCarInput, CarFilters } from './car.dto';

@Resolver(() => Car)
export class CarResolver {
  constructor(
    private readonly carService: CarService,
    private readonly carTypeService: CarTypeService,
  ) {}

  // ===========================================
  // FIELD RESOLVERS (First - Most Important)
  // ===========================================

  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    return this.carTypeService.findOne(car.carTypeId);
  }

  @ResolveField(() => Number)
  async realAmortization(@Parent() car: Car): Promise<number> {
    return this.carService.calculateAmortization(car);
  }

  @ResolveField(() => [HistoryEvent])
  async historyEvents(@Parent() car: Car): Promise<HistoryEvent[]> {
    return this.carService.findHistoryEvents(car.id);
  }

  // ===========================================
  // QUERIES (Second)
  // ===========================================

  @Query(() => [Car])
  async cars(
    @Args('filters', { nullable: true }) filters?: CarFilters
  ): Promise<Car[]> {
    return this.carService.findAll(filters);
  }

  @Query(() => Car, { nullable: true })
  async car(@Args('id') id: string): Promise<Car | null> {
    return this.carService.findOne(id);
  }

  // ===========================================
  // MUTATIONS (Last)
  // ===========================================

  @Mutation(() => Car)
  @UseGuards(GqlAuthGuard)
  async createCar(
    @Args('input') input: CreateCarInput,
    @CurrentUser() user: any
  ): Promise<Car> {
    return this.carService.create(input);
  }

  @Mutation(() => Car)
  @UseGuards(GqlAuthGuard)
  async updateCar(
    @Args('id') id: string,
    @Args('input') input: UpdateCarInput
  ): Promise<Car> {
    return this.carService.update(id, input);
  }
}
```

## Field Resolver Patterns

### DataLoader Integration
```typescript
@Resolver(() => Car)
export class CarResolver {
  constructor(
    private readonly carService: CarService,
    @Inject('CAR_TYPE_LOADER')
    private readonly carTypeLoader: DataLoader<string, CarType>,
    @Inject('HISTORY_EVENTS_LOADER')
    private readonly historyEventsLoader: DataLoader<string, HistoryEvent[]>,
  ) {}

  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    return this.carTypeLoader.load(car.carTypeId);
  }

  @ResolveField(() => [HistoryEvent])
  async historyEvents(@Parent() car: Car): Promise<HistoryEvent[]> {
    return this.historyEventsLoader.load(car.id);
  }
}
```

### Computed Fields
```typescript
@ResolveField(() => Number)
async totalCost(@Parent() car: Car): Promise<number> {
  const amortization = this.carService.calculateAmortization(car);
  const additionalCosts = await this.carService.getAdditionalCosts(car.id);
  return amortization + additionalCosts.reduce((sum, cost) => sum + cost.amount, 0);
}

@ResolveField(() => Boolean)
async isAvailable(@Parent() car: Car): Promise<boolean> {
  return car.status === CarStatus.AVAILABLE;
}

@ResolveField(() => String, { nullable: true })
async mainImageUrl(@Parent() car: Car): Promise<string | null> {
  const images = await this.carService.getImages(car.id);
  return images.find(img => img.isMain)?.url ?? null;
}
```

### Conditional Field Resolution
```typescript
@ResolveField(() => Number, { nullable: true })
async currentRentalPrice(
  @Parent() car: Car,
  @CurrentUser() user?: User
): Promise<number | null> {
  // Only return price if user is authenticated
  if (!user) return null;
  
  // Only return price if car is available for rental
  if (car.status !== CarStatus.AVAILABLE) return null;

  return this.carService.calculateRentalPrice(car, user);
}
```

## Query Patterns

### Pagination with Cursor
```typescript
@Query(() => CarConnection)
async cars(
  @Args('first', { nullable: true }) first?: number,
  @Args('after', { nullable: true }) after?: string,
  @Args('filters', { nullable: true }) filters?: CarFilters
): Promise<CarConnection> {
  const limit = first ?? 25;
  const cursor = after ? Buffer.from(after, 'base64').toString() : undefined;

  const result = await this.carService.findPaginated({
    limit: limit + 1, // Get one extra to check if there's a next page
    cursor,
    filters
  });

  const hasNextPage = result.length > limit;
  const cars = hasNextPage ? result.slice(0, limit) : result;

  const edges = cars.map(car => ({
    node: car,
    cursor: Buffer.from(car.id).toString('base64')
  }));

  return {
    edges,
    pageInfo: {
      hasNextPage,
      hasPreviousPage: !!cursor,
      startCursor: edges[0]?.cursor,
      endCursor: edges[edges.length - 1]?.cursor
    }
  };
}
```

### Complex Filtering
```typescript
@Query(() => [Car])
async searchCars(
  @Args('query') query: string,
  @Args('filters', { nullable: true }) filters?: SearchFilters,
  @Args('sort', { nullable: true }) sort?: CarSortInput
): Promise<Car[]> {
  return this.carService.search({
    query,
    filters: {
      manufacturer: filters?.manufacturer,
      yearRange: filters?.yearRange,
      priceRange: filters?.priceRange,
      features: filters?.features
    },
    sort: {
      field: sort?.field ?? 'relevance',
      direction: sort?.direction ?? 'DESC'
    }
  });
}
```

## Mutation Patterns

### Input Validation
```typescript
@Mutation(() => Car)
@UseGuards(GqlAuthGuard)
async createCar(
  @Args('input') input: CreateCarInput,
  @CurrentUser() user: User
): Promise<Car> {
  // Validate user permissions
  if (user.role !== 'admin') {
    throw new ForbiddenException('Only admins can create cars');
  }

  // Validate business rules
  if (input.year > new Date().getFullYear() + 1) {
    throw new BadRequestException('Car year cannot be more than one year in the future');
  }

  return this.carService.create(input);
}
```

### Optimistic Updates
```typescript
@Mutation(() => Car)
@UseGuards(GqlAuthGuard)
async updateCar(
  @Args('id') id: string,
  @Args('input') input: UpdateCarInput,
  @Args('version') version: number // For optimistic locking
): Promise<Car> {
  const car = await this.carService.findOne(id);
  
  if (!car) {
    throw new NotFoundException('Car not found');
  }

  if (car.version !== version) {
    throw new ConflictException('Car has been modified by another user');
  }

  return this.carService.update(id, { 
    ...input, 
    version: version + 1 
  });
}
```

### File Upload Mutations
```typescript
@Mutation(() => Car)
@UseGuards(GqlAuthGuard)
async uploadCarImage(
  @Args('carId') carId: string,
  @Args('file', { type: () => GraphQLUpload }) file: FileUpload
): Promise<Car> {
  const { createReadStream, filename, mimetype } = await file;
  
  // Validate file type
  if (!mimetype.startsWith('image/')) {
    throw new BadRequestException('Only image files are allowed');
  }

  // Process upload
  const imageUrl = await this.carService.uploadImage(carId, {
    stream: createReadStream(),
    filename,
    mimetype
  });

  return this.carService.findOne(carId);
}
```

## Authentication and Authorization

### Role-Based Access Control
```typescript
@Resolver(() => Car)
export class CarResolver {
  @Query(() => [Car])
  @UseGuards(GqlAuthGuard, RolesGuard)
  @Roles('admin', 'manager')
  async allCars(): Promise<Car[]> {
    return this.carService.findAll();
  }

  @Mutation(() => Car)
  @UseGuards(GqlAuthGuard)
  async createCar(
    @Args('input') input: CreateCarInput,
    @CurrentUser() user: User
  ): Promise<Car> {
    // Custom authorization logic
    if (user.role !== 'admin' && input.price > 100000) {
      throw new ForbiddenException('Only admins can create high-value cars');
    }

    return this.carService.create(input);
  }
}
```

### Resource-Based Authorization
```typescript
@Mutation(() => Car)
@UseGuards(GqlAuthGuard)
async updateCar(
  @Args('id') id: string,
  @Args('input') input: UpdateCarInput,
  @CurrentUser() user: User
): Promise<Car> {
  const car = await this.carService.findOne(id);
  
  if (!car) {
    throw new NotFoundException('Car not found');
  }

  // Check if user owns this car or is admin
  if (car.ownerId !== user.id && user.role !== 'admin') {
    throw new ForbiddenException('You can only update your own cars');
  }

  return this.carService.update(id, input);
}
```

## Error Handling in Resolvers

### Custom Error Formatting
```typescript
@Mutation(() => Car)
async createCar(@Args('input') input: CreateCarInput): Promise<Car> {
  try {
    return await this.carService.create(input);
  } catch (error) {
    if (error instanceof CarValidationException) {
      throw new UserInputError('Invalid car data', {
        validationErrors: error.context?.validationErrors
      });
    }

    if (error instanceof DuplicateKeyException) {
      throw new UserInputError('Car with this VIN already exists', {
        field: 'vin',
        value: input.vin
      });
    }

    // Let global error handler deal with other errors
    throw error;
  }
}
```

## Subscription Patterns

### Real-time Updates
```typescript
@Resolver(() => Car)
export class CarResolver {
  constructor(
    private readonly carService: CarService,
    @Inject('PUB_SUB') private readonly pubSub: PubSubEngine,
  ) {}

  @Subscription(() => Car)
  carUpdated(@Args('carId') carId: string): AsyncIterator<Car> {
    return this.pubSub.asyncIterator(`carUpdated.${carId}`);
  }

  @Subscription(() => Car)
  @UseGuards(GqlAuthGuard)
  newCarsAdded(): AsyncIterator<Car> {
    return this.pubSub.asyncIterator('newCarsAdded');
  }

  @Mutation(() => Car)
  async updateCar(
    @Args('id') id: string,
    @Args('input') input: UpdateCarInput
  ): Promise<Car> {
    const updatedCar = await this.carService.update(id, input);
    
    // Notify subscribers
    await this.pubSub.publish(`carUpdated.${id}`, { carUpdated: updatedCar });
    
    return updatedCar;
  }
}
```

## Testing Resolver Patterns

### Resolver Unit Tests
```typescript
describe('CarResolver', () => {
  let resolver: CarResolver;
  let carService: MockType<CarService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        CarResolver,
        {
          provide: CarService,
          useFactory: serviceMockFactory,
        },
      ],
    }).compile();

    resolver = module.get<CarResolver>(CarResolver);
    carService = module.get<CarService>(CarService);
  });

  describe('cars', () => {
    it('returns all cars', async () => {
      const cars = [{ id: '1', title: 'BMW X5' }];
      carService.findAll.mockResolvedValue(cars);

      const result = await resolver.cars();

      expect(result).toEqual(cars);
      expect(carService.findAll).toHaveBeenCalled();
    });

    it('applies filters when provided', async () => {
      const filters = { manufacturer: 'BMW' };
      const cars = [{ id: '1', title: 'BMW X5', manufacturer: 'BMW' }];
      carService.findAll.mockResolvedValue(cars);

      const result = await resolver.cars(filters);

      expect(result).toEqual(cars);
      expect(carService.findAll).toHaveBeenCalledWith(filters);
    });
  });

  describe('createCar', () => {
    it('creates new car with valid input', async () => {
      const input = { title: 'BMW X5', price: 50000, carTypeId: '1' };
      const car = { id: '1', ...input };
      const user = { id: '1', role: 'admin' };

      carService.create.mockResolvedValue(car);

      const result = await resolver.createCar(input, user);

      expect(result).toEqual(car);
      expect(carService.create).toHaveBeenCalledWith(input);
    });
  });
});
```