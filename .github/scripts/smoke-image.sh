#!/usr/bin/env bash
# Smoke test for the backend Docker image, shared by the PR check and the publish job.
#   usage: smoke-image.sh <image> <expected-revision>
# 1. the image must refuse to start without a JWT_SECRET (no insecure fallback)
#    and its native sqlite3 module must load on the base image
# 2. started like on the VM (NODE_ENV=production is baked into the image) it must become ready
#    and report the commit it was built from
set -euo pipefail

IMAGE="${1:?usage: smoke-image.sh <image> <expected-revision>}"
REVISION="${2:?usage: smoke-image.sh <image> <expected-revision>}"
NAME="smoke-$$"
PORT=3000

if timeout 60 docker run --rm --name "${NAME}-nosecret" "$IMAGE" > /dev/null 2>&1; then
  echo "::error::Image started without JWT_SECRET; it must fail fast"
  exit 1
fi
echo "OK: image refuses to start without JWT_SECRET"

# The native SQLite binding must load on this base image. A glibc mismatch otherwise only shows up as
# TypeORM retrying the connection forever, which hides the real cause.
if ! docker run --rm --entrypoint node "$IMAGE" -e "require('sqlite3')"; then
  echo "::error::The sqlite3 native module does not load on this base image"
  exit 1
fi
echo "OK: sqlite3 native module loads"

# The image runs with NODE_ENV=production, which requires a JWT_SECRET of 32+ characters.
docker run -d --name "$NAME" -p "$PORT:3000" \
  -e JWT_SECRET=ci-smoke-test-secret-not-used-anywhere-else "$IMAGE" > /dev/null
trap 'docker rm -f "$NAME" > /dev/null 2>&1 || true' EXIT

for _ in $(seq 1 30); do
  if curl -fsS "http://localhost:$PORT/health/ready" > /dev/null \
    && curl -fsS "http://localhost:$PORT/recipes" > /dev/null \
    && curl -fsS "http://localhost:$PORT/metrics" > /dev/null \
    && curl -fsS "http://localhost:$PORT/health" | grep -q "$REVISION"; then
    echo "Image is healthy and reports revision $REVISION"
    exit 0
  fi
  sleep 2
done

docker logs "$NAME" || true
echo "::error::Image did not become healthy"
exit 1
