# Error Handling in API Integrations

## HTTP Client Error Handling

```typescript
import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { catchError, retry, timeout } from 'rxjs/operators';
import { throwError, of } from 'rxjs';

import { LoggerService } from 'src/common/logger/logger.service';

export class ExternalApiException extends HttpException {
  constructor(
    message: string,
    public readonly statusCode: number,
    public readonly endpoint: string,
    public readonly context?: any
  ) {
    super(message, statusCode);
    this.name = 'ExternalApiException';
  }
}

@Injectable()
export class ExternalCarApiService {
  private readonly baseUrl = 'https://api.carservice.com';
  private readonly timeoutMs = 30000; // 30 seconds
  private readonly maxRetries = 3;

  constructor(
    private readonly httpService: HttpService,
    private readonly loggerService: LoggerService,
  ) {}

  async syncCar(carId: string): Promise<ExternalCarData> {
    const endpoint = `/cars/${carId}`;
    const url = `${this.baseUrl}${endpoint}`;

    try {
      const response = await this.httpService
        .get<ExternalCarData>(url, {
          headers: {
            'Authorization': `Bearer ${process.env.EXTERNAL_API_TOKEN}`,
            'Content-Type': 'application/json',
          },
          timeout: this.timeoutMs,
        })
        .pipe(
          timeout(this.timeoutMs),
          retry({
            count: this.maxRetries,
            delay: (error, retryIndex) => {
              // Exponential backoff with jitter
              const baseDelay = Math.pow(2, retryIndex) * 1000;
              const jitter = Math.random() * 1000;
              return of(null).pipe(delay(baseDelay + jitter));
            },
            resetOnSuccess: true,
          }),
          catchError((error) => {
            return this.handleHttpError(error, endpoint, { carId });
          })
        )
        .toPromise();

      this.loggerService.debug(`Successfully synced car ${carId}`, {
        endpoint,
        responseStatus: response.status
      });

      return response.data;
    } catch (error) {
      // Manual error notification for external API failures
      this.loggerService.notifyError(error as Error, {
        context: {
          operation: 'syncCar',
          carId,
          endpoint,
          url
        }
      });
      throw error;
    }
  }

  async createCar(carData: CreateCarData): Promise<ExternalCarData> {
    const endpoint = '/cars';
    const url = `${this.baseUrl}${endpoint}`;

    try {
      const response = await this.httpService
        .post<ExternalCarData>(url, carData, {
          headers: {
            'Authorization': `Bearer ${process.env.EXTERNAL_API_TOKEN}`,
            'Content-Type': 'application/json',
          },
          timeout: this.timeoutMs,
        })
        .pipe(
          timeout(this.timeoutMs),
          retry({
            count: 2, // Fewer retries for POST requests
            delay: 2000,
          }),
          catchError((error) => {
            return this.handleHttpError(error, endpoint, { carData });
          })
        )
        .toPromise();

      return response.data;
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: {
          operation: 'createCar',
          endpoint,
          carData: JSON.stringify(carData)
        }
      });
      throw error;
    }
  }

  private handleHttpError(error: any, endpoint: string, context?: any) {
    const { response, request, message } = error;

    if (response) {
      // Server responded with error status
      const statusCode = response.status;
      const errorMessage = response.data?.message || response.statusText || 'Unknown error';
      
      this.loggerService.error(
        `External API error: ${statusCode} - ${errorMessage}`,
        {
          endpoint,
          statusCode,
          responseData: response.data,
          context
        }
      );

      // Map external API errors to our exceptions
      switch (statusCode) {
        case 400:
          throw new ExternalApiException(
            `Bad request to external API: ${errorMessage}`,
            HttpStatus.BAD_REQUEST,
            endpoint,
            context
          );
        case 401:
          throw new ExternalApiException(
            'Unauthorized access to external API',
            HttpStatus.UNAUTHORIZED,
            endpoint,
            context
          );
        case 404:
          throw new ExternalApiException(
            'Resource not found in external API',
            HttpStatus.NOT_FOUND,
            endpoint,
            context
          );
        case 429:
          throw new ExternalApiException(
            'Rate limit exceeded for external API',
            HttpStatus.TOO_MANY_REQUESTS,
            endpoint,
            context
          );
        case 500:
        case 502:
        case 503:
        case 504:
          throw new ExternalApiException(
            'External API server error',
            HttpStatus.SERVICE_UNAVAILABLE,
            endpoint,
            context
          );
        default:
          throw new ExternalApiException(
            `External API error: ${errorMessage}`,
            HttpStatus.INTERNAL_SERVER_ERROR,
            endpoint,
            context
          );
      }
    } else if (request) {
      // Request was made but no response received (network error, timeout)
      this.loggerService.error(
        `Network error calling external API: ${message}`,
        { endpoint, context }
      );

      throw new ExternalApiException(
        'Network error communicating with external API',
        HttpStatus.SERVICE_UNAVAILABLE,
        endpoint,
        context
      );
    } else {
      // Request setup error
      this.loggerService.error(
        `Request setup error: ${message}`,
        { endpoint, context }
      );

      throw new ExternalApiException(
        'Failed to setup request to external API',
        HttpStatus.INTERNAL_SERVER_ERROR,
        endpoint,
        context
      );
    }
  }
}
```

