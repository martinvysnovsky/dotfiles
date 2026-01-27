# GraphQL Schema Design

Schema-first GraphQL patterns using `.graphql` files with NestJS.

## Type Definitions

### Basic Type with Documentation

```graphql
"""
Car entity with financial tracking and rental history
"""
type Car @cacheControl(maxAge: 3600) {
  # === Basic Information ===
  "Unique identifier"
  id: ID!

  "Current status of the car"
  status: CarState!

  "Current car number"
  number: String!

  "Full name of car manufacturer, model and equipment type"
  fullName: String!

  # === Financial Information ===
  # NOTE: All prices are stored WITHOUT VAT (bez DPH)
  "Official catalog/pricelist price of car (without VAT)"
  pricelistPrice: Float! @cacheControl(maxAge: 30, scope: PRIVATE)

  "Real purchase price paid for car (without VAT)"
  purchasePrice: Float! @cacheControl(maxAge: 30, scope: PRIVATE)

  # === Related Data ===
  "Type of car"
  type: CarType

  "Get list of all car contracts"
  contracts: [Contract!]!

  "History events list"
  history: [HistoryEvent!]!
}
```

**Key patterns:**
- Triple-quote comments for type descriptions
- Double-quote comments for field descriptions
- Section comments with `# === Section ===`
- Inline notes with `# NOTE:`
- Field-level cache control directives

### Nullable vs Non-Nullable Fields

```graphql
type Car {
  # Required fields (non-nullable)
  id: ID!                    # Always present
  status: CarState!          # Enum - always has value
  pricelistPrice: Float!     # Number - always set

  # Optional fields (nullable)
  vin: String                # May not be available yet
  color: String              # May not be specified
  leasingCompany: String     # Only for leased cars

  # Required arrays (empty array if no items)
  numbers: [String!]!        # Array always exists, items non-null
  contracts: [Contract!]!    # Array always exists

  # Optional arrays (null if not applicable)
  images: [Image!]           # Null if no images
}
```

**Guidelines:**
- Use `!` for required fields
- Use `[Type!]!` for arrays that always exist but may be empty
- Use `[Type!]` for arrays that may be null
- Use nullable fields for truly optional data

## Enums

### Documented Enums

```graphql
"""
Type of vehicle
"""
enum VehicleType {
  "PERSONAL"
  PERSONAL

  "UTILITY"
  UTILITY

  "ELECTRO"
  ELECTRO

  "HYBRID"
  HYBRID
}

"""
State of car in the system
"""
enum CarState {
  "ACTIVE"
  ACTIVE

  "SOLD"
  SOLD

  "WAREHOUSE"
  WAREHOUSE

  "DAMAGED"
  DAMAGED

  "STOLEN"
  STOLEN
}

"""
Rental type for contracts and invoices
"""
enum RentalType {
  "Short-term rental"
  SHORT_TERM

  "Long-term rental"
  LONG_TERM
}
```

**Best practices:**
- Always document enum type with triple-quote comment
- Document each value (helps GraphQL playground)
- Use SCREAMING_SNAKE_CASE for values
- Group related enums together

## Input Types

### Update Inputs

```graphql
"""
Definition for updating car details
"""
input CarInputUpdate {
  """
  Official catalog/pricelist price (without VAT)
  """
  pricelistPrice: Float

  """
  Real purchase price paid for car (without VAT)
  """
  purchasePrice: Float

  "Notes"
  notes: String

  "Car status"
  status: CarState

  "Leasing company name"
  leasingCompany: String

  "MTP completion status"
  mtpCompleted: Boolean

  "MTP completion date"
  mtpDate: Date
}
```

**Patterns:**
- Use `Input` suffix for input types
- All fields typically optional for updates
- Document business rules in comments
- Match field names with type fields

### Create Inputs

```graphql
"""
Definition for creating a new history event
"""
input CreateHistoryEventInput {
  "Event name (required)"
  name: String!

  "Event date (required)"
  date: Date!

  "Event description (optional)"
  description: String

  "Car ID (required)"
  carId: ID!
}
```

