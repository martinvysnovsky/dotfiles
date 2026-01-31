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
    const startTime = Date.now();
    let processedCount = 0;
    let errorCount = 0;

    try {
      const carsNeedingMaintenance = await this.findCarsNeedingMaintenance();
      
      for (const car of carsNeedingMaintenance) {
        try {
          await this.scheduleMaintenanceReminder(car);
          processedCount++;
        } catch (error) {
          errorCount++;
          this.loggerService.error(`Failed to schedule maintenance for car ${car.id}`, error);
        }
      }

      this.loggerService.notifyInfo('Daily maintenance check completed', {
        context: { processedCount, errorCount, duration: Date.now() - startTime }
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'dailyMaintenanceCheck', processedCount, errorCount }
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

## Interval and Timeout Jobs

```typescript
import { Injectable } from '@nestjs/common';
import { Interval, Timeout } from '@nestjs/schedule';

@Injectable()
export class DataSyncJob {
  @Interval(60000) // Every minute (60000ms)
  async syncCarData(): Promise<void> {
    try {
      const cars = await this.carService.findAll({ needsSync: true });
      for (const car of cars) {
        await this.externalApiService.syncCar(car.id);
      }
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'syncCarData' }
      });
    }
  }

  @Timeout(5000) // Run once after 5 seconds
  async initializeCache(): Promise<void> {
    await this.carService.warmupCache();
  }
}
```

## Retry Logic with Exponential Backoff

```typescript
@Injectable()
export class RetryableJob {
  private readonly MAX_RETRIES = 3;
  private readonly BASE_DELAY = 1000;

  @Cron('0 */6 * * *')
  async syncWithRetry(): Promise<void> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= this.MAX_RETRIES; attempt++) {
      try {
        await this.performSync();
        return;
      } catch (error) {
        lastError = error as Error;
        
        if (attempt < this.MAX_RETRIES) {
          const delay = this.BASE_DELAY * Math.pow(2, attempt - 1);
          await this.sleep(delay);
        }
      }
    }

    this.loggerService.notifyError(lastError!, {
      context: { operation: 'syncWithRetry', attempts: this.MAX_RETRIES }
    });
    throw lastError;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Circuit Breaker Pattern

Prevents cascading failures when external services are unavailable.

```typescript
enum CircuitState {
  CLOSED = 'closed',
  OPEN = 'open',
  HALF_OPEN = 'half_open',
}

class CircuitBreaker {
  private state = CircuitState.CLOSED;
  private failureCount = 0;
  private lastFailureTime: number | null = null;
  private successCount = 0;

  constructor(
    private readonly failureThreshold: number = 5,
    private readonly recoveryTimeout: number = 60000,
    private readonly successThreshold: number = 3,
  ) {}

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (this.shouldAttemptReset()) {
        this.state = CircuitState.HALF_OPEN;
        this.successCount = 0;
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;
    if (this.state === CircuitState.HALF_OPEN) {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        this.state = CircuitState.CLOSED;
      }
    }
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();
    if (this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.OPEN;
    }
  }

  private shouldAttemptReset(): boolean {
    return this.lastFailureTime !== null && 
           (Date.now() - this.lastFailureTime) >= this.recoveryTimeout;
  }
}

// Usage
@Injectable()
export class ExternalApiSyncJob {
  private readonly circuitBreaker = new CircuitBreaker(5, 60000, 3);

  @Cron('0 */2 * * *')
  async syncWithExternalApi(): Promise<void> {
    try {
      await this.circuitBreaker.execute(async () => {
        const data = await this.externalApiService.fetchCarUpdates();
        await this.processUpdates(data);
      });
    } catch (error) {
      if (error.message === 'Circuit breaker is OPEN') {
        this.loggerService.warn('External API sync skipped - circuit breaker is open');
      } else {
        this.loggerService.notifyError(error as Error, {
          context: { operation: 'syncWithExternalApi' }
        });
      }
    }
  }
}
```

## Graceful Degradation

Continue with partial data when non-critical components fail.

```typescript
@Injectable()
export class CarReportingJob {
  @Cron('0 6 * * 1') // Every Monday at 6 AM
  async generateWeeklyReport(): Promise<void> {
    const reportData: Partial<WeeklyReport> = {};
    const errors: string[] = [];

    // Critical data - abort if this fails
    try {
      reportData.carCount = await this.carService.getTotalCount();
      reportData.availableCount = await this.carService.getAvailableCount();
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'generateWeeklyReport', section: 'critical_data' }
      });
      throw error;
    }

    // Non-critical data - continue even if these fail
    try {
      reportData.maintenanceAlerts = await this.carService.getMaintenanceAlerts();
    } catch (error) {
      errors.push('Failed to fetch maintenance alerts');
      reportData.maintenanceAlerts = []; // Fallback
    }

    try {
      reportData.revenueData = await this.carService.getRevenueData();
    } catch (error) {
      errors.push('Failed to fetch revenue data');
      reportData.revenueData = null;
    }

    // Generate report with available data
    const report = await this.reportService.generateWeeklyReport(reportData as WeeklyReport);
    
    if (errors.length > 0) {
      report.notes = `Note: Some data incomplete: ${errors.join(', ')}`;
    }

    await this.emailService.sendWeeklyReport(report);
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
    await this.carQueue.add('process-car', { carId }, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 }
    });
  }
}
```

### Queue Processor

```typescript
import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';

