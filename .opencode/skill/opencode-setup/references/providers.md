# OpenCode Provider Configuration

Complete guide to setting up LLM providers and API keys.

## Provider Setup Methods

### 1. Interactive Setup (Recommended)
```bash
opencode
/connect
```

Select provider from list:
- **opencode** - OpenCode Zen (curated models)
- **anthropic** - Claude models
- **openai** - GPT models
- **google** - Gemini models
- **amazon-bedrock** - AWS Bedrock models
- And more...

### 2. Environment Variables
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GOOGLE_API_KEY="..."
opencode
```

### 3. Configuration File
```json
{
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "sk-ant-..."
      }
    }
  }
}
```

## OpenCode Zen (Recommended)

OpenCode Zen provides curated models tested and verified by the OpenCode team.

### Setup
1. Run `/connect` in TUI
2. Select `opencode`
3. Visit https://opencode.ai/auth
4. Sign in and add billing details
5. Copy API key
6. Paste into OpenCode

### Available Models
```
opencode/gpt-5.1-codex
opencode/claude-sonnet-4-5
opencode/gemini-pro-2.0
```

### Configuration
```json
{
  "model": "opencode/gpt-5.1-codex",
  "provider": {
    "opencode": {
      "options": {
        "apiKey": "{env:OPENCODE_API_KEY}"
      }
    }
  }
}
```

## Anthropic (Claude)

### Setup
Get API key from: https://console.anthropic.com/

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Or via `/connect`:
```bash
opencode
/connect
# Select: anthropic
# Enter API key
```

### Available Models
- `claude-sonnet-4-5-20250929` - Latest Sonnet (recommended)
- `claude-opus-4-5-20250514` - Most capable
- `claude-haiku-4-5-20251001` - Fast and efficient

### Configuration
```json
{
  "model": "anthropic/claude-sonnet-4-5-20250929",
  "small_model": "anthropic/claude-haiku-4-5-20251001",
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}",
        "timeout": 600000,
        "setCacheKey": true
      }
    }
  }
}
```

### Options
- `apiKey` - API key (required)
- `timeout` - Request timeout in ms (default: 300000)
- `setCacheKey` - Always set cache key for prompt caching (default: false)

## OpenAI (GPT)

### Setup
Get API key from: https://platform.openai.com/api-keys

```bash
export OPENAI_API_KEY="sk-..."
```

### Available Models
- `gpt-4-turbo` - Latest GPT-4
- `gpt-4` - Standard GPT-4
- `gpt-3.5-turbo` - Fast and affordable

### Configuration
```json
{
  "model": "openai/gpt-4-turbo",
  "provider": {
    "openai": {
      "options": {
        "apiKey": "{env:OPENAI_API_KEY}",
        "timeout": 300000
      }
    }
  }
}
```

### Reasoning Models
For GPT-5 and o1 models with reasoning:
```json
{
  "agent": {
    "deep-thinker": {
      "model": "openai/gpt-5",
      "reasoningEffort": "high",
      "textVerbosity": "low"
    }
  }
}
```

## Google (Gemini)

### Setup
Get API key from: https://makersuite.google.com/app/apikey

Or use Google Cloud project:
```bash
export GOOGLE_API_KEY="..."
```

### Available Models
- `gemini-2.0-flash` - Fast and efficient
- `gemini-pro` - Balanced performance

### Configuration
```json
{
  "model": "google/gemini-2.0-flash",
  "provider": {
    "google": {
      "options": {
        "apiKey": "{env:GOOGLE_API_KEY}",
        "projectId": "your-project-id"
      }
    }
  }
}
```

### With Google Cloud
```json
{
  "provider": {
    "google": {
      "options": {
        "projectId": "98761157302"
      }
    }
  },
  "plugin": ["opencode-gemini-auth@latest"]
}
```

## Amazon Bedrock

### Setup
Configure AWS credentials:
```bash
aws configure
# Or use named profile
export AWS_PROFILE=my-profile
```

### Available Models
- `anthropic.claude-sonnet-4-5-v2`
- `anthropic.claude-opus-4-5-v1`
- `anthropic.claude-haiku-4-5-v1`

### Configuration
```json
{
  "model": "amazon-bedrock/anthropic.claude-sonnet-4-5-v2",
  "provider": {
    "amazon-bedrock": {
      "options": {
        "region": "us-east-1",
        "profile": "my-aws-profile",
        "endpoint": "https://bedrock-runtime.us-east-1.vpce-xxxxx.amazonaws.com"
      }
    }
  }
}
```

### Options
- `region` - AWS region (default: `AWS_REGION` env or `us-east-1`)
- `profile` - AWS named profile (default: `AWS_PROFILE` env)
- `endpoint` - Custom VPC endpoint URL

### Authentication Precedence
1. Bearer token (`AWS_BEARER_TOKEN_BEDROCK` or `/connect`)
2. AWS profile credentials
3. Default AWS credential chain

## Local Models (Ollama)

### Setup Ollama
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama
ollama serve

# Pull a model
ollama pull llama3.1
```

### Configuration
```json
{
  "model": "ollama/llama3.1",
  "provider": {
    "ollama": {
      "options": {
        "baseURL": "http://localhost:11434"
      }
    }
  }
}
```

### Available Models
Any model from https://ollama.com/library:
- `llama3.1`
- `codellama`
- `mistral`
- `mixtral`

## Multiple Providers

Configure multiple providers and switch between them:

