# GraphQL Code Generator

Generate TypeScript types from GraphQL schema and operations using `@graphql-codegen/cli`.

## Configuration File

### Basic Structure

```typescript
// codegen.ts
import type { CodegenConfig } from "@graphql-codegen/cli";

const config: CodegenConfig = {
  // Schema source
  schema: process.env.VITE_API_URL || "http://localhost:4000/graphql",

  // GraphQL documents (queries, mutations, fragments)
  documents: ["app/**/*.graphql"],

  // Generation targets
  generates: {
    // Per-operation files
    app: {
      preset: "near-operation-file",
      presetConfig: {
        baseTypesPath: "./generated/graphql.ts",
        extension: ".generated.ts",
      },
      plugins: ["typescript-operations", "typed-document-node"],
      config: { /* ... */ },
    },

    // Base types file
    "app/generated/graphql.ts": {
      plugins: ["typescript"],
      config: { /* ... */ },
    },
  },

  // Global options
  overwrite: true,
  ignoreNoDocuments: true,
  watch: process.env.NODE_ENV === "development",
  verbose: process.env.DEBUG === "true",
  hooks: {
    afterAllFileWrite: ["prettier --write"],
  },
};

export default config;
```

## Near-Operation-File Preset

### File Organization

**Input structure:**
```
app/
├── components/
│   ├── CarInfo/
│   │   ├── CarInfo.tsx
│   │   └── graphql/
│   │       ├── CarInfoFragment.graphql
│   │       └── UpdateCarMutation.graphql
│   └── CarList/
│       ├── CarList.tsx
│       └── graphql/
│           └── CarsQuery.graphql
```

**Generated output:**
```
app/
├── components/
│   ├── CarInfo/
│   │   ├── CarInfo.tsx
│   │   └── graphql/
│   │       ├── CarInfoFragment.graphql
│   │       ├── CarInfoFragment.generated.ts      # ✨ Generated
│   │       ├── UpdateCarMutation.graphql
│   │       └── UpdateCarMutation.generated.ts    # ✨ Generated
│   └── CarList/
│       ├── CarList.tsx
│       └── graphql/
│           ├── CarsQuery.graphql
│           └── CarsQuery.generated.ts            # ✨ Generated
└── generated/
    └── graphql.ts                                # ✨ Base types
```

### Preset Configuration

```typescript
{
  preset: "near-operation-file",
  presetConfig: {
    // Path to base types (relative to generated file location)
    baseTypesPath: "./generated/graphql.ts",
    
    // Extension for generated files
    extension: ".generated.ts",
    
    // Optional: Only generate for files matching pattern
    // baseTypesPath: "~graphql/types",
  },
}
```

**Benefits:**
- Types co-located with operations
- Easy to find related code
- Tree-shakeable (only import what you use)
- Better IDE autocomplete context

## Plugin Configuration

### Operation Files (near-operation-file)

```typescript
{
  plugins: ["typescript-operations", "typed-document-node"],
  config: {
    // === Type Generation ===
    // Don't generate enums in operation files (import from base)
    enumsAsTypes: false,
    
    // Only generate types for operations (not full schema)
    onlyOperationTypes: true,
    
    // Pre-resolve types for better performance
    preResolveTypes: true,

    // === Import Configuration ===
    // Use TypeScript type imports (import type { ... })
    useTypeImports: true,
    
    // Don't add __typename to every object
    skipTypename: false,

    // === Performance ===
    // Add /*#__PURE__*/ comment for tree-shaking
    pureMagicComment: true,
    
    // Remove duplicate fragments
    dedupeFragments: true,

    // === Custom Scalars ===
    scalars: {
      Date: "string",
      DateTime: "string",
      Upload: "File",
    },

    // === Naming ===
    // Keep original naming from GraphQL
    namingConvention: "keep",

    // === Validation ===
    // Skip document validation during generation
    skipDocumentsValidation: false,
  },
}
```

### Base Types File

