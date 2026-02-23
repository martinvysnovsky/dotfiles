---
name: mui
description: Material UI v7 component library patterns, theming, layout, styling with sx prop, and MUI X Pro components (DataGrid Pro, DatePickers Pro, Charts Pro). Use when (1) building UI with MUI components, (2) using Grid/Stack/Box layout, (3) customizing theme with createTheme, (4) styling with sx prop or styled API, (5) working with DataGrid Pro tables, (6) implementing date/time pickers, (7) creating charts, (8) adding dialogs/snackbars/alerts, (9) implementing responsive designs, (10) design-to-code workflows with MUI.
---

# Material UI v7

## Quick Reference

**Team conventions & patterns:**
- **[conventions.md](references/conventions.md)** - Import order, Link patterns, flex rules, form components, anti-patterns
- **[data-grid-patterns.md](references/data-grid-patterns.md)** - DataGrid Pro column definitions, formatting, date columns, fullHeight

**For full component API and advanced docs:**
Use the MUI MCP tools (`mui_useMuiDocs`, `mui_fetchDocs`) to fetch live documentation from mui.com.

## MUI MCP Tools Usage

The `@mui/mcp` server provides live access to the full MUI documentation.

**Workflow:**
1. Call `mui_useMuiDocs` to fetch docs for the relevant package (`@mui/material`, `@mui/x-data-grid-pro`, `@mui/x-date-pickers-pro`, `@mui/x-charts-pro`)
2. Call `mui_fetchDocs` with specific URLs from the returned content for deeper details
3. Repeat until you have all relevant information

**When to use MUI MCP:**
- Looking up specific component props or API details
- Theming configuration options beyond the basics below
- Migration patterns or deprecated API alternatives
- Advanced customization (styled components, theme overrides)
- MUI X Pro features (DataGrid server-side data, Charts composition, DatePicker custom fields)

## Packages

```
@mui/material          - Core components (v7)
@mui/icons-material    - Material Design icons
@mui/x-data-grid-pro   - DataGrid Pro (columns, filtering, sorting, pinning, master-detail)
@mui/x-date-pickers-pro - DatePicker Pro (date ranges, time ranges)
@mui/x-charts-pro      - Charts Pro (bar, line, pie, scatter, heatmap, funnel)
@mui/material/styles   - createTheme, styled, ThemeProvider, useTheme
@mui/system            - Box, sx prop, breakpoints
```

## MUI v7 Grid (NOT Grid2)

MUI v7 renamed `Grid2` to `Grid`. Uses the `size` prop instead of breakpoint props directly.

```typescript
import { Grid } from '@mui/material';

// ✅ MUI v7 - Use size prop
<Grid container spacing={2}>
  <Grid size={{ xs: 12, md: 6 }}>
    <Item>Half width on md+</Item>
  </Grid>
  <Grid size={{ xs: 12, md: 6 }}>
    <Item>Half width on md+</Item>
  </Grid>
</Grid>

// ✅ Simple - number for all breakpoints
<Grid container spacing={2}>
  <Grid size={8}>
    <Item>8 columns</Item>
  </Grid>
  <Grid size={4}>
    <Item>4 columns</Item>
  </Grid>
</Grid>

// ✅ Auto-layout with "grow" and "auto"
<Grid container spacing={3}>
  <Grid size="grow">
    <Item>Fills remaining space</Item>
  </Grid>
  <Grid size={6}>
    <Item>Fixed 6 columns</Item>
  </Grid>
  <Grid size="auto">
    <Item>Fits content</Item>
  </Grid>
</Grid>

// ✅ Offset - push items right
<Grid container spacing={2}>
  <Grid size={{ xs: 6, md: 4 }} offset={{ md: 2 }}>
    <Item>Offset by 2 on md+</Item>
  </Grid>
  <Grid size={{ xs: 6, md: 4 }} offset={{ md: 'auto' }}>
    <Item>Push to right</Item>
  </Grid>
</Grid>

// ❌ WRONG - Old Grid2 / GridLegacy syntax
<Grid xs={12} md={6}>  // Don't use breakpoint props directly
<Grid item xs={12}>    // Don't use "item" prop
<Grid2 size={6}>       // Grid2 is deprecated in v7
```

