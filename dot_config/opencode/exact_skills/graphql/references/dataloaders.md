# GraphQL DataLoaders

Batch and cache data loading to prevent N+1 query problems in GraphQL resolvers.

## The N+1 Problem

### Without DataLoader

```typescript
@Resolver(() => Car)
export class CarResolver {
  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    // ❌ Executes separate query for each car
    return this.carTypeService.findOne(car.carTypeId);
  }
}

// Query for 100 cars:
// 1 query for cars
// + 100 queries for car types
// = 101 total queries (N+1 problem)
```

### With DataLoader

```typescript
@Resolver(() => Car)
export class CarResolver {
  constructor(
    @Inject('CAR_TYPE_LOADER')
    private readonly carTypeLoader: DataLoader<string, CarType>,
  ) {}

  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    // ✅ Batches all requests into single query
    return this.carTypeLoader.load(car.carTypeId);
  }
}

// Query for 100 cars:
// 1 query for cars
// + 1 batched query for all car types
// = 2 total queries
```

## Basic DataLoader Pattern

### Simple ID-Based Loader

```typescript
import { Injectable, Scope } from '@nestjs/common';
import {
  DocumentDataLoaderFunction,
  DocumentDataLoaderService,
} from '../document-data-loader/document-data-loader.service';
import { CarTypesService } from './car-types.service';
import { CarTypeDocument } from './interfaces/car-type-document.interface';

@Injectable({ scope: Scope.REQUEST })
export class CarTypeLoader {
  constructor(
    private readonly carTypesService: CarTypesService,
    private readonly documentDataLoaderService: DocumentDataLoaderService,
  ) {
    // Create loader with batch function
    const idLoader =
      this.documentDataLoaderService.createNewLoader<CarTypeDocument>(
        (keys) => this.carTypesService.findByIds(keys)
      );

    // Prepare load function
    this.getOne = idLoader.prepareLoadFunction();
  }

  public readonly getOne: DocumentDataLoaderFunction<CarTypeDocument>;
}
```

### Service Batch Function

```typescript
@Injectable()
export class CarTypesService {
  constructor(
    @InjectModel('CarType') private readonly carTypeModel: Model<CarTypeDocument>,
  ) {}

  /**
   * Batch load car types by IDs
   * Returns array in same order as input keys
   */
  async findByIds(ids: ReadonlyArray<string>): Promise<Array<CarTypeDocument | null>> {
    // Single database query for all IDs
    const carTypes = await this.carTypeModel
      .find({ _id: { $in: ids } })
      .exec();

    // Return results in same order as input keys
    // DocumentDataLoaderService handles reordering
    return carTypes;
  }
}
```

## DocumentDataLoader Abstraction

### Base DataLoader Class

```typescript
import DataLoader from 'dataloader';
import { Types } from 'mongoose';

export type DocumentDataLoaderKey = string | Types.ObjectId;

export type DocumentDataLoaderOptions<V, C> = DataLoader.Options<
  string,
  V,
  C
> & {
  idKey?: string;
};

export type DocumentDataLoaderFunction<T> = (
  id: DocumentDataLoaderKey,
  fresh?: boolean,
) => Promise<T | null>;

export class DocumentDataLoader<V, C = string> extends DataLoader<
  string,
  V | null,
  C
> {
  /**
   * Prepare load function with optional cache bypass
   */
  prepareLoadFunction(): DocumentDataLoaderFunction<V> {
    return (key: DocumentDataLoaderKey, fresh = false): Promise<V | null> => {
      const keyString = key.toString();

      if (fresh) {
        super.clear(keyString);  // Bypass cache
      }

      return super.load(keyString);
    };
  }
}
```

### DocumentDataLoader Service

