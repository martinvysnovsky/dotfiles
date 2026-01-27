# E2E Testing with Testcontainers

Patterns for end-to-end testing NestJS APIs with real database using Testcontainers.

## Testcontainers Setup

### MongoDB Container
```typescript
// test/setup/mongodb-container.ts
import { GenericContainer, StartedTestContainer } from 'testcontainers';

let sharedContainer: StartedTestContainer | null = null;

export async function getMongoContainer(): Promise<StartedTestContainer> {
  if (!sharedContainer) {
    sharedContainer = await new GenericContainer('mongo:7.0')
      .withExposedPorts(27017)
      .start();
  }
  return sharedContainer;
}

export async function getMongoUri(): Promise<string> {
  const container = await getMongoContainer();
  const host = container.getHost();
  const port = container.getMappedPort(27017);
  return `mongodb://${host}:${port}/test`;
}

export async function stopMongoContainer(): Promise<void> {
  if (sharedContainer) {
    await sharedContainer.stop();
    sharedContainer = null;
  }
}
```

### PostgreSQL Container
```typescript
// test/setup/postgres-container.ts
import { GenericContainer, StartedTestContainer, Wait } from 'testcontainers';

let sharedContainer: StartedTestContainer | null = null;

export async function getPostgresContainer(): Promise<StartedTestContainer> {
  if (!sharedContainer) {
    sharedContainer = await new GenericContainer('postgres:16-alpine')
      .withExposedPorts(5432)
      .withEnvironment({
        POSTGRES_USER: 'test',
        POSTGRES_PASSWORD: 'test',
        POSTGRES_DB: 'testdb',
      })
      .withWaitStrategy(Wait.forLogMessage('database system is ready to accept connections'))
      .start();
  }
  return sharedContainer;
}

export async function getPostgresUri(): Promise<string> {
  const container = await getPostgresContainer();
  const host = container.getHost();
  const port = container.getMappedPort(5432);
  return `postgresql://test:test@${host}:${port}/testdb`;
}

export async function stopPostgresContainer(): Promise<void> {
  if (sharedContainer) {
    await sharedContainer.stop();
    sharedContainer = null;
  }
}
```

## Global Setup/Teardown

### Global Setup
```typescript
// test/setup/global-setup.ts
import { getMongoContainer } from './mongodb-container';

export default async function globalSetup() {
  console.log('\n🚀 Starting test containers...');

  // Start MongoDB container (shared across all tests)
  const container = await getMongoContainer();
  const port = container.getMappedPort(27017);

  console.log(`✅ MongoDB started on port ${port}`);

  // Store container info in global for tests
  process.env.MONGO_TEST_PORT = String(port);
  process.env.MONGO_TEST_HOST = container.getHost();
}
```

### Global Teardown
```typescript
// test/setup/global-teardown.ts
import { stopMongoContainer } from './mongodb-container';

export default async function globalTeardown() {
  console.log('\n🧹 Stopping test containers...');

  await stopMongoContainer();

  console.log('✅ Containers stopped');
}
```

## Jest E2E Configuration

```typescript
// test/jest-e2e.config.ts
import type { Config } from 'jest';

const config: Config = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  modulePaths: ['<rootDir>/..'],
  rootDir: '.',
  testEnvironment: 'node',
  testRegex: '.e2e-spec.ts$',
  transform: {
    '^.+\\.(t|j)s$': ['@swc/jest', { sourceMaps: false }],
  },
  transformIgnorePatterns: ['node_modules/(?!@faker-js)'],
  // Longer timeout for E2E tests
  testTimeout: 30000,
  // Use global setup for container management
  globalSetup: '<rootDir>/setup/global-setup.ts',
  globalTeardown: '<rootDir>/setup/global-teardown.ts',
};

export default config;
```

## Test Application Module

```typescript
// test/testing-app.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CarsFactory } from './factories/cars.factory';
import { ContractsFactory } from './factories/contracts.factory';
import { UsersFactory } from './factories/users.factory';

