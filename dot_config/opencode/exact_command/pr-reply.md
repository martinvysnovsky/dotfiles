---
description: Reply to PR comments and mark them as resolved
agent: plan
---

For each review comment on the current branch's PR: reply with what was done (or why it was skipped), then mark the comment as resolved.

## Instructions

1. **Get current branch** — Run `git branch --show-current`
2. **Get Bitbucket remote** — Run `git remote -v` to extract workspace and repository slug from the Bitbucket origin URL (format: `bitbucket.org/<workspace>/<repo>`)
3. **Find the PR** — Use `bitbucket_list_pull_requests` filtered by the current branch
4. **Get PR details** — Use `bitbucket_get_pull_request` to fetch all active comments
5. **Filter comments** — Skip bot summary/walkthrough comments (CodeRabbit walkthrough, general summaries). Focus only on actionable inline code review comments
6. **For each actionable comment**:
   - Read the referenced file and line in the codebase to understand the current state
   - Determine the outcome:
     - ✅ **Fixed** — issue was addressed in the code
     - ⏭️ **Skipped** — issue was intentionally not fixed (with a reason)
     - 🔄 **Partially fixed** — issue was partially addressed
   - Reply using `bitbucket_add_comment` with `parent_comment_id` set to the comment's `id`:
     - Fixed: `"Fixed — <brief description of what was changed>"`
     - Skipped: `"Not fixed — <brief reason>"`
     - Partial: `"Partially fixed — <what was done and what remains>"`
   - After replying, mark the comment as resolved using `bitbucket_resolve_comment`

7. **Summary** — Report which comments were replied to and resolved, and which (if any) could not be resolved

If no PR is found for the current branch, inform the user.

Additional context from user: $ARGUMENTS
