// Runs before each e2e test file is loaded, so AppModule and AuthModule read these
// values instead of touching the developer's real ./data/app.sqlite and ./uploads.
import { mkdtempSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

process.env.DB_PATH = ':memory:';
process.env.JWT_SECRET = 'e2e-test-secret';
// Tests register dozens of users from one IP; the dedicated rate-limit test lowers these again.
process.env.RATE_LIMIT_PER_MINUTE = '100000';
process.env.AUTH_RATE_LIMIT_PER_MINUTE = '100000';
process.env.UPLOADS_DIR = mkdtempSync(join(tmpdir(), 'recipe-e2e-uploads-'));