```typescript
import { Injectable } from '@nestjs/common';
import { Document } from 'mongoose';
import {
  DocumentDataLoader,
  DocumentDataLoaderOptions,
} from './document-data-loader';

@Injectable()
export class DocumentDataLoaderService {
  /**
   * Create new data loader with automatic result reordering
   */
  createNewLoader<V extends Document, C = string>(
    batchLoadFn: (keys: ReadonlyArray<string>) => Promise<Array<V | null>>,
    options?: DocumentDataLoaderOptions<V, C>,
  ): DocumentDataLoader<V, C> {
    const batchLoadFnWithReorder = async (keys: ReadonlyArray<string>) => {
      const items = await batchLoadFn(keys);
      return this.reorderResult(items, keys, options?.idKey);
    };

    return new DocumentDataLoader<V, C>(batchLoadFnWithReorder, options);
  }

  /**
   * Reorder result to match order from provided ids
   * Critical for DataLoader correctness
   */
  reorderResult<T extends Document>(
    data: Array<T | null>,
    keys: ReadonlyArray<string>,
    idKey = '_id',
  ): Array<T | null> {
    // Build index map
    const indexes: { [key: string]: number } = {};

    data.forEach((item: T, key: number) => {
      if (item && !(item instanceof Error)) {
        const id: string = item.get(idKey) as string;
        const ids: string[] = Array.isArray(id) ? id : [id];

        ids.forEach((id) => {
          indexes[id] = key;
        });
      }
    });

    // Return array in same order as keys
    return keys.map((id) =>
      Object.hasOwnProperty.call(indexes, id) ? data[indexes[id]] : null,
    );
  }
}
```

**Key features:**
- Automatic result reordering
- Handles Mongoose ObjectId
- Supports custom ID keys
- Null handling for missing records

## Complex DataLoader Patterns

### Composite Key Loader

For loaders that need multiple parameters (e.g., cost by car + year + month):

```typescript
type CostsLoaderKeyElements = [
  string,           // car ID
  number | undefined,  // year
  number | undefined,  // month
  CostType,         // cost type
];

@Injectable({ scope: Scope.REQUEST })
export class CostsLoader {
  // Cache car references for batch processing
  private readonly carCache = new Map<string, CarDocument>();

  constructor(private readonly costsService: CostsService) {
    // Encode/decode composite keys
    const encodeId = (...args: CostsLoaderKeyElements) =>
      `${args[0]}|${args[1] ?? ''}|${args[2] ?? ''}|${args[3]}`;

    const decodeId = (id: string): CostsLoaderKeyElements => {
      const parts = id.split('|');
      return [
        parts[0],
        parts[1] ? Number(parts[1]) : undefined,
        parts[2] ? Number(parts[2]) : undefined,
        parts[3] as CostType,
      ];
    };

    // Create loader with composite key
    const loader = new DocumentDataLoader<number>(
      (keys) => this.batchLoadCosts(keys, decodeId)
    );

    const getOne = loader.prepareLoadFunction();
    
    // Public API
    this.getCost = async (car, costType, year, month) => {
      const carId = car.id as string;
      this.carCache.set(carId, car);
      const key = encodeId(carId, year, month, costType);
      const result = await getOne(key);
      return result ?? 0;
    };
  }

  private async batchLoadCosts(
    keys: readonly string[],
    decodeId: (id: string) => CostsLoaderKeyElements,
  ): Promise<number[]> {
    // Parse all requests
    const requests = keys.map((key) => {
      const [carId, year, month, costType] = decodeId(key);
      const car = this.carCache.get(carId);
      if (!car) {
        throw new Error(`Car ${carId} not found in cache`);
      }
      return { carId, car, year, month, costType };
    });

    // Group by query signature for efficient batching
    const requestGroups = new Map<string, typeof requests>();
    for (const request of requests) {
      const groupKey = `${request.year ?? ''}|${request.month ?? ''}|${request.costType}`;
      const group = requestGroups.get(groupKey) || [];
      group.push(request);
      requestGroups.set(groupKey, group);
    }

    // Execute batch calculations
    const costsByKey = new Map<string, number>();

    for (const [groupKey, groupRequests] of requestGroups) {
      const [yearStr, monthStr, costTypeStr] = groupKey.split('|');
      const year = yearStr ? Number(yearStr) : undefined;
      const month = monthStr ? Number(monthStr) : undefined;
      const costType = costTypeStr as CostType;

      for (const request of groupRequests) {
        const cost = await this.calculateCost(
          request.car,
          costType,
          year,
          month
        );
        
        const key = `${request.carId}|${year ?? ''}|${month ?? ''}|${costType}`;
        costsByKey.set(key, cost);
      }
    }

    // Return results in original order
    return keys.map((key) => costsByKey.get(key) ?? 0);
  }

  private async calculateCost(
    car: CarDocument,
    costType: CostType,
    year?: number,
    month?: number,
  ): Promise<number> {
    // Cost calculation logic
    return this.costsService.calculateCost(car, costType, year, month);
  }

  public readonly getCost: (
    car: CarDocument,
    costType: CostType,
    year?: number,
    month?: number,
  ) => Promise<number>;
}
```

**Benefits of composite keys:**
- Support multiple parameters
- Efficient grouping of similar requests
- Cache car references across batch
- Type-safe key encoding/decoding

