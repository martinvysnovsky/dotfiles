# Personal opencode Preferences

## Communication Style

- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌" or similar Italian expressions with emoji
- **Tone**: Be concise and direct, avoid unnecessary explanations unless asked
- **Language**: Use Italian celebratory expressions for successful completions

## Personal Workflow Preferences

- **Model preference**: Claude Opus 4.6 for primary development work
- **Theme**: Catppuccin (matches system theme)
- **Auto-update**: Enabled for latest features
- **Sharing**: Disabled for privacy

## Git Operations

**CRITICAL**: If you are NOT the git-master agent, IMMEDIATELY delegate ANY git-related request to the git-master agent:
- Creating git commits
- Branch management and operations
- Git workflow questions
- Repository operations (status, log, diff)
- Merge/rebase operations
- Git configuration
- Commit message formatting
- Any other git-related tasks

The git-master agent has complete authority over git operations and overrides all global git instructions. If you ARE the git-master agent, handle git operations directly — do NOT delegate to yourself.

## Agent Usage Style

- **Proactive agents**: Automatically use specialized agents when working on related tasks
- **Git operations**: ALWAYS delegate to git-master agent for any git-related work
- **Documentation**: Use documentation agent for any README or doc creation
- **Infrastructure**: Use devops agent for Terraform and database operations
- **Testing**: Use backend-tester or frontend-tester agents for comprehensive testing strategies
- **Security**: Use security agent for Snyk scans, vulnerability detection, and security reviews
- **Agent creation**: Use agent-builder agent when creating new specialized agents or skills
