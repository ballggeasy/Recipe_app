# Security

What protects the API today, what was deliberately left open, and what to do about it. Findings and their history: [ENGINEERING_ROADMAP.md](ENGINEERING_ROADMAP.md).

## In place

| Area | Control |
|------|---------|
| Secrets | `JWT_SECRET` is mandatory, validated at boot (≥ 32 chars and not a placeholder in production) and read through `ConfigService`; there is no built-in fallback. No secrets in git (`.env` is ignored; `.env.example` ships an empty `JWT_SECRET`). The VM env file is mode 0600 and generated randomly by Ansible. |
| Passwords | bcrypt (cost 10), maximum 128 characters; hashes never leave the auth module. |
| Login | Unknown email and wrong password give the same 401 body and take the same time (a bcrypt compare runs either way), so registered emails cannot be enumerated through login. |
| Rate limiting | Per client IP and route: 120/min generally, 10/min on login, register, change-password and reset. Health and metrics are exempt. Behind a proxy set `TRUST_PROXY`. |
| Account takeover | `POST /auth/reset-password` and `GET /auth/exists/:email` identify an account by email alone, so they are **disabled (403)** unless `ALLOW_INSECURE_PASSWORD_RESET=true`, which is for local development only and is never set on the VM. |
| Input | Global `ValidationPipe` (whitelist, reject unknown fields, transform); length and size caps on all text and lists; recipe `isRecommended`/`isOfficial` cannot be set by users. |
| Authorization | Ownership enforced in services (recipes, comments, meal plan, folders); references to missing recipes are rejected; covered by e2e tests with two users. |
| Uploads | Images only (JPEG/PNG/WebP/GIF, SVG rejected), 5 MB limit, stored name derived from the validated MIME type (never the client filename), deletion restricted to files under the uploads folder. |
| HTTP | `helmet` headers (cross-origin resource policy relaxed for `/uploads` images), CORS allow-list from `CORS_ORIGINS` (none in production unless set), `x-powered-by` removed. |
| Errors and logs | Uniform error body; unexpected errors become a generic 500 without stack or database details; access log records the path only (no query string, headers or bodies), so tokens and passwords cannot reach the logs. |
| Dependencies | `npm audit --omit=dev` runs in CI and fails on high/critical; Dependabot proposes updates weekly. |
| Transport | The API is served over HTTPS (Caddy, Let's Encrypt certificate renewed automatically); the Android app only allows plain HTTP to the emulator and localhost. |
| Supply chain / deploy | Pull-based deploy; webhook requests must carry a valid HMAC-SHA256 signature; image tags are immutable (`sha-<commit>`). |

## Accepted risks and open items

| # | Risk | Why it is open | What to do |
|---|------|----------------|------------|
| 1 | **No password reset for real users.** With the insecure endpoints disabled, a user who forgot their password cannot recover the account. | A safe flow needs an emailed single-use token, i.e. SMTP credentials and a sender domain. | Provide an SMTP service, then add `POST /auth/forgot-password` (emails a token) and `POST /auth/reset-password` (token + new password). The Flutter screen already shows the server's message. |
| 2 | `/metrics` is reachable from outside because port 3000 is published. It exposes route names, counts and process stats (no user data). | Authenticating Prometheus needs a secret shared between the app and Prometheus config, i.e. changes to the VM provisioning that cannot be tested from here. | Put a reverse proxy in front that only exposes the API routes, or add a `METRICS_TOKEN` bearer check and a `credentials_file` in `prometheus.yml` provisioned by Ansible. |
| 3 | JWTs live 7 days and cannot be revoked (also not after a password change). | A refresh-token flow is a feature, not a fix. | Shorten `JWT_EXPIRES_IN` once the app has a refresh flow; or add a `tokenVersion` claim checked in `JwtStrategy`. |
| 4 | The app stores the token in `SharedPreferences` (plain storage; localStorage on web). | A secure keystore needs a new dependency and does not help on web. | Use `flutter_secure_storage` for Android/iOS builds when shipping to stores. |
| 5 | 4 moderate advisories remain (`npm audit --omit=dev`): `@nestjs/core` (and `@nestjs/platform-express` which depends on it), `@nestjs/typeorm` and `uuid`. | Fixes need major upgrades (Nest 11+, `@nestjs/typeorm` 12). `@nestjs/core` GHSA-36xv-jgw5-4q75 only affects Server-Sent Events (`@Sse()`) and this app has none. The `uuid` advisory concerns v3/v5/v6 with a caller-supplied buffer; ids here are v4 generated internally. | Plan the Nest 11 upgrade; the CI gate (`--audit-level=high`) keeps high/critical out meanwhile. |
| 6 | The Android release build is signed with the debug key. | Needs a keystore. | See [DEPLOYMENT.md](DEPLOYMENT.md#configuration). |
| 7 | Grafana is published on all interfaces by default (login required, sign-up disabled, password set by Ansible). | Changing the default could lock current users out of dashboards. | Set `GRAFANA_BIND=127.0.0.1` and use an SSH tunnel, or firewall port 3001. |
| 8 | Image URLs in recipes/comments/reviews are free-form strings (a client may point at any host). | The app also uses external image URLs. | If it becomes a concern, restrict to `/uploads/...` and an allow-list of hosts. |
| 9 | TLS terminates on the VM (Caddy, `docs/DEPLOYMENT.md#https`). The backend listens on localhost only, but the network firewall rules (Azure NSG) are set by hand, not by this repo. | Not manageable from the repo. | Once HTTPS works, close TCP 3000 in the network firewall and keep only 22, 80 and 443. Restrict 22 to known IPs if they are stable. |

## Reporting

Treat anything that exposes another user's data or lets someone act as another user as urgent; rotate `JWT_SECRET` (all sessions end) if tokens may have leaked.