```json
{
  "model": "anthropic/claude-sonnet-4-5",
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    },
    "openai": {
      "options": {
        "apiKey": "{env:OPENAI_API_KEY}"
      }
    },
    "google": {
      "options": {
        "apiKey": "{env:GOOGLE_API_KEY}"
      }
    }
  },
  "agent": {
    "fast-coder": {
      "model": "openai/gpt-4-turbo",
      "description": "Fast implementation with GPT-4"
    },
    "deep-thinker": {
      "model": "anthropic/claude-opus-4-5",
      "description": "Complex reasoning with Claude Opus"
    }
  }
}
```

## Provider Management

### Disable Providers
```json
{
  "disabled_providers": ["openai", "gemini"]
}
```

Disabled providers:
- Won't load even if credentials exist
- Won't appear in model selection
- API keys ignored

### Enable Only Specific Providers
```json
{
  "enabled_providers": ["anthropic", "opencode"]
}
```

**Precedence**: `disabled_providers` takes priority over `enabled_providers`

## Secure API Key Storage

### Environment Variables
```bash
# In ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."

# Reference in config
{
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    }
  }
}
```

### File Storage
```bash
# Store in separate file
echo "sk-ant-..." > ~/.secrets/anthropic-key
chmod 600 ~/.secrets/anthropic-key

# Reference in config
{
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{file:~/.secrets/anthropic-key}"
      }
    }
  }
}
```

### Chezmoi Encryption (Recommended)
```bash
# Add encrypted secret file
chezmoi add --encrypt ~/.secrets/anthropic-key

# Source file becomes: encrypted_private_dot_secrets/encrypted_private_anthropic-key.asc

# Reference in config (chezmoi decrypts on apply)
{
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{file:~/.secrets/anthropic-key}"
      }
    }
  }
}
```

### Machine-Specific Keys (Chezmoi)
```json
// In dot_config/opencode/config.json.tmpl
{
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{{ if eq .chezmoi.hostname "work-laptop" }}{env:WORK_ANTHROPIC_KEY}{{ else }}{env:ANTHROPIC_API_KEY}{{ end }}"
      }
    }
  }
}
```

## Model Selection

### Check Available Models
```bash
opencode models
```

Lists all available models from configured providers.

### Primary vs Small Model
```json
{
  "model": "anthropic/claude-sonnet-4-5",        // Main model for coding
  "small_model": "anthropic/claude-haiku-4-5"   // Lightweight tasks (titles)
}
```

**Small Model Uses**:
- Generating conversation titles
- Quick classifications
- Simple transformations

If not specified, falls back to main model.

### Per-Agent Models
```json
{
  "model": "anthropic/claude-sonnet-4-5",
  "agent": {
    "fast-coder": {
      "model": "openai/gpt-4-turbo"
    },
    "analyzer": {
      "model": "anthropic/claude-haiku-4-5"
    }
  }
}
```

## Provider-Specific Options

### Timeout Configuration
```json
{
  "provider": {
    "anthropic": {
      "options": {
        "timeout": 600000,        // 10 minutes
        "timeout": false          // Disable timeout
      }
    }
  }
}
```

### Base URL Override
```json
{
  "provider": {
    "openai": {
      "options": {
        "baseURL": "https://custom-proxy.example.com"
      }
    }
  }
}
```

### Custom Headers
```json
{
  "provider": {
    "openai": {
      "options": {
        "headers": {
          "X-Custom-Header": "value"
        }
      }
    }
  }
}
```

## Authentication Plugins

For providers requiring OAuth or complex auth:

```json
{
  "plugin": [
    "opencode-gemini-auth@latest",
    "opencode-anthropic-auth@latest"
  ]
}
```

These plugins handle:
- OAuth flows
- Token refresh
- Credential storage

## Troubleshooting

### Invalid API Key
```
Error: Invalid API key for provider: anthropic
```

**Solution**:
1. Verify API key is correct
2. Check environment variable is set: `echo $ANTHROPIC_API_KEY`
3. Ensure no extra whitespace in key
4. Try re-running `/connect`

### Timeout Errors
```
Error: Request timeout
```

**Solution**:
```json
{
  "provider": {
    "anthropic": {
      "options": {
        "timeout": 600000  // Increase to 10 minutes
      }
    }
  }
}
```

### Provider Not Loading
```
Warning: Provider 'openai' not loaded
```

**Solution**:
1. Check `disabled_providers` - remove if listed
2. Check `enabled_providers` - add if using allowlist
3. Verify API key is set
4. Check logs: `tail -f ~/.opencode/logs/latest.log`

### Model Not Found
```
Error: Model not found: anthropic/claude-sonnet-5
```

**Solution**:
1. Check available models: `opencode models`
2. Verify model name format: `provider/model-id`
3. Ensure provider is configured and has valid API key

## Best Practices

### Development vs Production
```json
{
  "model": "{{ if env \"PRODUCTION\" }}anthropic/claude-opus-4-5{{ else }}anthropic/claude-haiku-4-5{{ end }}"
}
```

### Cost Optimization
```json
{
  "model": "anthropic/claude-sonnet-4-5",        // Main work
  "small_model": "anthropic/claude-haiku-4-5",   // Quick tasks
  "agent": {
    "quick-tasks": {
      "model": "anthropic/claude-haiku-4-5",
      "description": "Fast, low-cost operations"
    }
  }
}
```

### Security
- ✅ **DO** use environment variables or file references
- ✅ **DO** encrypt API keys with chezmoi
- ✅ **DO** use different keys for different environments
- ❌ **DON'T** commit API keys to Git
- ❌ **DON'T** share API keys in team configs

### Provider Selection
- ✅ **DO** use OpenCode Zen for curated models
- ✅ **DO** configure multiple providers for flexibility
- ✅ **DO** match model to task (fast for simple, powerful for complex)
- ❌ **DON'T** use expensive models for everything
- ❌ **DON'T** hardcode provider in shared configs
