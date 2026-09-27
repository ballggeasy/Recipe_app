import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';
import { httpRequestDuration, httpRequestsTotal } from './metrics.registry';

@Injectable()
export class MetricsMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const stopTimer = httpRequestDuration.startTimer();
    res.on('finish', () => {
      // Use the route pattern (/recipes/:id), not the raw URL, to keep label cardinality bounded.
      const route = req.route?.path ? `${req.baseUrl}${req.route.path}` : 'unmatched';
      const labels = { method: req.method, route, status: String(res.statusCode) };
      stopTimer(labels);
      httpRequestsTotal.inc(labels);
    });
    next();
  }
}