// Schemas
import { Car, CarSchema } from 'src/cars/schemas/car.schema';
import { Contract, ContractSchema } from 'src/contracts/schemas/contract.schema';
import { User, UserSchema } from 'src/users/schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Car.name, schema: CarSchema },
      { name: Contract.name, schema: ContractSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  providers: [CarsFactory, ContractsFactory, UsersFactory],
  exports: [CarsFactory, ContractsFactory, UsersFactory],
})
export class TestingAppModule {}
```

## GraphQL E2E Test Pattern

### Test Helper
```typescript
// test/helpers/test.helper.ts
import { INestApplication } from '@nestjs/common';
import { Express } from 'express';
import * as request from 'supertest';
import * as jwt from 'jsonwebtoken';

import { UserRole } from 'src/users/enums/user-role.enum';

export interface GraphQLResponse<T> {
  data?: T;
  errors?: Array<{
    message: string;
    extensions?: Record<string, unknown>;
  }>;
}

export interface SendRequestOptions {
  app: INestApplication<Express>;
  query: string;
  variables?: Record<string, unknown>;
  token?: string;
}

export const sendRequest = async <T>({
  app,
  query,
  variables,
  token,
}: SendRequestOptions): Promise<GraphQLResponse<T>> => {
  const req = request(app.getHttpServer())
    .post('/graphql')
    .send({ query, variables });

  if (token) {
    req.set('Authorization', `Bearer ${token}`);
  }

  const response = await req;
  return response.body as GraphQLResponse<T>;
};

// Token builders
export const buildAuthToken = (
  userId: string,
  role: UserRole,
  secret = 'test-secret',
): string => {
  return jwt.sign(
    {
      sub: userId,
      role,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600, // 1 hour
    },
    secret,
  );
};

export const buildManagerAuthToken = (userId = 'manager-id'): string => {
  return buildAuthToken(userId, UserRole.MANAGER);
};

export const buildEmployeeAuthToken = (userId = 'employee-id'): string => {
  return buildAuthToken(userId, UserRole.EMPLOYEE);
};

export const buildValidAuthToken = (): string => {
  return buildManagerAuthToken();
};
```

### Complete E2E Test Example
```typescript
// test/cars.e2e-spec.ts
import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { Express } from 'express';
import mongoose from 'mongoose';

import { ConfigModule } from 'src/config/config.module';
import { DatabaseModule } from 'src/database/database.module';
import { CarsModule } from 'src/cars/cars.module';
import { Car } from 'src/cars/schemas/car.schema';

import { CarsFactory } from './factories/cars.factory';
import { TestingAppModule } from './testing-app.module';
import { getMongoUri } from './setup/mongodb-container';
import {
  sendRequest,
  buildManagerAuthToken,
  buildEmployeeAuthToken,
} from './helpers/test.helper';

