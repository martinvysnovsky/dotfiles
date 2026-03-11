---
description: Fetch Jira ticket and plan implementation
agent: plan
---

Implement Jira ticket $1

Fetch the Jira ticket $1 using `jira_get_issue` and create a detailed implementation plan.

$1 can be an issue key (e.g., `EB-354`) or full URL (e.g., `https://ketler.atlassian.net/browse/EB-354`). Parse it accordingly.

Additional requirements from the user: $2

## Plan should include

- Files to create or modify
- Technical approach
- Edge cases to consider
- Testing strategy
- Incorporate any additional requirements provided above as constraints or modifications to the ticket's scope

## Steps

1. Fetch ticket details - description, acceptance criteria, priority, status, linked issues
2. Analyze and break down requirements
3. Explore the codebase for relevant files, patterns, and existing implementations
4. Create step-by-step implementation plan
