---
description: Check PR comments and plan fixes for the current branch
agent: plan
---

Check the Bitbucket pull request for the current branch, verify review comments against the code, and create an implementation plan for fixing valid issues.

## Instructions

1. **Get current branch** — Run `git branch --show-current` to get the current branch name
2. **Get Bitbucket remote** — Run `git remote -v` to extract the workspace and repository slug from the Bitbucket origin URL (format: `bitbucket.org/<workspace>/<repo>`)
3. **Find the PR** — Use `bitbucket_list_pull_requests` filtered by the current branch to find the open PR
4. **Get PR details** — Use `bitbucket_get_pull_request` to fetch the full PR with active comments
5. **Filter comments** — Skip bot summary/walkthrough comments. Focus only on actionable code review feedback
6. **Verify each comment** — For every actionable comment:
   - Read the referenced file and line in the actual codebase
   - Determine if the issue is **still valid** in the current code or already fixed
   - Mark as: ✅ Valid | ❌ Already fixed | ⚠️ Partially valid | 🤔 Debatable
   - If invalid or already fixed, briefly explain why
7. **Create implementation plan** — For all valid issues:
   - Group fixes by file
   - Describe the specific code change needed for each
   - Note any edge cases or dependencies between fixes
   - Suggest a testing approach

If no PR is found for the current branch, inform the user.

Additional context from user: $ARGUMENTS
