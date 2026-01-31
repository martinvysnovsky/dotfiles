# Query Patterns

## Basic Queries

### Find One

```typescript
// By specific field
findOneByNumber(number: string): Promise<CarDocument | null> {
  return this.carModel
    .findOne({ numbers: number })
    .exec();
}

// By nested field
findOneByHistoryEventId(id: string): Promise<CarDocument | null> {
  return this.carModel
    .findOne({ 'history._id': id })
    .exec();
}

// By ID
findById(id: string): Promise<CarDocument | null> {
  return this.carModel.findById(id).exec();
}
```

### Find All

```typescript
// Simple find all with sorting
findAll(): Promise<CarTypeDocument[]> {
  return this.carTypeModel.find().sort('name').exec();
}

// Find by IDs
findByIds(ids: readonly string[]): Promise<CarDocument[]> {
  return this.carModel.find({ _id: { $in: ids } }).exec();
}

// Find by array value
findByNumbers(keys: readonly string[]): Promise<CarDocument[]> {
  return this.carModel.find({ numbers: { $in: keys } }).exec();
}

// Find by reference
findByCarType(carTypeId: Types.ObjectId | string): Promise<CarDocument[]> {
  return this.carModel.find({ type: carTypeId }).exec();
}
```

## FilterQuery Pattern

Type-safe query building with `FilterQuery<T>`:

```typescript
import { FilterQuery } from 'mongoose';

async findAll(filter?: {
  statuses?: CarState[];
  rentalTypes?: RentalType[];
}): Promise<CarDocument[]> {
  const { statuses, rentalTypes } = filter || {};

  const query: FilterQuery<Car> = {};

  // Filter by status if specified
  if (statuses && statuses.length > 0) {
    query.status = { $in: statuses };
  }

  // Complex OR conditions
  if (rentalTypes && rentalTypes.length > 0) {
    const rentalConditions: FilterQuery<Car>[] = [];

    if (rentalTypes.includes(RentalType.SHORT_TERM)) {
      rentalConditions.push({
        shortTermRentalYears: { $exists: true, $ne: [] },
      });
    }

    if (rentalTypes.includes(RentalType.LONG_TERM)) {
      rentalConditions.push({
        longTermRentalYears: { $exists: true, $ne: [] },
      });
    }

    // Apply OR logic
    if (rentalConditions.length === 1) {
      Object.assign(query, rentalConditions[0]);
    } else if (rentalConditions.length > 1) {
      query.$or = rentalConditions;
    }
  }

  return this.carModel.find(query).exec();
}
```

## Query Operators

### Comparison Operators

```typescript
// Equal (implicit)
{ status: CarState.ACTIVE }

// In array
{ status: { $in: [CarState.ACTIVE, CarState.SOLD] } }

// Not equal
{ shortTermRentalYears: { $ne: [] } }

// Greater than / Less than
{ createdAt: { $gte: startDate, $lte: endDate } }

// Exists
{ externalId: { $exists: true } }
```

### Logical Operators

```typescript
// AND (implicit - multiple conditions)
{
  status: CarState.ACTIVE,
  type: carTypeId,
}

// Explicit AND
{
  $and: [
    { status: CarState.ACTIVE },
    { createdAt: { $gte: startDate } },
  ]
}

// OR
{
  $or: [
    { status: CarState.ACTIVE },
    { status: CarState.RESERVED },
  ]
}
```

### Array/Embedded Document Operators

```typescript
// Element match for embedded documents
{
  history: {
    $elemMatch: {
      name: HistoryEventType.START_OF_RENTING,
      date: { $lte: endDate },
    },
  },
}

// NOT element match
{
  history: {
    $not: {
      $elemMatch: {
        name: HistoryEventType.SALE,
      },
    },
  },
}
```

## Complex Query Example

Find cars active in a specific month:

```typescript
findByActiveInMonth(year: number, month: number) {
  const [startOfMonth, endOfMonth] = this.monthsService.getMonthBoundaries(year, month);

  return this.carModel.find({
    $or: [
      // Started renting before/in current month and never sold
      {
        history: {
          $elemMatch: {
            name: HistoryEventType.START_OF_RENTING,
            date: { $lte: endOfMonth },
          },
          $not: {
            $elemMatch: {
              name: HistoryEventType.SALE,
            },
          },
        },
      },
      // Started renting before/in current month and sold in/after current month
      {
        $and: [
          {
            history: {
              $elemMatch: {
                name: HistoryEventType.START_OF_RENTING,
                date: { $lte: endOfMonth },
              },
            },
          },
          {
            history: {
              $elemMatch: {
                name: HistoryEventType.SALE,
                date: { $gte: startOfMonth },
              },
            },
          },
        ],
      },
    ],
  });
}
```

## Aggregation Pipeline

For complex data transformations:

```typescript
findDuplicates() {
  return this.carModel.aggregate([
    // Unwind array to separate documents
    {
      $unwind: '$numbers',
    },
    // Group by number and count
    {
      $group: {
        _id: '$numbers',
        count: { $sum: 1 },
      },
    },
    // Filter for duplicates
    {
      $match: {
        count: { $gt: 1 },
      },
    },
    // Project final shape
    {
      $project: {
        id: '$_id',
        number: '$_id',
      },
    },
  ]);
}
```

### Common Aggregation Stages

```typescript
// $match - Filter documents
{ $match: { status: CarState.ACTIVE } }

// $group - Group by field
{
  $group: {
    _id: '$type',
    count: { $sum: 1 },
    totalValue: { $sum: '$purchasePrice' },
  }
}

// $sort - Order results
{ $sort: { count: -1 } }

// $limit - Limit results
{ $limit: 10 }

// $lookup - Join with another collection
{
  $lookup: {
    from: 'cartypes',
    localField: 'type',
    foreignField: '_id',
    as: 'carType',
  }
}

// $unwind - Flatten array
{ $unwind: '$history' }

// $project - Shape output
{
  $project: {
    _id: 0,
    id: '$_id',
    name: 1,
    total: { $add: ['$price1', '$price2'] },
  }
}
```

## Query Chaining

```typescript
// Sort
this.carModel.find().sort('name').exec();
this.carModel.find().sort({ createdAt: -1 }).exec(); // Descending

// Limit and skip (pagination)
this.carModel.find().skip(offset).limit(pageSize).exec();

// Select specific fields
this.carModel.find().select('name status').exec();
this.carModel.find().select('-password -secret').exec(); // Exclude

// Lean (returns plain objects, faster but no document methods)
this.carModel.find().lean().exec();
```

## Population (References)

```typescript
// Single population
this.carModel
  .find()
  .populate('type')
  .exec();

// Multiple populations
this.carModel
  .find()
  .populate('type')
  .populate('owner')
  .exec();

// Selective population
this.carModel
  .find()
  .populate('type', 'name amortization')
  .exec();

// Nested population
this.carModel
  .find()
  .populate({
    path: 'contracts',
    populate: { path: 'customer' },
  })
  .exec();
```

## Always Use .exec()

End queries with `.exec()` for proper Promise handling:

```typescript
// Good - returns proper Promise
return this.carModel.find().exec();

// Avoid - returns Query object (works but less explicit)
return this.carModel.find();
```
