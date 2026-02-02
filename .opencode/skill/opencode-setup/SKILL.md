---
name: opencode-setup
description: Configure and customize OpenCode CLI. Use when (1) setting up opencode.json config, (2) connecting providers and API keys, (3) creating custom agents, (4) building skills, (5) configuring MCP servers, (6) setting up themes and keybinds, (7) managing tool permissions, (8) configuring formatters and rules.
---

# OpenCode Configuration

## Quick Reference

This skill provides comprehensive OpenCode configuration patterns. Load reference files as needed:

**Core Configuration:**
- **[configuration.md](references/configuration.md)** - opencode.json schema, config locations, precedence order, all available options
- **[providers.md](references/providers.md)** - Setting up LLM providers (Anthropic, OpenAI, Google, Zen), API key management
- **[agents.md](references/agents.md)** - Built-in agents (Build/Plan), creating custom agents, agent options and permissions
- **[skills.md](references/skills.md)** - Creating SKILL.md files, frontmatter requirements, reference patterns, permissions

## Essential Commands

```bash
# Initialize OpenCode in a project
opencode                        # Start TUI
/init                          # Analyze project and create AGENTS.md

# Provider connection
/connect                       # Interactive provider setup

# Agent management
<Tab>                          # Switch between primary agents (Build/Plan)
@agent-name                    # Invoke subagent in message

# Sharing (if enabled)
/share                         # Share current conversation
```

## Repository-Specific Configuration

Your OpenCode setup (from `~/.config/opencode/config.json` managed by chezmoi):

### Current Configuration
- **Model**: Claude Sonnet 4.5 (latest)
- **Theme**: Catppuccin (matching system theme)
- **Sharing**: Disabled for privacy
- **Auto-update**: Enabled

### Permissions
- **Edit/Write**: Allowed
- **Bash**: Allowed
- **WebFetch**: Allowed

### Instructions (Rules)
Located at `~/.config/opencode/rules/`:
- `agent-guidelines.md` - Agent behavior guidelines
- `code-standards.md` - Code quality standards
- `error-handling.md` - Error handling patterns
- `frontend-standards.md` - Frontend coding conventions
- `testing-standards.md` - Testing requirements

### MCP Integration
- **Gateway**: `http://localhost:8888` (remote MCP server)
- **Timeout**: 10 seconds
- **OAuth**: Disabled

### Custom Agents
Located at `~/.config/opencode/agent/`:
- `git-master.md` - Git operations specialist
- `documentation.md` - Documentation creation
- `devops.md` - Infrastructure and deployment
- `backend-tester.md` - Backend testing strategies
- `frontend-tester.md` - Frontend testing strategies
- `browser-automation.md` - Browser testing with agent-browser
- And more specialized agents

### Custom Skills
Located at `~/.config/opencode/skills/`:
- `nestjs/` - NestJS patterns and best practices
- `react/` - React component patterns
- `graphql/` - GraphQL schema and resolver patterns
- `mongoose/` - MongoDB with Mongoose patterns
- `testing-nestjs/` - NestJS testing strategies
- `testing-react/` - React testing patterns
- `marketing/` - Marketing analytics (GA4, Google Ads, SEO)
- `google-tag-manager/` - GTM implementation patterns
- `bitbucket-pipelines/` - CI/CD pipeline patterns

## Configuration File Locations

OpenCode loads configuration in this order (later overrides earlier):

1. **Remote config** - From `.well-known/opencode` endpoint (organizational defaults)
2. **Global config** - `~/.config/opencode/opencode.json` (managed by chezmoi in your setup)
3. **Project config** - `opencode.json` in project root
4. **Environment variable** - `OPENCODE_CONFIG` for custom path

### Chezmoi Integration

Your global config is managed by chezmoi:
- **Source**: `~/.local/share/chezmoi/dot_config/opencode/config.json`
- **Target**: `~/.config/opencode/config.json`
- **Changes**: Edit source file, then run `chezmoi apply`

## Basic Configuration Structure

```json
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "catppuccin",
  "model": "anthropic/claude-sonnet-4-5-20250929",
  "share": "disabled",
  "autoupdate": true,
  "permission": {
    "edit": "allow",
    "bash": "allow",
    "webfetch": "allow"
  },
  "instructions": [
    "rules/agent-guidelines.md",
    "rules/code-standards.md"
  ],
  "agent": {},
  "mcp": {}
}
```

## Agent Modes

### Primary Agents (Switch with Tab)

**Build Mode** (default):
- Full development capabilities
- All tools enabled (read, write, edit, bash)
- Use for implementing features and making changes

**Plan Mode**:
- Read-only analysis
- Cannot make file changes
- Use for code review, exploration, planning

### Subagents (Invoke with @mention)

**General**:
- Multi-step tasks and research
- Full tool access
- Use for parallel work units

**Explore**:
- Fast read-only codebase exploration
- Pattern searching and analysis
- Use for finding files or understanding structure

## Creating Custom Configuration

### Project-Specific Config

