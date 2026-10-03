import { randomUUID } from 'crypto';
import { NextFunction, Request, Response } from 'express';

export const REQUEST_ID_HEADER = 'x-request-id';

/** Only accept a client-supplied id when it is short and harmless to put in logs and headers. */
const SAFE_REQUEST_ID = /^[A-Za-z0-9._-]{1,64}$/;

/** Gives every request an id (reusing a sane `X-Request-Id`), echoes it back and exposes it as `res.locals.requestId`. */
export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const incoming = req.header(REQUEST_ID_HEADER);
  const requestId = incoming && SAFE_REQUEST_ID.test(incoming) ? incoming : randomUUID();
  res.locals.requestId = requestId;
  res.setHeader('X-Request-Id', requestId);
  next();
}
