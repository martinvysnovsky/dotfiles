---
description: Create a Bitbucket PR for the current branch
agent: build
---

Create a Bitbucket pull request for the current branch.

## Instructions

1. **Get current branch** — Run `git branch --show-current` to get the current branch name
2. **Get Bitbucket remote** — Run `git remote -v` to extract the workspace and repository slug from the Bitbucket origin URL (format: `bitbucket.org/<workspace>/<repo>`)
3. **Determine destination branch** — Default to `master`. If $ARGUMENTS specifies a target branch, use that instead
4. **Rebase on destination branch** — Run `git fetch origin` then `git rebase origin/<destination_branch>` to ensure the branch is up to date. If rebase fails due to conflicts, stop and inform the user
5. **Push to remote** — Run `git push --force-with-lease` to update the remote branch after rebase
6. **Build PR title and description**:
   - Extract Jira ticket key from branch name if present (e.g., `EB-448-some-description` → `EB-448`)
   - If Jira key found, fetch the ticket summary using `mcp_Mcp-gateway_jira_getIssue` for context
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
7. **Fetch default reviewers** — Use `mcp_Mcp-gateway_bitbucket_getEffectiveDefaultReviewers` and include them in the `reviewers` array of the PR
8. **Create the PR** — Use `mcp_Mcp-gateway_bitbucket_createPullRequest` with the built title, description, source and destination branches (branch auto-deletion is governed by the repository's merge settings, not the PR payload)
9. **Return the PR URL** to the user

Additional context from user: $ARGUMENTS
