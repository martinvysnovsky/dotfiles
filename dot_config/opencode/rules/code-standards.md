# Code Standards

## Import Organization

Follow this strict import order for all TypeScript/JavaScript files:

1. **Framework imports** (e.g., `@nestjs/...`, `@angular/...`, `react`)
2. **Third-party packages** (e.g., `lodash`, `moment`, `axios`)
3. **Generated files** (e.g., `src/generated/...`)
4. **Helper utilities** (e.g., `src/helpers/...`)
5. **Common modules** (e.g., `src/common/...`)
6. **Application modules** (e.g., `src/modules/...`)
7. **Relative imports** (e.g., `./`, `../`)

### React/Frontend Import Sorting
- **Order**: React → MUI → @ → ~ → relative (auto-sorted with simple-import-sort)
- **Path aliases**: Use `~/*` for app directory imports
- **Object keys**: Auto-sorted alphabetically

## Method Ordering Standards

### Universal Principles
- **Most important functionality first**: Business logic before CRUD operations
- **Public before private**: Public methods before private helpers
- **Logical grouping**: Related methods grouped together
- **Consistent ordering**: Same pattern across similar components

### Component-Specific Ordering
- **Resolvers (GraphQL)**: Field resolvers (@ResolveField) → Queries (@Query) → Mutations (@Mutation)
- **Services**: Business logic methods → CRUD methods (findOne, findAll, create, update, delete)
- **Controllers (REST)**: GET → POST → PUT/PATCH → DELETE methods
- **Data Loaders**: Constructor → Public properties → Private helpers
- **Background Jobs**: Private helpers → Public job methods
- **Test Files**: Follow same order as source file methods being tested

## TypeScript Standards

### Code Style
- **Use single quotes and trailing commas** (Prettier config)
- **TypeScript strict mode** with explicit types
- **Avoid `any` types** - use proper TypeScript typing
- **Use readonly** for immutable properties in interfaces
- **Prefer dependency injection** via constructor

### File Naming Conventions
- **kebab-case** for all file names with descriptive suffixes
- `.service.ts` for services
- `.resolver.ts` for GraphQL resolvers
- `.controller.ts` for REST controllers
- `.entity.ts` for database entities
- `.interface.ts` for TypeScript interfaces
- `.dto.ts` for data transfer objects
- `.spec.ts` for unit tests
- `.e2e-spec.ts` for end-to-end tests

### Interface Naming Conventions
- `SomethingDocument` for database documents (Mongoose/TypeORM)
- `SomethingModel` for data models
- `SomethingInput` for input types
- `SomethingResponse` for response types
- **PascalCase** for all interface names

### Type Organization
- Group related interfaces in same file
- Use barrel exports for type collections
- Keep domain-specific types together

## React Standards

### Component Organization
- **Components**: Use default exports, PascalCase naming
- **Props interfaces**: Use `Props` suffix (e.g., `CarDetailsProps`)
- **No React imports**: JSX transform enabled, no need to import React
- **Project structure**: All application code under `app/` directory

### React Router
- **Route components**: Prefer route arguments over useParams hook
- **Pattern**: `function Component({ params }: Route.ComponentProps)`
- **useParams**: Can be used in non-route components that need URL parameters

### Best Practices
- **Links**: Always use MUI Link component instead of React Router Link
- **Form elements**: Use components from `~/components/form/` instead of raw MUI
- **Date handling**: Use `dateColumn` for proper null date display
- **Price formatting**: Return empty strings for null/undefined instead of "NaN €"

## Material-UI (MUI) Standards

### Component Usage
- **Grid**: Use Grid2 syntax
- **Containers**: Use Paper for containers
- **Table columns**: Always add `minWidth` for proper display
- **Column definitions**: Extract as constants outside components

### Sizing Guidelines
- **Column widths**: dates (100px), prices (100px), text (120px), names (200px)
- **Flex values**: Use whole numbers only, never decimals (e.g., `flex: 1` not `flex: 0.8`)
- **Table height**: Use `fullHeight` for full-page tables

## GraphQL Standards

