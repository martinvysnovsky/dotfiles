# TypeScript Method Ordering Patterns

## Service Class Organization

```typescript
@Injectable()
export class CarService {
  constructor(
    @InjectRepository(Car) private carRepository: Repository<Car>,
    private carTypeService: CarTypeService,
    private loggerService: LoggerService,
  ) {}

  // ===========================================
  // BUSINESS LOGIC METHODS (Most Important)
  // ===========================================
  
  /**
   * Calculates depreciation based on car age and usage
   */
  calculateAmortization(car: Car): number {
    const ageInYears = this.calculateCarAge(car.registrationDate);
    const usageMultiplier = this.calculateUsageMultiplier(car.mileage);
    return car.originalPrice * 0.15 * ageInYears * usageMultiplier;
  }

  /**
   * Validates car history events are in correct chronological order
   */
  validateCarHistory(events: HistoryEvent[]): boolean {
    const sortedEvents = events.sort((a, b) => 
      a.eventDate.getTime() - b.eventDate.getTime()
    );
    
    for (let i = 0; i < sortedEvents.length - 1; i++) {
      if (!this.isValidEventSequence(sortedEvents[i], sortedEvents[i + 1])) {
        return false;
      }
    }
    return true;
  }

  /**
   * Processes end of rental period, updates car status and creates invoice
   */
  async processRentalEnd(carId: string, endDate: Date): Promise<void> {
    const car = await this.findOne(carId);
    if (!car) throw new NotFoundException('Car not found');

    // Update car status
    car.status = CarStatus.AVAILABLE;
    car.lastRentalEndDate = endDate;
    
    // Create final invoice
    await this.createFinalInvoice(car, endDate);
    
    // Save changes
    await this.carRepository.save(car);
    
    this.loggerService.notifyInfo('Rental period ended successfully', {
      context: { carId, endDate: endDate.toISOString() }
    });
  }

  // ===========================================
  // CRUD METHODS (Standard Operations)
  // ===========================================

  /**
   * Retrieves all cars with optional filtering
   */
  async findAll(filters?: CarFilters): Promise<Car[]> {
    const queryBuilder = this.carRepository.createQueryBuilder('car');
    
    if (filters?.manufacturer) {
      queryBuilder.andWhere('car.manufacturer = :manufacturer', {
        manufacturer: filters.manufacturer
      });
    }
    
    if (filters?.yearFrom) {
      queryBuilder.andWhere('car.year >= :yearFrom', {
        yearFrom: filters.yearFrom
      });
    }
    
    return queryBuilder.getMany();
  }

  /**
   * Retrieves a single car by ID
   */
  async findOne(id: string): Promise<Car | null> {
    return this.carRepository.findOne({
      where: { id },
      relations: ['carType', 'historyEvents']
    });
  }

  /**
   * Creates a new car record
   */
  async create(data: CreateCarInput): Promise<Car> {
    // Validate car type exists
    const carType = await this.carTypeService.findOne(data.carTypeId);
    if (!carType) {
      throw new BadRequestException('Car type not found');
    }

    // Create car entity
    const car = this.carRepository.create({
      ...data,
      carType,
      status: CarStatus.AVAILABLE,
      createdAt: new Date(),
    });

    return this.carRepository.save(car);
  }

  /**
   * Updates an existing car record
   */
  async update(id: string, data: UpdateCarInput): Promise<Car> {
    const car = await this.findOne(id);
    if (!car) throw new NotFoundException('Car not found');

    // Validate car type if provided
    if (data.carTypeId) {
      const carType = await this.carTypeService.findOne(data.carTypeId);
      if (!carType) {
        throw new BadRequestException('Car type not found');
      }
      car.carType = carType;
    }

    // Update fields
    Object.assign(car, data);
    car.updatedAt = new Date();

    return this.carRepository.save(car);
  }

  /**
   * Soft deletes a car record
   */
  async delete(id: string): Promise<void> {
    const car = await this.findOne(id);
    if (!car) throw new NotFoundException('Car not found');

    car.deletedAt = new Date();
    await this.carRepository.save(car);
  }

  // ===========================================
  // PRIVATE HELPER METHODS
  // ===========================================

  private calculateCarAge(registrationDate: Date): number {
    const now = new Date();
    const ageInMs = now.getTime() - registrationDate.getTime();
    return ageInMs / (1000 * 60 * 60 * 24 * 365.25); // Convert to years
  }

  private calculateUsageMultiplier(mileage: number): number {
    if (mileage < 50000) return 1.0;
    if (mileage < 100000) return 1.2;
    if (mileage < 200000) return 1.5;
    return 2.0;
  }

  private isValidEventSequence(current: HistoryEvent, next: HistoryEvent): boolean {
    const validSequences = {
      [HistoryEventType.REGISTRATION]: [
        HistoryEventType.START_OF_RENTING,
        HistoryEventType.SALE,
        HistoryEventType.UNREGISTRATION
      ],
      [HistoryEventType.START_OF_RENTING]: [
        HistoryEventType.END_OF_RENTING
      ],
      [HistoryEventType.END_OF_RENTING]: [
        HistoryEventType.START_OF_RENTING,
        HistoryEventType.SALE,
        HistoryEventType.UNREGISTRATION,
        HistoryEventType.TERMINATE_INSURANCE
      ]
    };

    return validSequences[current.type]?.includes(next.type) ?? true;
  }

  private async createFinalInvoice(car: Car, endDate: Date): Promise<void> {
    // Implementation for creating final rental invoice
    // This would typically involve calculating final costs, damages, etc.
  }
}
```

