import { LoggerService } from '@nestjs/common';

type Level = 'log' | 'error' | 'warn' | 'debug' | 'verbose' | 'fatal';

/** Nest logger that writes one JSON object per line (for log shippers); used in production. */
export class JsonLogger implements LoggerService {
  private write(level: Level, message: unknown, optionalParams: unknown[]): void {
    // Nest passes the context as the last string argument; for errors a stack may precede it.
    const params = [...optionalParams];
    const context = typeof params[params.length - 1] === 'string' ? (params.pop() as string) : undefined;
    const base = { time: new Date().toISOString(), level, context };
    // A structured message (e.g. the per-request log) becomes top-level fields instead of a nested string.
    const entry: Record<string, unknown> =
      typeof message === 'object' && message !== null && !(message instanceof Error)
        ? { ...base, ...message }
        : { ...base, message: message instanceof Error ? message.message : String(message) };
    if (params.length > 0) entry.detail = params.map((p) => (typeof p === 'string' ? p : JSON.stringify(p)));
    const line = JSON.stringify(entry) + '\n';
    (level === 'error' || level === 'fatal' ? process.stderr : process.stdout).write(line);
  }

  log(message: unknown, ...optionalParams: unknown[]) {
    this.write('log', message, optionalParams);
  }
  error(message: unknown, ...optionalParams: unknown[]) {
    this.write('error', message, optionalParams);
  }
  warn(message: unknown, ...optionalParams: unknown[]) {
    this.write('warn', message, optionalParams);
  }
  debug(message: unknown, ...optionalParams: unknown[]) {
    this.write('debug', message, optionalParams);
  }
  verbose(message: unknown, ...optionalParams: unknown[]) {
    this.write('verbose', message, optionalParams);
  }
  fatal(message: unknown, ...optionalParams: unknown[]) {
    this.write('fatal', message, optionalParams);
  }
}
