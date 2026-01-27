# Background Jobs and Scheduled Tasks

## Cron Job Patterns

### Basic Cron Job

```typescript
import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

@Injectable()
export class CarMaintenanceJob {
  constructor(
    private readonly carService: CarService,
    private readonly notificationService: NotificationService,
    private readonly loggerService: LoggerService,
  ) {}

  @Cron('0 0 * * *') // Daily at midnight
  async dailyMaintenanceCheck(): Promise<void> {
    try {
      const carsNeedingMaintenance = await this.findCarsNeedingMaintenance();
      
      for (const car of carsNeedingMaintenance) {
        await this.scheduleMaintenanceReminder(car);
      }

      this.loggerService.notifyInfo('Daily maintenance check completed', {
        context: { 
          carsChecked: carsNeedingMaintenance.length,
          operation: 'dailyMaintenanceCheck'
        }
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'dailyMaintenanceCheck' }
      });
      throw error;
    }
  }

  private async findCarsNeedingMaintenance(): Promise<Car[]> {
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    return this.carService.findAll({
      lastMaintenanceDate: { $lt: threeMonthsAgo },
      status: CarStatus.AVAILABLE
    });
  }

  private async scheduleMaintenanceReminder(car: Car): Promise<void> {
    await this.notificationService.send({
      type: 'maintenance_reminder',
      carId: car.id,
      message: `Car ${car.title} needs maintenance check`
    });
  }
}
```

## Cron Expression Patterns

```typescript
@Cron('0 0 * * *')        // Every day at midnight
@Cron('0 */2 * * *')      // Every 2 hours
@Cron('0 0 * * 0')        // Every Sunday at midnight
@Cron('0 0 1 * *')        // First day of month at midnight
@Cron('*/30 * * * *')     // Every 30 minutes
@Cron('0 9 * * 1-5')      // Weekdays at 9 AM
```

## Interval-Based Jobs

```typescript
import { Injectable } from '@nestjs/common';
import { Interval } from '@nestjs/schedule';

@Injectable()
export class DataSyncJob {
  constructor(
    private readonly carService: CarService,
    private readonly externalApiService: ExternalApiService,
    private readonly loggerService: LoggerService,
  ) {}

  @Interval(60000) // Every minute (60000ms)
  async syncCarData(): Promise<void> {
    try {
      const cars = await this.carService.findAll({ 
        needsSync: true 
      });

      for (const car of cars) {
        await this.externalApiService.syncCar(car.id);
      }

      this.loggerService.notifyInfo('Car data sync completed', {
        context: { syncedCount: cars.length }
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'syncCarData' }
      });
    }
  }
}
```

## Timeout-Based Jobs

```typescript
import { Injectable } from '@nestjs/common';
import { Timeout } from '@nestjs/schedule';

@Injectable()
export class StartupJob {
  constructor(
    private readonly carService: CarService,
    private readonly loggerService: LoggerService,
  ) {}

  @Timeout(5000) // Run once after 5 seconds
  async initializeCache(): Promise<void> {
    try {
      await this.carService.warmupCache();
      this.loggerService.notifyInfo('Cache initialized successfully');
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'initializeCache' }
      });
    }
  }
}
```

## Error Handling in Background Jobs

### Required: Manual Error Notifications

Background jobs REQUIRE manual error notifications using `loggerService.notifyError()`:

```typescript
@Cron('0 0 * * *')
async dailyReport(): Promise<void> {
  try {
    const report = await this.generateReport();
    await this.emailService.send(report);
    
    // Success notification for critical operations
    this.loggerService.notifyInfo('Daily report sent successfully', {
      context: { 
        operation: 'dailyReport',
        reportDate: new Date().toISOString()
      }
    });
  } catch (error) {
    // REQUIRED: Manual error notification
    this.loggerService.notifyError(error as Error, {
      context: { operation: 'dailyReport' }
    });
    throw error;
  }
}
```

### Retry Logic

```typescript
@Injectable()
export class RetryableJob {
  private readonly MAX_RETRIES = 3;

  constructor(
    private readonly carService: CarService,
    private readonly loggerService: LoggerService,
  ) {}

  @Cron('0 */6 * * *') // Every 6 hours
  async syncWithRetry(): Promise<void> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= this.MAX_RETRIES; attempt++) {
      try {
        await this.performSync();
        
        if (attempt > 1) {
          this.loggerService.notifyInfo(`Sync succeeded after ${attempt} attempts`);
        }
        
        return; // Success, exit
      } catch (error) {
        lastError = error as Error;
        
        if (attempt < this.MAX_RETRIES) {
          const delay = Math.pow(2, attempt) * 1000; // Exponential backoff
          await this.sleep(delay);
        }
      }
    }

    // All retries failed
    this.loggerService.notifyError(lastError!, {
      context: { 
        operation: 'syncWithRetry',
        attempts: this.MAX_RETRIES
      }
    });
    throw lastError;
  }

  private async performSync(): Promise<void> {
    // Sync implementation
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Dynamic Job Scheduling

```typescript
import { Injectable } from '@nestjs/common';
import { SchedulerRegistry } from '@nestjs/schedule';
import { CronJob } from 'cron';

