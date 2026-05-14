---
description: Generate FE migration instructions after breaking API changes
---

Analyze the current conversation context to identify backward-incompatible GraphQL API changes and generate a clipboard-ready instruction block for a Frontend AI agent.

Additional context from user: $ARGUMENTS

## Instructions

1. **Extract breaking changes from context** — Review the full conversation for:
   - Removed or renamed fields/types/enums
   - Changed field types (e.g., `String` → `String!`, `Float` → `Int`)
   - Modified query/mutation signatures (renamed args, new required args, removed args)
   - Removed or renamed queries/mutations
   - Changed enum values
   - Restructured nested types (e.g., flattened or nested a field)

2. **Categorize each change** by severity:
   - 🔴 **Removed** — field/query/mutation/enum value deleted entirely
   - 🟠 **Renamed** — name changed but same concept
   - 🟡 **Signature changed** — args added/removed/retyped
   - 🔵 **Type changed** — field type modified

3. **Generate the FE instruction block** — Output a single markdown code block (fenced with triple backticks) ready to copy to clipboard. The block must follow this exact structure:

````
## API Breaking Changes — [brief summary]

### Changes

1. **[emoji] [Entity].[field/query/mutation]** — [what changed]
   - Before: `[old signature/type]`
   - After: `[new signature/type]`

### Required FE Updates

1. **[component area / file pattern]** — [what to update]
   - Update `[OperationName.graphql]`: [specific field/arg changes]

### Migration Notes

- [Any additional context: new enum values to handle, nullable→required transitions, etc.]
- Run `npm run codegen` to regenerate types after updating all `.graphql` files
````

4. **Keep it concise** — The FE agent doesn't need backend implementation details. Focus only on:
   - What changed in the GraphQL schema (types, queries, mutations, enums)
   - Which `.graphql` operation files on FE likely need updating
   - Any new required variables or removed fields the FE must handle

5. **If `$ARGUMENTS` mentions specific files or features**, narrow the scope to only those changes.

6. **Output only the copyable block** — No extra explanation before or after. Just the migration instructions, ready for clipboard.
