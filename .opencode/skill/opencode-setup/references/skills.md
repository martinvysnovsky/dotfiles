# OpenCode Skills Reference

Complete guide to creating, structuring, and managing OpenCode skills.

## Overview

Skills are reusable instruction sets that agents can load on-demand. They provide domain-specific knowledge without cluttering the main context.

**How It Works**:
1. OpenCode discovers skill definitions from configured directories
2. Skills appear in agent's `skill` tool description with name and description
3. Agent loads full skill content when needed via tool call
4. Permissions control which skills agents can access

## Skill File Locations

OpenCode searches these locations in order:

### Project Config
```
.opencode/skills/<name>/SKILL.md
.opencode/skill/<name>/SKILL.md       # Singular also works
.claude/skills/<name>/SKILL.md        # Claude-compatible
```

### Global Config
```
~/.config/opencode/skills/<name>/SKILL.md
~/.config/opencode/skill/<name>/SKILL.md
~/.claude/skills/<name>/SKILL.md
```

**Discovery**: OpenCode walks up from current directory to git worktree root, loading all matching skills found.

## SKILL.md Structure

### Required Frontmatter

Every `SKILL.md` must start with YAML frontmatter:

```markdown
---
name: skill-name
description: Clear description of what this skill covers and when to use it
---

# Skill Content

[Skill documentation goes here]
```

**Required Fields**:
- `name` - Skill identifier (must match directory name)
- `description` - 1-1024 chars, used for agent selection

**Optional Fields**:
- `license` - License identifier (e.g., MIT)
- `compatibility` - Target system (e.g., opencode)
- `metadata` - String-to-string map for custom data

**Ignored**: Any other frontmatter fields are silently ignored

### Name Requirements

Skill names must follow strict rules:

**Pattern**: `^[a-z0-9]+(-[a-z0-9]+)*$`

**Rules**:
- Lowercase alphanumeric only
- Single hyphen separators allowed
- 1-64 characters
- Cannot start or end with `-`
- Cannot contain consecutive `--`
- Must match directory name exactly

**Valid Examples**:
```
chezmoi
nestjs
google-tag-manager
testing-react
opencode-setup
```

**Invalid Examples**:
```
Chezmoi          # Uppercase not allowed
nest_js          # Underscores not allowed
--skill          # Cannot start with -
skill-           # Cannot end with -
my--skill        # Consecutive -- not allowed
MySkill          # Uppercase not allowed
skill.name       # Dots not allowed
```

### Description Requirements

**Length**: 1-1024 characters

**Purpose**: Help agent decide when to load the skill

**Good Descriptions** (specific and actionable):
```yaml
description: NestJS patterns for services and GraphQL resolvers including structure, dependency injection, error handling, background jobs, field resolvers, queries, mutations, subscriptions, and testing. Use when (1) creating NestJS services or resolvers, (2) implementing CRUD operations with Mongoose, (3) adding GraphQL field resolvers.
```

**Bad Descriptions** (too generic):
```yaml
description: NestJS stuff
description: Use for backend development
description: Help with code
```

## File Organization Patterns

### Pattern 1: Single-File Skill (Simple)

For focused, concise skills:

```
.opencode/skills/my-skill/
└── SKILL.md
```

**Example** (200-500 lines):
```markdown
---
name: my-skill
description: Brief skill covering X, Y, and Z
---

# My Skill

## Quick Patterns

[Core patterns and examples]

## Common Operations

[Step-by-step guides]

## Best Practices

[Do's and don'ts]
```

### Pattern 2: Multi-File Skill (Comprehensive)

For complex skills with extensive documentation:

```
.opencode/skills/my-framework/
├── SKILL.md                    # Main file with quick reference
└── references/
    ├── setup.md                # Setup and installation
    ├── patterns.md             # Common patterns
    ├── advanced.md             # Advanced features
    └── troubleshooting.md      # Common issues
```

