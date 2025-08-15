# Code Organization Standards

## Import Order Guidelines

Follow this strict import order for all TypeScript/JavaScript files:

1. **Framework imports** (e.g., `@nestjs/...`, `@angular/...`, `react`)
2. **Third-party packages** (e.g., `lodash`, `moment`, `axios`)
3. **Generated files** (e.g., `src/generated/...`)
4. **Helper utilities** (e.g., `src/helpers/...`)
5. **Common modules** (e.g., `src/common/...`)
6. **Application modules** (e.g., `src/modules/...`)
7. **Relative imports** (e.g., `./`, `../`)

## Method Ordering Principles

### Component-Specific Ordering
- **Resolvers (GraphQL)**: Field resolvers → Queries → Mutations
- **Services**: Business logic methods → CRUD methods
- **Controllers (REST)**: GET → POST → PUT/PATCH → DELETE
- **Data Loaders**: Constructor → Public properties → Private helpers
- **Background Jobs**: Private helpers → Public job methods
- **Test Files**: Follow same order as source file methods

### Universal Principles
- **Most important functionality first**: Business logic before CRUD operations
- **Public before private**: Public methods before private helpers
- **Logical grouping**: Related methods grouped together
- **Consistent ordering**: Same pattern across similar components

## File Naming Conventions

### File Names
- **kebab-case** for all file names
- **Descriptive suffixes** that indicate file purpose

### File Suffixes
- `.service.ts` for services
- `.resolver.ts` for GraphQL resolvers
- `.controller.ts` for REST controllers
- `.entity.ts` for database entities
- `.interface.ts` for TypeScript interfaces
- `.dto.ts` for data transfer objects
- `.spec.ts` for unit tests
- `.e2e-spec.ts` for end-to-end tests

## Interface Naming Conventions

### Naming Patterns
- `SomethingDocument` for database documents (Mongoose/TypeORM)
- `SomethingModel` for data models
- `SomethingInput` for input types
- `SomethingResponse` for response types
- **PascalCase** for all interface names

### Type Organization
- Group related interfaces in same file
- Use barrel exports for type collections
- Keep domain-specific types together

## Implementation Examples

See detailed code examples and templates in `/guides/` for:
- Framework-specific organization guides
- Complete file structure examples
- Import organization templates
- Method ordering implementations