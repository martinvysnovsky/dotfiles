# OpenCode Configuration Reference

Complete guide to `opencode.json` configuration options and locations.

## Configuration Locations

OpenCode loads configuration from multiple locations with this precedence (later overrides earlier):

### 1. Remote Config
```
.well-known/opencode
```
Organizational defaults fetched automatically when authenticating with providers.

### 2. Global Config
```
~/.config/opencode/opencode.json
```
User-wide preferences (themes, providers, keybinds).

### 3. Project Config
```
<project-root>/opencode.json
```
Project-specific settings (instructions, custom agents, formatters).

### 4. Custom Path
```bash
export OPENCODE_CONFIG=/path/to/custom-config.json
opencode
```

### 5. Custom Directory
```bash
export OPENCODE_CONFIG_DIR=/path/to/config-directory
opencode
```

Directory structure:
```
/path/to/config-directory/
├── agents/
├── commands/
├── skills/
└── plugins/
```

## Complete Schema

```json
{
  "$schema": "https://opencode.ai/config.json",
  
  // UI Configuration
  "theme": "catppuccin",
  "tui": {
    "scroll_speed": 3,
    "scroll_acceleration": {
      "enabled": true
    },
    "diff_style": "auto"
  },
  
  // Server Configuration
  "server": {
    "port": 4096,
    "hostname": "0.0.0.0",
    "mdns": true,
    "cors": ["http://localhost:5173"]
  },
  
  // Model Configuration
  "model": "anthropic/claude-sonnet-4-5",
  "small_model": "anthropic/claude-haiku-4-5",
  "provider": {
    "anthropic": {
      "options": {
        "timeout": 600000,
        "setCacheKey": true,
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    }
  },
  
  // Agent Configuration
  "default_agent": "build",
  "agent": {
    "custom-agent": {
      "description": "Custom agent description",
      "mode": "primary",
      "model": "anthropic/claude-sonnet-4-5",
      "temperature": 0.3,
      "steps": 50,
      "tools": {},
      "permission": {}
    }
  },
  
  // Tools
  "tools": {
    "write": true,
    "edit": true,
    "bash": true
  },
  
  // Permissions
  "permission": {
    "edit": "allow",
    "bash": "ask",
    "webfetch": "allow"
  },
  
  // Instructions
  "instructions": [
    "CONTRIBUTING.md",
    "docs/guidelines/*.md"
  ],
  
  // Commands
  "command": {
    "test": {
      "template": "Run tests with coverage",
      "description": "Run test suite",
      "agent": "build",
      "model": "anthropic/claude-haiku-4-5"
    }
  },
  
  // Keybinds
  "keybinds": {
    "switch_agent": ["tab"],
    "interrupt": ["ctrl+c"],
    "quit": ["ctrl+d"]
  },
  
  // Sharing
  "share": "manual",
  
  // Auto-update
  "autoupdate": true,
  
  // Formatters
  "formatter": {
    "prettier": {
      "disabled": false
    }
  },
  
  // Context Compaction
  "compaction": {
    "auto": true,
    "prune": true
  },
  
  // File Watcher
  "watcher": {
    "ignore": ["node_modules/**", "dist/**"]
  },
  
  // MCP Servers
  "mcp": {
    "server-name": {
      "type": "remote",
      "url": "http://localhost:8888",
      "enabled": true,
      "oauth": false,
      "timeout": 10000
    }
  },
  
  // Plugins
  "plugin": [
    "opencode-gemini-auth@latest",
    "opencode-anthropic-auth@latest"
  ],
  
  // Provider Management
  "disabled_providers": ["openai"],
  "enabled_providers": ["anthropic", "google"],
  
  // Experimental
  "experimental": {}
}
```

## TUI Options

```json
{
  "tui": {
    "scroll_speed": 3,              // Custom scroll multiplier (min: 1)
    "scroll_acceleration": {
      "enabled": true                // macOS-style acceleration
    },
    "diff_style": "auto"             // "auto" or "stacked"
  }
}
```

**Scroll Configuration**:
- `scroll_acceleration.enabled` takes precedence over `scroll_speed`
- `scroll_speed` only applies when acceleration is disabled
- `diff_style: "auto"` adapts to terminal width, `"stacked"` always single column

## Server Options

```json
{
  "server": {
    "port": 4096,                   // Port to listen on
    "hostname": "0.0.0.0",          // Hostname to bind
    "mdns": true,                    // mDNS service discovery
    "cors": [                        // Additional CORS origins
      "http://localhost:5173",
      "https://app.example.com"
    ]
  }
}
```

**CORS**: Values must be full origins (scheme + host + optional port).

## Model Configuration

