# Engineering Checklist

Legend: `[PASS]` verified by running it, `[PARTIAL]` partly done or partly verified, `[TODO]` not done, `[N/A]` does not apply.
Nothing is marked PASS without a command or test that proved it. Plan: [ENGINEERING_ROADMAP.md](ENGINEERING_ROADMAP.md). Summary: [ENGINEERING_REPORT.md](ENGINEERING_REPORT.md).

Last verified: 2026-10-03, on branch `chore/engineering-upgrade` (not pushed; CI has not run on it yet).

## Definition of done

| Item | Status | Evidence / note |
|------|--------|-----------------|
| Backend builds | [PASS] | `npm run build` |
| Frontend builds | [PARTIAL] | `flutter test` and `flutter analyze` pass; the APK build only exists as a CI job (`frontend.yml` → `build`) and has not run. The Thai checkout path also blocks a local web build. |
| Lint passes (backend) | [PASS] | `npm run lint` |
| Lint passes (frontend) | [PASS] | `flutter analyze --no-fatal-infos`: no issues (run in an ASCII-path copy, see README note) |
| Formatting passes | [PASS] | `npm run format:check`; `dart format --set-exit-if-changed lib test` |
| Backend tests | [PASS] | 37 unit + 54 e2e (baseline was 22 + 20) |
| Frontend tests | [PASS] | 99 tests (baseline was 84) |
| Authentication works | [PASS] | e2e: register, login, `/auth/me`, invalid/forged/expired-style tokens, deleted account |
| Authorization works | [PASS] | e2e with two users for recipes, folders, meal plan, comments; reviews can be liked/reported/replied to by any signed-in user by design |
| Environment configuration documented | [PASS] | `backend/.env.example`, variable table in `docs/DEPLOYMENT.md` |
| CI works | [PARTIAL] | Every command in the workflows was run locally and the YAML parses; the workflows themselves have not run on GitHub |
| Docker builds | [PARTIAL] | No Docker daemon on this machine. The build steps (`npm ci`, `npm run build`, `npm ci --omit=dev`, loading sqlite3) and the `HEALTHCHECK` command were run directly; the image build and `smoke-image.sh` run in CI |
| Health check works | [PASS] | e2e for `/health` and `/health/ready`; production-mode boot checked by hand |
| Secrets are not hardcoded | [PASS] | `git grep` scan clean, no tracked `.env`, no fallback secret in code, boot test proves production refuses placeholder/short/missing secrets |
| Error handling is reasonable | [PASS] | Uniform error filter with tests, including "500 leaks nothing" |
| Deployment process documented | [PASS] | `docs/DEPLOYMENT.md`, `ansible/README.md` |
| Rollback process documented | [PASS] | `docs/DEPLOYMENT.md#rolling-back` |
| Rollback proven | [PARTIAL] | Script logic tested against stubs (incl. mutation check); **not rehearsed on the real VM** |
| README updated | [PASS] | Root and backend README |
| Git diff reviewed | [PASS] | Each commit staged by explicit file list and checked with `git status`/`git diff --stat`; reviewed by the author only |

## Backlog status

| ID | Item | Status |
|----|------|--------|
| SEC-01 | Gate unauthenticated password reset | [PASS] e2e both default (403, password unchanged) and opt-in |
| SEC-02 | Required, validated JWT secret | [PASS] unit + e2e + manual production boot |
| SEC-03 | Uniform login failure | [PASS] unit + e2e |
| SEC-04 | Dependency vulnerabilities | [PARTIAL] 19 → 4 moderate; rest needs Nest 11+ (SECURITY.md #5) |
| SEC-05 | helmet, CORS allow-list, rate limit | [PASS] e2e (headers, 429, health exempt); CORS checked manually in production mode |
| SEC-06 | Protect `/metrics` | [TODO] deferred, options in SECURITY.md #2 |
| SEC-07 | Remove `isRecommended` mass assignment | [PASS] e2e |
| SEC-08 | Token lifetime decision | [PARTIAL] documented, not changed |
| SEC-09 | Release signing | [PARTIAL] documented; needs a keystore |
| BE-01 | Migrations | [PASS] `migrations.spec.ts` + real dev DB copy |
| BE-02 | Error filter, request id, JSON logs | [PASS] unit + e2e + manual |
| BE-03 | Readiness endpoint | [PASS] |
| BE-04 | Indexes | [PASS] query plans asserted |
| BE-05 | Referential checks | [PARTIAL] one-review-per-user not done (see roadmap outcome) |
| BE-06 | SQL aggregates, transactions | [PARTIAL] like toggle still read-modify-write |
| BE-07 | Pagination | [TODO] deferred |
| BE-08 | `viewCount` | [PASS] e2e |
| BE-09 | DTO limits | [PARTIAL] limits done; no `ParseUUIDPipe` by design |
| BE-10 | ESLint + Prettier | [PASS] |
| BE-11 | Swagger | [N/A] skipped on purpose |
| FE-01 | Load error + retry | [PASS] provider + widget tests |
| FE-02 | 401 handling | [PASS] ApiClient + provider tests |
| FE-03 | Configurable base URL | [PASS] unit tests; `--dart-define` documented |
| FE-04 | Context across async gaps | [PASS] analyzer clean |
| FE-05 | Forgot-password disabled path | [PASS] widget tests |
| FE-06 | Analyzer infos + dart format | [PASS] |
| FE-07 | Large screens | [N/A] opportunistic |
| QA-01 | Tests for untested modules | [PASS] `community.e2e-spec.ts` and others |
| CI-01 | Backend pipeline | [PARTIAL] written, commands verified locally, not run on GitHub |
| CI-02 | Frontend pipeline | [PARTIAL] same |
| CI-03 | Dependabot | [PASS] file valid; takes effect once pushed |
| CD-01 | Rollback | [PARTIAL] stub-tested, not rehearsed on the VM |
| CD-02 | Readiness smoke test | [PASS] script and image smoke test use `/health/ready` |
| OPS-01 | HEALTHCHECK, Grafana bind | [PARTIAL] HEALTHCHECK command verified; image not built here |
| DOC-01 | Docs | [PASS] |
