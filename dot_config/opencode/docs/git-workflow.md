# Git Workflow Guidelines

## GitHub Flow

**Follow GitHub Flow**: Use the workflow described at https://docs.github.com/en/get-started/using-github/github-flow

This applies to all Git repositories, including Bitbucket repositories.

## Key Principles

- **Create feature branches from main/master**: Always branch from the main branch for new features
- **Make commits with descriptive messages**: Write clear, concise commit messages that explain the "why"
- **Open pull requests for code review**: Use PRs/MRs for all changes, even small ones
- **Deploy from main/master branch**: Keep the main branch as the source of truth for deployments
- **Keep main/master branch always deployable**: Ensure the main branch is always in a working state

## Branch Naming

- Use descriptive branch names: `feature/user-authentication`, `fix/login-bug`, `docs/api-documentation`
- Avoid generic names like `fix`, `update`, or `changes`

## Commit Messages

- Use imperative mood: "Add user authentication" not "Added user authentication"
- Keep first line under 50 characters
- Include detailed description if needed after a blank line
- Reference issues/tickets when applicable

## Pull Request Best Practices

- Write clear PR titles and descriptions
- Include context about what changed and why
- Request appropriate reviewers
- Keep PRs focused and reasonably sized
- Update PR description if scope changes during review