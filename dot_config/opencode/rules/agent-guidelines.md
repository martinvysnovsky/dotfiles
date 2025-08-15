# Agent Usage Guidelines

## External File Loading

**CRITICAL**: When you encounter a file reference (e.g., @rules/development-standards.md), use your Read tool to load it on a need-to-know basis when they're relevant to the SPECIFIC task at hand.

Instructions:
- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## Available Custom Agents

The following specialized agents are available in `~/.config/opencode/agent/`:

- **backend-tester** - Comprehensive testing for NestJS APIs (unit + E2E with Testcontainers)
- **devops** - Infrastructure as code (Terraform), database safety, and git workflows
- **documentation** - Technical writing, knowledge management, file organization, and Confluence
- **frontend-tester** - Comprehensive React testing (unit with Vitest + E2E with Playwright)
- **graphql-specialist** - GraphQL schemas, queries, and resolvers
- **react-architect** - React guides and architecture best practices
- **typescript-expert** - TypeScript best practices and type safety

## Proactive Agent Usage

**IMPORTANT**: Use these agents proactively when working on related tasks! Don't wait for explicit requests - if you're working on code that falls within an agent's expertise, automatically invoke the appropriate agent to ensure best practices and quality.

Examples of proactive usage:
- After writing TypeScript code → Use **typescript-expert** to review and improve type safety
- After creating React components → Use **react-architect** to ensure proper guides
- When git operations are needed → Use **devops** for all git-related tasks
- After writing tests → Use **backend-tester** or **frontend-tester** as appropriate
- When working with documentation → Use **documentation** for proper formatting
- After database changes → Use **devops** for safety validation
- When working with infrastructure → Use **devops** for Terraform configurations

## Agent Priority Rules

1. **devops** has complete authority over ALL git operations, database modifications, and infrastructure tasks
2. **documentation** should handle any README, documentation creation, or knowledge management
3. **typescript-expert** should review any significant TypeScript code changes
4. **backend-tester** and **frontend-tester** provide comprehensive testing strategies for their respective domains

## Git Standards

- Do NOT mention opencode in commit messages
- Do NOT add Co-Authored-By opencode in commits
- Follow conventional commit format when appropriate
- Always use devops agent for any git operations