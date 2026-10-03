import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { DataSource } from 'typeorm';

// Probes and the deploy smoke test hit these constantly; they must never be rate limited.
@SkipThrottle()
@Controller('health')
export class HealthController {
  constructor(private readonly dataSource: DataSource) {}

  /**
   * Liveness: the process is up. APP_REVISION is the commit SHA baked into the Docker image by CI,
   * so a request shows which build is actually running on the VM.
   */
  @Get()
  health(): { status: string; revision: string } {
    return { status: 'ok', revision: process.env.APP_REVISION || 'dev' };
  }

  /** Readiness: the app can actually serve traffic, i.e. the database answers. 503 otherwise. */
  @Get('ready')
  async ready(): Promise<{ status: string; revision: string }> {
    try {
      await this.dataSource.query('SELECT 1');
    } catch {
      throw new ServiceUnavailableException('Database is not reachable');
    }
    return { status: 'ready', revision: process.env.APP_REVISION || 'dev' };
  }
}
