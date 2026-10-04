# Load test

[k6](https://k6.io) script for the read endpoints (recipe list and detail, which also counts a view = a database write) plus a register/login mix every tenth iteration (bcrypt, CPU bound).

```bash
k6 run -e BASE_URL=http://localhost:3000 -e VUS=150 -e HOLD=30s loadtest/recipes.js
```

`VUS` is the number of concurrent virtual users (default 50), `HOLD` how long to stay at that level (default 30s). Thresholds: under 1% failed requests and a p95 under 800 ms.

## Only on your own machine

Run it against a local stack, not against production:

- The default rate limits (120 requests per minute per client, 10 for login/register) answer `429` after a few seconds, which measures the limiter, not the server. For a local test put `RATE_LIMIT_PER_MINUTE=1000000` and `AUTH_RATE_LIMIT_PER_MINUTE=1000000` in the env file. Never do that on the VM.
- It registers a few hundred throwaway accounts (`load-*@example.test`).

## Compare one replica with several

```bash
cd backend
printf 'JWT_SECRET=local-load-test-secret-0123456789-abcdefghijklmnopqrstuvwxyz\nGRAFANA_ADMIN_PASSWORD=x\nRATE_LIMIT_PER_MINUTE=1000000\nAUTH_RATE_LIMIT_PER_MINUTE=1000000\n' > /tmp/lb.env
export BACKEND_ENV_FILE=/tmp/lb.env HOST_PORT=8080
dc() { docker compose -p lbtest --env-file "$BACKEND_ENV_FILE" -f docker-compose.yml "$@"; }

dc up -d --build nginx                              # migrate, then the replicas, then nginx
dc up -d --no-build --no-deps --scale backend=1 backend
k6 run -e BASE_URL=http://localhost:8080 -e VUS=150 loadtest/recipes.js
dc up -d --no-build --no-deps --scale backend=3 backend
k6 run -e BASE_URL=http://localhost:8080 -e VUS=150 loadtest/recipes.js
dc down -v
```

Which replica served a request: `dc logs nginx | grep -o 'upstream=[0-9.:]*' | sort | uniq -c`.

## What it showed

Windows 11, Docker Desktop (12 CPUs shared with k6), 150 virtual users, 30 s at peak, two runs each:

| Replicas | Requests/s | Average | p95 | Failed |
|---------:|-----------:|--------:|----:|-------:|
| 1 | 93 - 108 | 1.06 - 1.26 s | 1.9 - 2.2 s | 0% |
| 3 | 184 - 190 | 0.57 - 0.60 s | 1.6 - 1.9 s | 0% |

About 1.8 times the throughput and half the average latency. The p95 barely moves because it is set by the registrations and logins (bcrypt), which queue behind each other on the one SQLite write lock. Numbers from a laptop; the VM has 2 vCPUs and will differ.

The first version of this test, before transactions were made to start with `BEGIN IMMEDIATE`, answered 7.5% of requests with `SQLITE_BUSY` (see `src/database/immediate-transactions.ts`). Keep an eye on the backend logs for `SQLITE_BUSY` when you change anything that writes.
