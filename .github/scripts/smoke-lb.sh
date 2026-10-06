#!/usr/bin/env bash
# Smoke test for the load-balanced stack (nginx + several backend replicas + the migrate job).
#   usage: smoke-lb.sh <backend-image>
# 1. the stack comes up through nginx: migrate runs once, the replicas wait for it
# 2. requests are spread over every replica
# 3. with one replica stopped, requests still succeed (nginx skips it)
set -euo pipefail

IMAGE="${1:?usage: smoke-lb.sh <backend-image>}"
REPLICAS=3
PORT=8089
WORKDIR="$(mktemp -d)"
ENV_FILE="$WORKDIR/lb.env"

cat > "$ENV_FILE" <<ENV
JWT_SECRET=ci-load-balancer-test-secret-not-used-anywhere-else
GRAFANA_ADMIN_PASSWORD=ci-only
ENV

dc() {
  BACKEND_IMAGE="$IMAGE" BACKEND_ENV_FILE="$ENV_FILE" BACKEND_REPLICAS="$REPLICAS" HOST_PORT="$PORT" \
    docker compose -p lbsmoke --env-file "$ENV_FILE" -f backend/docker-compose.yml "$@"
}
cleanup() {
  dc logs --no-color --tail=40 > "$WORKDIR/logs.txt" 2>&1 || true
  dc down -v > /dev/null 2>&1 || true
}
fail() {
  echo "::error::$1"
  cat "$WORKDIR/logs.txt" 2> /dev/null || true
  exit 1
}
trap cleanup EXIT

# Only the balancer and what it needs: migrate -> backend replicas -> nginx.
dc up -d --no-build nginx > /dev/null

for _ in $(seq 1 45); do
  if curl -fsS "http://localhost:$PORT/health/ready" > /dev/null 2>&1; then break; fi
  sleep 2
done
curl -fsS "http://localhost:$PORT/health/ready" > /dev/null || { cleanup; fail "Stack did not become ready through nginx"; }
echo "OK: stack is ready through nginx"

running=$(dc ps --status running --format '{{.Service}}' | grep -c '^backend$' || true)
[[ "$running" == "$REPLICAS" ]] || { cleanup; fail "Expected $REPLICAS running replicas, got $running"; }

upstreams_seen() {
  dc logs --no-log-prefix --since "$1" nginx 2>&1 | grep 'GET /recipes ' | grep -o 'upstream=[0-9.:]*' | sort -u | wc -l
}

# 2. spread over every replica. nginx re-reads the replica addresses every 10 seconds, so a replica
# that came up after nginx started can take that long to join: keep sending until all of them were hit.
seen=0
for _ in $(seq 1 12); do
  for _ in $(seq 1 30); do curl -fsS "http://localhost:$PORT/recipes" > /dev/null; done
  seen=$(upstreams_seen 2m)
  [[ "$seen" == "$REPLICAS" ]] && break
  sleep 3
done
[[ "$seen" == "$REPLICAS" ]] || { cleanup; fail "Requests reached $seen of $REPLICAS replicas"; }
echo "OK: requests are spread over all $REPLICAS replicas"

# 3. one replica down
victim=$(dc ps --status running --format '{{.Name}}' backend | head -1)
docker stop "$victim" > /dev/null
failed=0
for _ in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT/recipes" || true)
  if [[ "$code" != "200" ]]; then
    failed=$((failed + 1))
    echo "request failed with HTTP $code"
  fi
done
[[ "$failed" == "0" ]] || { cleanup; fail "$failed of 30 requests failed while one replica was down"; }
echo "OK: no request failed with one replica down"