```typescript
{
  plugins: ["typescript"],
  config: {
    // === Enum Generation ===
    // Generate real TypeScript enums (not union types)
    enumsAsTypes: false,
    
    // Make enums future-proof (allow additional values)
    futureProofEnums: true,
    
    // Use const enums for smaller bundle
    constEnums: false,
    
    // Don't use numeric enums
    numericEnums: false,

    // === Custom Scalars ===
    scalars: {
      Date: "string",
      DateTime: "string",
      Upload: "File",
    },

    // === Import Configuration ===
    useTypeImports: true,

    // === Schema Processing ===
    // Don't strip non-null from schema
    stripNonNullFromSchema: false,
  },
}
```

## Scalar Mappings

### Common Scalar Types

```typescript
scalars: {
  // Date scalars
  Date: "string",              // ISO date: "2024-01-15"
  DateTime: "string",          // ISO datetime: "2024-01-15T10:30:00Z"
  
  // File uploads
  Upload: "File",              // Browser File object
  
  // JSON data
  JSON: "Record<string, any>", // Generic JSON object
  JSONObject: "Record<string, any>",
  
  // Numbers
  BigInt: "bigint",            // JavaScript BigInt
  Long: "number",              // 64-bit integer as number
  
  // IDs
  UUID: "string",              // UUID string
}
```

### Custom Scalar Mapping

```typescript
// For branded types
scalars: {
  UserId: "string & { __brand: 'UserId' }",
  Email: "string & { __brand: 'Email' }",
}

// For library types
scalars: {
  DateTime: "Date",            // Native Date object
  Decimal: "Decimal",          // Import from decimal.js
  Money: "Dinero",             // Import from dinero.js
}
```

## TypedDocumentNode

### Generated Hooks

```typescript
// CarInfoFragment.generated.ts
import type { TypedDocumentNode } from '@graphql-typed-document-node/core';

export type CarInfoFragment = {
  __typename?: 'Car';
  id: string;
  title: string;
  price: number;
};

export const CarInfoFragmentDoc: TypedDocumentNode<
  CarInfoFragment,
  Record<string, never>
> = /* GraphQL */ `
  fragment CarInfo on Car {
    id
    title
    price
  }
`;
```

### Usage in Components

```typescript
import { useQuery } from '@apollo/client';
import { CarsQueryDoc } from './graphql/CarsQuery.generated';

function CarList() {
  // Fully typed query with TypedDocumentNode
  const { data, loading } = useQuery(CarsQueryDoc);
  
  // data is typed as CarsQuery | undefined
  // data.cars is typed as Car[]
  
  return (
    <div>
      {data?.cars.map(car => (
        <div key={car.id}>{car.title}</div>
      ))}
    </div>
  );
}
```

## Enum Generation

### Schema Definition

```graphql
enum CarState {
  ACTIVE
  SOLD
  WAREHOUSE
  DAMAGED
}
```

### Generated TypeScript Enum

```typescript
// app/generated/graphql.ts
export enum CarState {
  Active = 'ACTIVE',
  Sold = 'SOLD',
  Warehouse = 'WAREHOUSE',
  Damaged = 'DAMAGED'
}

// Future-proof enum (allows unknown values)
export type CarStateFutureAdded = CarState | `${CarState}`;
```

### Using Generated Enums

```typescript
import { CarState } from '~/generated/graphql';

// Type-safe enum usage
const status: CarState = CarState.Active;

// Comparison
if (car.status === CarState.Sold) {
  // Handle sold car
}

// Switch statement
switch (car.status) {
  case CarState.Active:
    return 'Available';
  case CarState.Sold:
    return 'Not available';
  default:
    return 'Unknown';
}
```

## Fragment Spreading

### Fragment Definition

```graphql
# CarBasicFragment.graphql
fragment CarBasic on Car {
  id
  title
  price
}

# CarDetailedFragment.graphql
fragment CarDetailed on Car {
  ...CarBasic
  description
  mileage
  images {
    id
    url
  }
}
```

### Generated Types

