# Global Agent Guidelines

## Success Messages

- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌" or similar Italian expressions with emoji

## External File Loading

**CRITICAL**: When you encounter a file reference (e.g., @rules/chezmoi-conventions.md), use your Read tool to load it on a need-to-know basis when they're relevant to the SPECIFIC task at hand.

Instructions:
- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## Development Guidelines

For chezmoi-specific conventions and file naming: @rules/chezmoi-conventions.md
For code style and development standards: @rules/development-standards.md
For testing strategies and patterns: @patterns/testing/**/*.md

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

Use these agents proactively when working on related tasks!
