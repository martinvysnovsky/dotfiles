# Global Agent Guidelines

## Database Safety Rules

**CRITICAL: Always ask for explicit user confirmation before running any script that modifies database data.**

Scripts that require confirmation:

- Data migration scripts
- Database update operations
- Record deletion scripts
- Schema modification scripts
- Any script that writes/modifies data

Scripts that can be run without confirmation:

- Read-only operations (backups, queries)
- Information display scripts
- Connection tests
- Build/test commands

## Meta Guidelines

- **Proactive Documentation**: When discovering new coding patterns, conventions, or rules during conversations, proactively update either this local AGENTS.md file or the global AGENTS.md file to preserve institutional knowledge for future sessions
- **Rule Discovery**: If a user establishes a new coding standard, preference, or workflow during a conversation, immediately document it in the appropriate AGENTS.md file
- **Knowledge Preservation**: Treat AGENTS.md files as living documents that should evolve with each conversation to capture learned best practices
