import { CanActivate, ForbiddenException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Guards the password-reset endpoints, which identify the account by email alone (no emailed
 * token), so anyone could take over any account. They stay off unless the operator opts in with
 * ALLOW_INSECURE_PASSWORD_RESET=true, intended for local development only.
 */
@Injectable()
export class PasswordResetEnabledGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(): boolean {
    if (this.config.get<string>('ALLOW_INSECURE_PASSWORD_RESET') !== 'true') {
      throw new ForbiddenException('ระบบรีเซ็ตรหัสผ่านยังไม่เปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ');
    }
    return true;
  }
}
