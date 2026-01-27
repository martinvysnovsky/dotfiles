# Database Operations with TypeORM

## Query Builder Patterns

### Basic Query with Filters

```typescript
async findWithFilters(filters: CarFilters): Promise<Car[]> {
  const queryBuilder = this.carRepository.createQueryBuilder('car')
    .leftJoinAndSelect('car.carType', 'carType')
    .leftJoinAndSelect('car.historyEvents', 'historyEvents');

  if (filters.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

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

  if (filters.priceRange) {
    queryBuilder.andWhere('car.price BETWEEN :minPrice AND :maxPrice', {
      minPrice: filters.priceRange.min,
      maxPrice: filters.priceRange.max
    });
  }

  return queryBuilder
    .orderBy('car.createdAt', 'DESC')
    .getMany();
}
```

### Complex Joins

```typescript
async findCarWithFullDetails(id: string): Promise<Car> {
  return this.carRepository
    .createQueryBuilder('car')
    .leftJoinAndSelect('car.carType', 'carType')
    .leftJoinAndSelect('car.historyEvents', 'historyEvents')
    .leftJoinAndSelect('car.maintenanceRecords', 'maintenance')
    .leftJoinAndSelect('car.rentals', 'rentals')
    .leftJoinAndSelect('rentals.customer', 'customer')
    .where('car.id = :id', { id })
    .orderBy('historyEvents.eventDate', 'DESC')
    .addOrderBy('maintenance.date', 'DESC')
    .getOne();
}
```

### Conditional Query Building

```typescript
async searchCars(searchParams: CarSearchParams): Promise<Car[]> {
  const queryBuilder = this.carRepository.createQueryBuilder('car');

  // Dynamic filtering
  if (searchParams.searchTerm) {
    queryBuilder.andWhere(
      '(car.title ILIKE :search OR car.manufacturer ILIKE :search)',
      { search: `%${searchParams.searchTerm}%` }
    );
  }

  if (searchParams.statuses?.length) {
    queryBuilder.andWhere('car.status IN (:...statuses)', {
      statuses: searchParams.statuses
    });
  }

  if (searchParams.hasImage !== undefined) {
    if (searchParams.hasImage) {
      queryBuilder.andWhere('car.mainImageUrl IS NOT NULL');
    } else {
      queryBuilder.andWhere('car.mainImageUrl IS NULL');
    }
  }

  return queryBuilder.getMany();
}
```

## Transaction Handling

### Basic Transaction Pattern

```typescript
async processRentalEnd(carId: string, endDate: Date): Promise<void> {
  await this.carRepository.manager.transaction(async (transactionManager) => {
    // Update car status
    const car = await transactionManager.findOne(Car, { 
      where: { id: carId } 
    });
    
    if (!car) {
      throw new NotFoundException('Car not found');
    }

    car.status = CarStatus.AVAILABLE;
    car.lastRentalEndDate = endDate;
    await transactionManager.save(car);

    // Create history event
    const historyEvent = transactionManager.create(HistoryEvent, {
      carId,
      type: HistoryEventType.END_OF_RENTING,
      eventDate: endDate,
      description: 'Rental period ended'
    });
    await transactionManager.save(historyEvent);

    // Create final invoice
    await this.createFinalInvoice(transactionManager, car, endDate);
  });

  this.loggerService.notifyInfo('Rental period ended successfully', {
    context: { carId, endDate: endDate.toISOString() }
  });
}
```

### Transaction with Multiple Repositories

```typescript
async transferCarOwnership(
  carId: string, 
  newOwnerId: string
): Promise<void> {
  await this.carRepository.manager.transaction(async (manager) => {
    // Get car
    const car = await manager.findOne(Car, { where: { id: carId } });
    if (!car) {
      throw new NotFoundException('Car not found');
    }

    // Get new owner
    const newOwner = await manager.findOne(Owner, { 
      where: { id: newOwnerId } 
    });
    if (!newOwner) {
      throw new NotFoundException('Owner not found');
    }

    // Archive old ownership record
    if (car.currentOwnership) {
      car.currentOwnership.endDate = new Date();
      await manager.save(car.currentOwnership);
    }

    // Create new ownership record
    const ownership = manager.create(Ownership, {
      carId: car.id,
      ownerId: newOwner.id,
      startDate: new Date(),
    });
    await manager.save(ownership);

    // Update car
    car.currentOwnership = ownership;
    car.ownerId = newOwner.id;
    await manager.save(car);

    // Create history event
    const event = manager.create(HistoryEvent, {
      carId: car.id,
      type: HistoryEventType.OWNERSHIP_TRANSFER,
      eventDate: new Date(),
      description: `Ownership transferred to ${newOwner.name}`,
    });
    await manager.save(event);
  });
}
```