### Grid Limitations
- NO `direction="column"` — use `Stack` for vertical layouts
- NO row spanning — use CSS Grid if needed
- NO auto-placement — items flow left-to-right, wrap to next line

```typescript
// ✅ Vertical layout inside Grid
<Grid container spacing={2}>
  <Grid size={4}>
    <Stack spacing={2}>
      <Item>Row 1</Item>
      <Item>Row 2</Item>
    </Stack>
  </Grid>
  <Grid size={8}>
    <Item sx={{ height: '100%' }}>Tall content</Item>
  </Grid>
</Grid>
```

## The `sx` Prop

The primary way to style MUI components. Supports theme-aware values and responsive syntax.

```typescript
// Theme-aware values
<Box sx={{
  color: 'primary.main',          // theme.palette.primary.main
  bgcolor: 'background.paper',    // theme.palette.background.paper
  p: 3,                           // theme.spacing(3) = 24px
  m: 2,                           // theme.spacing(2) = 16px
  borderRadius: 1,                // theme.shape.borderRadius * 1
  typography: 'body1',            // theme.typography.body1
}} />

// Responsive values
<Box sx={{
  width: { xs: '100%', md: '50%' },
  display: { xs: 'none', md: 'block' },
  p: { xs: 2, md: 3 },
}} />

// Nested selectors
<Card sx={{
  '& .MuiCardHeader-root': { pb: 0 },
  '&:hover': { boxShadow: 3 },
  '& .Mui-disabled': { opacity: 0.5 },
}} />

// Callback with theme access
<Box sx={(theme) => ({
  color: theme.palette.mode === 'dark' ? 'grey.300' : 'grey.800',
})} />
```

### sx Shorthand Properties

| Shorthand | CSS Property | Example |
|-----------|-------------|---------|
| `m`, `mt`, `mr`, `mb`, `ml`, `mx`, `my` | margin | `m: 2` → `margin: 16px` |
| `p`, `pt`, `pr`, `pb`, `pl`, `px`, `py` | padding | `p: 3` → `padding: 24px` |
| `bgcolor` | backgroundColor | `bgcolor: 'primary.light'` |
| `gap` | gap | `gap: 2` → `gap: 16px` |
| `flexGrow` | flexGrow | `flexGrow: 1` |
| `display` | display | `display: 'flex'` |

## Customization Hierarchy

From narrowest to broadest scope:

1. **`sx` prop** — One-off instance styling
2. **`styled()` utility** — Reusable styled components
3. **Theme `components` key** — Global component overrides via `createTheme`
4. **`GlobalStyles` / `CssBaseline`** — Global CSS overrides

```typescript
// 1. sx prop (one-off)
<Button sx={{ borderRadius: 8 }}>Rounded</Button>

// 2. styled() (reusable)
const RoundedButton = styled(Button)({ borderRadius: 8 });

// 3. Theme overrides (global)
const theme = createTheme({
  components: {
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 8 },
      },
      defaultProps: {
        variant: 'contained',
      },
    },
  },
});

// 4. Global CSS
<GlobalStyles styles={{ h1: { color: 'grey' } }} />
```

## Theming Quick Reference

```typescript
import { createTheme, ThemeProvider } from '@mui/material/styles';

const theme = createTheme({
  palette: {
    primary: { main: '#1976d2' },
    secondary: { main: '#dc004e' },
    // Enable dark mode
    mode: 'dark',
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Arial", sans-serif',
    h1: { fontSize: '2.5rem', fontWeight: 700 },
  },
  spacing: 8, // base spacing unit (default)
  shape: {
    borderRadius: 8,
  },
  // CSS theme variables (v7 feature)
  cssVariables: true,
  // Global component overrides
  components: {
    MuiButton: {
      defaultProps: { variant: 'contained' },
      styleOverrides: {
        root: { textTransform: 'none' },
      },
    },
  },
});

// Usage
<ThemeProvider theme={theme}>
  <CssBaseline />
  <App />
</ThemeProvider>

// Access theme in components
import { useTheme } from '@mui/material/styles';
const theme = useTheme();
```

### CSS Theme Variables (v7)