## Request-Scoped Loaders

### Why Request Scope

```typescript
// ❌ Singleton scope - cache persists across requests
@Injectable()
export class CarTypeLoader {
  // Cache shared across all users - security risk!
}

// ✅ Request scope - cache per GraphQL request
@Injectable({ scope: Scope.REQUEST })
export class CarTypeLoader {
  // Cache isolated to single request - safe
}
```

**Benefits:**
- Cache isolation per request
- No cross-user data leaks
- Fresh data for each request
- Memory automatically cleaned after request

### Module Configuration

```typescript
@Module({
  providers: [
    // Request-scoped loader
    CarTypeLoader,
    
    // Singleton services (normal scope)
    CarTypesService,
    DocumentDataLoaderService,
  ],
  exports: [CarTypeLoader],
})
export class CarTypesModule {}
```

## Usage in Resolvers

### Field Resolver with DataLoader

```typescript
import { Resolver, ResolveField, Parent } from '@nestjs/graphql';
import { Inject } from '@nestjs/common';
import { Car, CarType } from 'src/generated/graphql';
import { CarTypeLoader } from '../car-types/car-type.loader';

@Resolver(() => Car)
export class CarResolver {
  constructor(
    @Inject(CarTypeLoader)
    private readonly carTypeLoader: CarTypeLoader,
  ) {}

  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    // Load with DataLoader - automatically batched
    return this.carTypeLoader.getOne(car.carTypeId);
  }
}
```

### Multiple DataLoaders

```typescript
@Resolver(() => Car)
export class CarResolver {
  constructor(
    @Inject(CarTypeLoader)
    private readonly carTypeLoader: CarTypeLoader,
    
    @Inject(ContractLoader)
    private readonly contractLoader: ContractLoader,
    
    @Inject(InvoiceLoader)
    private readonly invoiceLoader: InvoiceLoader,
  ) {}

  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    return this.carTypeLoader.getOne(car.carTypeId);
  }

  @ResolveField(() => [Contract])
  async contracts(@Parent() car: Car): Promise<Contract[]> {
    return this.contractLoader.loadByCarId(car.id);
  }

  @ResolveField(() => [Invoice])
  async invoices(@Parent() car: Car): Promise<Invoice[]> {
    return this.invoiceLoader.loadByCarId(car.id);
  }
}
```

## Batch Optimization Strategies

### Grouping Similar Queries

```typescript
private async batchLoadCosts(
  keys: readonly string[],
  decodeId: (id: string) => CostsLoaderKeyElements,
): Promise<number[]> {
  const requests = keys.map(decodeId);

  // Group by query signature (year|month|costType)
  const groups = new Map<string, Request[]>();
  
  for (const request of requests) {
    const groupKey = `${request.year}|${request.month}|${request.costType}`;
    const group = groups.get(groupKey) || [];
    group.push(request);
    groups.set(groupKey, group);
  }

  // Execute one optimized query per group
  for (const [groupKey, groupRequests] of groups) {
    // Database-level filtering instead of N queries
    await this.executeBatchQuery(groupRequests);
  }
}
```

### Caching Intermediate Data

```typescript
@Injectable({ scope: Scope.REQUEST })
export class CostsLoader {
  // Cache entities used across multiple cost calculations
  private readonly carCache = new Map<string, CarDocument>();
  private readonly pricelistCache = new Map<string, PricelistDocument>();

  async getCost(car: CarDocument, costType: CostType): Promise<number> {
    // Cache car for reuse in batch
    this.carCache.set(car.id as string, car);
    
    // Load pricelist (shared across many cars)
    const pricelist = await this.loadPricelist(car.carTypeId);
    this.pricelistCache.set(car.carTypeId, pricelist);
    
    return this.calculateCost(car, pricelist, costType);
  }
}
```

## Testing DataLoaders

### Unit Test

