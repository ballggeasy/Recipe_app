import { Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';

/** What the app needs from a verified Google ID token. */
export interface GoogleIdentity {
  /** Google's stable, unique id for the account (the `sub` claim). Never changes, unlike the email. */
  googleId: string;
  email: string;
  name: string | null;
  picture: string | null;
}

/** OAuth client ids whose tokens are accepted (the audience): `GOOGLE_CLIENT_IDS=a.apps.googleusercontent.com,b...`. */
export function googleClientIds(): string[] {
  return (process.env.GOOGLE_CLIENT_IDS ?? '')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
}

/**
 * Checks a Google ID token the way Google documents it: signature against Google's public keys, issuer,
 * expiry and audience (must be one of our own client ids, so a token issued to someone else's app is
 * refused). A class of its own so tests can replace it without any network access.
 */
@Injectable()
export class GoogleTokenVerifier {
  private readonly client = new OAuth2Client();

  async verify(idToken: string): Promise<GoogleIdentity> {
    const audience = googleClientIds();
    if (audience.length === 0) {
      throw new ServiceUnavailableException('ยังไม่ได้ตั้งค่า Google Sign-In บนเซิร์ฟเวอร์');
    }

    let payload;
    try {
      const ticket = await this.client.verifyIdToken({ idToken, audience });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('ยืนยันตัวตนกับ Google ไม่สำเร็จ');
    }
    // An unverified address could belong to someone else, and we link accounts by email.
    if (!payload?.sub || !payload.email || payload.email_verified !== true) {
      throw new UnauthorizedException('บัญชี Google นี้ยังไม่ได้ยืนยันอีเมล');
    }

    return {
      googleId: payload.sub,
      email: payload.email,
      name: payload.name ?? null,
      picture: payload.picture ?? null,
    };
  }
}