### Query Conventions
- **Query names**: NO "Query" suffix (e.g., `query Pricelist` not `query PricelistQuery`)
- **Generated types**: Use `.generated.ts` files
- **Apollo hooks**: Use generated hooks from codegen

### Error Handling
- **Error handling**: Use ErrorMessage component for GraphQL errors
- **Loading states**: Use Loading component for async operations

## Testing Standards

### Test Descriptions
- **Use direct statements without "should"**: `returns user data` not `should return user data`
- **Use proper verb forms**: `parses data correctly` not `parse data correctly`

### Variable Naming in Tests
- **Use simple, descriptive names without "mock" prefix**: `car` not `mockCar`
- **Use explicit type annotations with `fromPartial`**

### Test Strategy
- **Services/Loaders**: Use real database connections via testcontainers
- **Resolvers/Controllers**: Use mocked dependencies for unit tests
- **Follow Arrange-Act-Assert pattern**

## Configuration File Standards

### Shell Scripts
- Use `#!/bin/bash` shebang
- Follow existing patterns in run scripts
- Use proper error handling with `set -e`
- Quote variables to prevent word splitting

### Lua (Neovim)
- Use tabs for indentation
- Return table syntax for plugins
- Follow lazy.nvim plugin structure
- Keep configs modular in separate files

### YAML/TOML
- Use 2-space indentation for YAML
- Follow chezmoi configuration patterns in TOML
- Maintain consistent formatting across files

### General Configuration
- Use meaningful variable names
- Document complex configurations
- Test changes with `chezmoi diff` before applying
- Keep sensitive data encrypted

## Error Handling Standards

### Automatic Handling
- GraphQL resolvers and HTTP controllers use global exception filters
- No manual error notifications needed for these components

### Manual Error Notifications
- **Required for**: Background jobs, cron tasks, external API integrations
- **Use `loggerService.notifyError()`** with proper context
- **Success notifications**: Only for critical background operations

## Performance Guidelines

### Pipeline Optimization
- **Combine related operations**: Merge lint, typecheck, test, build into single steps
- **Use parallel steps sparingly**: Only for truly independent operations
- **Fail fast**: Place critical checks early in pipeline
- **Cache effectively**: Share caches between consolidated operations

### Code Performance
- Use proper caching strategies with appropriate durations
- Implement proper database indexing and query optimization
- Use connection pooling for database connections
- Implement proper pagination for large datasets

## Git Standards

- **CRITICAL**: All git operations must use the devops agent
- Do NOT mention opencode in commit messages
- Do NOT add Co-Authored-By opencode in commits
- Follow conventional commit format when appropriate
- Auto-commit and auto-push are enabled in chezmoi config

## Implementation Examples

### Skills
Load comprehensive implementation patterns with `openskills read <skill-name>`:
- **nestjs** - NestJS backend patterns: services, GraphQL resolvers, DI, pagination, background jobs, custom exceptions
- **mongoose** - Mongoose database patterns: entities (@Schema/@Prop), documents/models (HydratedDocument), queries (FilterQuery, aggregation), embedded schemas, helpers (setters/getters/virtuals)
- **react** - React patterns: components, forms with react-hook-form + Zod, GraphQL with Apollo Client, MUI components, routing, hooks, state management
- **graphql** - GraphQL-specific patterns: schema design (schema-first), code generation (GraphQL Code Generator), DataLoaders (N+1 prevention)
- **testing-nestjs** - NestJS testing: Jest + @suites/unit auto-mocking, Testcontainers E2E, TestDataFactory patterns, database cleanup
- **testing-react** - React testing: Vitest + Testing Library, component/hook testing, Apollo MockedProvider, browser API mocks

### Additional References
Advanced patterns are available within relevant skills:
- **nestjs/references/api-integrations.md** - HTTP clients, WebSocket, file uploads, bulk operations
- **nestjs/references/background-jobs.md** - Circuit breaker, graceful degradation, job health monitoring
- **testing-nestjs/references/ci-cd.md** - GitHub Actions, GitLab CI, Docker Compose for tests