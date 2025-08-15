# Error Handling Standards

## Error Handling Strategy

### Automatic vs Manual Error Handling

**Automatic Error Handling** (Framework handles):
- **GraphQL Resolvers**: Global exception filter captures all errors
- **HTTP Controllers**: Global exception filter captures all errors
- **Validation errors**: Framework validation pipes handle automatically

**Manual Error Handling** (Requires explicit notification):
- **Background jobs and cron tasks**
- **External API integration errors**
- **Authentication strategy errors**
- **Database connection failures**
- **File system operations**
- **Third-party service integrations**

## Success Notification Strategy

**When to Notify Success**:
- Critical background operation completions
- Cron job successes with metrics
- External system synchronization completions
- Batch processing completions
- System maintenance completions

**When NOT to Notify Success**:
- Regular CRUD operations
- Standard API responses
- Simple data retrievals

## Error Context Guidelines

### Always Include
- **operation**: Clear identifier of what operation failed
- **timestamp**: When the error occurred (if not automatic)
- **userId**: If user-specific operation
- **entityId**: If operating on specific entity

### Include When Relevant
- **requestId**: For request tracing
- **externalId**: For external system references
- **parameters**: Input parameters that caused the error
- **retryCount**: For retry mechanisms
- **duration**: For performance-related errors

## Exception Types

### Framework Exceptions
- Use built-in framework exceptions for standard scenarios
- Let global filters handle these automatically
- Examples: `BadRequestException`, `NotFoundException`, `ForbiddenException`

### Custom Application Exceptions
- Create domain-specific exceptions for business logic
- Extend framework base exceptions
- Include proper context and error details

### Background Task Exceptions
- Require manual error notification
- Include operation context for debugging
- Handle retry logic appropriately

## Implementation Patterns

See detailed implementation examples and code templates in `/guides/error-handling/` for:
- Framework-specific error handling guides
- Service integration error handling
- Background job error management
- Custom exception creation
- Error context building strategies