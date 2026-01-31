# External API Integrations

## HTTP Client with Error Handling

```typescript
import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { catchError, retry, timeout } from 'rxjs/operators';
import { of } from 'rxjs';

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
  private readonly timeoutMs = 30000;
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
              const baseDelay = Math.pow(2, retryIndex) * 1000;
              const jitter = Math.random() * 1000;
              return of(null).pipe(delay(baseDelay + jitter));
            },
          }),
          catchError((error) => this.handleHttpError(error, endpoint, { carId }))
        )
        .toPromise();

      return response.data;
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'syncCar', carId, endpoint }
      });
      throw error;
    }
  }

  private handleHttpError(error: any, endpoint: string, context?: any) {
    const { response, request, message } = error;

    if (response) {
      const statusCode = response.status;
      const errorMessage = response.data?.message || response.statusText;
      
      switch (statusCode) {
        case 400:
          throw new ExternalApiException(`Bad request: ${errorMessage}`, HttpStatus.BAD_REQUEST, endpoint, context);
        case 401:
          throw new ExternalApiException('Unauthorized', HttpStatus.UNAUTHORIZED, endpoint, context);
        case 404:
          throw new ExternalApiException('Not found', HttpStatus.NOT_FOUND, endpoint, context);
        case 429:
          throw new ExternalApiException('Rate limit exceeded', HttpStatus.TOO_MANY_REQUESTS, endpoint, context);
        case 500: case 502: case 503: case 504:
          throw new ExternalApiException('Server error', HttpStatus.SERVICE_UNAVAILABLE, endpoint, context);
        default:
          throw new ExternalApiException(errorMessage, HttpStatus.INTERNAL_SERVER_ERROR, endpoint, context);
      }
    } else if (request) {
      throw new ExternalApiException('Network error', HttpStatus.SERVICE_UNAVAILABLE, endpoint, context);
    } else {
      throw new ExternalApiException('Request setup error', HttpStatus.INTERNAL_SERVER_ERROR, endpoint, context);
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
  async syncMultipleCars(carIds: string[]): Promise<BulkSyncResult> {
    const result: BulkSyncResult = { successful: [], failed: [], totalProcessed: 0 };
    const batchSize = 5;
    const batches = this.createBatches(carIds, batchSize);

    for (const batch of batches) {
      const promises = batch.map(carId => this.syncSingleCar(carId));
      const settledResults = await Promise.allSettled(promises);

      settledResults.forEach((settledResult, index) => {
        const carId = batch[index];
        result.totalProcessed++;

        if (settledResult.status === 'fulfilled') {
          result.successful.push(carId);
        } else {
          result.failed.push({ carId, error: settledResult.reason?.message || 'Unknown error' });
        }
      });

      // Delay between batches
      if (batches.indexOf(batch) < batches.length - 1) {
        await this.delay(1000);
      }
    }

    // Notify about results
    if (result.failed.length > 0) {
      this.loggerService.notifyError(
        new Error(`Bulk sync: ${result.failed.length} failures`),
        { context: { successful: result.successful.length, failed: result.failed.length } }
      );
    }

    return result;
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

## WebSocket Connection with Reconnect

```typescript
import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { WebSocket } from 'ws';

enum ConnectionState {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  RECONNECTING = 'reconnecting',
}

@Injectable()
export class RealTimeUpdatesService implements OnModuleDestroy {
  private websocket: WebSocket | null = null;
  private connectionState = ConnectionState.DISCONNECTED;
  private reconnectAttempts = 0;
  private readonly maxReconnectAttempts = 5;
  private readonly reconnectDelay = 5000;
  private reconnectTimer: NodeJS.Timeout | null = null;

  constructor(private readonly loggerService: LoggerService) {
    this.connect();
  }

  onModuleDestroy() {
    this.disconnect();
  }

  private connect(): void {
    if (this.connectionState === ConnectionState.CONNECTING) return;

    this.connectionState = ConnectionState.CONNECTING;

    try {
      this.websocket = new WebSocket(process.env.REALTIME_API_URL);
      this.setupHandlers();
    } catch (error) {
      this.handleConnectionError(error as Error);
    }
  }

