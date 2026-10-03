import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';

export interface ErrorBody {
  statusCode: number;
  error: string;
  /** A string, or a list of strings for validation errors (the Flutter client joins lists). */
  message: string | string[];
  requestId?: string;
  path: string;
  timestamp: string;
}

const STATUS_TEXT: Record<number, string> = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  409: 'Conflict',
  413: 'Payload Too Large',
  429: 'Too Many Requests',
  500: 'Internal Server Error',
  503: 'Service Unavailable',
};

/**
 * Every error leaves the API in the same JSON shape. HTTP exceptions keep their message; anything
 * unexpected becomes a generic 500 so stack traces and database details never reach the client.
 * The real error is logged server-side with the request id for correlation.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exceptions');

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const res = http.getResponse<Response>();
    const req = http.getRequest<Request>();
    const requestId = res.locals?.requestId as string | undefined;

    let statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';
    let error = STATUS_TEXT[500];

    if (exception instanceof HttpException) {
      statusCode = exception.getStatus();
      error = STATUS_TEXT[statusCode] ?? exception.name;
      const body = exception.getResponse();
      if (typeof body === 'string') {
        message = body;
      } else {
        const obj = body as { message?: string | string[]; error?: string };
        message = obj.message ?? exception.message;
        error = obj.error ?? STATUS_TEXT[statusCode] ?? exception.name;
      }
    }

    if (statusCode >= 500) {
      const stack = exception instanceof Error ? exception.stack : String(exception);
      this.logger.error(`${req.method} ${req.originalUrl.split('?')[0]} failed (requestId=${requestId})`, stack);
    }

    const payload: ErrorBody = {
      statusCode,
      error,
      message,
      requestId,
      path: req.originalUrl.split('?')[0],
      timestamp: new Date().toISOString(),
    };
    res.status(statusCode).json(payload);
  }
}
