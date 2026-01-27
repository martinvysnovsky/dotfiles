# GraphQL Skill

## Overview

This skill focuses on **GraphQL-specific patterns** that complement but don't duplicate the GraphQL usage patterns already covered in the `nestjs` and `react` skills.

### What This Skill Covers

- **Schema Design**: Schema-first patterns with `.graphql` files
- **Code Generation**: GraphQL Code Generator configuration
- **DataLoaders**: Advanced N+1 prevention patterns

### What This Skill Does NOT Cover

For these topics, refer to the existing skills:

- **Resolver Patterns**: See `nestjs/resolver-patterns` for resolver structure, field resolvers, mutations, authentication, error handling, and subscriptions
- **Apollo Client**: See `react/graphql` for queries, mutations, cache updates, fragments, and optimistic updates

## Quick Reference

| Topic | Reference File | Description |
|-------|----------------|-------------|
| Schema design | `graphql/schema-design` | Type definitions, enums, directives, extend patterns |
| Code generation | `graphql/codegen` | GraphQL Code Generator setup with near-operation-file preset |
| DataLoaders | `graphql/dataloaders` | N+1 query prevention with request-scoped loaders |
| Resolvers | `nestjs/resolver-patterns` | Query/mutation/field resolver implementation |
| Apollo Client | `react/graphql` | Client-side GraphQL with React hooks |

## Architecture

### Schema-First Approach

```
backend/
├── src/
│   ├── cars/
│   │   ├── cars.graphql          # Schema definition
│   │   ├── cars.resolver.ts       # Resolver implementation
│   │   ├── cars.service.ts        # Business logic
│   │   └── car.loader.ts          # DataLoader for N+1 prevention
│   └── graphql/
│       └── common.graphql         # Shared types, directives
```

### Frontend Code Generation

```
frontend/
├── app/
│   ├── components/CarInfo/
│   │   ├── CarInfo.tsx
│   │   ├── graphql/
│   │   │   ├── CarInfoFragment.graphql
│   │   │   └── CarInfoFragment.generated.ts  # Auto-generated
│   └── generated/
│       └── graphql.ts              # Base types (enums, scalars)
└── codegen.ts                      # Configuration
```

## Core Concepts

### 1. Schema-First Development

Define GraphQL schema in `.graphql` files with clear documentation:
- Use triple-quote comments for type/field descriptions
- Define custom directives (`@cacheControl`)
- Modular schema with `extend type` pattern

### 2. TypeScript Code Generation

Generate TypeScript types from GraphQL schema and operations:
- Near-operation-file preset for co-located types
- TypedDocumentNode for type-safe operations
- Proper scalar mappings (Date, DateTime, Upload)

### 3. DataLoader Pattern

Batch and cache data fetching to prevent N+1 queries:
- Request-scoped loaders (fresh per GraphQL request)
- Automatic result reordering
- Support for complex composite keys

## Workflow Integration

### Backend Development

1. Define schema in `.graphql` files
2. Implement resolvers using NestJS patterns
3. Add DataLoaders for relationship fields
4. Test with GraphQL playground

### Frontend Development

1. Write GraphQL operations in `.graphql` files
2. Run code generator to create TypeScript types
3. Import generated hooks in components
4. Use TypedDocumentNode for type safety

## Common Patterns

### Field Arguments

```graphql
type Car {
  "Get car sales. Can be filtered by month"
  sales(year: Int, month: Int): Float!
  
  "Active months with optional date filter"
  activeMonths(untilDate: DateTime): [ActiveMonth!]!
}
```

### Cache Control

```graphql
type Car @cacheControl(maxAge: 3600) {
  id: ID!
  
  "Sensitive financial data with short cache"
  price: Float! @cacheControl(maxAge: 30, scope: PRIVATE)
}
```

### Fragment Composition

```graphql
# fragments/car.graphql
fragment CarBasic on Car {
  id
  title
  price
}

fragment CarDetailed on Car {
  ...CarBasic
  description
  images { url }
}
```

## Best Practices

1. **Schema Design**
   - Document all types and fields with triple-quote comments
   - Use enums for fixed value sets with clear descriptions
   - Apply `@cacheControl` directives at type and field level
   - Organize schema files by domain (one per module)

2. **Code Generation**
   - Run codegen after schema changes
   - Commit generated files to version control
   - Use `enumsAsTypes: false` to generate real TypeScript enums
   - Configure scalar mappings for all custom scalars

3. **DataLoaders**
   - Use request-scoped loaders (`Scope.REQUEST`)
   - Batch similar queries together
   - Cache loaded entities within request
   - Handle null results gracefully

4. **Performance**
   - Set appropriate `maxAge` for cache control
   - Use PRIVATE scope for user-specific data
   - Batch field resolvers with DataLoaders
   - Avoid N+1 queries on list fields

## Related Skills

- **nestjs**: Resolver implementation, authentication, error handling
- **react**: Apollo Client usage, cache management, optimistic updates
- **testing-nestjs**: Testing resolvers and DataLoaders
- **testing-react**: Testing GraphQL queries and mutations
