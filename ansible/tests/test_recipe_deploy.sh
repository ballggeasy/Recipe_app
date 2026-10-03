#!/usr/bin/env bash
# Behaviour tests for the deploy script (roles/deploy_agent/templates/recipe-deploy.sh.j2).
# The template is rendered with sed and run against stub docker/git/curl/sleep commands, so the
# deploy, rollback, "skip a failed revision" and pin logic are exercised without a VM or Docker.
#   usage: bash ansible/tests/test_recipe_deploy.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${DEPLOY_TEMPLATE:-$HERE/../roles/deploy_agent/templates/recipe-deploy.sh.j2}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

APP="$WORK/app"
BIN="$WORK/bin"
FAKE="$WORK/fake"
mkdir -p "$APP/repo/backend" "$BIN" "$FAKE"
echo "JWT_SECRET=x" > "$APP/.env"
touch "$APP/repo/backend/docker-compose.yml"

# --- render the Jinja template (only plain variables and raw blocks are used) ---
sed -e 's/{{ ansible_managed }}/test/' \
  -e 's/{{ deploy_user }}/tester/g' \
  -e "s#{{ backend_image_repo }}#ghcr.io/example/recipe-backend#" \
  -e "s#{{ deploy_repo_dir }}#$APP/repo#" \
  -e "s#{{ app_env_file }}#$APP/.env#" \
  -e "s#{{ app_dir }}#$APP#g" \
  -e '/{% raw %}/d' -e '/{% endraw %}/d' \
  "$TEMPLATE" > "$WORK/recipe-deploy"
if grep -q '{{ [a-z_]* }}\|{%' "$WORK/recipe-deploy"; then
  echo "unrendered template markers left in script:"; grep -n '{{ [a-z_]* }}\|{%' "$WORK/recipe-deploy"; exit 1
fi
bash -n "$WORK/recipe-deploy" || exit 1

# --- stubs ---
cat > "$BIN/docker" << 'EOF'
#!/usr/bin/env bash
echo "docker $*" >> "$FAKE/calls.log"
case "$1" in
  pull) ;;
  image)
    if [[ "$2" == "inspect" ]]; then cat "$FAKE/latest"; fi ;;
  images) cat "$FAKE/local-images" 2> /dev/null || true ;;
  compose)
    if [[ " $* " == *" up "* ]]; then
      echo "up $BACKEND_IMAGE" >> "$FAKE/calls.log"
      echo "${BACKEND_IMAGE##*sha-}" > "$FAKE/running"
    fi ;;
esac
exit 0
EOF
cat > "$BIN/git" << 'EOF'
#!/usr/bin/env bash
echo "git $*" >> "$FAKE/calls.log"
EOF
cat > "$BIN/sleep" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
# curl: a revision is healthy unless listed in $FAKE/unhealthy; revisions in $FAKE/legacy predate /health/ready
cat > "$BIN/curl" << 'EOF'
#!/usr/bin/env bash
url="${*: -1}"
rev="$(cat "$FAKE/running" 2> /dev/null || true)"
if grep -qx "$rev" "$FAKE/unhealthy" 2> /dev/null; then
  [[ "$*" == *"-w"* ]] && { printf 503; exit 0; }
  exit 22
fi
if [[ "$url" == */health/ready ]]; then
  if grep -qx "$rev" "$FAKE/legacy" 2> /dev/null; then printf 404; else printf 200; fi
  exit 0