describe('Cars (e2e)', () => {
  let app: INestApplication<Express>;
  let carsFactory: CarsFactory;

  beforeAll(async () => {
    const mongoUri = await getMongoUri();

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.register({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [
            () => ({
              DB_CONNECTION: mongoUri,
              JWT_SECRET: 'test-secret',
              ENVIRONMENT: 'test',
            }),
          ],
        }),
        DatabaseModule.forRoot(),
        CarsModule,
        TestingAppModule,
      ],
    }).compile();

    app = moduleRef.createNestApplication({ logger: false });
    await app.init();

    carsFactory = moduleRef.get(CarsFactory);
  }, 60000); // 60s timeout for container startup

  beforeEach(async () => {
    await carsFactory.clean();
  });

  afterAll(async () => {
    await app.close();
    await mongoose.disconnect();
  });

  describe('Query: cars', () => {
    const CARS_QUERY = `
      query Cars($filters: CarFiltersInput) {
        cars(filters: $filters) {
          id
          title
          manufacturer
          price
          status
        }
      }
    `;

    it('returns all cars for authenticated user', async () => {
      await carsFactory.create({ title: 'BMW X5', manufacturer: 'BMW' });
      await carsFactory.create({ title: 'Audi A6', manufacturer: 'Audi' });

      const { data, errors } = await sendRequest<{ cars: Car[] }>({
        app,
        query: CARS_QUERY,
        token: buildManagerAuthToken(),
      });

      expect(errors).toBeUndefined();
      expect(data?.cars).toHaveLength(2);
      expect(data?.cars.map((c) => c.manufacturer)).toContain('BMW');
      expect(data?.cars.map((c) => c.manufacturer)).toContain('Audi');
    });

    it('filters cars by manufacturer', async () => {
      await carsFactory.create({ manufacturer: 'BMW' });
      await carsFactory.create({ manufacturer: 'Audi' });

      const { data } = await sendRequest<{ cars: Car[] }>({
        app,
        query: CARS_QUERY,
        variables: { filters: { manufacturer: 'BMW' } },
        token: buildManagerAuthToken(),
      });

      expect(data?.cars).toHaveLength(1);
      expect(data?.cars[0].manufacturer).toBe('BMW');
    });

    it('returns empty array when no cars match filter', async () => {
      await carsFactory.create({ manufacturer: 'BMW' });

      const { data } = await sendRequest<{ cars: Car[] }>({
        app,
        query: CARS_QUERY,
        variables: { filters: { manufacturer: 'Mercedes' } },
        token: buildManagerAuthToken(),
      });

      expect(data?.cars).toHaveLength(0);
    });

    it('returns error when not authenticated', async () => {
      const { errors } = await sendRequest<{ cars: Car[] }>({
        app,
        query: CARS_QUERY,
      });

      expect(errors).toBeDefined();
      expect(errors![0].message).toContain('Unauthorized');
    });
  });

  describe('Query: car', () => {
    const CAR_QUERY = `
      query Car($id: ID!) {
        car(id: $id) {
          id
          title
          manufacturer
          model
          price
        }
      }
    `;

    it('returns car by ID', async () => {
      const car = await carsFactory.create({
        title: 'BMW X5',
        manufacturer: 'BMW',
        model: 'X5',
        price: 50000,
      });

      const { data, errors } = await sendRequest<{ car: Car }>({
        app,
        query: CAR_QUERY,
        variables: { id: car.id },
        token: buildManagerAuthToken(),
      });

      expect(errors).toBeUndefined();
      expect(data?.car.id).toBe(car.id);
      expect(data?.car.title).toBe('BMW X5');
      expect(data?.car.price).toBe(50000);
    });

    it('returns null for non-existent car', async () => {
      const { data, errors } = await sendRequest<{ car: Car | null }>({
        app,
        query: CAR_QUERY,
        variables: { id: new mongoose.Types.ObjectId().toString() },
        token: buildManagerAuthToken(),
      });

      expect(errors).toBeUndefined();
      expect(data?.car).toBeNull();
    });
  });

  describe('Mutation: createCar', () => {
    const CREATE_CAR_MUTATION = `
      mutation CreateCar($input: CreateCarInput!) {
        createCar(input: $input) {
          id
          title
          manufacturer
          price
        }
      }
    `;

    it('creates car for manager', async () => {
      const input = {
        title: 'BMW X5',
        manufacturer: 'BMW',
        price: 50000,
        year: 2023,
      };

      const { data, errors } = await sendRequest<{ createCar: Car }>({
        app,
        query: CREATE_CAR_MUTATION,
        variables: { input },
        token: buildManagerAuthToken(),
      });

      expect(errors).toBeUndefined();
      expect(data?.createCar.id).toBeDefined();
      expect(data?.createCar.title).toBe('BMW X5');

      // Verify in database
      const cars = await carsFactory.findAll();
      expect(cars).toHaveLength(1);
    });

    it('rejects create for employee', async () => {
      const input = { title: 'BMW X5', manufacturer: 'BMW', price: 50000 };

      const { errors } = await sendRequest<{ createCar: Car }>({
        app,
        query: CREATE_CAR_MUTATION,
        variables: { input },
        token: buildEmployeeAuthToken(),
      });

      expect(errors).toBeDefined();
      expect(errors![0].message).toContain('Forbidden');
    });

    it('validates required fields', async () => {
      const { errors } = await sendRequest<{ createCar: Car }>({
        app,
        query: CREATE_CAR_MUTATION,
        variables: { input: { title: '' } },
        token: buildManagerAuthToken(),
      });

      expect(errors).toBeDefined();
    });
  });

  describe('Mutation: updateCar', () => {
    const UPDATE_CAR_MUTATION = `
      mutation UpdateCar($id: ID!, $input: UpdateCarInput!) {
        updateCar(id: $id, input: $input) {
          id
          title
          price
        }
      }
    `;

    it('updates existing car', async () => {
      const car = await carsFactory.create({ title: 'Old Title', price: 40000 });

      const { data } = await sendRequest<{ updateCar: Car }>({
        app,
        query: UPDATE_CAR_MUTATION,
        variables: { id: car.id, input: { title: 'New Title', price: 45000 } },
        token: buildManagerAuthToken(),
      });

      expect(data?.updateCar.title).toBe('New Title');
      expect(data?.updateCar.price).toBe(45000);
    });
  });

  describe('Mutation: deleteCar', () => {
    const DELETE_CAR_MUTATION = `
      mutation DeleteCar($id: ID!) {
        deleteCar(id: $id)
      }
    `;

    it('deletes existing car', async () => {
      const car = await carsFactory.create();

      const { data } = await sendRequest<{ deleteCar: boolean }>({
        app,
        query: DELETE_CAR_MUTATION,
        variables: { id: car.id },
        token: buildManagerAuthToken(),
      });

      expect(data?.deleteCar).toBe(true);

      // Verify deleted
      const cars = await carsFactory.findAll();
      expect(cars).toHaveLength(0);
    });
  });
});
```

## Testing Authentication & Authorization

```typescript
describe('Authorization', () => {
  describe('role-based access', () => {
    const ADMIN_QUERY = `
      query AdminStats {
        adminStats {
          totalCars
          totalRevenue
        }
      }
    `;

    it('allows manager to access admin stats', async () => {
      const { data, errors } = await sendRequest({
        app,
        query: ADMIN_QUERY,
        token: buildManagerAuthToken(),
      });

      expect(errors).toBeUndefined();
      expect(data).toBeDefined();
    });

    it('denies employee access to admin stats', async () => {
      const { errors } = await sendRequest({
        app,
        query: ADMIN_QUERY,
        token: buildEmployeeAuthToken(),
      });

      expect(errors).toBeDefined();
      expect(errors![0].extensions?.code).toBe('FORBIDDEN');
    });

    it('denies unauthenticated access', async () => {
      const { errors } = await sendRequest({
        app,
        query: ADMIN_QUERY,
      });

      expect(errors).toBeDefined();
      expect(errors![0].extensions?.code).toBe('UNAUTHENTICATED');
    });
  });

  describe('token validation', () => {
    it('rejects expired token', async () => {
      const expiredToken = jwt.sign(
        { sub: 'user-id', role: 'manager', exp: Math.floor(Date.now() / 1000) - 3600 },
        'test-secret',
      );

      const { errors } = await sendRequest({
        app,
        query: CARS_QUERY,
        token: expiredToken,
      });

      expect(errors).toBeDefined();
      expect(errors![0].message).toContain('expired');
    });

    it('rejects invalid token', async () => {
      const { errors } = await sendRequest({
        app,
        query: CARS_QUERY,
        token: 'invalid-token',
      });

      expect(errors).toBeDefined();
    });
  });
});
```

## Testing Subscriptions

```typescript
import { createClient } from 'graphql-ws';
import { WebSocket } from 'ws';

