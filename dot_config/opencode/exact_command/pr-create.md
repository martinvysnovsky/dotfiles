---
description: Create a Bitbucket PR for the current branch
agent: plan
---

Create a Bitbucket pull request for the current branch.

## Instructions

1. **Get current branch** — Run `git branch --show-current` to get the current branch name
2. **Get Bitbucket remote** — Run `git remote -v` to extract the workspace and repository slug from the Bitbucket origin URL (format: `bitbucket.org/<workspace>/<repo>`)
3. **Check remote is up to date** — Run `git status` to verify the branch has been pushed
4. **Determine destination branch** — Default to `master`. If $ARGUMENTS specifies a target branch, use that instead
5. **Build PR title and description**:
   - Extract Jira ticket key from branch name if present (e.g., `EB-448-some-description` → `EB-448`)
   - If Jira key found, fetch the ticket summary using `jira_get_issue` for context
   - Run `git log origin/master..HEAD --oneline` to see all commits
   - Create a concise PR title following pattern: `<TICKET-KEY>: <type>: <description>`
   - Create the description in **proper Markdown with real newlines** (not escaped `\n`). Use a multi-line string to preserve formatting. Structure:
     ```
     ## Summary
     **Jira**: [EB-448](https://ketler.atlassian.net/browse/EB-448) — <ticket summary>

     ## Changes
     - <change 1>
     - <change 2>
     - <change 3>
     ```
6. **Create the PR** — Use `bitbucket_create_pull_request` with the built title, description, source and destination branches. Set `close_source_branch: true` to auto-delete the branch after merge
7. **Return the PR URL** to the user

Additional context from user: $ARGUMENTS