fi
exit 0
EOF
chmod +x "$BIN"/*

export PATH="$BIN:$PATH" FAKE
failures=0
check() { # check <description> <expected> <actual>
  if [[ "$2" == "$3" ]]; then echo "ok   - $1"; else echo "FAIL - $1 (expected '$2', got '$3')"; failures=$((failures + 1)); fi
}
state() { cat "$APP/$1" 2> /dev/null || echo "-"; }
ups() { grep -c '^up ' "$FAKE/calls.log" 2> /dev/null || true; }
run() { : > "$FAKE/calls.log"; bash "$WORK/recipe-deploy" "$@" > "$WORK/out.log" 2>&1; echo $?; }
reset() { rm -f "$APP"/.*-revision "$FAKE"/{running,unhealthy,legacy,local-images}; : > "$FAKE/calls.log"; }

echo "--- first deploy"
reset; echo "aaa" > "$FAKE/latest"
check "exit code" 0 "$(run)"
check "deployed revision recorded" aaa "$(state .deployed-revision)"
check "uses the immutable sha tag" "up ghcr.io/example/recipe-backend:sha-aaa" "$(grep '^up ' "$FAKE/calls.log")"
check "no previous revision yet" - "$(state .previous-revision)"

echo "--- same image again does nothing"
check "exit code" 0 "$(run)"
check "no compose up" 0 "$(ups)"

echo "--- new healthy revision"
echo "bbb" > "$FAKE/latest"
check "exit code" 0 "$(run)"
check "current is bbb" bbb "$(state .deployed-revision)"
check "previous is aaa" aaa "$(state .previous-revision)"

echo "--- new unhealthy revision rolls back"
echo "ccc" > "$FAKE/latest"; echo "ccc" > "$FAKE/unhealthy"
check "exit code is failure" 1 "$(run)"
check "still recorded as bbb" bbb "$(state .deployed-revision)"
check "ccc remembered as failed" ccc "$(state .failed-revision)"
check "bbb is what runs" bbb "$(cat "$FAKE/running")"
check "ups: ccc then rollback to bbb" "up ghcr.io/example/recipe-backend:sha-ccc
up ghcr.io/example/recipe-backend:sha-bbb" "$(grep '^up ' "$FAKE/calls.log")"

echo "--- the failed revision is not retried"
check "exit code" 0 "$(run)"
check "no compose up" 0 "$(ups)"

echo "--- a newer healthy revision deploys and clears the failure"
echo "ddd" > "$FAKE/latest"
check "exit code" 0 "$(run)"
check "current is ddd" ddd "$(state .deployed-revision)"
check "failure forgotten" - "$(state .failed-revision)"

echo "--- manual rollback pins the revision"
check "exit code" 0 "$(run --revision bbb)"
check "current is bbb" bbb "$(state .deployed-revision)"
check "pinned to bbb" bbb "$(state .pinned-revision)"
echo "eee" > "$FAKE/latest"
check "automatic run is skipped while pinned" 0 "$(run)"
check "no compose up while pinned" 0 "$(ups)"
check "unpin" 0 "$(run --unpin)"
check "automatic deploys resume" 0 "$(run)"
check "current is eee" eee "$(state .deployed-revision)"

echo "--- a failing manual deploy stays on the known-good revision"
echo "fff" > "$FAKE/unhealthy"
check "exit code is failure" 1 "$(run --revision fff)"
check "running eee again" eee "$(cat "$FAKE/running")"
check "pinned to the good revision, not the failed one" eee "$(state .pinned-revision)"
check "manual failures are not remembered as failed" - "$(state .failed-revision)"

echo "--- images without /health/ready are judged by /health"
reset; echo "old" > "$FAKE/legacy"; echo "old" > "$FAKE/latest"
check "legacy image deploys" 0 "$(run)"
check "legacy image recorded" old "$(state .deployed-revision)"

echo "--- first deploy that fails has nothing to roll back to"
reset; echo "bad" > "$FAKE/latest"; echo "bad" > "$FAKE/unhealthy"
check "exit code is failure" 1 "$(run)"
check "nothing recorded as deployed" - "$(state .deployed-revision)"
check "message says there is no previous revision" 1 "$(grep -c 'no previous revision' "$WORK/out.log")"

echo "--- old images are cleaned up, keeping current and previous"
reset; echo "r2" > "$FAKE/latest"; echo "r1" > "$APP/.deployed-revision"
printf '%s\n' ghcr.io/example/recipe-backend:latest ghcr.io/example/recipe-backend:sha-r0 \
  ghcr.io/example/recipe-backend:sha-r1 ghcr.io/example/recipe-backend:sha-r2 > "$FAKE/local-images"
run > /dev/null
check "removes only the image older than the previous one" "docker rmi ghcr.io/example/recipe-backend:sha-r0" "$(grep '^docker rmi' "$FAKE/calls.log")"

echo "--- bad usage"
check "unknown flag exits 2" 2 "$(run --bogus)"

if [[ $failures -gt 0 ]]; then echo "$failures check(s) failed"; exit 1; fi
echo "all deploy script checks passed"