## Bulk Operations with Partial Failures

```typescript
interface BulkSyncResult {
  successful: string[];
  failed: Array<{ carId: string; error: string }>;
  totalProcessed: number;
}

@Injectable()
export class BulkCarSyncService {
  constructor(
    private readonly externalApiService: ExternalCarApiService,
    private readonly carService: CarService,
    private readonly loggerService: LoggerService,
  ) {}

  async syncMultipleCars(carIds: string[]): Promise<BulkSyncResult> {
    const result: BulkSyncResult = {
      successful: [],
      failed: [],
      totalProcessed: 0,
    };

    const batchSize = 5; // Process 5 cars at a time
    const batches = this.createBatches(carIds, batchSize);

    for (const batch of batches) {
      await this.processBatch(batch, result);
      
      // Small delay between batches to avoid overwhelming the external API
      if (batches.indexOf(batch) < batches.length - 1) {
        await this.delay(1000);
      }
    }

    // Notify about results
    if (result.failed.length > 0) {
      this.loggerService.notifyError(
        new Error(`Bulk sync completed with ${result.failed.length} failures`),
        {
          context: {
            operation: 'syncMultipleCars',
            totalCars: carIds.length,
            successful: result.successful.length,
            failed: result.failed.length,
            failedCars: result.failed.map(f => f.carId)
          }
        }
      );
    } else {
      this.loggerService.notifyInfo('Bulk car sync completed successfully', {
        context: {
          operation: 'syncMultipleCars',
          totalCars: carIds.length,
          successful: result.successful.length
        }
      });
    }

    return result;
  }

  private async processBatch(carIds: string[], result: BulkSyncResult): Promise<void> {
    const promises = carIds.map(carId => this.syncSingleCar(carId));
    const settledResults = await Promise.allSettled(promises);

    settledResults.forEach((settledResult, index) => {
      const carId = carIds[index];
      result.totalProcessed++;

      if (settledResult.status === 'fulfilled') {
        result.successful.push(carId);
      } else {
        result.failed.push({
          carId,
          error: settledResult.reason?.message || 'Unknown error'
        });
        
        this.loggerService.warn(
          `Failed to sync car ${carId}`,
          { error: settledResult.reason?.message }
        );
      }
    });
  }

  private async syncSingleCar(carId: string): Promise<void> {
    try {
      const externalData = await this.externalApiService.syncCar(carId);
      await this.carService.updateFromExternalData(carId, externalData);
    } catch (error) {
      // Don't re-throw - we handle errors at the batch level
      throw error;
    }
  }

  private createBatches<T>(items: T[], batchSize: number): T[][] {
    const batches: T[][] = [];
    for (let i = 0; i < items.length; i += batchSize) {
      batches.push(items.slice(i, i + batchSize));
    }
    return batches;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## WebSocket Connection Error Handling

```typescript
import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { WebSocket } from 'ws';

import { LoggerService } from 'src/common/logger/logger.service';

enum ConnectionState {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  RECONNECTING = 'reconnecting',
}

@Injectable()
export class RealTimeCarUpdatesService implements OnModuleDestroy {
  private websocket: WebSocket | null = null;
  private connectionState = ConnectionState.DISCONNECTED;
  private reconnectAttempts = 0;
  private readonly maxReconnectAttempts = 5;
  private readonly reconnectDelay = 5000; // 5 seconds
  private reconnectTimer: NodeJS.Timeout | null = null;

  constructor(private readonly loggerService: LoggerService) {
    this.connect();
  }

  onModuleDestroy() {
    this.disconnect();
  }

  private connect(): void {
    if (this.connectionState === ConnectionState.CONNECTING) {
      return;
    }

    this.connectionState = ConnectionState.CONNECTING;
    this.loggerService.debug('Attempting to connect to real-time car updates service');

    try {
      this.websocket = new WebSocket(process.env.REALTIME_API_URL);
      this.setupWebSocketHandlers();
    } catch (error) {
      this.handleConnectionError(error as Error);
    }
  }

