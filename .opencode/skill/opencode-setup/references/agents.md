# OpenCode Agents Reference

Complete guide to built-in agents, creating custom agents, and agent configuration.

## Agent Types

### Primary Agents
Agents you interact with directly. Switch between them using **Tab** key or configured `switch_agent` keybind.

**Characteristics**:
- Direct user interaction
- Cycle through with Tab
- Handle main conversation
- Configured tool access

### Subagents
Specialized assistants invoked for specific tasks. Can be called by primary agents or manually via **@mention**.

**Characteristics**:
- Invoked by primary agents or @mention
- Specialized for specific tasks
- Create child sessions
- Navigate with Leader+Right/Left

## Built-in Agents

### Build (Primary Agent)
**Default agent for development work.**

```json
{
  "agent": {
    "build": {
      "mode": "primary",
      "description": "Full development work with all tools enabled",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true,
        "read": true,
        "grep": true,
        "glob": true
      }
    }
  }
}
```

**Use for**:
- Implementing features
- Making file changes
- Running commands
- Full development work

### Plan (Primary Agent)
**Read-only agent for analysis and planning.**

```json
{
  "agent": {
    "plan": {
      "mode": "primary",
      "description": "Analysis and planning without making changes",
      "tools": {
        "write": false,
        "edit": false,
        "bash": true,
        "read": true,
        "grep": true,
        "glob": true
      },
      "permission": {
        "bash": "ask"
      }
    }
  }
}
```

**Use for**:
- Code review
- Planning changes
- Analyzing codebase
- Exploring unfamiliar code

### General (Subagent)
**General-purpose agent for complex research and multi-step tasks.**

```json
{
  "agent": {
    "general": {
      "mode": "subagent",
      "description": "Multi-step tasks and research",
      "tools": {
        "*": true,
        "todo": false
      }
    }
  }
}
```

**Use for**:
- Complex searches
- Multi-step research
- Parallel work units
- Background investigations

### Explore (Subagent)
**Fast, read-only codebase exploration.**

```json
{
  "agent": {
    "explore": {
      "mode": "subagent",
      "description": "Fast read-only codebase exploration",
      "tools": {
        "write": false,
        "edit": false,
        "read": true,
        "grep": true,
        "glob": true
      }
    }
  }
}
```

**Use for**:
- Finding files by patterns
- Searching code for keywords
- Understanding codebase structure
- Quick code analysis

## Creating Custom Agents

### Method 1: JSON Configuration

In `opencode.json`:

```json
{
  "agent": {
    "code-reviewer": {
      "description": "Reviews code for best practices and security",
      "mode": "subagent",
      "model": "anthropic/claude-sonnet-4-5",
      "temperature": 0.1,
      "steps": 50,
      "color": "#ff6b6b",
      "tools": {
        "write": false,
        "edit": false,
        "bash": false
      },
      "permission": {
        "bash": {
          "git diff": "allow"
        }
      }
    }
  }
}
```

### Method 2: Markdown Files

Create `~/.config/opencode/agent/code-reviewer.md`:

```markdown
---
description: Reviews code for best practices and security
mode: subagent
model: anthropic/claude-sonnet-4-5
temperature: 0.1
tools:
  write: false
  edit: false
  bash: false
permission:
  bash:
    "git diff": allow
---

You are a code reviewer focusing on:

## Security
- Input validation vulnerabilities
- Authentication and authorization flaws
- Data exposure risks
- Dependency vulnerabilities

## Best Practices
- Code clarity and maintainability
- Performance implications
- Error handling patterns
- Test coverage

Provide constructive feedback without making direct changes.
```

**File Locations**:
- Global: `~/.config/opencode/agent/`
- Project: `.opencode/agent/`

**Naming**: File name becomes agent name (e.g., `code-reviewer.md` → `code-reviewer` agent)

### Method 3: Interactive Creation

```bash
opencode agent create
```

Interactive prompts:
1. Location (global or project)
2. Agent description
3. System prompt generation
4. Tool selection
5. Create markdown file

## Agent Configuration Options

### Description (Required)
```json
{
  "agent": {
    "custom": {
      "description": "Brief description for agent selection"
    }
  }
}
```

Used by AI to decide when to invoke agent.

### Mode
```json
{
  "agent": {
    "custom": {
      "mode": "primary"        // "primary", "subagent", or "all" (default)
    }
  }
}
```

- `primary` - Switch via Tab, main conversation
- `subagent` - @mention or Task tool only
- `all` - Can be used as both

### Model
```json
{
  "agent": {
    "custom": {
      "model": "anthropic/claude-sonnet-4-5"
    }
  }
}
```

Override default model for this agent. Format: `provider/model-id`

**Defaults**:
- Primary agents: Use global `model` setting
- Subagents: Use invoking agent's model

### Temperature
```json
{
  "agent": {
    "analyzer": {
      "temperature": 0.1      // Focused, deterministic
    },
    "creative": {
      "temperature": 0.8      // Creative, varied
    }
  }
}
```

