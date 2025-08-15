# Testing Standards

## Test Strategy by Component Type

- **Services and Loaders**: Use real database connections via testcontainers with actual data. These tests verify business logic and database interactions.
- **Resolvers and Controllers**: Use mocked dependencies for true unit tests. Mock all services and external dependencies to test only the component's logic.

## Test Writing Principles

### Test Descriptions
- **Use direct statements without "should"**: 
  - ✅ `returns user data`
  - ❌ `should return user data`
- **Use proper verb forms**: `parses data correctly` not `parse data correctly`
- **Use active voice**: `handles errors` not `error handling`

### Variable Naming
- **Use simple, descriptive names without "mock" prefix**:
  - ✅ `car` instead of `mockCar`
  - ✅ `user` instead of `mockUser` 
  - ✅ `service` instead of `mockService`

### Type Safety
- **Use proper TypeScript types in tests**
- **Avoid `any` types where possible**
- **Use explicit type annotations with test helpers**

### Test Structure
- **Follow Arrange-Act-Assert pattern**
- **Use clear test descriptions**
- **Group related tests using `describe` blocks**
- **Test methods should follow the same order as the methods in the source file being tested**

## Testing Strategy

### Unit Testing Focus
- **Services**: Test all business logic methods with real database interactions
- **Resolvers**: Test all field resolvers, queries, and mutations with mocked dependencies
- **Controllers**: Test all endpoints with mocked services
- **Utilities**: Test all helper functions and utilities

### E2E Testing Focus
- **Integration**: Test critical user workflows end-to-end
- **Authentication**: Test all authentication and authorization flows
- **API Contracts**: Verify API responses match expected schemas
- **Basic functionality**: One general test per API endpoint/GraphQL query/mutation

### What NOT to Test in E2E
- Detailed input validation (move to unit tests)
- Edge cases (move to unit tests)
- Complex business logic validation (move to service tests)
- Sorting and filtering logic (move to unit tests)

## Performance Guidelines

- Unit tests should run quickly without external dependencies
- E2E tests should complete within reasonable time limits
- Use proper test data setup and cleanup
- Avoid unnecessary database operations in unit tests

## Implementation Details

See specific implementation guides in `/guides/testing/` for:
- Framework-specific testing guides
- Code examples and templates
- Dependency injection setups
- Mock creation strategies