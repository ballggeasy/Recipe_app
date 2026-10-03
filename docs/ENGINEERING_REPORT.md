# Engineering Report

Branch `chore/engineering-upgrade` (27 commits on top of `main`), 2026-10-03. Nothing is pushed or deployed.

## Executive Summary

The app was already tidy (thin controllers, tests, a working pull-based deploy). The audit found problems that mattered more than structure:

1. **Anyone could reset anyone's password** (`POST /auth/reset-password` took an email and a new password, no proof of identity) and could list which emails were registered.
2. **The server booted with a public default JWT secret** if `JWT_SECRET` was missing, which lets anyone forge tokens. A second bug hid behind it: `JwtModule` read the secret before `.env` was loaded, so a secret set only in `.env` was ignored when signing.
3. 19 vulnerable dependencies (1 critical, 8 high), no rate limiting, open CORS, no security headers.
4. `synchronize: true` on the production database, no migrations, no indexes.
5. A failed deploy left the broken version running with no way back.

All of these are fixed or consciously handled (below). Tests went from 126 to 190, lint/format/audit/Docker/compile checks were added to CI, and operations are documented.

**What still needs a human** (not fakeable from a repo): a real password-reset email flow needs SMTP credentials; the first push is the first real CI run; one rollback rehearsal on the VM; a release keystore for Android; a database backup routine. See [Remaining Technical Debt](#remaining-technical-debt).

**Behaviour changes to know before deploying**
- "Forgot password" no longer works for users (it was the vulnerability). The screen shows "reset is not enabled, contact the admin".
- `JWT_SECRET` must be set (the VM already has a 64-char one from Ansible).
- Production sends no CORS headers unless `CORS_ORIGINS` is set (matters only for a Flutter *web* build served from another origin).
- Login answers `อีเมลหรือรหัสผ่านไม่ถูกต้อง` for both failures; a wrong current password in change-password is `400` (was `401`).
- Limits: 10 login/register/password calls per minute per IP, 120 requests per minute otherwise.
- Existing databases and sessions keep working (migration baseline is a no-op on them; the secret is unchanged).

## Architecture Before

Controller → service → TypeORM → SQLite already; Flutter provider → service → ApiClient. Cross-cutting concerns were scattered: HTTP setup duplicated between `main.ts` and the e2e tests, secrets read from `process.env` in three places, Nest default errors and logger, schema auto-altered on boot.

## Architecture After

Same layering (it was right-sized), plus: `app.setup.ts` shared by `main.ts` and the tests; `ConfigService` + boot validation; migrations; a global exception filter and request ids; rate limiting; readiness endpoint; deploy with rollback. See [ARCHITECTURE.md](ARCHITECTURE.md).

## NestJS Improvements

- Config: required, validated `JWT_SECRET`; async `JwtModule`; no literals.
- HTTP: helmet, CORS allow-list, trust-proxy option, rate limits (global and strict on credential endpoints), uniform errors, `X-Request-Id`, JSON access log without query/headers/bodies, JSON logger in production.
- Auth: password reset gated, login enumeration closed, 401/400 semantics fixed.
- Data rules: references to missing recipes rejected (reviews, comments, favorites, folders, meal plan); reply must belong to the same recipe; rating aggregate computed in SQL in a transaction; `isRecommended` no longer user-settable; view counter; size limits on all inputs.
- Tooling: ESLint + Prettier (`npm run lint`, `format:check`).

## Flutter Improvements

- Recipe list: loading state, error state with retry, a failed refresh keeps what is on screen (previously a failure looked like "no results").
- Session: a 401 on an authenticated call clears the token and returns to login.
- `API_BASE_URL` via `--dart-define` instead of editing source.
- Latent crash fixed (`BuildContext` after awaits in the profile screen); analyzer clean (8 infos → 0); code formatted and format enforced in CI.
- Forgot-password screen handles the disabled endpoint.
- Not changed on purpose: state management (`provider`), folder structure, the large screens (opportunistic refactor only).

## Database Improvements

Migrations instead of `synchronize` (baseline is `IF NOT EXISTS`; verified against a copy of the real dev database: data kept, schema identical); a test that fails when entities and migrations drift; seven indexes for the hot lookups with query plans asserted; transactional rating update. Docs: [DATABASE.md](DATABASE.md).

## Testing Improvements

| | Before | After |
|-|--------|-------|
| Backend unit | 22 | 37 |
| Backend e2e | 20 | 54 |
| Flutter | 84 | 99 |

New coverage: favorites/folders, reviews, comments, meal plan, profile, change password, avatar validation, cross-user authorization, orphan-reference rejection, rating aggregation, error shape and request ids, security headers, rate limiting, readiness, config validation, migrations and drift, JSON logger, exception filter, forged-token rejection, the disabled and enabled password-reset paths, 401 handling, retry state, base URL. Deploy script: 40 behavioural checks against stubs (and a mutation check that they catch a broken rollback).

## CI/CD Improvements

- Backend: lint, format, build, unit, e2e, `npm audit` (high/critical), **Docker build + smoke test on pull requests** (before, a broken Dockerfile was found after merge), publish only from `main` after all checks; the smoke test also proves the image refuses to start without `JWT_SECRET`; superseded PR runs are cancelled.
- Frontend: format check, analyze, tests, Android debug APK build.
- Ansible: syntax, lint, deploy-script tests. Dependabot for npm, pub, Docker, Actions.
- Deploy: immutable `sha-<commit>` tags, readiness-based check, automatic rollback, failed-revision memory, manual `--revision`/`--unpin`, old-image cleanup. Docs: [DEPLOYMENT.md](DEPLOYMENT.md).

## Security Improvements

See the table in [SECURITY.md](SECURITY.md). Headlines: account takeover closed, forgeable tokens closed, enumeration closed, brute force limited, dependencies 19 → 4 moderate (reachability analysed), uploads/inputs bounded, secrets handling enforced at boot and in CI.

## Observability Improvements

`/health` (liveness + revision), `/health/ready` (DB), Docker `HEALTHCHECK`, request ids end to end, structured logs, errors logged with stack and request id server-side only. Existing Prometheus/Grafana kept.

## Performance Improvements

Targeted, not speculative: indexes on the per-request lookups (verified with `EXPLAIN QUERY PLAN`), SQL `AVG/COUNT` instead of loading every review, atomic view counter. No benchmarks were run; the catalog is small. Pagination is deferred.

## Documentation Improvements

README refresh (config, `--dart-define`, lint/format, docs index, Windows path caveat), backend README (health, error format, status semantics), and new ARCHITECTURE, DATABASE, DEPLOYMENT (variables, health, rollback runbook), SECURITY (controls, accepted risks) documents.

## Final review (fresh eyes, by role)

- **Architect**: layering is consistent and unchanged; new cross-cutting code is in one place (`app.setup.ts`, `common/`). `reviews.service` touches the `Recipe` entity directly for the transaction: acceptable, flagged here.
- **Backend**: errors, validation, ownership and transactions are uniform; two known weak spots (like toggle race, no pagination) are documented.
- **Flutter**: error and session handling are now explicit; many screens still swallow API errors silently (e.g. reviews, comments) and show nothing to the user. Worth a pass, and a prerequisite for a "one review per user" rule.
- **DevOps**: pipeline is complete on paper and each command was run locally; **the first push is the first true run** and may need small fixes (APK build, Docker steps). Rollback is stub-tested only.
- **Security**: highest-impact holes closed; open items listed with owners' decisions needed (SMTP, `/metrics` exposure).
- **QA**: critical flows and authorization are covered; no browser/device integration tests exist (not added: they would need an emulator or browser in CI).
- **New developer**: can run, test, configure, deploy and roll back from README + docs; the Thai-path analyzer problem is called out.

## Remaining Technical Debt

| Item | Why it is open |
|------|----------------|
| Real password reset (emailed token) | Needs SMTP credentials and a sender domain |
| `/metrics` reachable from outside | Needs VM provisioning change (reverse proxy or token + Prometheus credentials) |
| 4 moderate advisories | Need Nest 11+ / `@nestjs/typeorm` 12 upgrade |
| Rollback not rehearsed on the VM; CI not yet run on GitHub | Needs a push and VM access |
| Backups not automated | Procedure documented ([DATABASE.md](DATABASE.md)); needs a scheduler and a destination |
| Pagination | Contract change for the app |
| One review per user per recipe | Needs the app to surface review errors first |
| Silent error handling in several providers | UI work |
| Token storage (`SharedPreferences`), 7-day non-revocable JWT | Needs refresh-token flow / secure storage decision |
| Android release signing | Needs a keystore |
| Large screens (`detail_screen` 729 lines, `home_screen` 600+) | Refactor only when touched |
| No browser/device integration tests | Needs emulator infrastructure |

## Production Readiness Checklist

- [PASS] Secrets: none in git; mandatory, validated JWT secret
- [PASS] Authentication and authorization tested end to end
- [PASS] Input validation and size limits
- [PASS] Rate limiting on credential endpoints
- [PASS] Error handling uniform, nothing internal leaked
- [PASS] Health and readiness endpoints, image healthcheck
- [PASS] Structured logs with request ids
- [PASS] Schema under migrations, existing DB upgrade verified
- [PASS] Lint, format, build and tests pass locally (backend and Flutter)
- [PASS] Environment and deployment documented, rollback documented
- [PARTIAL] CI: all steps verified locally, not yet executed on GitHub
- [PARTIAL] Docker image: build steps verified, image build and smoke run in CI only
- [PARTIAL] Rollback: stub-tested, not rehearsed on the VM
- [PARTIAL] Dependencies: no high/critical; 4 moderate documented
- [TODO] Password reset for real users
- [TODO] Protect `/metrics`
- [TODO] Automated backups
- [TODO] Pagination
- [N/A] OpenAPI/Swagger (skipped deliberately)
