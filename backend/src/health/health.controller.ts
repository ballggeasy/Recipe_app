import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  // APP_REVISION is the commit SHA baked into the Docker image by CI, so a request
  // shows which build is actually running on the VM.
  @Get()
  health(): { status: string; revision: string } {
    return { status: 'ok', revision: process.env.APP_REVISION || 'dev' };
  }
}