describe('Subscriptions', () => {
  let wsClient: any;

  beforeAll(() => {
    const port = app.getHttpServer().address().port;
    wsClient = createClient({
      url: `ws://localhost:${port}/graphql`,
      webSocketImpl: WebSocket,
      connectionParams: {
        authorization: `Bearer ${buildManagerAuthToken()}`,
      },
    });
  });

  afterAll(() => {
    wsClient.dispose();
  });

  it('receives car updates', (done) => {
    const subscription = wsClient.subscribe(
      {
        query: `
          subscription CarUpdated($carId: ID!) {
            carUpdated(carId: $carId) {
              id
              status
            }
          }
        `,
        variables: { carId: 'test-car-id' },
      },
      {
        next: (data: any) => {
          expect(data.data.carUpdated.status).toBe('SOLD');
          done();
        },
        error: done,
        complete: () => {},
      },
    );

    // Trigger update
    setTimeout(async () => {
      await sendRequest({
        app,
        query: UPDATE_CAR_MUTATION,
        variables: { id: 'test-car-id', input: { status: 'SOLD' } },
        token: buildManagerAuthToken(),
      });
    }, 100);
  });
});
```

## Best Practices

### Do's
- Use shared container across tests (faster)
- Clean database in `beforeEach` for isolation
- Use meaningful test data (not random UUIDs)
- Test both success and error paths
- Test authorization for each endpoint
- Set appropriate timeouts for E2E tests

### Don'ts
- Don't start new container for each test
- Don't forget to disconnect mongoose after tests
- Don't test internal implementation details
- Don't share state between tests
- Don't skip authentication tests