## GraphQL Resolver Organization

```typescript
@Resolver(() => Car)
export class CarResolver {
  constructor(
    private carService: CarService,
    private carTypeService: CarTypeService,
  ) {}

  // ===========================================
  // FIELD RESOLVERS (Most Important)
  // ===========================================

  @ResolveField(() => CarType)
  async carType(@Parent() car: Car): Promise<CarType> {
    return this.carTypeService.findOne(car.carTypeId);
  }

  @ResolveField(() => Number)
  async realAmortization(@Parent() car: Car): Promise<number> {
    return this.carService.calculateAmortization(car);
  }

  @ResolveField(() => [HistoryEvent])
  async historyEvents(@Parent() car: Car): Promise<HistoryEvent[]> {
    return this.carService.findHistoryEvents(car.id);
  }

  @ResolveField(() => Boolean)
  async hasValidHistory(@Parent() car: Car): Promise<boolean> {
    const events = await this.carService.findHistoryEvents(car.id);
    return this.carService.validateCarHistory(events);
  }

  // ===========================================
  // QUERIES
  // ===========================================

  @Query(() => [Car])
  async cars(
    @Args('filters', { nullable: true }) filters?: CarFilters
  ): Promise<Car[]> {
    return this.carService.findAll(filters);
  }

  @Query(() => Car, { nullable: true })
  async car(@Args('id') id: string): Promise<Car | null> {
    return this.carService.findOne(id);
  }

  @Query(() => [Car])
  async availableCars(): Promise<Car[]> {
    return this.carService.findAll({ status: CarStatus.AVAILABLE });
  }

  // ===========================================
  // MUTATIONS
  // ===========================================

  @Mutation(() => Car)
  async createCar(@Args('input') input: CreateCarInput): Promise<Car> {
    return this.carService.create(input);
  }

  @Mutation(() => Car)
  async updateCar(
    @Args('id') id: string,
    @Args('input') input: UpdateCarInput
  ): Promise<Car> {
    return this.carService.update(id, input);
  }

  @Mutation(() => Boolean)
  async deleteCar(@Args('id') id: string): Promise<boolean> {
    await this.carService.delete(id);
    return true;
  }

  @Mutation(() => Boolean)
  async processRentalEnd(
    @Args('carId') carId: string,
    @Args('endDate') endDate: Date
  ): Promise<boolean> {
    await this.carService.processRentalEnd(carId, endDate);
    return true;
  }
}
```

## REST Controller Organization