  private setupWebSocketHandlers(): void {
    if (!this.websocket) return;

    this.websocket.on('open', () => {
      this.connectionState = ConnectionState.CONNECTED;
      this.reconnectAttempts = 0;
      
      this.loggerService.debug('Connected to real-time car updates service');
      
      // Send authentication if required
      this.websocket?.send(JSON.stringify({
        type: 'auth',
        token: process.env.REALTIME_API_TOKEN
      }));
    });

    this.websocket.on('message', (data: Buffer) => {
      try {
        const message = JSON.parse(data.toString());
        this.handleMessage(message);
      } catch (error) {
        this.loggerService.warn('Failed to parse WebSocket message', {
          error: error.message,
          data: data.toString()
        });
      }
    });

    this.websocket.on('error', (error: Error) => {
      this.handleConnectionError(error);
    });

    this.websocket.on('close', (code: number, reason: Buffer) => {
      this.connectionState = ConnectionState.DISCONNECTED;
      
      this.loggerService.warn('WebSocket connection closed', {
        code,
        reason: reason.toString()
      });

      this.scheduleReconnect();
    });

    // Setup ping/pong for connection health
    this.websocket.on('ping', () => {
      this.websocket?.pong();
    });

    this.websocket.on('pong', () => {
      // Connection is alive
    });
  }

  private handleMessage(message: any): void {
    try {
      switch (message.type) {
        case 'car_update':
          this.handleCarUpdate(message.data);
          break;
        case 'car_status_change':
          this.handleCarStatusChange(message.data);
          break;
        case 'auth_success':
          this.loggerService.debug('WebSocket authentication successful');
          break;
        case 'auth_failed':
          this.loggerService.error('WebSocket authentication failed');
          this.disconnect();
          break;
        case 'error':
          this.loggerService.warn('Received error from WebSocket server', {
            error: message.error
          });
          break;
        default:
          this.loggerService.debug('Unknown message type received', {
            type: message.type
          });
      }
    } catch (error) {
      this.loggerService.warn('Error processing WebSocket message', {
        error: error.message,
        messageType: message.type
      });
    }
  }

  private handleConnectionError(error: Error): void {
    this.connectionState = ConnectionState.DISCONNECTED;
    
    this.loggerService.warn('WebSocket connection error', {
      error: error.message,
      reconnectAttempts: this.reconnectAttempts
    });

    // Notify on persistent connection failures
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      this.loggerService.notifyError(
        new Error('Failed to establish WebSocket connection after maximum attempts'),
        {
          context: {
            operation: 'websocket_connection',
            reconnectAttempts: this.reconnectAttempts,
            maxAttempts: this.maxReconnectAttempts
          }
        }
      );
    }

