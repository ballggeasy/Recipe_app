import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy, jwtSecret } from './jwt.strategy';

@Module({
  imports: [
    UsersModule,
    PassportModule,
    // registerAsync ให้อ่านค่าหลัง ConfigModule โหลด .env แล้ว — register() ธรรมดาจะอ่าน process.env ตอน import ไฟล์นี้ ซึ่งเกิดก่อน
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: jwtSecret(config),
        signOptions: { expiresIn: config.get<string>('JWT_EXPIRES_IN') ?? '7d' },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
})
export class AuthModule {}
