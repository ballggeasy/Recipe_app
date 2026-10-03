# Engineering Checklist

Legend: `[PASS]` verified by running it, `[PARTIAL]` partly done or partly verified, `[TODO]` not done, `[N/A]` does not apply.
Nothing is marked PASS without a command or test that proved it. Plan and rationale: [ENGINEERING_ROADMAP.md](ENGINEERING_ROADMAP.md).

Last updated: 2026-10-03 (after audit, before implementation).

## Definition of done

| Item | Status | Evidence / note |
|------|--------|-----------------|
| Backend builds | [PASS] | `npm run build` (baseline) |
| Frontend builds | [PARTIAL] | `flutter test` passes; no compile/build check run yet (Thai path blocks web build locally) |
| Lint passes (backend) | [TODO] | no ESLint yet (BE-10) |
| Lint passes (frontend) | [PARTIAL] | `flutter analyze`: 0 errors, 8 infos (FE-04, FE-06) |
| Formatting passes | [TODO] | backend has no Prettier; 62/70 Dart files unformatted (FE-06) |
| Backend tests | [PASS] | 22 unit + 20 e2e (baseline) |
| Frontend tests | [PASS] | 84 tests (baseline) |
| Authentication works | [PASS] | e2e register/login/me/401 (baseline) |
| Authorization works | [PARTIAL] | recipes/comments/meal-plan/folders enforced; only recipes covered by tests (QA-01) |
| Environment configuration documented | [PARTIAL] | `.env.example` exists, placeholder secret, no env table (SEC-02, DOC-01) |
| CI works | [PARTIAL] | exists; lacks lint/format/audit/PR Docker build (CI-01/02) |
| Docker builds | [TODO] | not run locally yet; CI builds on `main` only |
| Health check works | [PARTIAL] | `/health` e2e-tested; no readiness (BE-03) |
| Secrets not hardcoded | [PARTIAL] | no secrets in git, but fallback JWT secret literal in code (SEC-02) |
| Error handling reasonable | [PARTIAL] | Nest defaults; no uniform shape (BE-02) |
| Deployment process documented | [PARTIAL] | `ansible/README.md` only (DOC-01) |
| Rollback process documented | [TODO] | none exists (CD-01) |
| README updated | [TODO] | DOC-01 |
| Git diff reviewed | [TODO] | per commit |

## Backlog status

| ID | Item | Status |
|----|------|--------|
| SEC-01 | Gate unauthenticated password reset | [TODO] |
| SEC-02 | Required, validated JWT secret | [TODO] |
| SEC-03 | Uniform login failure | [TODO] |
| SEC-04 | Dependency vulnerabilities | [TODO] |
| SEC-05 | helmet, CORS allow-list, rate limit | [TODO] |
| SEC-06 | Protect `/metrics` | [TODO] |
| SEC-07 | Remove `isRecommended` mass assignment | [TODO] |
| SEC-08 | Token lifetime decision | [TODO] |
| SEC-09 | Release signing note | [TODO] |
| BE-01 | Migrations | [TODO] |
| BE-02 | Error filter, request id, JSON logs | [TODO] |
| BE-03 | Readiness endpoint | [TODO] |
| BE-04 | Indexes | [TODO] |
| BE-05 | Referential checks | [TODO] |
| BE-06 | SQL aggregates, transactions | [TODO] |
| BE-07 | Pagination | [TODO] |
| BE-08 | `viewCount` | [TODO] |
| BE-09 | DTO limits | [TODO] |
| BE-10 | ESLint + Prettier | [TODO] |
| BE-11 | Swagger | [TODO] |
| FE-01 | Load error + retry | [TODO] |
| FE-02 | 401 handling | [TODO] |
| FE-03 | Configurable base URL | [TODO] |
| FE-04 | Context across async gaps | [TODO] |
| FE-05 | Forgot-password disabled path | [TODO] |
| FE-06 | Analyzer infos + dart format | [TODO] |
| FE-07 | Large screens | [N/A] opportunistic |
| QA-01 | Tests for untested modules | [TODO] |
| CI-01 | Backend pipeline | [TODO] |
| CI-02 | Frontend pipeline | [TODO] |
| CI-03 | Dependabot | [TODO] |
| CD-01 | Rollback | [TODO] |
| CD-02 | Readiness smoke test | [TODO] |
| OPS-01 | HEALTHCHECK, Grafana bind | [TODO] |
| DOC-01 | Docs | [TODO] |
