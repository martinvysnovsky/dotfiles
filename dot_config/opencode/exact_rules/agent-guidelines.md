# Agent Usage Guidelines

## Tool Usage Preferences

### List Tool Configuration

- **CRITICAL**: The `list` tool must show ALL files and directories, including those in .gitignore
- Do NOT filter out .gitignore entries when using the list tool
- For comprehensive codebase analysis, all files must be visible regardless of git tracking status
- **WORKAROUND**: If list tool filters .gitignore entries, use `bash` with `find` or `ls -la` commands to see all files

## External File Loading

**CRITICAL**: When you encounter a file reference (e.g., @rules/code-standards.md), use your Read tool to load it on a need-to-know basis when they're relevant to the SPECIFIC task at hand.

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

## Reference Code Access from Old Projects

**CRITICAL**: Use the `reference_*` custom tools to access code from `~/www/` directory when:

- User asks to "check old projects" or "check previous projects"
- User mentions specific project names like "EDENcars", "Ketler", "Riwers", "Ambitas", "HA Frontend", etc.
- User asks for reference implementations or examples from past work
- User wants to find similar code patterns from previous projects

### Available Reference Tools

1. **`reference_list_projects`** - List all available projects in ~/www/
   - Use when user wants to see what projects are available
   - Use at the start when unsure which project to check

2. **`reference_read_file`** - Read specific files from old projects
   - Example: `reference_read_file projectPath="edencars/src/components/Auth.tsx"`
   - Use when you know the exact file path needed

3. **`reference_search_files`** - Search for files by glob pattern
   - Example: `reference_search_files pattern="riwers/**/*.graphql"`
   - Example: `reference_search_files pattern="**/authentication/**/*.ts"`
   - Use when searching for specific file types or patterns

4. **`reference_list_directory`** - Show directory structure
   - Example: `reference_list_directory projectPath="ketler/src"`
   - Use to understand project structure before diving into specific files

### Project Name Mapping

When user mentions these project names, use the corresponding directory path. The ~/www/ folder contains multiple organizations with subprojects:

#### EDENcars Projects (edencars/\*)

- "EDENcars" or "Eden Cars" → `edencars/`
- "EDENcars Infosystem" → `edencars/edencars-infosystem/` or `edencars/edencars-infosystem-api/`
- "Eden Bazar" or "EdenBazar" → `edencars/edenbazar/` or `edencars/edenbazar-api/`
- "Auto Sklad" → `edencars/auto-sklad/` or `edencars/auto-sklad-api/`
- "TaxiRent" → `edencars/taxirent/` or `edencars/taxirent-api/`
- "Drive Patak" → `edencars/drivepatak/`

#### Ketler Projects (ketler/\*)

- "Ketler" → `ketler/`
- "Gravel Trans Jura" → `ketler/gravel-trans-jura/`

#### Riwers Projects (riwers/\*)

- "Bergversetzer" → `riwers/bergversetzer-fe/`, `riwers/bergversetzer-api/`
- "EFTEC HR" → `riwers/eftec-hr-fe/`, `riwers/eftec-hr-api/`
- "Hygentile" → `riwers/hygentile-fe/`, `riwers/hygentile-api/`
- "Procorp" → `riwers/procorp-fe/`, `riwers/procorp-api/`
- "WorkConnect" → `riwers/workconnect-fe/`, `riwers/workconnect-api/`

#### Other Projects

- "Peppermill" → `peppermill/peppermill/` or `peppermill/peppermill-api/`

**IMPORTANT**:

- Always use lowercase directory names even if user uses different casing
- Many projects have separate frontend/backend/api/infrastructure repos
- Use `reference_list_projects` or `reference_search_files` if unsure of exact path
- Projects often follow pattern: `organization/project-name-{fe,api,infrastructure}/`

## Available Custom Agents

The following specialized agents are available in `~/.config/opencode/agent/`:

- **backend-tester** - Comprehensive testing for NestJS APIs (unit + E2E with Testcontainers)
- **devops** - Infrastructure as code (Terraform), database safety, and git workflows
- **documentation** - Technical writing, knowledge management, file organization, and Confluence
- **frontend-tester** - Comprehensive React testing (unit with Vitest + E2E with Playwright)
- **graphql-specialist** - GraphQL schemas, queries, and resolvers
- **react-architect** - React guides and architecture best practices
- **security** - Security scanning (Snyk CLI), vulnerability detection, OWASP Top 10, code security review
- **typescript-expert** - TypeScript best practices and type safety

## Proactive Agent Usage

**IMPORTANT**: Use these agents proactively when working on related tasks! Don't wait for explicit requests - if you're working on code that falls within an agent's expertise, automatically invoke the appropriate agent to ensure best practices and quality.

Examples of proactive usage:

- After writing TypeScript code → Use **typescript-expert** to review and improve type safety
- After creating React components → Use **react-architect** to ensure proper guides
- When git operations are needed → Use **git-master** for all git-related tasks
- After writing tests → Use **backend-tester** or **frontend-tester** as appropriate
- When working with documentation → Use **documentation** for proper formatting
- After database changes → Use **devops** for safety validation
- When working with infrastructure → Use **devops** for Terraform configurations
- Before deployments or security reviews → Use **security** for Snyk scans and vulnerability detection

## Agent Priority Rules

1. **git-master** has complete authority over ALL git operations; **devops** handles database modifications and infrastructure tasks
2. **documentation** should handle any README, documentation creation, or knowledge management
3. **typescript-expert** should review any significant TypeScript code changes
4. **backend-tester** and **frontend-tester** provide comprehensive testing strategies for their respective domains
5. **security** should handle any security scanning, vulnerability assessment, or Snyk CLI operations

## Git Standards

- Do NOT mention opencode in commit messages
- Do NOT add Co-Authored-By opencode in commits
- Follow conventional commit format when appropriate
- Always use git-master agent for any git operations