Create `opencode.json` in project root:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["./CONTRIBUTING.md", "./docs/guidelines.md"],
  "agent": {
    "custom-reviewer": {
      "description": "Code review without modifications",
      "mode": "subagent",
      "tools": {
        "write": false,
        "edit": false
      }
    }
  }
}
```

### Custom Agent Example

Create `~/.config/opencode/agent/code-reviewer.md`:

```markdown
---
description: Reviews code for best practices and potential issues
mode: subagent
model: anthropic/claude-sonnet-4-5
tools:
  write: false
  edit: false
---

You are a code reviewer focusing on:
- Security vulnerabilities
- Performance implications
- Code maintainability
- Best practices
```

### Custom Skill Example

Create `~/.config/opencode/skills/my-framework/SKILL.md`:

```markdown
---
name: my-framework
description: Patterns for MyFramework. Use when working with MyFramework projects.
---

# MyFramework Patterns

## Quick Reference
[Content here]
```

## Common Patterns

### Machine-Specific Provider Config

When different machines need different providers (work vs personal), use chezmoi templates:

```json
// In dot_config/opencode/config.json.tmpl
{
  "model": "{{ if eq .chezmoi.hostname "work-laptop" }}openai/gpt-4{{ else }}anthropic/claude-sonnet-4-5{{ end }}"
}
```

### Encrypted API Keys

Store sensitive API keys encrypted with chezmoi:

```bash
# Add encrypted API key file
chezmoi add --encrypt ~/.config/opencode/secrets.json

# Reference in config with {file:...}
{
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{file:~/.config/opencode/secrets.json}"
      }
    }
  }
}
```

### Per-Project Instructions

Use glob patterns to load all project guidelines:

```json
{
  "instructions": [
    "CONTRIBUTING.md",
    "docs/guidelines/*.md",
    ".opencode/rules/*.md"
  ]
}
```

## Tool Permissions

### Permission Levels
- `"allow"` - Execute without approval
- `"ask"` - Prompt user for approval
- `"deny"` - Block the tool entirely

### Global Permissions
```json
{
  "permission": {
    "edit": "ask",
    "bash": "ask",
    "webfetch": "allow"
  }
}
```

### Agent-Specific Permissions
```json
{
  "agent": {
    "plan": {
      "permission": {
        "bash": {
          "*": "ask",
          "git status": "allow",
          "git log*": "allow"
        }
      }
    }
  }
}
```

## Best Practices

### Configuration Management
- ✅ **DO** manage global config with chezmoi
- ✅ **DO** commit project configs to Git
- ✅ **DO** use `.tmpl` for machine-specific settings
- ✅ **DO** encrypt API keys with chezmoi GPG
- ❌ **DON'T** commit plaintext API keys
- ❌ **DON'T** duplicate configuration across locations

### Agent Design
- ✅ **DO** create focused agents for specific tasks
- ✅ **DO** use subagents for read-only analysis
- ✅ **DO** set appropriate tool permissions
- ✅ **DO** provide clear descriptions for agent selection
- ❌ **DON'T** give all tools to analysis agents
- ❌ **DON'T** create overly broad agents

### Skill Creation
- ✅ **DO** follow the SKILL.md frontmatter format
- ✅ **DO** provide specific, actionable descriptions
- ✅ **DO** use reference files for detailed content
- ✅ **DO** include concrete examples
- ❌ **DON'T** duplicate existing skills
- ❌ **DON'T** use generic descriptions

### Instructions (Rules)
- ✅ **DO** keep rules focused and actionable
- ✅ **DO** organize rules by category
- ✅ **DO** include examples in rule files
- ✅ **DO** reference rules from config
- ❌ **DON'T** write overly verbose rules
- ❌ **DON'T** contradict other rules

## When to Load Reference Files

**Setting up configuration?**
- Complete config schema → [configuration.md](references/configuration.md)
- Config locations and precedence → [configuration.md](references/configuration.md)
- All available options → [configuration.md](references/configuration.md)

**Connecting providers?**
- API key setup → [providers.md](references/providers.md)
- OpenCode Zen setup → [providers.md](references/providers.md)
- Multiple provider configuration → [providers.md](references/providers.md)
- Local model setup → [providers.md](references/providers.md)

**Creating custom agents?**
- Agent options and structure → [agents.md](references/agents.md)
- Permission configuration → [agents.md](references/agents.md)
- Agent modes (primary vs subagent) → [agents.md](references/agents.md)

**Building skills?**
- SKILL.md format and frontmatter → [skills.md](references/skills.md)
- Name validation rules → [skills.md](references/skills.md)
- Reference file patterns → [skills.md](references/skills.md)
- Skill permissions → [skills.md](references/skills.md)

## Integration with Chezmoi

This OpenCode setup integrates with your chezmoi dotfiles:

- **Global Config**: `~/.config/opencode/config.json` (managed by chezmoi)
- **Agents Directory**: `~/.config/opencode/agent/` (exact_ prefix in chezmoi)
- **Skills Directory**: `~/.config/opencode/skills/` (exact_ prefix in chezmoi)
- **Rules Directory**: `~/.config/opencode/rules/` (exact_ prefix in chezmoi)
- **Project Config**: `.opencode/` in project repositories
- **Encryption**: Use chezmoi GPG for sensitive configuration

To update global config:
```bash
# Edit source file
chezmoi edit ~/.config/opencode/config.json

# Or edit directly and re-add
vim ~/.config/opencode/config.json
chezmoi re-add ~/.config/opencode/config.json

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply
```
