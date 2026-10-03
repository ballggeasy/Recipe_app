# Architecture

A recipe app: a Flutter client (`frontend/`) talking JSON over HTTP to a NestJS API (`backend/`) that stores data in SQLite. The VM that runs it is described in [DEPLOYMENT.md](DEPLOYMENT.md).

```
Flutter app ──HTTP/JSON──▶ NestJS API ──TypeORM──▶ SQLite file (+ uploads folder)
                              │
                              └─ /metrics ─▶ Prometheus ─▶ Grafana
```

## Backend (`backend/src`)

One Nest module per feature; each follows the same shape:

```
Controller   thin: routes, DTO validation, guards, no rules
   ↓
Service      the rules: ownership checks, referential checks, transactions
   ↓
Repository   TypeORM repository (Repository<Entity>) — no hand-written data layer on top
   ↓
SQLite       schema owned by migrations (docs/DATABASE.md)
```

| Module | Responsibility |
|--------|----------------|
| `auth`, `users` | Register/login, JWT (`passport-jwt`), profile, avatar, change password, delete account |
| `recipes` | Catalog (public read, owner-only write), image upload, view counter |
| `favorites` | Favorite recipes and folders (per user) |
| `reviews` | Ratings with likes/replies; recomputes the recipe's average in a transaction |
| `comments` | Threaded comments (reply must be in the same recipe) |
| `meal-plan` | A user's planned meals |
| `seed` | Inserts the 16 sample recipes into an empty database |
| `metrics`, `health` | Prometheus `/metrics`; `/health` (liveness + revision), `/health/ready` (database) |
| `database`, `config`, `common` | Migrations and connection options; env validation; shared filter, logger, rate limits, upload helpers |

Cross-cutting behaviour is configured once in `src/app.setup.ts` and used by both `main.ts` and the e2e tests, so tests run against the real HTTP setup:

```
request → request id → (access log) → helmet → CORS → rate limit → ValidationPipe → JwtAuthGuard
        → controller → service → repository
errors  → AllExceptionsFilter → { statusCode, error, message, requestId, path, timestamp }
```

Conventions:
- **Authorization lives in services** (compare `uploaderId` / `userId` with the caller). Another user's private resource answers 404 (folders) or 403 (recipes, meal plan, comments).
- **401 means "your session is not valid"**, nothing else. The app logs the user out on 401, so business failures (wrong current password) use 400.
- User-supplied text and lists have size limits (`common/limits.ts`); unknown fields are rejected (`forbidNonWhitelisted`).
- Responses never include `passwordHash`; only `SafeUser` leaves the auth module. Unexpected errors become a generic 500; the real error is logged with the request id.

## Frontend (`frontend/lib`)

```
screens / widgets   UI only
   ↓ context.watch / read
providers           ChangeNotifier per feature: state, filtering, error + loading flags
   ↓
services            one class per API area (auth, recipe, review, ...): typed models in/out
   ↓
api_client.dart     base URL (API_BASE_URL), JWT header, error mapping, 401 → logout hook
```

- `models/` are plain typed classes with `fromApi` / `toJson`.
- No screen talks to the HTTP client; providers are constructed with injectable services, which is how the tests substitute a fake API (`test/helpers/fake_api.dart`).
- Loading, error (with retry) and empty states exist for the recipe list; other lists degrade to empty on error.
- The auth token is kept in `SharedPreferences` (see [SECURITY.md](SECURITY.md) for the trade-off).

## Decisions worth knowing

- **SQLite** is a deliberate fit for a single VM and one writer; moving to PostgreSQL would be a data-source change plus new migrations, not a rewrite.
- **`provider`** was kept (no state-management swap): the existing structure is consistent and well tested.
- **Pull-based deploy**: nothing in GitHub can run code on the VM; it pulls images CI built from `main` after tests passed.