  private setupHandlers(): void {
    if (!this.websocket) return;

    this.websocket.on('open', () => {
      this.connectionState = ConnectionState.CONNECTED;
      this.reconnectAttempts = 0;
      
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
        this.loggerService.warn('Failed to parse WebSocket message');
      }
    });

    this.websocket.on('error', (error: Error) => this.handleConnectionError(error));
    this.websocket.on('close', () => {
      this.connectionState = ConnectionState.DISCONNECTED;
      this.scheduleReconnect();
    });
  }

  private handleConnectionError(error: Error): void {
    this.connectionState = ConnectionState.DISCONNECTED;

    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      this.loggerService.notifyError(
        new Error('WebSocket connection failed after max attempts'),
        { context: { reconnectAttempts: this.reconnectAttempts } }
      );
    }

    this.scheduleReconnect();
  }

  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) return;
    if (this.connectionState === ConnectionState.RECONNECTING) return;

    this.connectionState = ConnectionState.RECONNECTING;
    this.reconnectAttempts++;

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    this.reconnectTimer = setTimeout(() => this.connect(), delay);
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
  }

  getConnectionStatus(): { state: ConnectionState; isHealthy: boolean } {
    return {
      state: this.connectionState,
      isHealthy: this.connectionState === ConnectionState.CONNECTED
    };
  }
}
```

## File Upload with Validation

```typescript
@Injectable()
export class FileUploadService {
  private readonly maxFileSize = 10 * 1024 * 1024; // 10MB
  private readonly allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

  async uploadCarImage(carId: string, file: Express.Multer.File): Promise<{ url: string; fileId: string }> {
    try {
      this.validateFile(file);

      const fileName = `cars/${carId}/${Date.now()}${path.extname(file.originalname)}`;
      const uploadResult = await this.uploadWithRetry(fileName, file.buffer, file.mimetype);

      await this.carService.addImage(carId, {
        url: uploadResult.url,
        fileId: uploadResult.fileId,
        originalName: file.originalname,
        size: file.size,
        mimeType: file.mimetype
      });

      return uploadResult;
    } catch (error) {
      this.loggerService.notifyError(error as Error, {
        context: { operation: 'uploadCarImage', carId, fileName: file.originalname }
      });
      throw error;
    }
  }

  private validateFile(file: Express.Multer.File): void {
    if (!file) throw new BadRequestException('No file provided');
    if (file.size > this.maxFileSize) throw new BadRequestException('File too large');
    if (!this.allowedMimeTypes.includes(file.mimetype)) throw new BadRequestException('Invalid file type');
    if (!this.isValidFileContent(file)) throw new BadRequestException('File content mismatch');
  }

  private isValidFileContent(file: Express.Multer.File): boolean {
    const signatures: Record<string, number[]> = {
      'image/jpeg': [0xFF, 0xD8, 0xFF],
      'image/png': [0x89, 0x50, 0x4E, 0x47],
      'application/pdf': [0x25, 0x50, 0x44, 0x46]
    };

    const signature = signatures[file.mimetype];
    if (!signature) return true;

    return signature.every((byte, i) => file.buffer[i] === byte);
  }

  private async uploadWithRetry(fileName: string, buffer: Buffer, mimeType: string, maxRetries = 3): Promise<{ url: string; fileId: string }> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.storageService.upload(fileName, buffer, mimeType);
      } catch (error) {
        lastError = error as Error;
        if (attempt < maxRetries) {
          await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt - 1) * 1000));
        }
      }
    }

    throw new InternalServerErrorException(`Upload failed after ${maxRetries} attempts`);
  }
}
```

## Best Practices

- Use exponential backoff with jitter for retries
- Implement circuit breaker for frequently failing external services
- Use `Promise.allSettled()` for bulk operations to handle partial failures
- Validate file content (magic bytes), not just MIME type
- Always include context in error notifications
- Use connection health checks for long-lived connections (WebSocket)
