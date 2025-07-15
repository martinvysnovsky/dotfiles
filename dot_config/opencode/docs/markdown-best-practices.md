# Markdown Best Practices

## Document Structure

### Headings

- Use ATX-style headings (`#`) instead of Setext-style (`===` or `---`)
- Always put a space between `#` and the heading text
- Use only one H1 (`#`) per document for the main title
- Follow logical heading hierarchy (don't skip levels)
- Put blank lines before and after headings

```markdown
# Document Title

## Section Heading

### Subsection Heading
```

### Document Organization

- Start with a clear, descriptive title
- Include a brief introduction or overview
- Use consistent heading structure throughout
- End with conclusion or next steps when appropriate

## Text Formatting

### Emphasis

- Use `**bold**` for strong emphasis (prefer over `__bold__`)
- Use `*italic*` for emphasis (prefer over `_italic_`)
- Use `***bold and italic***` for combined emphasis
- Avoid emphasis in the middle of words with underscores

### Line Breaks and Paragraphs

- Use blank lines to separate paragraphs
- End lines with two spaces for line breaks (or use `<br>` tag)
- Don't indent paragraphs with spaces or tabs
- Keep line lengths reasonable (80-120 characters)

## Lists

### Unordered Lists

- Use consistent markers (`-`, `*`, or `+`) throughout document
- Prefer `-` for consistency
- Use proper indentation for nested lists (2-4 spaces)
- Add blank lines around lists for better readability

```markdown
- First item
- Second item
  - Nested item
  - Another nested item
- Third item
```

### Ordered Lists

- Use `1.` for all items (auto-numbering)
- Use periods, not parentheses (`1.` not `1)`)
- Maintain consistent indentation for nested items

```markdown
1. First step
1. Second step
   1. Sub-step
   1. Another sub-step
1. Third step
```

## Code and Technical Content

### Inline Code

- Use single backticks for inline code: `code`
- Use double backticks when code contains backticks: ``code with `backticks` ``
- Don't use code formatting for emphasis

### Code Blocks

- Use fenced code blocks with triple backticks
- Always specify language for syntax highlighting
- Use consistent indentation within code blocks
- Add blank lines before and after code blocks

````markdown
```javascript
function example() {
  return "Hello, World!";
}
```
````

````

### Language Specifications
- Use standard language identifiers: `javascript`, `python`, `bash`, `json`
- Use `text` for plain text or when no highlighting is needed
- Use `diff` for showing changes

## Links and References

### Link Formatting
- Use descriptive link text (avoid "click here" or "read more")
- Use reference-style links for repeated URLs
- URL-encode spaces and special characters in URLs
- Add titles for additional context when helpful

```markdown
[Descriptive link text](https://example.com "Optional title")

[Reference link][ref-id]

[ref-id]: https://example.com "Reference URL"
````

### Internal Links

- Use relative paths for internal links
- Link to specific sections with heading anchors
- Test all links before publishing

## Images and Media

### Image Best Practices

- Always include descriptive alt text
- Use relative paths for local images
- Optimize image sizes for web
- Add titles for additional context

```markdown
![Descriptive alt text](path/to/image.png "Optional title")
```

### Image Organization

- Store images in dedicated directories (`images/`, `assets/`)
- Use descriptive filenames
- Consider using reference-style for repeated images

## Tables

### Table Structure

- Use pipes (`|`) to separate columns
- Include header row with hyphens (`---`)
- Align columns for readability in source
- Use colons for column alignment

```markdown
| Left Aligned | Center Aligned | Right Aligned |
| :----------- | :------------: | ------------: |
| Content      |    Content     |       Content |
| More content |  More content  |  More content |
```

### Table Content

- Keep cell content concise
- Use HTML for complex formatting within cells
- Escape pipe characters with `&#124;` when needed

## Special Elements

### Blockquotes

- Use `>` for blockquotes
- Add blank lines before and after blockquotes
- Use `>>` for nested quotes
- Include attribution when quoting sources

```markdown
> This is a blockquote.
> It can span multiple lines.
>
> > This is a nested quote.
```

### Horizontal Rules

- Use three or more hyphens (`---`) on their own line
- Add blank lines before and after horizontal rules
- Use sparingly for section breaks

### Task Lists

- Use `- [ ]` for unchecked items
- Use `- [x]` for checked items
- Maintain consistent spacing

```markdown
- [x] Completed task
- [ ] Pending task
- [ ] Another pending task
```

## Compatibility and Standards

### Cross-Platform Compatibility

- Test rendering across different Markdown processors
- Use standard syntax over processor-specific extensions
- Avoid mixing different list markers in the same document
- Use consistent line endings (LF preferred)

### Accessibility

- Use descriptive alt text for images
- Maintain logical heading hierarchy
- Use sufficient color contrast in custom styling
- Provide text alternatives for visual content

## File Organization

### File Naming

- Use lowercase with hyphens: `file-name.md`
- Use descriptive, meaningful names
- Include date prefixes for chronological content: `2024-01-15-post-title.md`

### Directory Structure

- Organize related documents in folders
- Use consistent naming conventions
- Include README.md files in directories
- Keep assets organized in dedicated folders

## Quality Assurance

### Before Publishing

- Run markdown linter (markdownlint, remark-lint)
- Check all links are working
- Verify images display correctly
- Test rendering in target platform
- Proofread for spelling and grammar

### Maintenance

- Regular link checking
- Update outdated information
- Maintain consistent style across documents
- Version control for collaborative editing
