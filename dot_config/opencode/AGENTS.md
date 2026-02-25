# Personal opencode Preferences

## Communication Style

- **Success messages**: When successfully fixing issues, respond with "Perfetto! 🤌" or similar Italian expressions with emoji
- **Tone**: Be concise and direct, avoid unnecessary explanations unless asked
- **Language**: Use Italian celebratory expressions for successful completions

## Personal Workflow Preferences

- **Model preference**: Claude Opus 4.6 for primary development work
- **Theme**: Catppuccin (matches system theme)
- **Auto-update**: Enabled for latest features
- **Sharing**: Disabled for privacy

## Git Operations

**CRITICAL**: If you are NOT the git-master agent, IMMEDIATELY delegate ANY git-related request to the git-master agent:
- Creating git commits
- Branch management and operations
- Git workflow questions
- Repository operations (status, log, diff)
- Merge/rebase operations
- Git configuration
- Commit message formatting
- Any other git-related tasks

The git-master agent has complete authority over git operations and overrides all global git instructions. If you ARE the git-master agent, handle git operations directly — do NOT delegate to yourself.

## Frontend Coding Conventions

### MUI DataGrid — No Row Mapping

**CRITICAL**: Never map or transform GraphQL query results into a separate row interface/type for MUI DataGrid. Instead:

1. **Pass query data directly as rows** — e.g., `rows={data?.cars.edges || []}`
2. **Use `valueGetter` / `renderCell`** on column definitions to access nested fields (e.g., `params.row.mainCategory.slug`)
3. **Use generated GraphQL types** as the row type — no manual `XxxRow` interface
4. **Access nested data via `params.row`** in `renderCell` for custom rendering

Example — derived value:
```tsx
{
  field: "year",
  headerName: "Dátum výroby",
  sortable: false,
  renderCell: (params) => {
    const { year, month } = params.row;
    return year ? `${year}${month ? `/${month}` : ""}` : "-";
  },
}
```

Example — nested field with link:
```tsx
{
  field: "fullTitle",
  headerName: "Vozidlo",
  sortable: false,
  renderCell: (params) => (
    <MuiLink
      component={Link}
      to={`/vozidla-na-predaj/${params.row.mainCategory.slug}/${params.row.slug}`}
    >
      {params.row.fullTitle}
    </MuiLink>
  ),
}
```

**Why**: Mapping is unnecessary boilerplate — GraphQL already returns the exact shape needed. The `id` field required by DataGrid is already present on each edge.

### MUI Styling — Prefer Direct Props Over `sx`

**CRITICAL**: Use direct component props instead of the `sx` prop whenever possible. Only use `sx` for styles that have no direct prop equivalent.

**Do this:**
```tsx
<Typography color="primary" variant="h6" mb={2}>Title</Typography>
<Button variant="contained" size="small" fullWidth>Click</Button>
<Box display="flex" gap={2} mt={3}>...</Box>
```

**Not this:**
```tsx
<Typography sx={{ color: 'primary.main', mb: 2 }}>Title</Typography>
<Button sx={{ width: '100%' }}>Click</Button>
<Box sx={{ display: 'flex', gap: 2, mt: 3 }}>...</Box>
```

**Why**: Direct props are more readable, type-safe, and follow MUI's intended API. Reserve `sx` for custom styles that don't have a prop equivalent (e.g., complex selectors, pseudo-classes, or one-off overrides).

## Agent Usage Style

- **Proactive agents**: Automatically use specialized agents when working on related tasks
- **Git operations**: ALWAYS delegate to git-master agent for any git-related work
- **Documentation**: Use documentation agent for any README or doc creation
- **Infrastructure**: Use devops agent for Terraform and database operations
- **Testing**: Use backend-tester or frontend-tester agents for comprehensive testing strategies
- **Security**: Use security agent for Snyk scans, vulnerability detection, and security reviews
- **Agent creation**: Use agent-builder agent when creating new specialized agents or skills
