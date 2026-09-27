import { Controller, Get } from '@nestjs/common';

/** Liveness probe for Docker HEALTHCHECK and post-deploy smoke checks. */
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok' };
  }
}
