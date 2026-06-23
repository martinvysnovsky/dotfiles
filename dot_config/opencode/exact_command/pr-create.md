---
description: Create a Bitbucket PR for the current branch
agent: build
---

Create a Bitbucket pull request for the current branch.

## Instructions

1. **Get current branch** — Run `git branch --show-current` to get the current branch name
2. **Get Bitbucket remote** — Run `git remote -v` to extract the workspace and repository slug from the Bitbucket origin URL (format: `bitbucket.org/<workspace>/<repo>`)
3. **Determine destination branch** — Default to `master`. If $ARGUMENTS specifies a target branch, use that instead
4. **Push check** — The branch is normally already rebased and pushed. Run `git status -sb` to check for unpushed commits. If there are unpushed commits, run a plain `git push`. Otherwise skip. Do **not** fetch, rebase, or force-push
5. **Build PR title and description**:
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
6. **Create the PR** — Always use the Bitbucket MCP tool `mcp_Mcp-gateway_bitbucket_createPullRequest` with the built title, description, source and destination branches. Do **not** set `reviewers` — leave Bitbucket to apply its own default reviewers. Do **not** use or look for the GitHub (`gh`) or GitLab (`glab`) CLIs; this is a Bitbucket-only workflow (branch auto-deletion is governed by the repository's merge settings, not the PR payload)
7. **Return the PR URL** to the user

Additional context from user: $ARGUMENTS
