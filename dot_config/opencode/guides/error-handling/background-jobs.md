# Error Handling in Background Jobs

## Basic Background Job Error Handling

```typescript
import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { LoggerService } from 'src/common/logger/logger.service';

import { CarService } from '../car/car.service';
import { NotificationService } from '../notification/notification.service';

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
          this.loggerService.error(
            `Failed to schedule maintenance for car ${car.id}`,
            error
          );
        }
      }

      // Success notification with metrics
      this.loggerService.notifyInfo('Daily maintenance check completed', {
        context: { 
          processedCount,
          errorCount,
          duration: Date.now() - startTime,
          operation: 'dailyMaintenanceCheck'
        }
      });
    } catch (error) {
      // Critical failure - notify immediately
      this.loggerService.notifyError(error as Error, {
        context: { 
          operation: 'dailyMaintenanceCheck',
          scheduledTime: new Date().toISOString(),
          processedCount,
          errorCount
        }
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

## Retry Logic with Exponential Backoff

```typescript
@Injectable()
export class DataSyncJob {
  private readonly MAX_RETRIES = 3;
  private readonly BASE_DELAY = 1000; // 1 second

  constructor(
    private readonly externalApiService: ExternalApiService,
    private readonly loggerService: LoggerService,
  ) {}

  @Cron('0 */4 * * *') // Every 4 hours
  async syncCarData(): Promise<void> {
    try {
      const carsToSync = await this.getCarsPendingSync();
      
      for (const car of carsToSync) {
        await this.syncCarWithRetry(car);
      }

      this.loggerService.notifyInfo('Car data sync completed successfully', {
        context: { 
          syncedCount: carsToSync.length,
          operation: 'syncCarData'
        }
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'syncCarData' }
      });
      throw error;
    }
  }

  private async syncCarWithRetry(car: Car): Promise<void> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= this.MAX_RETRIES; attempt++) {
      try {
        await this.externalApiService.syncCar(car.id);
        
        // Success - update sync status
        await this.carService.updateSyncStatus(car.id, 'synced');
        return;
      } catch (error) {
        lastError = error as Error;
        
        this.loggerService.warn(
          `Sync attempt ${attempt} failed for car ${car.id}`,
          { error: error.message, attempt }
        );

        // Don't wait after the last attempt
        if (attempt < this.MAX_RETRIES) {
          const delay = this.BASE_DELAY * Math.pow(2, attempt - 1);
          await this.sleep(delay);
        }
      }
    }

    // All retries failed - mark as failed and notify
    await this.carService.updateSyncStatus(car.id, 'failed');
    
    this.loggerService.notifyError(lastError!, {
      context: { 
        carId: car.id,
        attempts: this.MAX_RETRIES,
        operation: 'syncCarWithRetry'
      }
    });

    throw new Error(`Failed to sync car ${car.id} after ${this.MAX_RETRIES} attempts`);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Circuit Breaker Pattern

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
    private readonly recoveryTimeout: number = 60000, // 1 minute
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

@Injectable()
export class ExternalApiSyncJob {
  private readonly circuitBreaker = new CircuitBreaker(5, 60000, 3);

  constructor(
    private readonly externalApiService: ExternalApiService,
    private readonly loggerService: LoggerService,
  ) {}

