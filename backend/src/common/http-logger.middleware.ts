import { Logger } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

const logger = new Logger('HTTP');

/**
 * One log line per finished request. Deliberately records only the path (no query string, headers
 * or body) so tokens and passwords can never end up in the logs.
 */
export function httpLoggerMiddleware(req: Request, res: Response, next: NextFunction): void {
  const startedAt = process.hrtime.bigint();
  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - startedAt) / 1e6;
    const entry = {
      requestId: res.locals.requestId,
      method: req.method,
      path: req.originalUrl.split('?')[0],
      status: res.statusCode,
      durationMs: Math.round(durationMs * 10) / 10,
    };
    if (res.statusCode >= 500) logger.error(entry);
    else logger.log(entry);
  });
  next();
}
