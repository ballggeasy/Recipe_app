# Build stage: compile TypeScript to dist/
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Runtime stage: production deps + compiled output only
FROM node:22-bookworm-slim
ENV NODE_ENV=production \
    PORT=3000 \
    DB_PATH=/app/data/app.sqlite
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
# Pre-create writable dirs so named volumes inherit node ownership on first mount
RUN mkdir -p data uploads/avatars && chown -R node:node data uploads
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
