---
description: Fetch Jira ticket and plan implementation
agent: plan
---

Fetch the Jira ticket from the provided URL and create an implementation plan.

## Instructions

1. **Parse the Jira URL** - Extract the issue key from `$ARGUMENTS` (e.g., `EB-354` from `https://ketler.atlassian.net/browse/EB-354`)
2. **Fetch ticket details** - Use `jira_get_issue` to get full ticket information including description, acceptance criteria, priority, status, and linked issues
3. **Analyze requirements** - Break down the ticket into clear technical requirements
4. **Explore the codebase** - Search for relevant files, patterns, and existing implementations related to the ticket
5. **Create implementation plan** - Propose a detailed step-by-step plan with:
   - Files to create or modify
   - Technical approach
   - Edge cases to consider
   - Testing strategy