**Guidelines:**
- Mark required fields with `!`
- More strict than update inputs
- Validate required business fields

## Field Arguments

### Arguments on Type Fields

```graphql
type Car {
  "Get car sales. Can be filtered by month"
  sales(year: Int, month: Int): Float! @cacheControl(maxAge: 30, scope: PRIVATE)

  "Get list of months where car did renting"
  activeMonths(
    "End date if you want to see costs in future"
    untilDate: DateTime
  ): [ActiveMonth!]! @cacheControl(maxAge: 30)

  "Additional costs for car"
  additionalCosts(
    "Filter by cost type"
    type: CostType
  ): [AdditionalCost!]!
}
```

**Best practices:**
- Document arguments inline
- Use nullable arguments for optional filters
- Name arguments clearly (`untilDate` not `date`)
- Add cache control with arguments in mind

### Arguments on Queries

```graphql
extend type Query {
  "One car by ID or number"
  car(id: ID, number: String): Car @cacheControl(maxAge: 3600)

  "All cars with optional filtering"
  cars(
    "Filter by car states"
    statuses: [CarState!]
    "Filter by rental types"
    rentalTypes: [RentalType!]
  ): [Car!]! @cacheControl(maxAge: 3600)

  "All cars which are active in given month"
  activeCarsInMonth(year: Int, month: Int): [Car!]!
    @cacheControl(maxAge: 1800, scope: PRIVATE)
}
```

**Patterns:**
- Multiple argument options (id OR number)
- Array arguments for multiple filters
- Clear filter names (`statuses` not `filter`)

## Extend Type Pattern

### Modular Schema Organization

```graphql
# common.graphql - Base types
type Query {
  "Just for initial testing"
  test: String
}

type Mutation {
  "Fake mutation"
  test: String
}
```

```graphql
# cars.graphql - Car module
extend type Query {
  "One car"
  car(id: ID, number: String): Car @cacheControl(maxAge: 3600)

  "All cars"
  cars(statuses: [CarState!]): [Car!]! @cacheControl(maxAge: 3600)
}

extend type Mutation {
  "Update car details"
  updateCar(id: ID!, data: CarInputUpdate!): Car! @cacheControl(maxAge: 0)
}
```

```graphql
# active-months.graphql - Active months module
extend type Car {
  "Get list of months where car did renting"
  activeMonths(untilDate: DateTime): [ActiveMonth!]!
    @cacheControl(maxAge: 30)
}

extend type Query {
  "All cars which are active in given month"
  activeCarsInMonth(year: Int, month: Int): [Car!]!
    @cacheControl(maxAge: 1800, scope: PRIVATE)
}
```

**Benefits:**
- One `.graphql` file per module/feature
- Easy to find related schema definitions
- Clear ownership of fields
- Scales well with large schemas

## Custom Directives

### Cache Control Directive

```graphql
"""
Scope of cache
"""
enum CacheControlScope {
  "Public for all users"
  PUBLIC

  "Private scope for every user"
  PRIVATE
}

directive @cacheControl(
  maxAge: Int
  scope: CacheControlScope
  inheritMaxAge: Boolean
) on FIELD_DEFINITION | OBJECT | INTERFACE | UNION
```

**Usage patterns:**

```graphql
# Type-level cache (default for all fields)
type Car @cacheControl(maxAge: 3600) {
  id: ID!
  title: String!

  # Field-level override (shorter cache for sensitive data)
  price: Float! @cacheControl(maxAge: 30, scope: PRIVATE)
}

# Query-level cache
extend type Query {
  cars: [Car!]! @cacheControl(maxAge: 3600)
  
  # No cache for mutations
  updateCar(id: ID!): Car! @cacheControl(maxAge: 0)
}
```

