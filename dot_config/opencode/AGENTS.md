# Global Agent Guidelines

## Success Messages

- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌🎉" or similar Italian expressions with emoji

## Available Agents

Specialized agents are configured in the `agent/` directory:

- **api-e2e-tester**: NestJS E2E testing with Testcontainers + GraphQL
- **api-unit-tester**: NestJS unit testing with Jest + mocking strategies  
- **confluence-specialist**: Confluence documentation workflows and collaboration
- **database-guardian**: Database safety rules and data modification protocols
- **documentation-writer**: Markdown documentation standards and best practices
- **file-organizer**: Project structure and file organization patterns
- **frontend-e2e-tester**: Playwright E2E testing for React applications
- **frontend-unit-tester**: React/TypeScript unit testing with Vitest + Testing Library
- **git-master**: Git workflows, conventional commits, and repository best practices
- **graphql-specialist**: GraphQL query design and conventions
- **knowledge-keeper**: Documentation and knowledge preservation workflows
- **react-architect**: React component architecture and hooks patterns
- **terraform-engineer**: Terraform infrastructure as code best practices
- **typescript-expert**: TypeScript code style and best practices

## Agent Usage

Agents are self-contained markdown files with YAML frontmatter containing their configuration and instructions in the markdown body.