```json
{
  "model": "anthropic/claude-sonnet-4-5",
  "small_model": "anthropic/claude-haiku-4-5",
  "provider": {
    "anthropic": {
      "options": {
        "timeout": 600000,          // Request timeout (ms), false to disable
        "setCacheKey": true,        // Always set cache key
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    },
    "amazon-bedrock": {
      "options": {
        "region": "us-east-1",      // AWS region
        "profile": "my-profile",    // AWS named profile
        "endpoint": "https://..."   // Custom VPC endpoint
      }
    }
  }
}
```

**Model Format**: `provider/model-id`
- `anthropic/claude-sonnet-4-5`
- `openai/gpt-4`
- `google/gemini-pro`
- `opencode/gpt-5.1-codex` (for OpenCode Zen)

**Small Model**: Used for lightweight tasks (title generation). Falls back to main model if not specified.

## Agent Configuration

```json
{
  "default_agent": "build",
  "agent": {
    "custom-agent": {
      "description": "Agent description for selection",
      "mode": "primary",           // "primary", "subagent", or "all"
      "model": "anthropic/claude-sonnet-4-5",
      "temperature": 0.3,          // 0.0-1.0
      "top_p": 0.9,                // Alternative to temperature
      "steps": 50,                 // Max agentic iterations
      "color": "#ff6b6b",          // UI color (hex)
      "hidden": false,             // Hide from @ autocomplete (subagents only)
      "prompt": "{file:./prompts/agent.txt}",
      "tools": {
        "write": true,
        "edit": true,
        "bash": false
      },
      "permission": {
        "edit": "ask",
        "bash": {
          "*": "ask",
          "git status": "allow"
        },
        "task": {
          "*": "deny",
          "specific-agent": "allow"
        }
      }
    }
  }
}
```

**Mode**:
- `primary` - Switch via Tab key
- `subagent` - Invoke with @mention or via Task tool
- `all` - Both (default)

**Temperature**: Lower = focused, higher = creative
- `0.0-0.2` - Code analysis, planning
- `0.3-0.5` - General development
- `0.6-1.0` - Brainstorming, exploration

**Steps**: Limits agentic iterations (cost control)

**Hidden**: Only for subagents, prevents @ autocomplete visibility

**Task Permissions**: Control which subagents can be invoked via Task tool

## Tools Configuration

```json
{
  "tools": {
    "*": false,                    // Wildcard: disable all by default
    "write": true,                 // Then enable specific tools
    "edit": true,
    "bash": true,
    "read": true,
    "grep": true,
    "glob": true,
    "mcp_*": false,                // Disable all MCP tools
    "mcp_jira_*": true             // Enable specific MCP server tools
  }
}
```

**Wildcards**: Use `*` to match multiple tools

## Permissions Configuration

```json
{
  "permission": {
    "edit": "allow",               // "allow", "ask", "deny"
    "bash": "ask",
    "webfetch": "deny",
    "skill": {
      "*": "allow",                // Default for all skills
      "internal-*": "deny",        // Pattern matching
      "experimental-*": "ask"
    }
  }
}
```

**Bash Command Permissions**:
```json
{
  "permission": {
    "bash": {
      "*": "ask",                  // Default for all commands
      "git status": "allow",       // Specific commands
      "git log*": "allow",         // Glob patterns
      "git push": "deny"
    }
  }
}
```

**Rule Precedence**: Last matching rule wins

**External Directory Permissions**:
```json
{
  "permission": {
    "external_directory": {
      "*": "deny",                   // Default: deny all external directories
      "~/www/**": "allow",           // Allow home-relative paths
      "~/obsidian/**": "allow",
      "/tmp/**": "allow",            // Allow absolute paths
      "~/.local/share/opencode/tool-output/**": "allow"
    }
  }
}
```

Controls access to directories outside the current working directory. Useful for:
- Accessing MCP tool outputs (e.g., downloaded attachments in `/tmp`)
- Reading files from multiple project directories
- Restricting agents to specific safe locations

**Path Formats**:
- Absolute paths: `/tmp/**`, `/var/log/**`
- Home-relative: `~/www/**`, `~/.config/**`
- Wildcards: `**` matches any subdirectory depth

**Note**: This permission is typically configured per-agent rather than globally.

## Instructions (Rules)

```json
{
  "instructions": [
    "CONTRIBUTING.md",             // Single file
    "docs/guidelines.md",          // Relative path
    "rules/*.md"                   // Glob pattern
  ]
}
```

**File Types**: Markdown files with coding guidelines and best practices

## Commands Configuration

