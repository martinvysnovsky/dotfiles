# TypeScript Import Organization Patterns

## Standard Import Order Template

```typescript
// 1. Framework imports
import { Injectable } from '@nestjs/common';
import { UseGuards } from '@nestjs/common';
import { Component } from 'react';

// 2. Third-party packages
import { fromPartial } from '@total-typescript/shoehorn';
import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

// 3. Generated files
import { CarType } from 'src/generated/graphql';
import { UserType } from 'src/generated/types';

// 4. Helper utilities
import { DateHelper } from 'src/helpers/date.helper';
import { ValidationHelper } from 'src/helpers/validation.helper';

// 5. Common modules
import { GqlGuard } from 'src/common/guards/gql.guard';
import { LoggerService } from 'src/common/logger/logger.service';

// 6. Application modules
import { CarService } from 'src/modules/car/car.service';
import { UserService } from 'src/modules/user/user.service';

// 7. Relative imports
import './car.interface';
import '../shared/types';
import { CarValidator } from './car.validator';
```

## Framework-Specific Examples

### NestJS Service
```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';

import { Repository } from 'typeorm';
import { fromPartial } from '@total-typescript/shoehorn';

import { Car } from 'src/generated/entities';

import { DatabaseHelper } from 'src/helpers/database.helper';

import { LoggerService } from 'src/common/logger/logger.service';

import { CarTypeService } from 'src/modules/car-type/car-type.service';

import { CarInterface } from './car.interface';
```

### React Component
```typescript
import { useState, useEffect } from 'react';

import { useQuery } from '@apollo/client';
import { Button } from '@mui/material';

import { CarType } from 'src/generated/graphql';

import { formatCurrency } from 'src/helpers/format.helper';

import { LoadingSpinner } from 'src/common/components/LoadingSpinner';

import { CarService } from 'src/services/car.service';

import './CarCard.styles.css';
import { CarCardProps } from './CarCard.types';
```

### Test File
```typescript
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';

import { TestBed } from '@nestjs/testing';
import { fromPartial } from '@total-typescript/shoehorn';

import { Car } from 'src/generated/entities';

import { TestHelper } from 'src/helpers/test.helper';

import { LoggerModule } from 'src/common/logger/logger.module';

import { CarService } from '../car.service';

import { CarServiceTestData } from './car.test-data';
```

## Type Organization Patterns

### Interface Grouping
```typescript
// Domain types first
export interface Car {
  id: string;
  title: string;
  price: number;
}

export interface CarType {
  id: string;
  name: string;
  category: string;
}

// Input/Output types second
export interface CarInput {
  title: string;
  price: number;
  carTypeId: string;
}

export interface CarResponse {
  car: Car;
  metadata: ResponseMetadata;
}

// Utility types last
export interface CarFilters {
  manufacturer?: string;
  yearFrom?: number;
  yearTo?: number;
}

export type CarSortBy = 'price' | 'year' | 'title';
```

### Barrel Export Pattern
```typescript
// src/types/car/index.ts
export type { Car, CarType } from './car.types';
export type { CarInput, CarResponse } from './car.dto';
export type { CarFilters, CarSortBy } from './car.utils';

// Usage in other files
import { Car, CarInput, CarFilters } from 'src/types/car';
```

## Interface Naming Conventions

### Database Documents
```typescript
// Mongoose
export interface CarDocument extends Document {
  title: string;
  price: number;
  createdAt: Date;
}

// TypeORM
export interface CarEntity {
  id: string;
  title: string;
  price: number;
}
```

### Data Models
```typescript
export interface CarModel {
  id: string;
  title: string;
  price: number;
  carType: CarTypeModel;
}

export interface CarTypeModel {
  id: string;
  name: string;
  category: string;
}
```

### Input/Output Types
```typescript
export interface CreateCarInput {
  title: string;
  price: number;
  carTypeId: string;
}

export interface UpdateCarInput {
  title?: string;
  price?: number;
}

export interface CarListResponse {
  cars: Car[];
  pagination: PaginationMeta;
}
```

## Type Safety Best Practices

### Explicit Type Annotations
```typescript
// Good - explicit type annotation
const car: Car = fromPartial({
  id: '1',
  title: 'BMW X5'
});

// Bad - implicit any type
const car = {
  id: '1',
  title: 'BMW X5'
};
```

### Generic Constraints
```typescript
// Good - constrained generic
interface Repository<T extends { id: string }> {
  findById(id: string): Promise<T | null>;
  save(entity: T): Promise<T>;
}

// Usage
class CarRepository implements Repository<Car> {
  async findById(id: string): Promise<Car | null> {
    // Implementation
  }
}
```

### Union Types Over Overloads
```typescript
// Good - union types
interface SearchOptions {
  type: 'quick' | 'advanced';
  query: string;
  filters?: CarFilters;
}

function searchCars(options: SearchOptions): Promise<Car[]> {
  // Implementation
}

// Usage
searchCars({ type: 'quick', query: 'BMW' });
searchCars({ type: 'advanced', query: 'luxury', filters: { yearFrom: 2020 } });
```