### Transaction Error Handling

```typescript
async complexOperation(data: ComplexOperationData): Promise<Result> {
  try {
    return await this.carRepository.manager.transaction(async (manager) => {
      // Step 1
      const result1 = await this.step1(manager, data);
      
      // Step 2 - depends on step 1
      const result2 = await this.step2(manager, result1);
      
      // Step 3 - validation before final commit
      this.validateResults(result1, result2);
      
      return { result1, result2 };
    });
  } catch (error) {
    this.loggerService.notifyError(error as Error, {
      context: { operation: 'complexOperation', data }
    });
    throw error;
  }
}
```

## Raw Queries

Use raw queries sparingly, only when query builder is insufficient:

```typescript
async getCarStatistics(): Promise<CarStatistics> {
  const result = await this.carRepository.query(`
    SELECT 
      COUNT(*) as total_cars,
      AVG(price) as average_price,
      COUNT(CASE WHEN status = 'available' THEN 1 END) as available_cars,
      COUNT(CASE WHEN status = 'rented' THEN 1 END) as rented_cars
    FROM cars
    WHERE deleted_at IS NULL
  `);

  return result[0];
}

async getRevenueByMonth(year: number): Promise<MonthlyRevenue[]> {
  return this.carRepository.query(`
    SELECT 
      EXTRACT(MONTH FROM rental_date) as month,
      SUM(total_amount) as revenue,
      COUNT(*) as rental_count
    FROM rentals
    WHERE EXTRACT(YEAR FROM rental_date) = $1
    GROUP BY month
    ORDER BY month
  `, [year]);
}
```

## Bulk Operations

### Bulk Insert

```typescript
async bulkCreateCars(carsData: CreateCarInput[]): Promise<Car[]> {
  const cars = carsData.map(data => 
    this.carRepository.create(data)
  );

  return this.carRepository.save(cars);
}
```

### Bulk Update

```typescript
async bulkUpdatePrices(updates: { id: string; price: number }[]): Promise<void> {
  await this.carRepository.manager.transaction(async (manager) => {
    for (const update of updates) {
      await manager.update(Car, update.id, { 
        price: update.price,
        modifiedAt: new Date()
      });
    }
  });
}
```

### Bulk Delete

```typescript
async bulkDeleteCars(ids: string[]): Promise<void> {
  await this.carRepository.delete(ids);
}

// Soft delete
async bulkSoftDeleteCars(ids: string[]): Promise<void> {
  await this.carRepository.softDelete(ids);
}
```

## Performance Optimization

### Use Select to Limit Fields

```typescript
async findCarsBasicInfo(): Promise<Partial<Car>[]> {
  return this.carRepository
    .createQueryBuilder('car')
    .select(['car.id', 'car.title', 'car.price', 'car.status'])
    .getMany();
}
```

### Efficient Counting

```typescript
async countAvailableCars(filters?: CarFilters): Promise<number> {
  const queryBuilder = this.carRepository
    .createQueryBuilder('car')
    .where('car.status = :status', { status: CarStatus.AVAILABLE });

  if (filters?.manufacturer) {
    queryBuilder.andWhere('car.manufacturer = :manufacturer', {
      manufacturer: filters.manufacturer
    });
  }

  return queryBuilder.getCount();
}
```

### Batch Loading with Relations

```typescript
async findCarsWithRelations(ids: string[]): Promise<Car[]> {
  return this.carRepository.find({
    where: { id: In(ids) },
    relations: ['carType', 'historyEvents'],
    order: { createdAt: 'DESC' }
  });
}
```