  @Cron('0 */2 * * *') // Every 2 hours
  async syncWithExternalApi(): Promise<void> {
    try {
      await this.circuitBreaker.execute(async () => {
        const data = await this.externalApiService.fetchCarUpdates();
        await this.processUpdates(data);
      });

      this.loggerService.notifyInfo('External API sync completed', {
        context: { operation: 'syncWithExternalApi' }
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

## Dead Letter Queue Pattern

```typescript
interface FailedJob {
  id: string;
  jobType: string;
  payload: any;
  error: string;
  failedAt: Date;
  retryCount: number;
  maxRetries: number;
}

@Injectable()
export class DeadLetterQueueService {
  constructor(
    @InjectRepository(FailedJob)
    private readonly failedJobRepository: Repository<FailedJob>,
    private readonly loggerService: LoggerService,
  ) {}

  async addFailedJob(
    jobType: string,
    payload: any,
    error: Error,
    retryCount: number = 0,
    maxRetries: number = 3
  ): Promise<void> {
    const failedJob = this.failedJobRepository.create({
      jobType,
      payload: JSON.stringify(payload),
      error: error.message,
      failedAt: new Date(),
      retryCount,
      maxRetries,
    });

    await this.failedJobRepository.save(failedJob);

    this.loggerService.notifyError(error, {
      context: {
        jobType,
        retryCount,
        maxRetries,
        operation: 'addFailedJob'
      }
    });
  }

  @Cron('0 */30 * * *') // Every 30 minutes
  async retryFailedJobs(): Promise<void> {
    const retryableJobs = await this.failedJobRepository.find({
      where: {
        retryCount: LessThan(new Repository().createQueryBuilder().select().from('failed_job', 'fj').where('fj.maxRetries').getQuery())
      },
      order: { failedAt: 'ASC' },
      take: 50, // Process max 50 at a time
    });

    let retryCount = 0;
    let successCount = 0;

    for (const job of retryableJobs) {
      try {
        await this.retryJob(job);
        await this.failedJobRepository.remove(job);
        successCount++;
      } catch (error) {
        job.retryCount++;
        job.error = error.message;
        await this.failedJobRepository.save(job);
        retryCount++;
      }
    }

    if (retryableJobs.length > 0) {
      this.loggerService.notifyInfo('Dead letter queue processing completed', {
        context: {
          processed: retryableJobs.length,
          succeeded: successCount,
          failed: retryCount,
          operation: 'retryFailedJobs'
        }
      });
    }
  }

  private async retryJob(failedJob: FailedJob): Promise<void> {
    const payload = JSON.parse(failedJob.payload);

    switch (failedJob.jobType) {
      case 'car_sync':
        await this.externalApiService.syncCar(payload.carId);
        break;
      case 'maintenance_reminder':
        await this.notificationService.send(payload);
        break;
      case 'invoice_generation':
        await this.invoiceService.generate(payload);
        break;
      default:
        throw new Error(`Unknown job type: ${failedJob.jobType}`);
    }
  }
}
```

## Graceful Degradation

```typescript
@Injectable()
export class CarReportingJob {
  constructor(
    private readonly carService: CarService,
    private readonly reportService: ReportService,
    private readonly emailService: EmailService,
    private readonly loggerService: LoggerService,
  ) {}

  @Cron('0 6 * * 1') // Every Monday at 6 AM
  async generateWeeklyReport(): Promise<void> {
    const reportData: Partial<WeeklyReport> = {};
    const errors: string[] = [];

    try {
      // Critical data - if this fails, abort the job
      reportData.carCount = await this.carService.getTotalCount();
      reportData.availableCount = await this.carService.getAvailableCount();
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { 
          operation: 'generateWeeklyReport',
          section: 'critical_data'
        }
      });
      throw error; // Abort the entire job
    }

    // Non-critical data - continue even if these fail
    try {
      reportData.maintenanceAlerts = await this.carService.getMaintenanceAlerts();
    } catch (error) {
      errors.push('Failed to fetch maintenance alerts');
      this.loggerService.warn('Non-critical error in weekly report', { error });
      reportData.maintenanceAlerts = []; // Provide fallback
    }

    try {
      reportData.revenueData = await this.carService.getRevenueData();
    } catch (error) {
      errors.push('Failed to fetch revenue data');
      this.loggerService.warn('Non-critical error in weekly report', { error });
      reportData.revenueData = null; // Indicate missing data
    }

    try {
      reportData.performanceMetrics = await this.carService.getPerformanceMetrics();
    } catch (error) {
      errors.push('Failed to fetch performance metrics');
      this.loggerService.warn('Non-critical error in weekly report', { error });
      reportData.performanceMetrics = this.getDefaultMetrics(); // Use defaults
    }

    // Generate report with available data
    try {
      const report = await this.reportService.generateWeeklyReport(reportData as WeeklyReport);
      
      // Add error notice if there were non-critical failures
      if (errors.length > 0) {
        report.notes = `Note: Some data may be incomplete due to: ${errors.join(', ')}`;
      }

      await this.emailService.sendWeeklyReport(report);

      this.loggerService.notifyInfo('Weekly report generated successfully', {
        context: {
          operation: 'generateWeeklyReport',
          hasErrors: errors.length > 0,
          errorCount: errors.length,
          errors: errors
        }
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { 
          operation: 'generateWeeklyReport',
          section: 'report_generation'
        }
      });
      throw error;
    }
  }

  private getDefaultMetrics(): PerformanceMetrics {
    return {
      utilizationRate: 0,
      averageRentalDuration: 0,
      popularModels: [],
      note: 'Metrics unavailable due to system error'
    };
  }
}
```

## Health Check Integration

```typescript
@Injectable()
export class JobHealthService {
  private readonly jobStatuses = new Map<string, JobStatus>();

  constructor(private readonly loggerService: LoggerService) {}

  updateJobStatus(jobName: string, status: 'running' | 'completed' | 'failed', error?: Error): void {
    this.jobStatuses.set(jobName, {
      name: jobName,
      status,
      lastRun: new Date(),
      error: error?.message,
    });
  }

  @Cron('0 */5 * * *') // Every 5 minutes
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
        new Error('Jobs are not running as expected'), 
        {
          context: {
            unhealthyJobs,
            operation: 'checkJobHealth'
          }
        }
      );
    }
  }

  private getMaxIntervalForJob(jobName: string): number {
    const intervals = {
      'dailyMaintenanceCheck': 25 * 60 * 60 * 1000, // 25 hours
      'syncCarData': 5 * 60 * 60 * 1000, // 5 hours
      'generateWeeklyReport': 8 * 24 * 60 * 60 * 1000, // 8 days
    };

    return intervals[jobName] || 24 * 60 * 60 * 1000; // Default 24 hours
  }
}

// Usage in job classes
@Injectable()
export class CarMaintenanceJob {
  constructor(
    private readonly carService: CarService,
    private readonly jobHealthService: JobHealthService,
    private readonly loggerService: LoggerService,
  ) {}

  @Cron('0 0 * * *')
  async dailyMaintenanceCheck(): Promise<void> {
    this.jobHealthService.updateJobStatus('dailyMaintenanceCheck', 'running');

    try {
      // Job logic here
      await this.performMaintenanceCheck();

      this.jobHealthService.updateJobStatus('dailyMaintenanceCheck', 'completed');
    } catch (error) {
      this.jobHealthService.updateJobStatus('dailyMaintenanceCheck', 'failed', error as Error);
      throw error;
    }
  }
}
```