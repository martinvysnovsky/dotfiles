---
description: Fetch Sentry issue and plan a fix
agent: plan
---

Fetch the Sentry issue from the provided URL and create a plan to fix it.

## Instructions

1. **Get issue details** - Use `sentry_get_issue_details` with the URL from `$ARGUMENTS` to get the full error information including stacktrace, breadcrumbs, and tags
2. **Run root cause analysis** - Use `sentry_analyze_issue_with_seer` to get AI-powered root cause analysis and suggested code fixes
3. **Analyze the error** - Break down the error into clear technical findings:
   - What is failing and why
   - Which files and lines are involved
   - How often it occurs and which users/environments are affected
4. **Explore the codebase** - Search for the relevant files and surrounding code to understand the full context
5. **Create fix plan** - Propose a detailed step-by-step plan with:
   - Root cause explanation
   - Files to modify with specific changes
   - Edge cases to consider
   - Testing strategy to prevent regression
