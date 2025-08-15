# Global opencode Configuration

This directory contains personal opencode configuration that applies across all projects.

## Files

- **`config.json`** - Personal preferences: theme, models, MCP providers, agent configurations
- **`AGENTS.md`** - Personal communication style and workflow preferences  
- **`rules/*.md`** - General development guidelines that apply across projects
- **`guides/`** - Reusable guides and templates for common development tasks
- **`agent/`** - 7 focused specialized agents for development workflows

## Specialized Agents

### Core Development Agents (3)
- **`typescript-expert.md`** - TypeScript best practices and type safety
- **`react-architect.md`** - React patterns and architecture best practices  
- **`graphql-specialist.md`** - GraphQL schemas, queries, and resolvers

### Consolidated Domain Agents (4)
- **`backend-tester.md`** - Complete backend testing strategy (unit + E2E with Testcontainers)
- **`frontend-tester.md`** - Complete frontend testing strategy (unit with Vitest + E2E with Playwright)
- **`devops.md`** - Infrastructure (Terraform), database safety, and git workflows
- **`documentation.md`** - Technical writing, knowledge management, file organization, and Confluence

## Structure

```
~/.config/opencode/
├── config.json              # Personal settings (theme, models, MCP)
├── AGENTS.md                 # Personal communication preferences & git rules
├── rules/                    # General development standards
│   ├── agent-guidelines.md   # How to use custom agents proactively
│   ├── code-standards.md     # Code style, imports, method ordering
│   ├── error-handling.md     # Error handling patterns
│   ├── frontend-standards.md # React/UI specific guidelines
│   └── testing-standards.md  # Testing strategies and patterns
├── guides/                   # Reusable development guides
│   ├── error-handling/       # API integration & background job patterns
│   ├── nestjs/              # NestJS resolver and service patterns
│   ├── react/               # React component and GraphQL patterns
│   ├── testing/             # Unit testing, E2E, and shared utilities
│   └── typescript/          # Import organization and method ordering
├── templates/               # Code templates and configurations
└── agent/                   # 7 focused specialized agents
    ├── typescript-expert.md    # Core: TypeScript best practices
    ├── react-architect.md      # Core: React patterns & architecture
    ├── graphql-specialist.md   # Core: GraphQL schemas & resolvers
    ├── backend-tester.md       # Domain: Complete backend testing
    ├── frontend-tester.md      # Domain: Complete frontend testing
    ├── devops.md              # Domain: Infrastructure, DB, git
    └── documentation.md       # Domain: Writing, knowledge, organization
```

## Usage

- **Personal settings** (theme, models, Italian messages) go in `config.json` and `AGENTS.md`
- **General development rules** go in `rules/*.md` and are auto-loaded via `instructions` field
- **Project-specific** rules go in each project's `AGENTS.md` file (e.g., chezmoi conventions)