```typescript
// CarBasicFragment.generated.ts
export type CarBasicFragment = {
  __typename?: 'Car';
  id: string;
  title: string;
  price: number;
};

// CarDetailedFragment.generated.ts
export type CarDetailedFragment = {
  __typename?: 'Car';
  id: string;
  title: string;
  price: number;
  description: string;
  mileage: number;
  images: Array<{
    __typename?: 'Image';
    id: string;
    url: string;
  }>;
};
```

## Running Code Generation

### NPM Scripts

```json
{
  "scripts": {
    "codegen": "graphql-codegen --config codegen.ts",
    "codegen:watch": "graphql-codegen --config codegen.ts --watch",
    "codegen:debug": "DEBUG=true graphql-codegen --config codegen.ts"
  }
}
```

### Development Workflow

```bash
# One-time generation
npm run codegen

# Watch mode (regenerate on schema/operation changes)
npm run codegen:watch

# Debug mode (verbose output)
npm run codegen:debug
```

### CI/CD Integration

```yaml
# .github/workflows/ci.yml
- name: Generate GraphQL Types
  run: npm run codegen

- name: Check for uncommitted changes
  run: |
    git diff --exit-code || (
      echo "Generated files have uncommitted changes"
      exit 1
    )
```

## Configuration Options

### Global Options

```typescript
{
  // Overwrite existing generated files
  overwrite: true,

  // Don't fail if no documents found
  ignoreNoDocuments: true,

  // Watch for changes in development
  watch: process.env.NODE_ENV === "development",

  // Verbose logging
  verbose: process.env.DEBUG === "true",

  // Silent mode (suppress output)
  silent: false,

  // Require schema to exist
  errorsOnly: false,
}
```

### Hooks

```typescript
{
  hooks: {
    // Run after each file is written
    afterOneFileWrite: ["prettier --write"],

    // Run after all files are written
    afterAllFileWrite: [
      "prettier --write",
      "eslint --fix",
    ],

    // Run before generation starts
    beforeAllFileWrite: [
      "echo 'Starting codegen...'",
    ],
  },
}
```

## Best Practices

1. **File Organization**
   - Keep `.graphql` files in `graphql/` folder within component
   - Use descriptive names: `CarsQuery.graphql`, `UpdateCarMutation.graphql`
   - Co-locate fragments with components that use them

2. **Commit Generated Files**
   - Always commit `.generated.ts` files
   - Add to CI checks to ensure they're up to date
   - Don't gitignore generated files

3. **Scalar Mappings**
   - Map all custom scalars to TypeScript types
   - Use branded types for domain-specific scalars
   - Document scalar format in schema comments

4. **Enum Configuration**
   - Use `enumsAsTypes: false` to generate real enums
   - Enable `futureProofEnums` for API evolution
   - Import enums from base types file

5. **Performance**
   - Use `pureMagicComment` for better tree-shaking
   - Enable `dedupeFragments` to reduce bundle size
   - Use `preResolveTypes` for faster generation
   - Don't generate unnecessary fields with `onlyOperationTypes`

6. **Development Workflow**
   - Run codegen in watch mode during development
   - Run codegen before commits
   - Run codegen in CI to catch drift

7. **Type Safety**
   - Use TypedDocumentNode for all operations
   - Import generated types for component props
   - Don't use `any` - leverage generated types

## Common Issues

### Issue: Generated files out of date

```bash
# Solution: Run codegen
npm run codegen
```

### Issue: Schema URL unreachable

```typescript
// Use local schema file instead
const config: CodegenConfig = {
  schema: "./schema.graphql",  // Local schema file
  // OR
  schema: [
    "http://localhost:4000/graphql",
    "./local-schema-extensions.graphql",  // Additional local types
  ],
};
```

### Issue: Scalar type mismatches

```typescript
// Ensure scalar mappings match runtime
scalars: {
  // Backend sends ISO string, map to string
  DateTime: "string",
  
  // NOT Date (would need parsing/serialization)
  // DateTime: "Date",  // ❌ Runtime mismatch
}
```

### Issue: Enum value conflicts

```typescript
// Use futureProofEnums to allow unknown values
config: {
  futureProofEnums: true,  // Allows new enum values from API
}
```
