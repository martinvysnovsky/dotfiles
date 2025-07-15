# General Coding Guidelines

## Universal Coding Standards

### Code Quality
- Write self-documenting code with clear, descriptive names
- Keep functions and methods small and focused on single responsibility
- Use consistent naming conventions throughout the project
- Avoid deep nesting - prefer early returns and guard clauses

### Error Handling
- Handle errors explicitly, don't ignore them
- Use appropriate error types for different scenarios
- Provide meaningful error messages for debugging
- Log errors with sufficient context for troubleshooting

### Performance Considerations
- Optimize for readability first, performance second
- Profile before optimizing - don't guess at bottlenecks
- Use appropriate data structures for the task
- Consider memory usage and avoid unnecessary allocations

### Security Best Practices
- Never commit secrets, API keys, or passwords to version control
- Validate and sanitize all user inputs
- Use parameterized queries to prevent injection attacks
- Follow principle of least privilege for access controls

## Code Style

### Formatting
- Use consistent indentation (spaces vs tabs, follow project convention)
- Keep line lengths reasonable (80-120 characters)
- Use whitespace to improve readability
- Group related code together with blank lines

### Comments and Documentation
- Write comments that explain "why", not "what"
- Keep comments up-to-date with code changes
- Use JSDoc/docstrings for public APIs
- Document complex algorithms and business logic

### Variable and Function Naming
- Use descriptive names that reveal intent
- Avoid abbreviations unless widely understood
- Use consistent naming patterns across the codebase
- Boolean variables should be questions (isValid, hasPermission)

## Testing

### Test Strategy
- Write tests for critical business logic
- Test edge cases and error conditions
- Use descriptive test names that explain the scenario
- Keep tests simple and focused on single behaviors

### Test Organization
- Group related tests with describe/context blocks
- Follow AAA pattern: Arrange, Act, Assert
- Use test fixtures and factories for consistent test data
- Mock external dependencies appropriately

## Version Control

### Commit Practices
- Write clear, descriptive commit messages
- Make atomic commits that represent single logical changes
- Use conventional commit format when applicable
- Review changes before committing

### Branch Management
- Use feature branches for new development
- Keep branches short-lived and focused
- Use descriptive branch names
- Rebase or merge appropriately based on team conventions

## Dependencies

### Dependency Management
- Keep dependencies up-to-date and secure
- Avoid unnecessary dependencies
- Pin versions for reproducible builds
- Regular security audits of dependencies
- Use `npm ci --ignore-scripts` in pipelines or Dockerfiles when project contains husky to prevent git hooks from running in CI environments

### Library Usage
- Prefer well-maintained, popular libraries
- Understand the libraries you use
- Follow library best practices and conventions
- Consider bundle size impact for frontend projects

## Code Reviews

### Review Guidelines
- Review for correctness, readability, and maintainability
- Check for security vulnerabilities
- Ensure tests are adequate
- Verify documentation is updated

### Collaboration
- Be constructive and respectful in feedback
- Explain reasoning behind suggestions
- Ask questions when code is unclear
- Acknowledge good practices and improvements

## Refactoring

### When to Refactor
- When adding new features to legacy code
- When fixing bugs in poorly structured code
- When code becomes difficult to understand or maintain
- As part of regular code maintenance

### Refactoring Practices
- Make small, incremental changes
- Ensure tests pass after each refactoring step
- Don't change behavior while refactoring
- Document significant architectural changes