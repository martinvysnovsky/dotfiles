# Pagination and Filtering Patterns

## Pagination Interfaces

```typescript
interface PaginationOptions {
  page: number;
  limit: number;
}

interface PaginatedResult<T> {
  data: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
```

## Basic Pagination

```typescript
async findAllPaginated(
  filters?: CarFilters,
  pagination?: PaginationOptions
): Promise<PaginatedResult<Car>> {
  const page = pagination?.page ?? 1;
  const limit = pagination?.limit ?? 25;
  const skip = (page - 1) * limit;

  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Apply filters
  if (filters?.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

  // Get total count
  const total = await queryBuilder.getCount();

  // Get paginated results
  const data = await queryBuilder
    .skip(skip)
    .take(limit)
    .orderBy('car.createdAt', 'DESC')
    .getMany();

  return {
    data,
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    }
  };
}
```

## Advanced Filtering

### Multiple Filter Types

```typescript
interface CarFilters {
  manufacturer?: string;
  yearFrom?: number;
  yearTo?: number;
  priceRange?: {
    min: number;
    max: number;
  };
  statuses?: CarStatus[];
  hasImage?: boolean;
  searchTerm?: string;
}

async findWithAdvancedFilters(
  filters: CarFilters,
  pagination: PaginationOptions
): Promise<PaginatedResult<Car>> {
  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Text search
  if (filters.searchTerm) {
    queryBuilder.andWhere(
      '(car.title ILIKE :search OR car.manufacturer ILIKE :search OR car.model ILIKE :search)',
      { search: `%${filters.searchTerm}%` }
    );
  }

  // Manufacturer filter
  if (filters.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

  // Year range
  if (filters.yearFrom) {
    queryBuilder.andWhere('car.year >= :yearFrom', {
      yearFrom: filters.yearFrom
    });
  }
  if (filters.yearTo) {
    queryBuilder.andWhere('car.year <= :yearTo', {
      yearTo: filters.yearTo
    });
  }

  // Price range
  if (filters.priceRange) {
    queryBuilder.andWhere('car.price BETWEEN :minPrice AND :maxPrice', {
      minPrice: filters.priceRange.min,
      maxPrice: filters.priceRange.max
    });
  }

  // Status filter (multiple values)
  if (filters.statuses?.length) {
    queryBuilder.andWhere('car.status IN (:...statuses)', {
      statuses: filters.statuses
    });
  }

  // Boolean filter
  if (filters.hasImage !== undefined) {
    if (filters.hasImage) {
      queryBuilder.andWhere('car.mainImageUrl IS NOT NULL');
    } else {
      queryBuilder.andWhere('car.mainImageUrl IS NULL');
    }
  }

  // Count total
  const total = await queryBuilder.getCount();

  // Apply pagination
  const page = pagination.page ?? 1;
  const limit = pagination.limit ?? 25;
  const skip = (page - 1) * limit;

  const data = await queryBuilder
    .skip(skip)
    .take(limit)
    .orderBy('car.createdAt', 'DESC')
    .getMany();

  return {
    data,
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    }
  };
}
```

## Sorting

### Dynamic Sorting

```typescript
interface SortOptions {
  sortBy?: string;
  sortOrder?: 'ASC' | 'DESC';
}

async findWithSorting(
  filters: CarFilters,
  pagination: PaginationOptions,
  sort?: SortOptions
): Promise<PaginatedResult<Car>> {
  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Apply filters (same as above)
  // ...

  // Apply sorting
  const sortBy = sort?.sortBy ?? 'createdAt';
  const sortOrder = sort?.sortOrder ?? 'DESC';

  // Validate sortBy to prevent SQL injection
  const allowedSortFields = ['createdAt', 'price', 'year', 'manufacturer', 'title'];
  if (!allowedSortFields.includes(sortBy)) {
    throw new BadRequestException(`Invalid sort field: ${sortBy}`);
  }

  queryBuilder.orderBy(`car.${sortBy}`, sortOrder);

  // Count and paginate
  const total = await queryBuilder.getCount();
  const page = pagination.page ?? 1;
  const limit = pagination.limit ?? 25;

  const data = await queryBuilder
    .skip((page - 1) * limit)
    .take(limit)
    .getMany();

  return { data, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
}
```

### Multiple Sort Fields

```typescript
async findWithMultipleSort(
  filters: CarFilters,
  pagination: PaginationOptions
): Promise<PaginatedResult<Car>> {
  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Apply filters
  // ...

  // Multiple sort fields
  const data = await queryBuilder
    .orderBy('car.status', 'ASC')         // Primary: by status
    .addOrderBy('car.price', 'DESC')       // Secondary: by price
    .addOrderBy('car.createdAt', 'DESC')   // Tertiary: by date
    .skip((pagination.page - 1) * pagination.limit)
    .take(pagination.limit)
    .getMany();

  const total = await queryBuilder.getCount();

  return {
    data,
    meta: {
      page: pagination.page,
      limit: pagination.limit,
      total,
      totalPages: Math.ceil(total / pagination.limit)
    }
  };
}
```