**Guidelines:**
- Use longer cache (3600s = 1h) for stable data
- Use short cache (30s) for frequently changing data
- Use `PRIVATE` scope for user-specific data
- Set `maxAge: 0` for mutations
- Type-level directive applies to all fields unless overridden

## Custom Scalars

### Scalar Definitions

```graphql
# In your schema (implicit declaration)
type Car {
  "Registration date"
  registrationDate: Date

  "Last modified timestamp"
  modifiedAt: DateTime

  "Profile image upload"
  avatar: Upload
}
```

### Scalar Mapping in Code

```typescript
// In GraphQL module configuration
GraphQLModule.forRoot({
  autoSchemaFile: true,
  resolvers: {
    Date: GraphQLDate,
    DateTime: GraphQLDateTime,
    Upload: GraphQLUpload,
  },
});
```

**Common scalars:**
- `Date`: ISO date string (YYYY-MM-DD)
- `DateTime`: ISO datetime string with timezone
- `Upload`: File upload type
- `JSON`: Arbitrary JSON data

## Complex Types

### Nested Objects

```graphql
type Car {
  id: ID!
  type: CarType
  costs: Costs!
}

type CarType {
  id: ID!
  name: String!
  category: String!
}

type Costs {
  id: ID!
  motorInsurance: Float!
  insurance: Float!
  roadTax: Float!
  interest: Float!
}
```

### Computed Fields

```graphql
type Car {
  # Stored fields
  purchasePrice: Float!
  actualSalePrice: Float!

  # Computed fields (calculated in resolver)
  "Expected total amortization (pricelist price)"
  amortizationExpected: Float! @cacheControl(maxAge: 30, scope: PRIVATE)

  "Real total amortization (actual depreciation)"
  amortizationReal: Float! @cacheControl(maxAge: 30, scope: PRIVATE)

  "Income tax amount on car sale"
  incomeTaxAmount: Float! @cacheControl(maxAge: 30, scope: PRIVATE)
}
```

**Guidelines:**
- Document computed fields clearly
- Use shorter cache for computed values
- Consider adding `@deprecated` for legacy fields

## Schema Organization

### File Structure

```
src/
├── graphql/
│   └── common.graphql          # Shared types, directives, base Query/Mutation
├── cars/
│   ├── cars.graphql            # Car types, queries, mutations
│   ├── cars.resolver.ts
│   └── cars.service.ts
├── active-months/
│   ├── active-months.graphql   # ActiveMonth type, extends Car
│   ├── active-months.resolver.ts
│   └── active-months.service.ts
└── contracts/
    ├── contracts.graphql       # Contract type, queries
    ├── contracts.resolver.ts
    └── contracts.service.ts
```

### Schema Loading in NestJS

```typescript
// app.module.ts
GraphQLModule.forRoot<ApolloDriverConfig>({
  driver: ApolloDriver,
  typePaths: ['./**/*.graphql'],  // Auto-discover all .graphql files
  definitions: {
    path: join(process.cwd(), 'src/generated/graphql.ts'),
  },
}),
```

## Best Practices

1. **Documentation**
   - Every type must have triple-quote description
   - Every field should have double-quote description
   - Use inline notes (`# NOTE:`) for important context
   - Document units (currency, time, distance)

2. **Naming Conventions**
   - Types: PascalCase (`Car`, `CarType`)
   - Fields: camelCase (`pricelistPrice`, `activeMonths`)
   - Enums: SCREAMING_SNAKE_CASE (`SHORT_TERM`)
   - Inputs: PascalCase with `Input` suffix (`CarInputUpdate`)

3. **Cache Control**
   - Set type-level defaults
   - Override for sensitive/dynamic fields
   - Use `PRIVATE` scope for user data
   - Shorter cache for frequently changing data

4. **Modularity**
   - One `.graphql` file per domain
   - Use `extend type` for cross-module fields
   - Keep related types together
   - Base types in `common.graphql`

5. **Field Arguments**
   - Make filters nullable (optional)
   - Use clear, descriptive names
   - Document expected format/range
   - Support multiple filter combinations
