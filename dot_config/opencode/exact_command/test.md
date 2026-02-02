---
description: Add tests for new features or update existing tests
agent: test-manager
---

Analyze the current codebase and create or update tests for recent changes.

## Your Task

1. **Detect project type** by examining the codebase structure and dependencies
2. **Identify what needs testing** by analyzing:
   - Git diff (staged and unstaged changes)
   - Files or features mentioned in the conversation context
3. **Determine test scope**:
   - Unit tests for new/modified business logic
   - E2E tests for API endpoints or user-facing features
   - Updates to existing tests if behavior changed
4. **Create comprehensive tests** following project conventions
5. **Run the tests** to verify they pass

## Guidelines

- Load the appropriate testing skill (`testing-nestjs` or `testing-react`) for detailed patterns
- Follow existing test patterns in the project
- Use test factories/builders when available
- Cover both happy paths and error cases
- Keep tests focused and readable