```json
{
  "command": {
    "test": {
      "template": "Run tests with coverage: $ARGUMENTS",
      "description": "Run test suite",
      "agent": "build",            // Which agent to use
      "model": "anthropic/claude-haiku-4-5"
    }
  }
}
```

**Variables**:
- `$ARGUMENTS` - Replaced with command arguments

## Keybinds Configuration

```json
{
  "keybinds": {
    "switch_agent": ["tab"],
    "interrupt": ["ctrl+c"],
    "quit": ["ctrl+d"],
    "session_child_cycle": ["leader+right"],
    "session_child_cycle_reverse": ["leader+left"]
  }
}
```

## Sharing Configuration

```json
{
  "share": "manual"                // "manual", "auto", "disabled"
}
```

- `manual` - Explicit `/share` command (default)
- `auto` - Automatically share conversations
- `disabled` - Disable sharing completely

## Auto-update Configuration

```json
{
  "autoupdate": true               // true, false, "notify"
}
```

- `true` - Auto-download updates
- `false` - No updates
- `"notify"` - Notify but don't download

## Formatter Configuration

```json
{
  "formatter": {
    "prettier": {
      "disabled": false
    },
    "custom-formatter": {
      "command": ["npx", "prettier", "--write", "$FILE"],
      "environment": {
        "NODE_ENV": "development"
      },
      "extensions": [".js", ".ts", ".jsx", ".tsx"]
    }
  }
}
```

## Compaction Configuration

```json
{
  "compaction": {
    "auto": true,                  // Auto-compact when context is full
    "prune": true                  // Remove old tool outputs
  }
}
```

## Watcher Configuration

```json
{
  "watcher": {
    "ignore": [
      "node_modules/**",
      "dist/**",
      ".git/**"
    ]
  }
}
```

**Patterns**: Glob syntax for excluding files from file watching

## MCP Servers

```json
{
  "mcp": {
    "server-name": {
      "type": "remote",            // "remote" or "stdio"
      "url": "http://localhost:8888",
      "enabled": true,
      "oauth": false,
      "timeout": 10000             // Timeout in milliseconds
    },
    "local-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

## Plugins

```json
{
  "plugin": [
    "opencode-gemini-auth@latest",
    "opencode-anthropic-auth@latest",
    "@my-org/custom-plugin"
  ]
}
```

**Plugin Locations**:
- NPM packages: Listed in `plugin` array
- Local files: Place in `.opencode/plugins/` or `~/.config/opencode/plugins/`

## Provider Management

```json
{
  "disabled_providers": ["openai", "gemini"],
  "enabled_providers": ["anthropic"]
}
```

**Precedence**: `disabled_providers` takes priority over `enabled_providers`

## Variable Substitution

### Environment Variables
```json
{
  "model": "{env:OPENCODE_MODEL}",
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    }
  }
}
```

### File Contents
```json
{
  "instructions": ["./custom-instructions.md"],
  "provider": {
    "openai": {
      "options": {
        "apiKey": "{file:~/.secrets/openai-key}"
      }
    }
  }
}
```

**File Paths**: Relative to config file or absolute paths (`/` or `~`)

## Configuration Merging

Configuration files are **merged together**, not replaced:

1. Remote config (base layer)
2. Global config (overrides remote)
3. Custom config via `OPENCODE_CONFIG` (overrides global)
4. Project config (overrides all, highest precedence)

**Merging Behavior**: Later configs override earlier ones **only for conflicting keys**. Non-conflicting settings from all configs are preserved.

Example:
```json
// Global config
{
  "theme": "opencode",
  "autoupdate": true
}

// Project config
{
  "model": "anthropic/claude-sonnet-4-5"
}

// Final merged config
{
  "theme": "opencode",
  "autoupdate": true,
  "model": "anthropic/claude-sonnet-4-5"
}
```

## Validation

Check your configuration:
```bash
# Start OpenCode (will validate config on startup)
opencode

# Check logs for validation errors
tail -f ~/.opencode/logs/latest.log
```

## Common Patterns

### Minimal Config
```json
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "catppuccin",
  "model": "anthropic/claude-sonnet-4-5"
}
```

### Security-Focused Config
```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "edit": "ask",
    "bash": {
      "*": "ask",
      "git status": "allow",
      "git diff": "allow"
    },
    "webfetch": "deny"
  },
  "share": "disabled"
}
```

### Team Config (Project)
```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "CONTRIBUTING.md",
    "docs/coding-standards.md",
    ".opencode/rules/*.md"
  ],
  "formatter": {
    "prettier": {
      "disabled": false
    }
  },
  "agent": {
    "reviewer": {
      "description": "Code review without changes",
      "mode": "subagent",
      "tools": {
        "write": false,
        "edit": false
      }
    }
  }
}
```