@Processor('car-processing')
export class CarProcessor {
  @Process('process-car')
  async handleCarProcessing(job: Job): Promise<void> {
    const { carId } = job.data;

    try {
      await this.carService.processComputation(carId);
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

## Dynamic Job Scheduling

```typescript
import { Injectable } from '@nestjs/common';
import { SchedulerRegistry } from '@nestjs/schedule';
import { CronJob } from 'cron';

@Injectable()
export class DynamicSchedulerService {
  constructor(private readonly schedulerRegistry: SchedulerRegistry) {}

  addCronJob(name: string, cronExpression: string, callback: () => Promise<void>): void {
    const job = new CronJob(cronExpression, callback);
    this.schedulerRegistry.addCronJob(name, job);
    job.start();
  }

  removeCronJob(name: string): void {
    this.schedulerRegistry.deleteCronJob(name);
  }

  getCronJobs(): Map<string, CronJob> {
    return this.schedulerRegistry.getCronJobs();
  }
}
```

## Job Health Monitoring

```typescript
interface JobStatus {
  name: string;
  status: 'running' | 'completed' | 'failed';
  lastRun: Date;
  error?: string;
}

@Injectable()
export class JobHealthService {
  private readonly jobStatuses = new Map<string, JobStatus>();

  updateJobStatus(jobName: string, status: JobStatus['status'], error?: Error): void {
    this.jobStatuses.set(jobName, {
      name: jobName,
      status,
      lastRun: new Date(),
      error: error?.message,
    });
  }

  @Cron('0 */5 * * *')
  async checkJobHealth(): Promise<void> {
    const unhealthyJobs: string[] = [];
    const now = Date.now();

    for (const [jobName, jobStatus] of this.jobStatuses.entries()) {
      const timeSinceLastRun = now - jobStatus.lastRun.getTime();
      const maxInterval = this.getMaxIntervalForJob(jobName);

      if (timeSinceLastRun > maxInterval && jobStatus.status !== 'running') {
        unhealthyJobs.push(jobName);
      }
    }

    if (unhealthyJobs.length > 0) {
      this.loggerService.notifyError(
        new Error('Jobs not running as expected'), 
        { context: { unhealthyJobs } }
      );
    }
  }

  private getMaxIntervalForJob(jobName: string): number {
    const intervals: Record<string, number> = {
      'dailyMaintenanceCheck': 25 * 60 * 60 * 1000, // 25 hours
      'syncCarData': 5 * 60 * 60 * 1000,            // 5 hours
    };
    return intervals[jobName] || 24 * 60 * 60 * 1000;
  }
}

// Usage in job classes
@Cron('0 0 * * *')
async dailyMaintenanceCheck(): Promise<void> {
  this.jobHealthService.updateJobStatus('dailyMaintenanceCheck', 'running');

  try {
    await this.performMaintenanceCheck();
    this.jobHealthService.updateJobStatus('dailyMaintenanceCheck', 'completed');
  } catch (error) {
    this.jobHealthService.updateJobStatus('dailyMaintenanceCheck', 'failed', error as Error);
    throw error;
  }
}
```

## Best Practices

### Error Handling Requirements
- **Always** use try/catch with `loggerService.notifyError()` for error notifications
- Log success for critical operations with `loggerService.notifyInfo()`
- Include context: operation name, counts, timing

### Method Organization
```typescript
@Injectable()
export class CarMaintenanceJob {
  constructor(/* dependencies */) {}

  // Private helper methods first
  private async findCarsNeedingMaintenance(): Promise<Car[]> { }
  private async scheduleReminder(car: Car): Promise<void> { }

  // Public job methods last
  @Cron('0 0 * * *')
  async dailyMaintenanceCheck(): Promise<void> { }
}
```