**Ranges**:
- `0.0-0.2` - Analysis, planning, code review
- `0.3-0.5` - General development
- `0.6-1.0` - Brainstorming, exploration

### Top P
```json
{
  "agent": {
    "custom": {
      "top_p": 0.9
    }
  }
}
```

Alternative to temperature for controlling randomness.

### Steps (Max Iterations)
```json
{
  "agent": {
    "quick-thinker": {
      "steps": 5              // Max agentic iterations
    }
  }
}
```

Limits agentic actions for cost control. When reached, agent provides summary and recommended next steps.

### Disable
```json
{
  "agent": {
    "custom": {
      "disable": true
    }
  }
}
```

Temporarily disable agent without removing configuration.

### Prompt
```json
{
  "agent": {
    "custom": {
      "prompt": "{file:./prompts/custom-agent.txt}"
    }
  }
}
```

Load system prompt from file. Path relative to config location.

### Color
```json
{
  "agent": {
    "custom": {
      "color": "#ff6b6b"      // Hex color code
    }
  }
}
```

Visual appearance in UI.

### Hidden (Subagents Only)
```json
{
  "agent": {
    "internal-helper": {
      "mode": "subagent",
      "hidden": true
    }
  }
}
```

Hide from @ autocomplete. Agent can still be invoked programmatically via Task tool.

## Tool Configuration

### Enable/Disable Tools
```json
{
  "agent": {
    "readonly": {
      "tools": {
        "*": false,           // Disable all
        "read": true,         // Enable specific
        "grep": true,
        "glob": true
      }
    }
  }
}
```

### Wildcard Patterns
```json
{
  "agent": {
    "custom": {
      "tools": {
        "mcp_*": false,        // Disable all MCP tools
        "mcp_jira_*": true     // Enable JIRA MCP tools
      }
    }
  }
}
```

## Permission Configuration

### Permission Levels
- `"allow"` - Execute without approval
- `"ask"` - Prompt for approval
- `"deny"` - Block entirely

### Edit Permissions
```json
{
  "agent": {
    "safe-agent": {
      "permission": {
        "edit": "ask"
      }
    }
  }
}
```

### Bash Permissions
```json
{
  "agent": {
    "careful-agent": {
      "permission": {
        "bash": {
          "*": "ask",               // Default: ask for all
          "git status": "allow",    // Allow specific
          "git log*": "allow",      // Allow with glob
          "git push": "deny"        // Deny specific
        }
      }
    }
  }
}
```

**Rule Precedence**: Last matching rule wins. Put `*` first, specific rules after.

### WebFetch Permissions
```json
{
  "agent": {
    "restricted": {
      "permission": {
        "webfetch": "deny"
      }
    }
  }
}
```

### Task Permissions (Subagent Invocation)
```json
{
  "agent": {
    "orchestrator": {
      "permission": {
        "task": {
          "*": "deny",                  // Block all by default
          "orchestrator-*": "allow",    // Allow specific subagents
          "code-reviewer": "ask"        // Ask for approval
        }
      }
    }
  }
}
```

Controls which subagents can be invoked via Task tool.

**Note**: Users can always @mention any subagent directly, regardless of task permissions.

### Skill Permissions
```json
{
  "agent": {
    "restricted": {
      "permission": {
        "skill": {
          "*": "allow",
          "internal-*": "deny",
          "experimental-*": "ask"
        }
      }
    }
  }
}
```

### External Directory Permissions
```json
{
  "agent": {
    "plan": {
      "permission": {
        "external_directory": {
          "~/www/**": "allow",              // Project directories
          "~/obsidian/**": "allow",          // Documentation
          "/tmp/**": "allow",                // Temporary files (MCP downloads)
          "~/.local/share/opencode/tool-output/**": "allow"
        }
      }
    }
  }
}
```

Controls access to directories outside the working directory. Essential for:
- Reading MCP tool outputs (attachments, downloads)
- Accessing multiple project directories
- Reading from system temporary directories

**Common Use Cases**:
- Plan agent needs to read Jira attachments downloaded to `/tmp`
- Agent accessing tool outputs from `~/.local/share/opencode/tool-output`
- Multi-project agents reading from `~/www/project-*/**`

## Agent Usage

### Switching Primary Agents
```
<Tab>                    # Switch to next primary agent
```

UI indicator shows current agent in lower right corner.

### Invoking Subagents
```
@general help me search for authentication code
@explore find all files using React hooks
```

### Session Navigation
When subagents create child sessions:
```
<Leader>+Right          # Cycle forward through sessions
<Leader>+Left           # Cycle backward through sessions
```

Cycle pattern: parent → child1 → child2 → ... → parent

## Agent Examples

