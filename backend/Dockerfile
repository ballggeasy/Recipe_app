# Build stage: compile TypeScript to dist/
# Debian 13 (trixie), not 12 (bookworm): the sqlite3 6 prebuilt binary needs glibc >= 2.38 and a GCC 13
# libstdc++, which bookworm (glibc 2.36) lacks, so the module fails to load there.
FROM node:25-trixie-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Runtime stage: production deps + compiled output only
FROM node:25-trixie-slim
ENV NODE_ENV=production \
    PORT=3000 \
    DB_PATH=/app/data/app.sqlite
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
# Commit SHA from CI, reported by GET /health
ARG REVISION=dev
ENV APP_REVISION=$REVISION
# Pre-create writable dirs so named volumes inherit node ownership on first mount
RUN mkdir -p data uploads/avatars && chown -R node:node data uploads
USER node
EXPOSE 3000
# Readiness probe for `docker ps` and orchestrators: unhealthy when the app or its database stops
# answering. Uses Node itself because the slim image has no curl.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD ["node", "-e", "fetch('http://127.0.0.1:' + (process.env.PORT || 3000) + '/health/ready').then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
CMD ["node", "dist/main.js"]
