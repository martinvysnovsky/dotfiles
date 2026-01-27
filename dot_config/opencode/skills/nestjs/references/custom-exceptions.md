# Custom Exception Patterns

## Basic Custom Exceptions

Create domain-specific exceptions for better error context:

```typescript
export class CarValidationException extends BadRequestException {
  constructor(message: string, public readonly context?: any) {
    super(message);
    this.name = 'CarValidationException';
  }
}

export class CarNotAvailableException extends BadRequestException {
  constructor(carId: string) {
    super(`Car ${carId} is not available for rental`);
    this.name = 'CarNotAvailableException';
  }
}

export class InsufficientInventoryException extends BadRequestException {
  constructor(
    public readonly carTypeId: string,
    public readonly requested: number,
    public readonly available: number
  ) {
    super(`Insufficient inventory: requested ${requested}, available ${available}`);
    this.name = 'InsufficientInventoryException';
  }
}
```

## Usage in Services

```typescript
@Injectable()
export class CarService {
  async startRental(carId: string): Promise<void> {
    const car = await this.findOne(carId);
    
    if (!car) {
      throw new NotFoundException('Car not found');
    }

    if (car.status !== CarStatus.AVAILABLE) {
      throw new CarNotAvailableException(carId);
    }

    // Process rental start
  }

  async validateCarData(data: CreateCarInput): Promise<void> {
    if (data.year > new Date().getFullYear() + 1) {
      throw new CarValidationException(
        'Car year cannot be more than one year in the future',
        { providedYear: data.year, maxYear: new Date().getFullYear() + 1 }
      );
    }

    if (data.mileage < 0) {
      throw new CarValidationException(
        'Mileage cannot be negative',
        { providedMileage: data.mileage }
      );
    }
  }
}
```

## Exception with Additional Metadata

```typescript
export class RentalConflictException extends ConflictException {
  constructor(
    public readonly carId: string,
    public readonly conflictingRentalId: string,
    public readonly conflictDates: { start: Date; end: Date }
  ) {
    super({
      message: 'Rental period conflicts with existing rental',
      carId,
      conflictingRentalId,
      conflictDates: {
        start: conflictDates.start.toISOString(),
        end: conflictDates.end.toISOString()
      }
    });
    this.name = 'RentalConflictException';
  }
}

// Usage
if (hasConflict) {
  throw new RentalConflictException(
    carId,
    existingRental.id,
    { start: existingRental.startDate, end: existingRental.endDate }
  );
}
```

## Business Rule Exceptions

```typescript
export class BusinessRuleException extends BadRequestException {
  constructor(
    public readonly rule: string,
    public readonly details: Record<string, any>
  ) {
    super({
      message: `Business rule violation: ${rule}`,
      rule,
      details
    });
    this.name = 'BusinessRuleException';
  }
}

// Usage
async validateRentalEligibility(customerId: string, carId: string): Promise<void> {
  const customer = await this.customerService.findOne(customerId);
  
  if (customer.activeRentals >= 3) {
    throw new BusinessRuleException(
      'MAX_ACTIVE_RENTALS',
      { 
        customerId,
        activeRentals: customer.activeRentals,
        maxAllowed: 3
      }
    );
  }

  if (customer.hasUnpaidInvoices) {
    throw new BusinessRuleException(
      'UNPAID_INVOICES',
      { 
        customerId,
        unpaidCount: customer.unpaidInvoices.length
      }
    );
  }
}
```

## Exception Hierarchies

Create exception hierarchies for related errors:

```typescript
// Base exception
export class CarDomainException extends BadRequestException {
  constructor(
    message: string,
    public readonly code: string,
    public readonly context?: any
  ) {
    super({ message, code, context });
    this.name = 'CarDomainException';
  }
}

// Specific exceptions
export class CarMaintenanceException extends CarDomainException {
  constructor(carId: string, maintenanceType: string) {
    super(
      `Car requires ${maintenanceType} maintenance`,
      'MAINTENANCE_REQUIRED',
      { carId, maintenanceType }
    );
    this.name = 'CarMaintenanceException';
  }
}

export class CarInspectionFailedException extends CarDomainException {
  constructor(
    carId: string,
    failedChecks: string[]
  ) {
    super(
      'Car failed inspection',
      'INSPECTION_FAILED',
      { carId, failedChecks }
    );
    this.name = 'CarInspectionFailedException';
  }
}

export class CarRetirementException extends CarDomainException {
  constructor(
    carId: string,
    reason: string
  ) {
    super(
      'Car is retired and cannot be used',
      'CAR_RETIRED',
      { carId, reason }
    );
    this.name = 'CarRetirementException';
  }
}
```

## Exception Factory Pattern

Create exceptions through a factory for consistency:

```typescript
export class CarExceptionFactory {
  static notFound(carId: string): NotFoundException {
    return new NotFoundException({
      message: 'Car not found',
      carId
    });
  }

  static notAvailable(carId: string, currentStatus: CarStatus): CarNotAvailableException {
    return new CarNotAvailableException(carId);
  }

  static invalidTransition(
    carId: string,
    fromStatus: CarStatus,
    toStatus: CarStatus
  ): BadRequestException {
    return new BadRequestException({
      message: 'Invalid status transition',
      carId,
      fromStatus,
      toStatus
    });
  }

  static rentalConflict(
    carId: string,
    requestedPeriod: { start: Date; end: Date },
    conflictingRental: { id: string; start: Date; end: Date }
  ): RentalConflictException {
    return new RentalConflictException(
      carId,
      conflictingRental.id,
      { start: conflictingRental.start, end: conflictingRental.end }
    );
  }
}

// Usage in service
async updateStatus(carId: string, newStatus: CarStatus): Promise<Car> {
  const car = await this.findOne(carId);
  
  if (!car) {
    throw CarExceptionFactory.notFound(carId);
  }

  if (!this.isValidTransition(car.status, newStatus)) {
    throw CarExceptionFactory.invalidTransition(carId, car.status, newStatus);
  }

  car.status = newStatus;
  return this.carRepository.save(car);
}
```

## Exception with Retry Information

```typescript
export class TemporaryServiceException extends ServiceUnavailableException {
  constructor(
    public readonly serviceName: string,
    public readonly retryAfter: number, // seconds
    public readonly details?: any
  ) {
    super({
      message: `Service ${serviceName} is temporarily unavailable`,
      serviceName,
      retryAfter,
      details
    });
    this.name = 'TemporaryServiceException';
  }
}

// Usage
async callExternalService(): Promise<void> {
  try {
    await this.externalService.call();
  } catch (error) {
    throw new TemporaryServiceException(
      'ExternalCarAPI',
      60, // Retry after 60 seconds
      { originalError: error.message }
    );
  }
}
```

## Best Practices

### Exception Naming
- End custom exceptions with `Exception` suffix
- Use descriptive names that indicate the error condition
- Group related exceptions with common prefixes

### Context Information
- Include relevant IDs and values in exception context
- Avoid sensitive information in exception messages
- Provide enough context for debugging

### HTTP Status Codes
Extend the appropriate base exception:
- `BadRequestException` (400) - Validation errors, business rule violations
- `UnauthorizedException` (401) - Authentication failures
- `ForbiddenException` (403) - Authorization failures
- `NotFoundException` (404) - Resource not found
- `ConflictException` (409) - State conflicts
- `InternalServerErrorException` (500) - Unexpected errors

### Exception Organization
```typescript
// exceptions/car-exceptions.ts
export class CarNotFoundException extends NotFoundException { }
export class CarNotAvailableException extends BadRequestException { }
export class CarValidationException extends BadRequestException { }

// exceptions/rental-exceptions.ts
export class RentalConflictException extends ConflictException { }
export class RentalValidationException extends BadRequestException { }

// exceptions/index.ts
export * from './car-exceptions';
export * from './rental-exceptions';
```
