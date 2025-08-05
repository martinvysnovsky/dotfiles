# Global Agent Guidelines

## Success Messages

- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌" or similar Italian expressions with emoji

## Available Custom Agents

The following specialized agents are available in `~/.config/opencode/agent/`:

- **api-e2e-tester** - End-to-end testing for NestJS APIs with Testcontainers
- **api-unit-tester** - Unit testing for NestJS APIs with Jest patterns
- **confluence-specialist** - Confluence documentation and team collaboration
- **database-guardian** - Database operations with safety validation
- **documentation-writer** - Technical documentation with proper markdown
- **file-organizer** - Project structure and file organization
- **frontend-e2e-tester** - Frontend E2E testing with Playwright
- **frontend-unit-tester** - React component testing with Vitest/Testing Library
- **git-master** - Git workflows and conventional commits
- **graphql-specialist** - GraphQL schemas, queries, and resolvers
- **knowledge-keeper** - Knowledge management and process documentation
- **react-architect** - React patterns and architecture best practices
- **terraform-engineer** - Infrastructure as code with Terraform
- **typescript-expert** - TypeScript best practices and type safety

## Proactive Agent Usage

**IMPORTANT**: Use these agents proactively when working on related tasks! Don't wait for explicit requests - if you're working on code that falls within an agent's expertise, automatically invoke the appropriate agent to ensure best practices and quality.

Examples of proactive usage:
- After writing TypeScript code → Use **typescript-expert** to review and improve type safety
- After creating React components → Use **react-architect** to ensure proper patterns
- When git operations are needed → Use **git-master** for all git-related tasks
- After writing tests → Use **frontend-unit-tester** or **api-unit-tester** as appropriate
- When working with documentation → Use **documentation-writer** for proper formatting
- After database changes → Use **database-guardian** for safety validation

Use these agents proactively when working on related tasks!