```typescript
describe('CarTypeLoader', () => {
  let loader: CarTypeLoader;
  let service: MockType<CarTypesService>;
  let loaderService: DocumentDataLoaderService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        CarTypeLoader,
        DocumentDataLoaderService,
        {
          provide: CarTypesService,
          useFactory: serviceMockFactory,
        },
      ],
    }).compile();

    loader = module.get(CarTypeLoader);
    service = module.get(CarTypesService);
    loaderService = module.get(DocumentDataLoaderService);
  });

  it('batches multiple loads into single query', async () => {
    const carTypes = [
      { _id: '1', name: 'SUV' },
      { _id: '2', name: 'Sedan' },
    ];
    
    service.findByIds.mockResolvedValue(carTypes);

    // Load multiple IDs
    const results = await Promise.all([
      loader.getOne('1'),
      loader.getOne('2'),
      loader.getOne('1'),  // Cached
    ]);

    // Only one batch call
    expect(service.findByIds).toHaveBeenCalledTimes(1);
    expect(service.findByIds).toHaveBeenCalledWith(['1', '2']);
    
    // Results in correct order
    expect(results[0].name).toBe('SUV');
    expect(results[1].name).toBe('Sedan');
    expect(results[2].name).toBe('SUV');
  });
});
```

### Integration Test

```typescript
describe('Car resolver with DataLoaders', () => {
  it('prevents N+1 queries', async () => {
    const query = gql`
      query {
        cars {
          id
          carType {
            id
            name
          }
        }
      }
    `;

    // Mock 100 cars
    const cars = Array.from({ length: 100 }, (_, i) => ({
      id: `car-${i}`,
      carTypeId: `type-${i % 10}`,  // 10 unique types
    }));

    // Execute query
    const { data } = await graphqlRequest(query);

    // Verify only 2 database queries:
    // 1. Load all cars
    // 2. Batch load car types
    expect(databaseQueries).toHaveLength(2);
    expect(data.cars).toHaveLength(100);
  });
});
```

## Best Practices

1. **Always Use Request Scope**
   ```typescript
   @Injectable({ scope: Scope.REQUEST })
   ```

2. **Return Results in Key Order**
   ```typescript
   // Use DocumentDataLoaderService for automatic reordering
   const loader = this.documentDataLoaderService.createNewLoader(batchFn);
   ```

3. **Handle Null Results**
   ```typescript
   async findByIds(ids: string[]): Promise<Array<Entity | null>> {
     const entities = await this.model.find({ _id: { $in: ids } });
     // Return null for missing IDs (handled by reorderResult)
     return entities;
   }
   ```

4. **Minimize Batch Function Complexity**
   ```typescript
   // ✅ Simple batch load
   async findByIds(ids: string[]): Promise<Entity[]> {
     return this.model.find({ _id: { $in: ids } });
   }

   // ❌ Complex logic in batch function
   async findByIds(ids: string[]): Promise<Entity[]> {
     const entities = await this.model.find({ _id: { $in: ids } });
     // Don't do heavy processing here
     return entities.map(e => this.transform(e));
   }
   ```

5. **Cache Intermediate Data**
   ```typescript
   // Store frequently accessed data in loader
   private readonly cache = new Map<string, Data>();
   ```

6. **Use Composite Keys When Needed**
   ```typescript
   // Encode multiple parameters into single key
   const key = `${carId}|${year}|${month}`;
   ```

7. **Monitor Loader Performance**
   ```typescript
   // Add logging to batch functions
   async batchLoad(keys: string[]): Promise<Entity[]> {
     console.log(`Loading ${keys.length} entities`);
     const start = Date.now();
     const result = await this.model.find({ _id: { $in: keys } });
     console.log(`Loaded in ${Date.now() - start}ms`);
     return result;
   }
   ```

## Common Patterns

### Load One-to-Many Relationships

```typescript
@Injectable({ scope: Scope.REQUEST })
export class ContractLoader {
  async loadByCarId(carId: string): Promise<Contract[]> {
    // Returns array of contracts for a car
    return this.loader.load(carId);
  }

  private async batchLoad(carIds: string[]): Promise<Contract[][]> {
    // Load all contracts for all cars
    const contracts = await this.model.find({
      carId: { $in: carIds },
    });

    // Group by car ID
    const grouped = new Map<string, Contract[]>();
    for (const contract of contracts) {
      const arr = grouped.get(contract.carId) || [];
      arr.push(contract);
      grouped.set(contract.carId, arr);
    }

    // Return in order
    return carIds.map((id) => grouped.get(id) || []);
  }
}
```

### Load with Filters

```typescript
async loadActiveContracts(carId: string): Promise<Contract[]> {
  const key = `${carId}|active`;
  return this.loader.load(key);
}

private async batchLoad(keys: string[]): Promise<Contract[][]> {
  const parsed = keys.map((k) => {
    const [carId, status] = k.split('|');
    return { carId, status };
  });

  const carIds = parsed.map((p) => p.carId);
  
  const contracts = await this.model.find({
    carId: { $in: carIds },
    status: 'active',
  });

  // Group and return
  // ...
}
```
