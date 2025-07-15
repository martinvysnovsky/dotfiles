# File Organization Guidelines

## Project Structure

### Component Organization

- Follow project-specific component organization patterns
- Group related components in logical directories
- Use consistent naming conventions across the project
- Separate concerns (components, utils, types, etc.)

### Index Files

- Use proper export patterns in index files
- Export components and utilities for clean imports
- Avoid deep import paths when possible
- Use barrel exports for module interfaces

### Generated Files

- Keep generated files separate from source files
- Use `.generated.` in filenames for clarity
- Never manually edit generated files
- Include generated files in .gitignore when appropriate

## Method Ordering Standards

### Resolvers (GraphQL)

1. **FieldResolvers** (`@ResolveField`) - Field-specific resolvers first
2. **Queries** (`@Query`) - Data fetching operations
3. **Mutations** (`@Mutation`) - Data modification operations

```typescript
@Resolver(() => User)
export class UserResolver {
  // Field resolvers first
  @ResolveField(() => Profile)
  async profile(@Parent() user: User): Promise<Profile> { ... }

  // Queries second
  @Query(() => User)
  async user(@Args('id') id: string): Promise<User> { ... }

  // Mutations last
  @Mutation(() => User)
  async updateUser(@Args() input: UpdateUserInput): Promise<User> { ... }
}
```

### Services

1. **findOne** - Single entity retrieval
2. **findAll** - Multiple entity retrieval
3. **create** - Entity creation
4. **update** - Entity modification
5. **delete** - Entity removal

```typescript
export class UserService {
  async findOne(id: string): Promise<User> { ... }
  async findAll(filters?: UserFilters): Promise<User[]> { ... }
  async create(input: CreateUserInput): Promise<User> { ... }
  async update(id: string, input: UpdateUserInput): Promise<User> { ... }
  async delete(id: string): Promise<void> { ... }
}
```

### Controllers (REST API)

1. **GET methods** - Data retrieval endpoints
2. **POST methods** - Data creation endpoints
3. **PUT/PATCH methods** - Data modification endpoints
4. **DELETE methods** - Data removal endpoints

```typescript
@Controller('users')
export class UserController {
  // GET methods first
  @Get()
  async findAll(): Promise<User[]> { ... }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<User> { ... }

  // POST methods
  @Post()
  async create(@Body() input: CreateUserDto): Promise<User> { ... }

  // PUT/PATCH methods
  @Put(':id')
  async update(@Param('id') id: string, @Body() input: UpdateUserDto): Promise<User> { ... }

  // DELETE methods last
  @Delete(':id')
  async delete(@Param('id') id: string): Promise<void> { ... }
}
```

### Loaders (DataLoader pattern)

1. **Constructor setup** - Initialization and configuration
2. **Public readonly properties** - Exposed loader instances

```typescript
export class UserLoader {
  // Constructor first
  constructor(private userService: UserService) {
    this.byId = new DataLoader(this.batchLoadById.bind(this));
  }

  // Public properties
  public readonly byId: DataLoader<string, User>;

  // Private methods last
  private async batchLoadById(ids: string[]): Promise<User[]> { ... }
}
```

### Jobs (Scheduled tasks)

1. **Private helper methods** - Internal utility functions
2. **Public job methods** - Methods with `@Cron` decorators

```typescript
export class EmailJob {
  // Private helpers first
  private async validateEmail(email: string): Promise<boolean> { ... }
  private async formatMessage(template: string, data: any): Promise<string> { ... }

  // Public job methods with decorators
  @Cron('0 9 * * *')
  async sendDailyDigest(): Promise<void> { ... }

  @Cron('0 */6 * * *')
  async processEmailQueue(): Promise<void> { ... }
}
```

### Tests

- **Test methods should follow the same order as the methods in the source file being tested**
- Group related tests with `describe` blocks
- Use consistent naming for test descriptions
- Follow AAA pattern (Arrange, Act, Assert)

```typescript
describe('UserService', () => {
  // Test findOne first (matches service method order)
  describe('findOne', () => {
    it('should return user when found', () => { ... });
    it('should throw error when not found', () => { ... });
  });

  // Test findAll second
  describe('findAll', () => {
    it('should return all users', () => { ... });
  });

  // Continue in same order as source file...
});
```

## Directory Structure Best Practices

### Monorepo Organization

```
src/
├── components/          # Reusable UI components
├── pages/              # Page-level components
├── services/           # Business logic services
├── utils/              # Utility functions
├── types/              # TypeScript type definitions
├── hooks/              # Custom React hooks
├── constants/          # Application constants
└── __tests__/          # Test files
```

### Module Boundaries

- Keep related functionality together
- Avoid circular dependencies
- Use clear import/export patterns
- Separate business logic from presentation logic