```typescript
@Controller('cars')
export class CarController {
  constructor(private carService: CarService) {}

  // ===========================================
  // GET METHODS
  // ===========================================

  @Get()
  async findAll(@Query() filters: CarFilters): Promise<Car[]> {
    return this.carService.findAll(filters);
  }

  @Get('available')
  async findAvailable(): Promise<Car[]> {
    return this.carService.findAll({ status: CarStatus.AVAILABLE });
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Car> {
    const car = await this.carService.findOne(id);
    if (!car) throw new NotFoundException('Car not found');
    return car;
  }

  @Get(':id/amortization')
  async getAmortization(@Param('id') id: string): Promise<{ amortization: number }> {
    const car = await this.carService.findOne(id);
    if (!car) throw new NotFoundException('Car not found');
    
    const amortization = this.carService.calculateAmortization(car);
    return { amortization };
  }

  // ===========================================
  // POST METHODS
  // ===========================================

  @Post()
  async create(@Body() data: CreateCarInput): Promise<Car> {
    return this.carService.create(data);
  }

  @Post(':id/end-rental')
  async endRental(
    @Param('id') id: string,
    @Body() data: { endDate: Date }
  ): Promise<{ success: boolean }> {
    await this.carService.processRentalEnd(id, data.endDate);
    return { success: true };
  }

  // ===========================================
  // PUT/PATCH METHODS
  // ===========================================

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() data: UpdateCarInput
  ): Promise<Car> {
    return this.carService.update(id, data);
  }

  @Patch(':id/status')
  async updateStatus(
    @Param('id') id: string,
    @Body() data: { status: CarStatus }
  ): Promise<Car> {
    return this.carService.update(id, { status: data.status });
  }

  // ===========================================
  // DELETE METHODS
  // ===========================================

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<{ success: boolean }> {
    await this.carService.delete(id);
    return { success: true };
  }
}
```

## Test File Organization

```typescript
describe('CarService', () => {
  let service: CarService;
  let repository: Repository<Car>;

  beforeEach(async () => {
    // Setup test module
  });

  // ===========================================
  // BUSINESS LOGIC METHOD TESTS (First)
  // ===========================================

  describe('calculateAmortization', () => {
    it('calculates amortization for new car', () => {
      const car = fromPartial<Car>({
        registrationDate: new Date('2023-01-01'),
        originalPrice: 50000,
        mileage: 15000
      });

      const result = service.calculateAmortization(car);

      expect(result).toBeCloseTo(7500, 0); // 50k * 0.15 * 1yr * 1.0
    });

    it('applies higher multiplier for high mileage', () => {
      const car = fromPartial<Car>({
        registrationDate: new Date('2020-01-01'),
        originalPrice: 50000,
        mileage: 150000
      });

      const result = service.calculateAmortization(car);

      expect(result).toBeCloseTo(33750, 0); // 50k * 0.15 * 3yr * 1.5
    });
  });

  describe('validateCarHistory', () => {
    it('validates correct history order', () => {
      const events = [
        { type: HistoryEventType.REGISTRATION, eventDate: new Date('2023-01-01') },
        { type: HistoryEventType.START_OF_RENTING, eventDate: new Date('2023-02-01') },
        { type: HistoryEventType.END_OF_RENTING, eventDate: new Date('2023-12-01') }
      ];

      const result = service.validateCarHistory(events);

      expect(result).toBe(true);
    });

    it('rejects invalid history order', () => {
      const events = [
        { type: HistoryEventType.START_OF_RENTING, eventDate: new Date('2023-01-01') },
        { type: HistoryEventType.REGISTRATION, eventDate: new Date('2023-02-01') }
      ];

      const result = service.validateCarHistory(events);

      expect(result).toBe(false);
    });
  });

  // ===========================================
  // CRUD METHOD TESTS (Last)
  // ===========================================

  describe('findAll', () => {
    it('returns all cars when no filters provided', async () => {
      const cars = [{ id: '1', title: 'BMW X5' }];
      repository.find = vi.fn().mockResolvedValue(cars);

      const result = await service.findAll();

      expect(result).toEqual(cars);
    });
  });

  describe('create', () => {
    it('creates new car with valid data', async () => {
      const input = { title: 'BMW X5', price: 50000, carTypeId: '1' };
      const car = { id: '1', ...input };
      
      repository.create = vi.fn().mockReturnValue(car);
      repository.save = vi.fn().mockResolvedValue(car);

      const result = await service.create(input);

      expect(result).toEqual(car);
    });
  });
});
```