**Main SKILL.md** (quick reference):
```markdown
---
name: my-framework
description: Complete guide to MyFramework patterns
---

# MyFramework Patterns

## Quick Reference

Load reference files as needed:

**Core:**
- **[setup.md](references/setup.md)** - Initial setup and configuration
- **[patterns.md](references/patterns.md)** - Common implementation patterns

**Advanced:**
- **[advanced.md](references/advanced.md)** - Advanced features
- **[troubleshooting.md](references/troubleshooting.md)** - Common issues

## Essential Commands

[Most important 10-20 commands/patterns]

## Core Patterns

[Most frequently used patterns]

## When to Load Reference Files

**Setting up project?**
- Installation and configuration → [setup.md](references/setup.md)

**Implementing features?**
- Standard patterns → [patterns.md](references/patterns.md)

**Need advanced features?**
- Complex scenarios → [advanced.md](references/advanced.md)
```

**Reference Files** (detailed documentation):
```markdown
# Setup and Configuration

[Extensive setup documentation]
[Multiple sections]
[Detailed examples]
[200-400 lines each]
```

## Content Structure Best Practices

### Quick Reference Section
Place at top of SKILL.md:
```markdown
## Quick Reference

**Core Operations:**
- **[file-1.md](references/file-1.md)** - Brief description
- **[file-2.md](references/file-2.md)** - Brief description

**Advanced Features:**
- **[file-3.md](references/file-3.md)** - Brief description
```

### Essential Commands
Most important 10-20 commands:
```markdown
## Essential Commands

\`\`\`bash
command --option arg         # Description
another-command              # Description
\`\`\`
```

### Core Patterns
Most frequently used patterns (code examples):
```markdown
## Core Service Structure

\`\`\`typescript
@Injectable()
export class MyService {
  // Implementation
}
\`\`\`
```

### When to Load Reference Files
Guide agent on when to read detailed references:
```markdown
## When to Load Reference Files

**Working with X?**
- Feature A → [file.md](references/file.md)
- Feature B → [file.md](references/file.md)

**Need Y?**
- Scenario C → [file.md](references/file.md)
```

### Best Practices Section
Do's and don'ts:
```markdown
## Best Practices

### Security
- ✅ **DO** encrypt sensitive files
- ❌ **DON'T** commit plaintext secrets

### Performance
- ✅ **DO** use caching
- ❌ **DON'T** make unnecessary API calls
```

## Real-World Examples

### Example 1: Chezmoi Skill

```
.opencode/skill/chezmoi/
├── SKILL.md                    # Main file (283 lines)
└── references/
    ├── file-naming.md          # Complete naming conventions (374 lines)
    ├── templates.md            # Template syntax and patterns
    ├── scripts.md              # Script execution patterns
    ├── encryption.md           # GPG encryption workflows
    ├── external-deps.md        # External file management
    └── troubleshooting.md      # Common issues
```

**SKILL.md Structure**:
1. Quick Reference (links to references)
2. Action Guidance (how to use skill)
3. Essential Commands (top 10-15 commands)
4. Repository-Specific Configuration
5. Core File Naming Patterns (most common)
6. Machine-Specific Templates (examples)
7. Common Workflows
8. Best Practices
9. When to Load Reference Files (guide)

### Example 2: NestJS Skill

```
.opencode/skills/nestjs/
├── SKILL.md                    # Main file (340 lines)
└── references/
    ├── dependency-injection.md # DI patterns
    ├── pagination-filtering.md # Pagination interfaces
    ├── background-jobs.md      # Cron and queue patterns
    ├── custom-exceptions.md    # Domain exceptions
    ├── testing.md              # Unit test patterns
    └── resolver-patterns.md    # GraphQL resolver patterns
```

**SKILL.md Structure**:
1. Quick Reference (grouped by category)
2. Core Service Structure (template)
3. Enum Usage (critical pattern)
4. Import Organization (standards)
5. Method Ordering Standards
6. Basic CRUD Patterns (code examples)
7. Error Handling (patterns)
8. GraphQL Resolver Structure
9. When to Load Reference Files (guide)

