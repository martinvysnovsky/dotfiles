# Code Standards

Quick reference for coding conventions. For detailed patterns, load relevant skills.

## Skills Reference

| Skill | Use For |
|-------|---------|
| **nestjs** | Services, resolvers, DI, pagination, background jobs, exceptions |
| **mongoose** | Schemas, documents, queries, aggregation, embedded schemas |
| **react** | Components, forms, GraphQL client, MUI, routing, hooks |
| **graphql** | Schema design, code generation, DataLoaders |
| **testing-nestjs** | Jest + @suites/unit, Testcontainers E2E, TestDataFactory |
| **testing-react** | Vitest + Testing Library, Apollo MockedProvider |

## Import Order

### Backend (NestJS)
1. Framework (`@nestjs/...`)
2. Third-party packages
3. Generated files (`src/generated/...`)
4. Helpers (`src/helpers/...`)
5. Common (`src/common/...`)
6. Modules (`src/modules/...`)
7. Relative (`./`, `../`)

### Frontend (React)
React → MUI → @ packages → ~ alias → relative

## Method Ordering

| Component | Order |
|-----------|-------|
| **Resolvers** | @ResolveField → @Query → @Mutation |
| **Services** | Business logic → CRUD (findOne, findAll, create, update, delete) |
| **Controllers** | GET → POST → PUT/PATCH → DELETE |
| **Background Jobs** | Private helpers → Public job methods |
| **Tests** | Same order as source file |

## Naming Conventions

### Files (kebab-case)
`.service.ts`, `.resolver.ts`, `.controller.ts`, `.entity.ts`, `.dto.ts`, `.spec.ts`, `.e2e-spec.ts`

### Interfaces (PascalCase)
`SomethingDocument`, `SomethingModel`, `SomethingInput`, `SomethingResponse`

### React
- Components: PascalCase, default exports
- Props: `ComponentNameProps` suffix
- Path alias: `~/*` for app directory

## TypeScript

- Single quotes, trailing commas (Prettier)
- Strict mode, explicit types
- Avoid `any` - use proper types
- Prefer constructor DI

## Testing

### Descriptions
- Direct statements: `returns user data` (not `should return...`)
- Active voice: `handles errors` (not `error handling`)

### Variables
- Simple names: `car` (not `mockCar`)
- Arrange-Act-Assert pattern

### Strategy
- **Services/Loaders**: Real database via Testcontainers
- **Resolvers/Controllers**: Mocked dependencies

## Enum Usage

### Golden Rule
**ALWAYS reuse generated enums from `src/generated/graphql`. NEVER create duplicate enums or use string literals.**

### Import Pattern
```typescript
// ✅ CORRECT
import { CarState, RentalType } from 'src/generated/graphql';
const car = await this.carModel.findOne({ status: CarState.ACTIVE });

// ❌ WRONG - String literal
const car = await this.carModel.findOne({ status: 'ACTIVE' });

// ❌ WRONG - Duplicate enum
enum CarStatus { ACTIVE = 'ACTIVE' }
```

### Workflow
1. Check `src/generated/graphql.ts` for existing enums
2. Import from generated types
3. Use enum values everywhere (services, DTOs, schemas, tests)

**Details**: See `graphql/enum-patterns` for comprehensive patterns

## Error Handling

### Automatic (framework handles)
- GraphQL resolvers, HTTP controllers

### Manual (requires `loggerService.notifyError()`)
- Background jobs, cron tasks, external APIs

## Git

- Use **git-master** agent for all git operations
- Conventional commit format
- No "opencode" in commits, no Co-Authored-By