@Injectable()
export class DynamicSchedulerService {
  constructor(
    private readonly schedulerRegistry: SchedulerRegistry,
    private readonly carService: CarService,
    private readonly loggerService: LoggerService,
  ) {}

  addCronJob(name: string, cronExpression: string): void {
    const job = new CronJob(cronExpression, async () => {
      try {
        await this.carService.performTask();
        this.loggerService.notifyInfo(`Job ${name} executed successfully`);
      } catch (error) {
        this.loggerService.notifyError(error as Error, {
          context: { job: name }
        });
      }
    });

    this.schedulerRegistry.addCronJob(name, job);
    job.start();

    this.loggerService.notifyInfo(`Job ${name} added`, {
      context: { cronExpression }
    });
  }

  removeCronJob(name: string): void {
    this.schedulerRegistry.deleteCronJob(name);
    this.loggerService.notifyInfo(`Job ${name} removed`);
  }

  getCronJobs(): Map<string, CronJob> {
    return this.schedulerRegistry.getCronJobs();
  }
}
```

## Queue-Based Background Processing

### Bull Queue Pattern

```typescript
import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';

@Injectable()
export class CarProcessingService {
  constructor(
    @InjectQueue('car-processing') 
    private readonly carQueue: Queue,
  ) {}

  async queueCarProcessing(carId: string): Promise<void> {
    await this.carQueue.add('process-car', {
      carId,
      timestamp: new Date().toISOString()
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000
      }
    });
  }

  async queueBulkProcessing(carIds: string[]): Promise<void> {
    const jobs = carIds.map(carId => ({
      name: 'process-car',
      data: { carId }
    }));

    await this.carQueue.addBulk(jobs);
  }
}
```

### Queue Processor

```typescript
import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';

@Processor('car-processing')
export class CarProcessor {
  constructor(
    private readonly carService: CarService,
    private readonly loggerService: LoggerService,
  ) {}

  @Process('process-car')
  async handleCarProcessing(job: Job): Promise<void> {
    const { carId } = job.data;

    try {
      await this.carService.processComputation(carId);
      
      this.loggerService.notifyInfo('Car processing completed', {
        context: { carId, jobId: job.id }
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { carId, jobId: job.id }
      });
      throw error; // Bull will retry based on job options
    }
  }

  @Process({ name: 'process-car', concurrency: 5 })
  async handleConcurrentProcessing(job: Job): Promise<void> {
    // Process up to 5 jobs concurrently
  }
}
```

## Job Progress Tracking

```typescript
@Process('long-running-task')
async handleLongTask(job: Job): Promise<void> {
  const steps = 100;
  
  for (let i = 0; i < steps; i++) {
    // Perform work
    await this.performStep(i);
    
    // Update progress
    await job.progress((i + 1) / steps * 100);
    
    // Log progress periodically
    if (i % 10 === 0) {
      this.loggerService.notifyInfo('Task progress', {
        context: { 
          jobId: job.id,
          progress: `${i + 1}/${steps}`
        }
      });
    }
  }
}
```

## Best Practices

### Method Organization in Job Classes

```typescript
@Injectable()
export class CarMaintenanceJob {
  constructor(
    private readonly carService: CarService,
    private readonly loggerService: LoggerService,
  ) {}

  // Private helper methods first
  private async findCarsNeedingMaintenance(): Promise<Car[]> {
    // Implementation
  }

  private async scheduleReminder(car: Car): Promise<void> {
    // Implementation
  }

  // Public job methods last
  @Cron('0 0 * * *')
  async dailyMaintenanceCheck(): Promise<void> {
    // Implementation using helper methods
  }
}
```

### Always Include Context in Logs

```typescript
this.loggerService.notifyError(error as Error, {
  context: { 
    operation: 'dailyMaintenanceCheck',
    carsProcessed: count,
    timestamp: new Date().toISOString()
  }
});
```

### Success Notifications for Critical Operations

```typescript
// For critical operations, notify on success too
this.loggerService.notifyInfo('Critical job completed', {
  context: { 
    operation: 'dailyBackup',
    recordsProcessed: count
  }
});
```
