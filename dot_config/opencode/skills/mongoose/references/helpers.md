# Database Helpers

## Custom Setters

Setters transform input values before storing in the database.

### Parse Number

Handles string inputs with European number formatting:

```typescript
// database.helper.ts
export const parseNumber = (
  value: number | string | null | undefined,
): number => {
  const numberValue: number =
    typeof value === 'string'
      ? parseFloat(value.replace(',', '.').replace(/\s/g, '')) || 0
      : value || 0;

  return numberValue || numberValue === 0 ? numberValue : 0;
};
```

Usage in entity:

```typescript
import { parseNumber } from 'src/database/database.helper';

@Prop({ type: Number, set: parseNumber })
enginePower?: number;

@Prop({ type: Number, set: parseNumber, default: 0 })
engineVolume: number;
```

### Parse Date

Handles string date inputs with locale-specific formatting:

```typescript
// database.helper.ts
import { parse } from 'date-fns';
import { sk } from 'date-fns/locale/sk';

export const parseDate = (
  value: string | Date | null,
  format: string = 'd.M.yyyy',
): Date | null => {
  return value === null || value instanceof Date
    ? value
    : parse(value, format, new Date(), { locale: sk });
};

export const parseDateTime = (
  value: string | Date | null,
  format: string = 'd.M.yyyy H:mm',
): Date | null => {
  return value === null || value instanceof Date
    ? value
    : parse(value, format, new Date(), { locale: sk });
};
```

Usage in entity:

```typescript
import { parseDateTime } from 'src/database/database.helper';

@Prop({
  set: (value: string) => parseDateTime(value, 'M/YYYY'),
  required: true,
})
date: Date;
```

## Custom Getters

Getters transform values when reading from the database.

### Default Value Getter

```typescript
@Prop({
  type: Number,
  get: (value: number | null) => value || 0,
})
pricelistPrice: number;

@Prop({
  type: Number,
  get: (value: number | null) => value || 0,
})
purchasePrice: number;
```

### Combined Setter and Getter

```typescript
@Prop({
  set: parseNumber,
  get: (value: number | null) => value || 0,
})
amortization?: number;
```

## Virtuals

Virtuals are computed properties that don't persist to the database.

### Simple Virtual Getter

```typescript
// After schema creation
CarSchema.virtual('fullName').get(function (this: Car) {
  return `${this.manufacturer} ${this.model}`;
});
```

### Virtual with Getter and Setter

```typescript
const addNumber = (self: Car, number: string) => {
  if (!number) return;
  if (!self.numbers) self.numbers = [];
  if (!self.numbers.includes(number)) {
    self.numbers.push(number);
  }
};

CarSchema.virtual('number')
  .set(function (this: Car, number: string) {
    addNumber(this, number);
  })
  .get(function (this: Car) {
    return this.numbers[0];
  });

// Additional virtuals for multiple numbers
CarSchema.virtual('number2').set(function (this: Car, number: string) {
  addNumber(this, number);
});

CarSchema.virtual('number3').set(function (this: Car, number: string) {
  addNumber(this, number);
});
```

### ID Virtual (Mongoose 9+)

Required because Mongoose 9 no longer provides `id` by default:

```typescript
import { Types } from 'mongoose';

CarSchema.virtual('id').get(function (this: Car & { _id: Types.ObjectId }) {
  return this._id.toHexString();
});
```

### Enable Virtuals in Output

Must be enabled in schema options:

```typescript
@Schema({
  timestamps: true,
  versionKey: false,
  toJSON: { virtuals: true },   // Include in JSON output
  toObject: { virtuals: true }, // Include in object conversion
})
export class Car {
  // ...
}
```

## Validation

### Simple Validation

```typescript
@Prop({
  validate: {
    validator: (value: number) => value >= 0,
    message: 'Price must be non-negative',
  },
})
price?: number;
```

### Validation with Custom Message

```typescript
@Prop({
  set: parseNumber,
  get: (value: number | null) => value || 0,
  validate: {
    validator: (value: number) => value >= 0,
    message: 'Tire price must be non-negative',
  },
})
tirePrice?: number;
```

### Async Validation

```typescript
@Prop({
  validate: {
    validator: async function(value: string) {
      const count = await this.model('Car').countDocuments({ vin: value });
      return count === 0;
    },
    message: 'VIN already exists',
  },
})
vin: string;
```

### Multiple Validators

```typescript
@Prop({
  validate: [
    {
      validator: (value: number) => value >= 0,
      message: 'Must be non-negative',
    },
    {
      validator: (value: number) => value <= 100,
      message: 'Must be at most 100',
    },
  ],
})
percentage?: number;
```

## Complete Helper File Example

```typescript
// src/database/database.helper.ts
import { parse } from 'date-fns';
import { sk } from 'date-fns/locale/sk';

export const parseNumber = (
  value: number | string | null | undefined,
): number => {
  const numberValue: number =
    typeof value === 'string'
      ? parseFloat(value.replace(',', '.').replace(/\s/g, '')) || 0
      : value || 0;

  return numberValue || numberValue === 0 ? numberValue : 0;
};

export const parseDateTime = (
  value: string | Date | null,
  format: string = 'd.M.yyyy H:mm',
): Date | null => {
  return value === null || value instanceof Date
    ? value
    : parse(value, format, new Date(), { locale: sk });
};

export const parseDate = (
  value: string | Date | null,
  format: string = 'd.M.yyyy',
): Date | null => {
  return value === null || value instanceof Date
    ? value
    : parse(value, format, new Date(), { locale: sk });
};
```

## Best Practices

1. **Keep helpers in dedicated file** (`src/database/database.helper.ts`)
2. **Handle null/undefined** in setters to prevent runtime errors
3. **Use getters for default values** instead of complex entity logic
4. **Always enable virtuals** in schema options if using them
5. **Add ID virtual** for Mongoose 9+ compatibility
6. **Test helpers** with edge cases (empty strings, null, special characters)
