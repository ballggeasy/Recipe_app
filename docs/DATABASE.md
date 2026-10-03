# Database

SQLite through TypeORM. The file lives at `DB_PATH` (default `./data/app.sqlite`; `/app/data/app.sqlite` in Docker, on the named volume `data`).

## The schema is owned by migrations

`synchronize` is **off**. On every start TypeORM runs the migrations that have not been applied yet (`migrationsRun: true`), then the seed inserts sample recipes into an empty catalog. Applied migrations are recorded in the `migrations` table.

| Migration | What it does |
|-----------|--------------|
| `1790985600000-InitialSchema` | The schema `synchronize` used to create. Every statement is `IF NOT EXISTS`, so on a database that already exists it does nothing. Cannot be reverted (that would drop every table). |
| `1790985700000-AddLookupIndexes` | Indexes for per-request lookups (reviews/comments by recipe, replies by review, meal plan and folders by user, recipe list order). |

### Changing the schema

1. Change the entity (`*.entity.ts`).
2. Add a migration in `src/database/migrations/` named `<timestamp>-<Description>.ts` (class `<Description><timestamp>`). Write SQL that is **safe on existing data**: add columns as nullable or with a default; never drop or rename a column in the same release that stops using it.
3. Add it to the `migrations` array in `src/database/database.config.ts` (explicit list on purpose: same behaviour under ts-node, ts-jest and the compiled `dist/`).
4. `npm test` — `test/migrations.spec.ts` fails if the entities and the migrations disagree (it asks TypeORM for pending schema changes after running all migrations), if a database made by the old `synchronize` stops upgrading cleanly, or if the hot queries lose their indexes.

SQLite note: `ALTER TABLE` is limited; changes it cannot express (dropping a column, changing a type) need the copy-table-and-rename pattern inside the migration.

## Backup and restore

Not automated yet (see ENGINEERING_REPORT, remaining debt). Manual, on the VM, with the app stopped so the file is consistent:

```bash
docker compose -p recipe-backend -f /opt/recipe-backend/repo/backend/docker-compose.yml stop backend
docker run --rm -v recipe-backend_data:/data -v "$PWD":/backup alpine tar czf /backup/data-$(date +%F).tgz -C /data .
docker run --rm -v recipe-backend_uploads:/data -v "$PWD":/backup alpine tar czf /backup/uploads-$(date +%F).tgz -C /data .
docker compose -p recipe-backend -f /opt/recipe-backend/repo/backend/docker-compose.yml start backend
```

Restore = stop, extract the archive back into the volume, start. Take a backup **before** deploying a revision that adds a migration; migrations only move forward, so the backup (plus redeploying the previous image, see [DEPLOYMENT.md](DEPLOYMENT.md)) is the way back.

## Known limits

- Lists (`/recipes`, reviews, comments) are not paginated; fine for the current catalog size, add `limit/offset` before it grows large.
- A user can post several reviews on one recipe (the app does not show errors from the review call yet, so a one-review rule would fail silently). Revisit together with the app change.
- Like toggling is read-modify-write on a JSON column; two simultaneous toggles by the same user can lose one.