## Skill Permissions

Control which skills agents can access:

### Global Permissions
```json
{
  "permission": {
    "skill": {
      "*": "allow",              // Default: allow all
      "internal-*": "deny",      // Block internal skills
      "experimental-*": "ask"    // Ask for experimental
    }
  }
}
```

### Per-Agent Permissions

**Custom Agents** (in agent frontmatter):
```markdown
---
permission:
  skill:
    "documents-*": "allow"
    "code-*": "deny"
---
```

**Built-in Agents** (in opencode.json):
```json
{
  "agent": {
    "plan": {
      "permission": {
        "skill": {
          "internal-*": "allow"
        }
      }
    }
  }
}
```

### Permission Levels
- `"allow"` - Load immediately without asking
- `"ask"` - Prompt user for approval
- `"deny"` - Hidden from agent, access rejected

### Pattern Matching
```json
{
  "permission": {
    "skill": {
      "*": "allow",              // Default
      "internal-*": "deny",      // Matches: internal-docs, internal-tools
      "test-*": "ask",           // Matches: test-utils, test-helpers
      "specific": "deny"         // Exact match only
    }
  }
}
```

## Disabling Skill Tool

Completely disable skills for an agent:

**Custom Agents**:
```markdown
---
tools:
  skill: false
---
```

**Built-in Agents**:
```json
{
  "agent": {
    "plan": {
      "tools": {
        "skill": false
      }
    }
  }
}
```

When disabled, `<available_skills>` section is omitted from tool description.

## Creating Skills

### Step 1: Create Directory Structure
```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

Or for project:
```bash
mkdir -p .opencode/skills/my-skill
```

### Step 2: Create SKILL.md
```markdown
---
name: my-skill
description: Clear description covering key topics and use cases
license: MIT
compatibility: opencode
metadata:
  author: Your Name
  version: 1.0.0
---

# My Skill

## Quick Reference

[Content]
```

### Step 3: Validate Name
Ensure name matches:
- Directory name: `my-skill`
- Frontmatter `name`: `my-skill`
- Pattern: `^[a-z0-9]+(-[a-z0-9]+)*$`

### Step 4: Add Reference Files (Optional)
```bash
mkdir -p ~/.config/opencode/skills/my-skill/references
```

Create detailed docs:
```markdown
# Detailed Topic

[Extensive documentation]
```

### Step 5: Link References
In SKILL.md:
```markdown
## Quick Reference

