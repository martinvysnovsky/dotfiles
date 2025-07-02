# Global Agent Guidelines

## Database Safety Rules

**CRITICAL: Always ask for explicit user confirmation before running any script that modifies database data.**

Scripts that require confirmation:

- Data migration scripts
- Database update operations
- Record deletion scripts
- Schema modification scripts
- Any script that writes/modifies data

Scripts that can be run without confirmation:

- Read-only operations (backups, queries)
- Information display scripts
- Connection tests
- Build/test commands

## Meta Guidelines

- **Proactive Documentation**: When discovering new coding patterns, conventions, or rules during conversations, proactively update either the local AGENTS.md file or the global AGENTS.md file to preserve institutional knowledge for future sessions
- **Rule Discovery**: If a user establishes a new coding standard, preference, or workflow during a conversation, immediately document it in the appropriate AGENTS.md file
- **Knowledge Preservation**: Treat AGENTS.md files as living documents that should evolve with each conversation to capture learned best practices
- **Local vs Global**: Update local AGENTS.md for project-specific rules, update global AGENTS.md for universal patterns
- **Learning from Corrections**: When a user corrects a mistake and the correction represents new general guidance (not just a one-off fix), immediately document this guidance in the appropriate AGENTS.md file to prevent similar mistakes in future sessions
- **README Maintenance**: When creating new features, tools, configurations, or significant changes that would be valuable for users to know about, proactively update the README.md file to keep documentation current and comprehensive

## Common Code Conventions

### GraphQL

- **Query naming**: Query names should NOT include 'Query' suffix (e.g., `query Pricelist` not `query PricelistQuery`)
- **Generated types**: Use generated TypeScript types from GraphQL schema
- **Apollo hooks**: Use Apollo Client hooks for data fetching

### TypeScript

- **Strict mode**: Enable strict TypeScript checking
- **Type safety**: Avoid `any` types, use proper interfaces and types
- **Import organization**: Follow project-specific import sorting rules

### React

- **Component structure**: Use functional components with hooks
- **Props interfaces**: Define clear prop interfaces with descriptive names
- **Error handling**: Implement proper error boundaries and error states
- **Loading states**: Show appropriate loading indicators

### File Organization

- **Component structure**: Follow project-specific component organization patterns
- **Index files**: Use proper export patterns in index files
- **Generated files**: Keep generated files separate from source files
- **Method ordering**:
  - Resolvers: FieldResolvers (@ResolveField) first, then queries (@Query), then mutations (@Mutation)
  - Services: findOne, findAll, create, update, delete
  - Controllers: GET methods first, then POST, PUT/PATCH, DELETE methods
  - Loaders: Constructor setup first, then public readonly properties
  - Jobs: Private helper methods first, then public job methods (typically with @Cron decorators)
  - **Tests**: Test methods should follow the same order as the methods in the source file being tested