## Search Implementation

### Full-Text Search

```typescript
async searchCars(
  searchTerm: string,
  pagination: PaginationOptions
): Promise<PaginatedResult<Car>> {
  const queryBuilder = this.carRepository
    .createQueryBuilder('car')
    .where(
      'car.searchVector @@ plainto_tsquery(:search)',
      { search: searchTerm }
    )
    .orderBy(
      "ts_rank(car.searchVector, plainto_tsquery(:search))",
      'DESC'
    );

  const total = await queryBuilder.getCount();

  const data = await queryBuilder
    .skip((pagination.page - 1) * pagination.limit)
    .take(pagination.limit)
    .getMany();

  return {
    data,
    meta: {
      page: pagination.page,
      limit: pagination.limit,
      total,
      totalPages: Math.ceil(total / pagination.limit)
    }
  };
}
```

### Search with Filters

```typescript
async searchWithFilters(
  searchTerm: string,
  filters: CarFilters,
  pagination: PaginationOptions
): Promise<PaginatedResult<Car>> {
  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Search condition
  if (searchTerm) {
    queryBuilder.where(
      '(car.title ILIKE :search OR car.manufacturer ILIKE :search OR car.description ILIKE :search)',
      { search: `%${searchTerm}%` }
    );
  }

  // Additional filters
  if (filters.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

  if (filters.priceRange) {
    queryBuilder.andWhere('car.price BETWEEN :min AND :max', {
      min: filters.priceRange.min,
      max: filters.priceRange.max
    });
  }

  const total = await queryBuilder.getCount();

  const data = await queryBuilder
    .skip((pagination.page - 1) * pagination.limit)
    .take(pagination.limit)
    .orderBy('car.createdAt', 'DESC')
    .getMany();

  return {
    data,
    meta: {
      page: pagination.page,
      limit: pagination.limit,
      total,
      totalPages: Math.ceil(total / pagination.limit)
    }
  };
}
```

## Cursor-Based Pagination

For infinite scroll or large datasets:

```typescript
interface CursorPaginationOptions {
  cursor?: string; // Last item ID from previous page
  limit: number;
}

interface CursorPaginatedResult<T> {
  data: T[];
  nextCursor?: string;
  hasMore: boolean;
}

async findWithCursorPagination(
  filters: CarFilters,
  pagination: CursorPaginationOptions
): Promise<CursorPaginatedResult<Car>> {
  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Apply filters
  if (filters.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

  // Apply cursor
  if (pagination.cursor) {
    queryBuilder.andWhere('car.id > :cursor', {
      cursor: pagination.cursor
    });
  }

  // Fetch one extra to check if there are more results
  const data = await queryBuilder
    .orderBy('car.id', 'ASC')
    .take(pagination.limit + 1)
    .getMany();

  const hasMore = data.length > pagination.limit;
  const results = hasMore ? data.slice(0, -1) : data;
  const nextCursor = hasMore ? results[results.length - 1].id : undefined;

  return {
    data: results,
    nextCursor,
    hasMore
  };
}
```

## Aggregation with Pagination

```typescript
interface AggregatedCarStats {
  manufacturer: string;
  count: number;
  averagePrice: number;
  minPrice: number;
  maxPrice: number;
}

async getCarStatsByManufacturer(
  pagination: PaginationOptions
): Promise<PaginatedResult<AggregatedCarStats>> {
  const queryBuilder = this.carRepository
    .createQueryBuilder('car')
    .select('car.manufacturer', 'manufacturer')
    .addSelect('COUNT(*)', 'count')
    .addSelect('AVG(car.price)', 'averagePrice')
    .addSelect('MIN(car.price)', 'minPrice')
    .addSelect('MAX(car.price)', 'maxPrice')
    .groupBy('car.manufacturer')
    .orderBy('count', 'DESC');

  // Count groups for pagination
  const countQuery = this.carRepository
    .createQueryBuilder('car')
    .select('COUNT(DISTINCT car.manufacturer)', 'total')
    .getRawOne();

  const total = (await countQuery).total;

  const data = await queryBuilder
    .skip((pagination.page - 1) * pagination.limit)
    .take(pagination.limit)
    .getRawMany();

  return {
    data,
    meta: {
      page: pagination.page,
      limit: pagination.limit,
      total: parseInt(total),
      totalPages: Math.ceil(total / pagination.limit)
    }
  };
}
```
