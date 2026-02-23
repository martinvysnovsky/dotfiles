# DataGrid Pro Patterns

## Contents
- Column definitions
- Value formatting
- Date columns
- Link columns
- Actions columns
- fullHeight usage
- Sorting and filtering
- Common patterns

## Column Definitions

Extract column definitions as typed constants outside the component. Always set `minWidth` on columns.

```typescript
import { DataGridPro, GridColDef } from '@mui/x-data-grid-pro';

// ✅ Good - Columns as typed constant outside component
const CAR_COLUMNS: GridColDef[] = [
  {
    field: 'title',
    headerName: 'Title',
    minWidth: 200,
    flex: 1,
  },
  {
    field: 'price',
    headerName: 'Price',
    minWidth: 100,
    valueFormatter: (value) => formatPrice(value),
  },
  {
    field: 'registrationDate',
    headerName: 'Registration Date',
    minWidth: 100,
    ...dateColumn,
  },
];

export default function CarTable({ cars }: { cars: Car[] }) {
  return (
    <DataGridPro
      rows={cars}
      columns={CAR_COLUMNS}
      fullHeight
    />
  );
}

// ❌ Bad - Columns inside component (causes re-renders)
export default function CarTable({ cars }: { cars: Car[] }) {
  const columns = [ ... ]; // Recreated every render
  return <DataGridPro rows={cars} columns={columns} />;
}

// ❌ Bad - Columns wrapped in useMemo (unnecessary for static columns)
const columns = useMemo(() => [ ... ], []);
```

## Value Formatting

### Price Formatter

```typescript
const CAR_COLUMNS: GridColDef[] = [
  {
    field: 'price',
    headerName: 'Price',
    minWidth: 120,
    // ✅ Returns empty string for null/undefined
    valueFormatter: (value) => formatPrice(value),
  },
];
```

### Custom Value Formatters

```typescript
const COLUMNS: GridColDef[] = [
  {
    field: 'mileage',
    headerName: 'Mileage',
    minWidth: 100,
    valueFormatter: (value) => {
      if (value == null) return '';
      return `${value.toLocaleString()} km`;
    },
  },
  {
    field: 'status',
    headerName: 'Status',
    minWidth: 100,
    valueFormatter: (value) => {
      const statusMap: Record<string, string> = {
        available: 'Available',
        sold: 'Sold',
        reserved: 'Reserved',
      };
      return statusMap[value] || value;
    },
  },
];
```

## Date Column Pattern

Use the shared `dateColumn` pattern for consistent date handling across all tables. Shows "-" for null dates.

```typescript
import { GridColDef } from '@mui/x-data-grid-pro';
import { format } from 'date-fns';

// ✅ Shared date column config - reuse across all tables
export const dateColumn: Partial<GridColDef> = {
  type: 'date',
  valueFormatter: (value: Date | null) => {
    if (!value || value.getTime() === 0) return '-';
    return format(value, 'dd.MM.yyyy');
  },
};

// Usage - spread into column definition
const COLUMNS: GridColDef[] = [
  {
    field: 'registrationDate',
    headerName: 'Registration Date',
    minWidth: 130,
    ...dateColumn,
  },
  {
    field: 'createdAt',
    headerName: 'Created',
    minWidth: 130,
    ...dateColumn,
  },
];
```

## Link Columns

Render clickable links in DataGrid cells using `renderCell`.

```typescript
import { Link } from '@mui/material';

const COLUMNS: GridColDef[] = [
  {
    field: 'title',
    headerName: 'Title',
    minWidth: 200,
    flex: 1,
    renderCell: (params) => (
      <Link href={`/cars/${params.row.id}`} color="primary" underline="hover">
        {params.value}
      </Link>
    ),
  },
];
```

## Actions Column

```typescript
import { GridColDef, GridActionsCellItem } from '@mui/x-data-grid-pro';
import { Edit, Delete, Visibility } from '@mui/icons-material';

const getColumns = (
  onEdit: (id: string) => void,
  onDelete: (id: string) => void,
): GridColDef[] => [
  // ... data columns ...
  {
    field: 'actions',
    type: 'actions',
    headerName: 'Actions',
    width: 120,
    getActions: (params) => [
      <GridActionsCellItem
        icon={<Visibility />}
        label="View"
        onClick={() => navigate(`/cars/${params.id}`)}
      />,
      <GridActionsCellItem
        icon={<Edit />}
        label="Edit"
        onClick={() => onEdit(params.id as string)}
      />,
      <GridActionsCellItem
        icon={<Delete />}
        label="Delete"
        onClick={() => onDelete(params.id as string)}
        color="error"
      />,
    ],
  },
];
```

## fullHeight Usage

Use `fullHeight` for DataGrids that should fill the available page height.