    this.scheduleReconnect();
  }

  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      this.loggerService.error('Maximum reconnection attempts reached, giving up');
      return;
    }

    if (this.connectionState === ConnectionState.RECONNECTING) {
      return;
    }

    this.connectionState = ConnectionState.RECONNECTING;
    this.reconnectAttempts++;

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
    
    this.loggerService.debug(`Scheduling reconnection attempt ${this.reconnectAttempts} in ${delay}ms`);

    this.reconnectTimer = setTimeout(() => {
      this.connect();
    }, delay);
  }

  private disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.websocket) {
      this.websocket.close(1000, 'Service shutdown');
      this.websocket = null;
    }

    this.connectionState = ConnectionState.DISCONNECTED;
  }

  private async handleCarUpdate(data: any): Promise<void> {
    try {
      await this.carService.updateFromRealTimeData(data.carId, data);
    } catch (error) {
      this.loggerService.warn('Failed to process real-time car update', {
        error: error.message,
        carId: data.carId
      });
    }
  }

  private async handleCarStatusChange(data: any): Promise<void> {
    try {
      await this.carService.updateStatus(data.carId, data.status);
    } catch (error) {
      this.loggerService.warn('Failed to process car status change', {
        error: error.message,
        carId: data.carId,
        status: data.status
      });
    }
  }

  // Public method to check connection health
  public getConnectionStatus(): {
    state: ConnectionState;
    reconnectAttempts: number;
    isHealthy: boolean;
  } {
    return {
      state: this.connectionState,
      reconnectAttempts: this.reconnectAttempts,
      isHealthy: this.connectionState === ConnectionState.CONNECTED
    };
  }
}
```

## File Upload Error Handling

```typescript
@Injectable()
export class FileUploadService {
  private readonly maxFileSize = 10 * 1024 * 1024; // 10MB
  private readonly allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf'
  ];

  constructor(
    private readonly storageService: StorageService,
    private readonly loggerService: LoggerService,
  ) {}

  async uploadCarImage(
    carId: string,
    file: Express.Multer.File
  ): Promise<{ url: string; fileId: string }> {
    try {
      // Validate file
      this.validateFile(file);

      // Generate unique filename
      const fileExtension = path.extname(file.originalname);
      const fileName = `cars/${carId}/${Date.now()}${fileExtension}`;

      // Attempt upload with retry logic
      const uploadResult = await this.uploadWithRetry(fileName, file.buffer, file.mimetype);

      // Update car with image URL
      await this.carService.addImage(carId, {
        url: uploadResult.url,
        fileId: uploadResult.fileId,
        originalName: file.originalname,
        size: file.size,
        mimeType: file.mimetype
      });

      this.loggerService.debug('Car image uploaded successfully', {
        carId,
        fileName,
        fileSize: file.size
      });

      return uploadResult;
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: {
          operation: 'uploadCarImage',
          carId,
          fileName: file.originalname,
          fileSize: file.size,
          mimeType: file.mimetype
        }
      });
      throw error;
    }
  }

  private validateFile(file: Express.Multer.File): void {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    if (file.size > this.maxFileSize) {
      throw new BadRequestException(
        `File size ${file.size} exceeds maximum allowed size of ${this.maxFileSize} bytes`
      );
    }

    if (!this.allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        `File type ${file.mimetype} not allowed. Allowed types: ${this.allowedMimeTypes.join(', ')}`
      );
    }

    // Validate file content matches extension
    if (!this.isValidFileContent(file)) {
      throw new BadRequestException('File content does not match file extension');
    }
  }

  private isValidFileContent(file: Express.Multer.File): boolean {
    // Check file signature (magic numbers)
    const fileSignatures = {
      'image/jpeg': [0xFF, 0xD8, 0xFF],
      'image/png': [0x89, 0x50, 0x4E, 0x47],
      'application/pdf': [0x25, 0x50, 0x44, 0x46]
    };

    const signature = fileSignatures[file.mimetype];
    if (!signature) return true; // Unknown type, trust mimetype

    const buffer = file.buffer;
    for (let i = 0; i < signature.length; i++) {
      if (buffer[i] !== signature[i]) {
        return false;
      }
    }

    return true;
  }

  private async uploadWithRetry(
    fileName: string,
    buffer: Buffer,
    mimeType: string,
    maxRetries: number = 3
  ): Promise<{ url: string; fileId: string }> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.storageService.upload(fileName, buffer, mimeType);
      } catch (error) {
        lastError = error as Error;
        
        this.loggerService.warn(
          `File upload attempt ${attempt} failed`,
          {
            fileName,
            error: error.message,
            attempt
          }
        );

        // Don't wait after the last attempt
        if (attempt < maxRetries) {
          const delay = Math.pow(2, attempt - 1) * 1000; // Exponential backoff
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    throw new InternalServerErrorException(
      `Failed to upload file after ${maxRetries} attempts: ${lastError?.message}`
    );
  }

  async deleteCarImage(carId: string, fileId: string): Promise<void> {
    try {
      // Delete from storage
      await this.storageService.delete(fileId);

      // Remove from car record
      await this.carService.removeImage(carId, fileId);

      this.loggerService.debug('Car image deleted successfully', {
        carId,
        fileId
      });
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: {
          operation: 'deleteCarImage',
          carId,
          fileId
        }
      });
      throw error;
    }
  }

  // Cleanup orphaned files (files in storage but not referenced by any car)
  async cleanupOrphanedFiles(): Promise<{ deletedCount: number; errors: string[] }> {
    const result = { deletedCount: 0, errors: [] };

    try {
      const allStorageFiles = await this.storageService.listFiles('cars/');
      const referencedFiles = await this.carService.getAllImageFileIds();

      const orphanedFiles = allStorageFiles.filter(
        file => !referencedFiles.includes(file.fileId)
      );

      for (const file of orphanedFiles) {
        try {
          await this.storageService.delete(file.fileId);
          result.deletedCount++;
        } catch (error) {
          result.errors.push(`Failed to delete ${file.fileId}: ${error.message}`);
        }
      }

      if (result.deletedCount > 0 || result.errors.length > 0) {
        this.loggerService.notifyInfo('Orphaned file cleanup completed', {
          context: {
            operation: 'cleanupOrphanedFiles',
            deletedCount: result.deletedCount,
            errorCount: result.errors.length
          }
        });
      }

      return result;
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'cleanupOrphanedFiles' }
      });
      throw error;
    }
  }
}
```