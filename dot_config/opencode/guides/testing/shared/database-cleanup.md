# Database Cleanup Patterns

Strategies for cleaning up test data between tests to ensure isolation.

## MongoDB Cleanup

### Simple Collection Cleanup
```typescript
afterEach(async () => {
  // Clean up database between tests
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});
```

### Factory-Based Cleanup
```typescript
// test/factories/test-data.factory.ts
import { Injectable } from '@nestjs/common';
import { HydratedDocument, Model, Types, UpdateQuery } from 'mongoose';

@Injectable()
export abstract class TestDataFactory<E> {
  protected abstract readonly model: Model<E>;

  async clean(): Promise<void> {
    await this.model.deleteMany({});
  }
}

// Usage in tests
beforeEach(async () => {
  await carsFactory.clean();
});
```

## TypeORM/SQL Cleanup

### Entity-Based Cleanup
```typescript
afterEach(async () => {
  // Clean up database between tests
  const entities = dataSource.entityMetadatas;
  for (const entity of entities) {
    const repository = dataSource.getRepository(entity.name);
    await repository.clear();
  }
});
```

### Advanced Database Cleaner
```typescript
// test/helpers/database-cleaner.ts
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';

@Injectable()
export class DatabaseCleaner {
  constructor(private readonly dataSource: DataSource) {}

  async cleanAll(): Promise<void> {
    const entities = this.dataSource.entityMetadatas;
    
    // Disable foreign key checks
    await this.dataSource.query('SET FOREIGN_KEY_CHECKS = 0;');
    
    // Clear all tables
    for (const entity of entities) {
      const repository = this.dataSource.getRepository(entity.name);
      await repository.clear();
    }
    
    // Re-enable foreign key checks
    await this.dataSource.query('SET FOREIGN_KEY_CHECKS = 1;');
  }

  async cleanTable(tableName: string): Promise<void> {
    await this.dataSource.query(`DELETE FROM ${tableName}`);
  }
}
```

## Transaction-Based Cleanup

### Using Database Transactions
```typescript
describe('Cars Service', () => {
  let queryRunner: QueryRunner;

  beforeEach(async () => {
    queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();
  });

  afterEach(async () => {
    await queryRunner.rollbackTransaction();
    await queryRunner.release();
  });

  it('should create car', async () => {
    // Test runs within transaction
    // Automatically rolled back after test
  });
});
```

## Best Practices

### ✅ Do's
- Clean database state between tests
- Use transactions for faster cleanup when possible
- Handle foreign key constraints properly
- Clean in reverse dependency order

### ❌ Don'ts
- Don't rely on test execution order
- Don't leave test data in database
- Don't ignore foreign key constraints
- Don't clean database in production