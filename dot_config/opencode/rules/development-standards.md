# Development Standards

## Code Style Guidelines

### TypeScript/JavaScript
- **Import order**: Framework → packages → generated → helpers → common → modules → relative
- **Use single quotes and trailing commas** (Prettier config)
- **TypeScript strict mode** with explicit types
- **Interface naming**: `SomethingDocument` for database documents, `SomethingModel` for models
- **File naming**: kebab-case with descriptive suffixes (`.service.ts`, `.resolver.ts`, etc.)
- **Use readonly** for immutable properties in interfaces
- **Prefer dependency injection** via constructor
- **Avoid `any` types** - use proper TypeScript typing

### React/Frontend Specific
- **Components**: Use default exports, PascalCase naming
- **Props interfaces**: Use `Props` suffix (e.g., `CarDetailsProps`)
- **No React imports**: JSX transform enabled, no need to import React
- **Project structure**: All application code under `app/` directory
- **Path aliases**: Use `~/*` for app directory imports
- **Import sorting**: React → MUI → @ → ~ → relative (auto-sorted with simple-import-sort)
- **Object keys**: Auto-sorted alphabetically
- **Links**: Always use MUI Link component instead of React Router Link
- **Form elements**: Use components from `~/components/form/` instead of raw MUI
- **Date handling**: Use `dateColumn` for proper null date display
- **Price formatting**: Return empty strings for null/undefined instead of "NaN €"

### React Router
- **Route components**: Prefer route arguments over useParams hook
- **Pattern**: `function Component({ params }: Route.ComponentProps)`
- **useParams**: Can be used in non-route components that need URL parameters

### Material-UI (MUI)
- **Grid**: Use Grid2 syntax
- **Containers**: Use Paper for containers
- **Table columns**: Always add `minWidth` for proper display
- **Column widths**: dates (100px), prices (100px), text (120px), names (200px)
- **Flex values**: Use whole numbers only, never decimals (e.g., `flex: 1` not `flex: 0.8`)
- **Table height**: Use `fullHeight` for full-page tables
- **Column definitions**: Extract as constants outside components

### GraphQL
- **Query names**: NO "Query" suffix (e.g., `query Pricelist` not `query PricelistQuery`)
- **Generated types**: Use `.generated.ts` files
- **Apollo hooks**: Use generated hooks from codegen
- **Error handling**: Use ErrorMessage component for GraphQL errors
- **Loading states**: Use Loading component for async operations

### Method Ordering Standards
- **Resolvers**: Field resolvers (@ResolveField) → queries (@Query) → mutations (@Mutation)
- **Services**: Business logic methods → CRUD methods (findOne, findAll, create, update, delete)
- **Controllers**: GET → POST → PUT/PATCH → DELETE methods
- **Tests**: Follow same order as source file methods being tested

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

### Configuration Files
- Use meaningful variable names
- Document complex configurations
- Test changes with `chezmoi diff` before applying
- Keep sensitive data encrypted

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

## Error Handling Standards

### Automatic Handling
- GraphQL resolvers and HTTP controllers use global exception filters
- No manual error notifications needed for these components

### Manual Error Notifications
- **Required for**: Background jobs, cron tasks, external API integrations
- **Use `loggerService.notifyError()`** with proper context
- **Success notifications**: Only for critical background operations

## Git Standards

- **CRITICAL**: All git operations must use the git-master agent
- Do NOT mention opencode in commit messages
- Do NOT add Co-Authored-By opencode in commits
- Follow conventional commit format when appropriate
- Auto-commit and auto-push are enabled in chezmoi config

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