```typescript
// ✅ Full-page table
<DataGridPro
  rows={cars}
  columns={CAR_COLUMNS}
  fullHeight
/>

// ✅ Fixed height (for inline tables, dialogs, etc.)
<Box sx={{ height: 400 }}>
  <DataGridPro
    rows={cars}
    columns={CAR_COLUMNS}
  />
</Box>
```

## Sorting

```typescript
<DataGridPro
  rows={cars}
  columns={CAR_COLUMNS}
  initialState={{
    sorting: {
      sortModel: [{ field: 'createdAt', sort: 'desc' }],
    },
  }}
/>
```

## Filtering

```typescript
<DataGridPro
  rows={cars}
  columns={CAR_COLUMNS}
  initialState={{
    filter: {
      filterModel: {
        items: [
          { field: 'status', operator: 'is', value: 'available' },
        ],
      },
    },
  }}
  // Enable header filters (Pro feature)
  headerFilters
/>
```

## Pagination

```typescript
<DataGridPro
  rows={cars}
  columns={CAR_COLUMNS}
  pagination
  pageSizeOptions={[25, 50, 100]}
  initialState={{
    pagination: {
      paginationModel: { pageSize: 25 },
    },
  }}
/>
```

## Column Pinning

```typescript
<DataGridPro
  rows={cars}
  columns={CAR_COLUMNS}
  initialState={{
    pinnedColumns: {
      left: ['title'],
      right: ['actions'],
    },
  }}
/>
```

## Row Selection

```typescript
import { useState } from 'react';
import { GridRowSelectionModel } from '@mui/x-data-grid-pro';

export default function CarTable({ cars }: { cars: Car[] }) {
  const [selectionModel, setSelectionModel] = useState<GridRowSelectionModel>([]);

  const handleBulkDelete = () => {
    // selectionModel contains selected row IDs
    console.log('Delete:', selectionModel);
  };

  return (
    <>
      {selectionModel.length > 0 && (
        <Button onClick={handleBulkDelete} color="error">
          Delete {selectionModel.length} selected
        </Button>
      )}
      <DataGridPro
        rows={cars}
        columns={CAR_COLUMNS}
        checkboxSelection
        rowSelectionModel={selectionModel}
        onRowSelectionModelChange={setSelectionModel}
        fullHeight
      />
    </>
  );
}
```

## Master-Detail (Pro)

```typescript
<DataGridPro
  rows={cars}
  columns={CAR_COLUMNS}
  getDetailPanelContent={({ row }) => (
    <Box sx={{ p: 2 }}>
      <Typography variant="h6">{row.title}</Typography>
      <Typography>{row.description}</Typography>
    </Box>
  )}
  getDetailPanelHeight={() => 200}
/>
```

## Complete Table Component Example

```typescript
import { DataGridPro, GridColDef, GridActionsCellItem } from '@mui/x-data-grid-pro';
import { Link, Box, Button } from '@mui/material';
import { Edit, Delete } from '@mui/icons-material';
import { Car } from '~/generated/graphql';
import { formatPrice } from '~/utils/format';
import { dateColumn } from '~/utils/dataGrid';

const getColumns = (
  onEdit: (id: string) => void,
  onDelete: (id: string) => void,
): GridColDef[] => [
  {
    field: 'title',
    headerName: 'Title',
    minWidth: 200,
    flex: 1,
    renderCell: (params) => (
      <Link href={`/cars/${params.row.id}`} color="primary" underline="hover">
        {params.value}
      </Link>
    ),
  },
  {
    field: 'price',
    headerName: 'Price',
    minWidth: 120,
    valueFormatter: (value) => formatPrice(value),
  },
  {
    field: 'registrationDate',
    headerName: 'Registration',
    minWidth: 130,
    ...dateColumn,
  },
  {
    field: 'actions',
    type: 'actions',
    headerName: '',
    width: 80,
    getActions: (params) => [
      <GridActionsCellItem
        icon={<Edit />}
        label="Edit"
        onClick={() => onEdit(params.id as string)}
      />,
      <GridActionsCellItem
        icon={<Delete />}
        label="Delete"
        onClick={() => onDelete(params.id as string)}
        color="error"
      />,
    ],
  },
];

interface CarTableProps {
  cars: Car[];
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

export default function CarTable({ cars, onEdit, onDelete }: CarTableProps) {
  const columns = getColumns(onEdit, onDelete);

  return (
    <DataGridPro
      rows={cars}
      columns={columns}
      fullHeight
      initialState={{
        sorting: {
          sortModel: [{ field: 'registrationDate', sort: 'desc' }],
        },
        pinnedColumns: {
          right: ['actions'],
        },
      }}
      pageSizeOptions={[25, 50, 100]}
    />
  );
}
```
