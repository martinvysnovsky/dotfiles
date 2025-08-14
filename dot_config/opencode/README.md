# Global opencode Configuration

This directory contains personal opencode configuration that applies across all projects.

## Files

- **`config.json`** - Personal preferences: theme, models, MCP providers, agent configurations
- **`AGENTS.md`** - Personal communication style and workflow preferences  
- **`rules/*.md`** - General development guidelines that apply across projects
- **`patterns/`** - Reusable patterns and templates for common development tasks
- **`agent/`** - Custom specialized agents for different development workflows

## Structure

```
~/.config/opencode/
├── config.json              # Personal settings (theme, models, MCP)
├── AGENTS.md                 # Personal communication preferences & git rules
├── rules/                    # General development standards
│   ├── agent-guidelines.md   # How to use custom agents proactively
│   └── development-standards.md # General code style & git standards
├── patterns/                 # Reusable development patterns
└── agent/                    # Custom specialized agents
```

## Usage

- **Personal settings** (theme, models, Italian messages) go in `config.json` and `AGENTS.md`
- **General development rules** go in `rules/*.md` and are auto-loaded via `instructions` field
- **Project-specific** rules go in each project's `AGENTS.md` file (e.g., chezmoi conventions)