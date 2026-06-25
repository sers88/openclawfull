#!/bin/sh
# Smoke tests for the openclawfull Docker image.
#
# Runs against $IMAGE (default: openclawfull:local). If the image is missing
# and SKIP_BUILD is unset, it is built from the repo root first.
#
# Version expectations are parsed from the Dockerfile so the assertions stay
# in sync with the pinned ARGs without manual updates.

set -u

IMAGE="${IMAGE:-openclawfull:local}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERFILE="$ROOT/Dockerfile"

passes=0
fails=0

pass() { printf '  [PASS] %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf '  [FAIL] %s\n' "$1"; fails=$((fails + 1)); }

# Run a command inside the image as a plain shell (bypasses the tini/node entrypoint).
run() { docker run --rm --entrypoint sh "$IMAGE" -c "$1"; }

assert_eq() {
  # $1 label, $2 expected, $3 actual
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1 (expected [$2] got [$3])"
  fi
}

assert_contains() {
  # $1 label, $2 needle, $3 haystack
  if echo "$3" | grep -qF "$2"; then
    pass "$1"
  else
    fail "$1 (missing [$2] in [$3])"
  fi
}

# --- version pins parsed from the Dockerfile (tests stay in sync with the image) ---
YQ_VERSION=$(grep -E '^ARG YQ_VERSION=' "$DOCKERFILE" | head -1 | cut -d= -f2)
HIMALAYA_VERSION=$(grep -E '^ARG HIMALAYA_VERSION=' "$DOCKERFILE" | head -1 | cut -d= -f2)
PARAMIKO_VERSION=$(grep -oE 'paramiko==[0-9.]+' "$DOCKERFILE" | head -1 | cut -d= -f3)

if [ -z "$YQ_VERSION" ] || [ -z "$HIMALAYA_VERSION" ] || [ -z "$PARAMIKO_VERSION" ]; then
  echo "Could not parse version pins from $DOCKERFILE" >&2
  exit 2
fi

# --- build the image if it is not already available ---
if [ -z "${SKIP_BUILD:-}" ] && ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo ">> image $IMAGE not found, building from $ROOT"
  docker build -t "$IMAGE" "$ROOT" || { echo "BUILD FAILED" >&2; exit 1; }
fi

# --- gateway container lifecycle: ensure teardown even on failure ---
GATEWAY_CID=""
cleanup() {
  if [ -n "$GATEWAY_CID" ]; then
    docker rm -f "$GATEWAY_CID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

echo "== image: $IMAGE =="
echo "== pins: yq=$YQ_VERSION himalaya=$HIMALAYA_VERSION paramiko=$PARAMIKO_VERSION =="
echo

echo "[1/6] non-root user"
assert_eq "runs as uid 1000 (node)" "1000" "$(run 'id -u')"

echo "[2/6] entrypoint"
if run 'test -x /app/openclaw.mjs'; then
  pass "openclaw.mjs present & executable"
else
  fail "openclaw.mjs missing or not executable"
fi

echo "[3/6] yq"
assert_contains "yq version pinned" "$YQ_VERSION" "$(run 'yq --version' 2>&1)"

echo "[4/6] himalaya"
assert_contains "himalaya version pinned" "$HIMALAYA_VERSION" "$(run 'himalaya --version' 2>&1)"

echo "[5/6] paramiko"
assert_eq "paramiko version pinned" "$PARAMIKO_VERSION" \
  "$(run 'python3 -c "import paramiko; print(paramiko.__version__)"' 2>&1)"

echo "[6/6] gateway healthz"
GATEWAY_CID=$(docker run -d --rm --entrypoint sh -e OPENCLAW_GATEWAY_TOKEN=smoke "$IMAGE" \
  -c "exec node openclaw.mjs gateway --bind lan --port 18789 --allow-unconfigured" 2>&1) || true
if [ -n "$GATEWAY_CID" ]; then
  out=""
  i=0
  while [ "$i" -lt 30 ]; do
    out=$(docker exec "$GATEWAY_CID" curl -fsS http://127.0.0.1:18789/healthz 2>/dev/null) && break
    i=$((i + 1))
    sleep 1
  done
  if echo "$out" | grep -qF '"ok":true'; then
    pass "healthz 200 ok"
  else
    fail "healthz (got: $out)"
  fi
else
  fail "healthz (could not start gateway container)"
fi

echo
echo "== results: $passes passed, $fails failed =="
[ "$fails" -eq 0 ]