- **[topic.md](references/topic.md)** - Description
```

### Step 6: Test Loading
```bash
opencode
```

Agent should see skill in tool description.

Manually load to verify:
```
Load the my-skill skill
```

## Best Practices

### Skill Design
- ✅ **DO** focus on single domain or framework
- ✅ **DO** provide concrete, actionable patterns
- ✅ **DO** include code examples
- ✅ **DO** organize with quick reference at top
- ❌ **DON'T** create overly broad skills
- ❌ **DON'T** duplicate existing skills
- ❌ **DON'T** include unrelated topics

### Naming
- ✅ **DO** use descriptive, clear names
- ✅ **DO** use hyphens for multi-word names
- ✅ **DO** keep names concise (2-3 words max)
- ✅ **DO** match directory name exactly
- ❌ **DON'T** use uppercase or special characters
- ❌ **DON'T** use underscores or dots
- ❌ **DON'T** exceed 64 characters

### Descriptions
- ✅ **DO** list specific topics covered
- ✅ **DO** include "use when" scenarios
- ✅ **DO** mention key features
- ✅ **DO** be specific and actionable
- ❌ **DON'T** be vague or generic
- ❌ **DON'T** exceed 1024 characters
- ❌ **DON'T** duplicate name in description

### Content Organization
- ✅ **DO** put most important content in SKILL.md
- ✅ **DO** use reference files for details
- ✅ **DO** provide "When to Load" guide
- ✅ **DO** include best practices section
- ❌ **DON'T** put everything in one file (if >500 lines)
- ❌ **DON'T** create too many reference files (>10)
- ❌ **DON'T** nest reference directories

### Code Examples
- ✅ **DO** include complete, working examples
- ✅ **DO** add comments explaining key parts
- ✅ **DO** show both correct and incorrect patterns
- ✅ **DO** use real-world scenarios
- ❌ **DON'T** use pseudocode without explanation
- ❌ **DON'T** show only trivial examples
- ❌ **DON'T** omit important context

### Maintenance
- ✅ **DO** update skills when frameworks change
- ✅ **DO** version skills with metadata
- ✅ **DO** deprecate outdated patterns
- ✅ **DO** test skills with real usage
- ❌ **DON'T** let skills become stale
- ❌ **DON'T** break existing reference links
- ❌ **DON'T** change names without migration

## Skill Discovery Process

### For Project Skills
1. Start from current working directory
2. Walk up to git worktree root
3. At each level, check for:
   - `.opencode/skills/*/SKILL.md`
   - `.opencode/skill/*/SKILL.md`
   - `.claude/skills/*/SKILL.md`
4. Load all found skills

### For Global Skills
1. Check `~/.config/opencode/skills/*/SKILL.md`
2. Check `~/.config/opencode/skill/*/SKILL.md`
3. Check `~/.claude/skills/*/SKILL.md`
4. Load all found skills

### Deduplication
If same skill name appears in multiple locations:
- **Only first found is loaded**
- Project skills take precedence over global
- Check logs for conflicts

## Troubleshooting

### Skill Not Appearing
**Symptom**: Skill doesn't appear in agent's available skills

**Solution**:
1. Verify `SKILL.md` is spelled correctly (all caps)
2. Check frontmatter has `name` and `description`
3. Ensure name matches directory name exactly
4. Verify name follows pattern: `^[a-z0-9]+(-[a-z0-9]+)*$`
5. Check permissions - denied skills are hidden

### Name Validation Error
**Symptom**: Error about invalid skill name

**Solution**:
1. Check name is lowercase only
2. Verify hyphens, not underscores
3. Ensure no special characters
4. Check length (1-64 chars)
5. No leading/trailing hyphens
6. No consecutive hyphens

### Permission Denied
**Symptom**: Agent can't load skill

**Solution**:
1. Check global permission settings
2. Check agent-specific permission overrides
3. Verify pattern matching (wildcards)
4. Look for explicit `deny` rules

### Reference Files Not Found
**Symptom**: Links in SKILL.md don't work

**Solution**:
1. Verify `references/` directory exists
2. Check file names match exactly (case-sensitive)
3. Ensure paths are relative: `references/file.md`
4. Don't use absolute paths

### Skill Content Too Long
**Symptom**: Skill takes too much context

**Solution**:
1. Move detailed content to reference files
2. Keep SKILL.md as quick reference
3. Provide "When to Load" guide
4. Consider splitting into multiple skills

## Integration with Chezmoi

When managing OpenCode config with chezmoi:

### Global Skills
```bash
# Add skill to chezmoi
chezmoi add ~/.config/opencode/skills/my-skill/SKILL.md
chezmoi add ~/.config/opencode/skills/my-skill/references/

# Chezmoi source structure
dot_config/opencode/exact_skills/
└── my-skill/
    ├── SKILL.md
    └── references/
        └── topic.md
```

**Note**: Use `exact_` prefix for skills directory to ensure sync.

### Project Skills
```bash
# Project skills committed to Git
.opencode/skills/
└── project-skill/
    ├── SKILL.md
    └── references/
        └── patterns.md
```

Commit project skills to Git for team sharing.

### Syncing Across Machines
```bash
# Update chezmoi
chezmoi update    # Pull and apply changes

# Skills automatically synced across all machines
```