### Security Auditor
```markdown
---
description: Performs security audits and identifies vulnerabilities
mode: subagent
temperature: 0.1
tools:
  write: false
  edit: false
  bash: false
---

You are a security expert focusing on:

## Vulnerabilities
- Input validation issues
- Authentication and authorization flaws
- Data exposure risks
- Dependency vulnerabilities
- Configuration security

## Analysis
- Review code for security issues
- Identify potential attack vectors
- Suggest security improvements
- Recommend best practices

Provide detailed security findings without making changes.
```

### Documentation Writer
```markdown
---
description: Writes and maintains project documentation
mode: subagent
temperature: 0.3
tools:
  write: true
  edit: true
  bash: false
---

You are a technical writer creating clear documentation.

## Style
- Clear, concise explanations
- Proper structure and organization
- Code examples with annotations
- User-friendly language

## Coverage
- Getting started guides
- API documentation
- Architecture overviews
- Troubleshooting guides
```

### Test Generator
```markdown
---
description: Generates comprehensive test suites
mode: subagent
model: anthropic/claude-haiku-4-5
temperature: 0.2
tools:
  write: true
  edit: true
  bash: true
permission:
  bash:
    "*": ask
    "npm test": allow
    "npm run test:*": allow
---

You generate thorough test suites covering:

## Test Types
- Unit tests for functions and methods
- Integration tests for modules
- E2E tests for user workflows
- Edge cases and error handling

## Best Practices
- Clear test descriptions
- Proper mocking and fixtures
- Isolated test cases
- Comprehensive coverage
```

### Git Specialist
```markdown
---
description: Git operations and repository management
mode: subagent
temperature: 0.1
tools:
  write: false
  edit: false
  bash: true
permission:
  bash:
    "*": ask
    "git status": allow
    "git log*": allow
    "git diff*": allow
    "git show*": allow
    "git branch*": allow
    "git push": ask
    "git push --force": deny
---

You are a Git expert handling:

## Operations
- Branch management
- Commit organization
- Conflict resolution
- History analysis

## Safety
- Always ask before destructive operations
- Never force push to main/master
- Verify changes before pushing
- Suggest git best practices
```

## Default Agent

Set which primary agent starts by default:

```json
{
  "default_agent": "plan"        // "build" (default) or "plan"
}
```

Must be a primary agent. If invalid or subagent, falls back to "build" with warning.

Applies to:
- TUI
- CLI (`opencode run`)
- Desktop app
- GitHub Action

## Best Practices

### Agent Design
- ✅ **DO** create focused agents for specific tasks
- ✅ **DO** use descriptive names and descriptions
- ✅ **DO** set appropriate tool permissions
- ✅ **DO** use lower temperature for analysis agents
- ❌ **DON'T** create overly broad agents
- ❌ **DON'T** give all tools to analysis agents

### Tool Permissions
- ✅ **DO** disable write/edit for review agents
- ✅ **DO** use "ask" for potentially destructive operations
- ✅ **DO** allow safe commands explicitly
- ✅ **DO** use glob patterns for command groups
- ❌ **DON'T** allow destructive bash commands without approval
- ❌ **DON'T** give unnecessary tool access

### Temperature Settings
- ✅ **DO** use 0.1-0.2 for code review and analysis
- ✅ **DO** use 0.3-0.5 for general development
- ✅ **DO** use 0.6-0.8 for creative tasks
- ❌ **DON'T** use high temperature for code generation
- ❌ **DON'T** use zero temperature for brainstorming

### Organization
- ✅ **DO** place team agents in project `.opencode/agent/`
- ✅ **DO** place personal agents in `~/.config/opencode/agent/`
- ✅ **DO** use markdown files for complex prompts
- ✅ **DO** commit team agent configs to Git
- ❌ **DON'T** duplicate agents across locations
- ❌ **DON'T** commit personal preferences to team configs

## Troubleshooting

### Agent Not Appearing
**Symptom**: Agent doesn't show in Tab cycling or @ autocomplete

**Solution**:
1. Check `mode` is set correctly (primary vs subagent)
2. Verify `disable: false` (or option not present)
3. Check file location matches naming convention
4. Restart OpenCode to reload configs

### Agent Not Loading Skills
**Symptom**: Agent can't access expected skills

**Solution**:
1. Check skill permissions in agent config
2. Verify skill names match exactly (including hyphens)
3. Check skill `SKILL.md` frontmatter is valid
4. Review permission patterns (wildcards may block)

### Wrong Model Being Used
**Symptom**: Agent uses unexpected model

**Solution**:
1. Check agent has explicit `model` set
2. Verify model ID format: `provider/model-id`
3. Ensure provider is configured with valid API key
4. Check `disabled_providers` and `enabled_providers`

### Permission Dialogs Not Appearing
**Symptom**: Commands execute without approval

**Solution**:
1. Check permission level is "ask" not "allow"
2. Verify bash pattern matches command exactly
3. Remember: specific rules override wildcards
4. Check global permissions don't override agent permissions
