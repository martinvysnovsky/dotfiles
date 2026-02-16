---
description: Fetch Jira ticket and plan implementation
agent: plan
---

Fetch the Jira ticket from the provided URL and create an implementation plan.

## Instructions

1. **Parse the arguments** - The first part of `$ARGUMENTS` is the Jira URL or issue key (e.g., `EB-354` or `https://ketler.atlassian.net/browse/EB-354`). Any text after the URL/key is treated as additional requirements or changes that should be incorporated into the plan.
2. **Fetch ticket details** - Use `jira_get_issue` to get full ticket information including description, acceptance criteria, priority, status, and linked issues
3. **Analyze requirements** - Break down the ticket into clear technical requirements
4. **Explore the codebase** - Search for relevant files, patterns, and existing implementations related to the ticket
5. **Create implementation plan** - Propose a detailed step-by-step plan with:
   - Files to create or modify
   - Technical approach
   - Edge cases to consider
   - Testing strategy
   - If additional requirements were provided in the arguments, incorporate them into the plan as constraints or modifications to the ticket's scope