```typescript
const theme = createTheme({ cssVariables: true });

// Generates CSS variables automatically:
// --mui-palette-primary-main: #1976d2;
// --mui-palette-background-paper: #fff;
// Components use var(--mui-palette-primary-main) instead of raw values
```

### Dark Mode

```typescript
import { createTheme, ThemeProvider } from '@mui/material/styles';
import { InitColorSchemeScript } from '@mui/material';

const theme = createTheme({
  cssVariables: true,
  colorSchemes: {
    light: { palette: { primary: { main: '#1976d2' } } },
    dark: { palette: { primary: { main: '#90caf9' } } },
  },
});

// In root layout (prevents flash)
<InitColorSchemeScript />
<ThemeProvider theme={theme}>
  <CssBaseline />
  <App />
</ThemeProvider>
```

### TypeScript Theme Augmentation

```typescript
declare module '@mui/material/styles' {
  interface Theme {
    status: { danger: string };
  }
  interface ThemeOptions {
    status?: { danger?: string };
  }
  interface Palette {
    custom: Palette['primary'];
  }
  interface PaletteOptions {
    custom?: PaletteOptions['primary'];
  }
}

declare module '@mui/system' {
  interface BreakpointOverrides {
    laptop: true;
    tablet: true;
    mobile: true;
    desktop: true;
    xs: false; // remove defaults if replacing
  }
}
```

## State Classes

Target component states with global MUI class names:

| State | Class | Example |
|-------|-------|---------|
| active | `.Mui-active` | `'& .Mui-active': { color: 'red' }` |
| checked | `.Mui-checked` | |
| disabled | `.Mui-disabled` | |
| error | `.Mui-error` | |
| expanded | `.Mui-expanded` | |
| focused | `.Mui-focused` | |
| selected | `.Mui-selected` | |

```typescript
// ✅ Always target state with component class
<TextField sx={{
  '& .MuiOutlinedInput-root.Mui-error': {
    borderColor: 'error.main',
  },
}} />

// ❌ Never target state class alone
<Box sx={{ '& .Mui-error': { color: 'red' } }} />  // Affects ALL components
```

## Component Categories

### Layout
`Box`, `Container`, `Grid`, `Stack`, `ImageList`

### Inputs
`Autocomplete`, `Button`, `ButtonGroup`, `Checkbox`, `Fab`, `NumberField` (new v7), `RadioGroup`, `Rating`, `Select`, `Slider`, `Switch`, `TextField`, `ToggleButton`, `TransferList`

### Data Display
`Avatar`, `Badge`, `Chip`, `Divider`, `Icons`, `List`, `Table`, `Tooltip`, `Typography`

### Feedback
`Alert`, `Backdrop`, `Dialog`, `Progress`, `Skeleton`, `Snackbar`

### Surfaces
`Accordion`, `AppBar`, `Card`, `Paper`

### Navigation
`BottomNavigation`, `Breadcrumbs`, `Drawer`, `Link`, `Menu`, `Pagination`, `SpeedDial`, `Stepper`, `Tabs`

### Utils
`ClickAwayListener`, `CssBaseline`, `InitColorSchemeScript`, `Modal`, `Popover`, `Popper`, `Portal`, `TextareaAutosize`, `Transitions`, `useMediaQuery`

### MUI X Pro
`DataGridPro`, `DatePicker`, `DateRangePicker`, `TimePicker`, `DateTimePicker`, `BarChart`, `LineChart`, `PieChart`, `ScatterChart`, `Heatmap`, `FunnelChart`, `RadarChart`, `Gauge`, `Sparkline`

### Lab
`Masonry`, `Timeline`

## When to Load Reference Files

**Working with component patterns specific to your team?**
- Import order, Link usage, flex rules, form elements → [conventions.md](references/conventions.md)

**Working with DataGrid Pro tables?**
- Column definitions, formatting, date columns, fullHeight → [data-grid-patterns.md](references/data-grid-patterns.md)

**Need full component API details?**
- Use `mui_useMuiDocs` tool with the relevant package name
- Then `mui_fetchDocs` with specific URLs from the returned content

**Need theming or customization details beyond the quick reference above?**
- Use `mui_useMuiDocs` for `@mui/material` and fetch theming docs
