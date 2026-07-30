#!/usr/bin/env bash
# Every end-to-end suite, in one run.
#
# These are the only tests that exercise the product through the interfaces a
# real user touches. Each layer below found defects the layers above it could
# not see, so the order is deliberate: API first, then the browser, then the
# device.
#
#   1. smoke.mjs      — the whole journey over HTTP/MQTT/WebSocket against a
#                       running server, with real data (34 checks)
#   2. e2e-portal.mjs — the admin portal in a real browser, signed in through
#                       the real form (11 checks)
#   3. integration_test — the resident's screens on a real device against the
#                       real backend (4 tests)
#
# Prerequisites, because these deliberately do not mock anything:
#   docker compose up -d
#   pnpm --filter @namma-kasa/api seed
#   API on :4000, portal on :3000, an Android device attached
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_URL="${API_URL:-http://localhost:4000}"
PORTAL_URL="${PORTAL_URL:-http://localhost:3000}"

fail() { echo "✗ $1" >&2; exit 1; }

curl -sf -o /dev/null "$API_URL/v1/metrics" || fail "API is not answering on $API_URL"
curl -sf -o /dev/null "$PORTAL_URL/login" || fail "portal is not answering on $PORTAL_URL"

echo "════ 1/3  Live smoke test (API, MQTT, WebSocket)"
(cd "$ROOT/apps/api" && node scripts/smoke.mjs "$API_URL")

echo
echo "════ 2/3  Portal in a real browser"
node "$ROOT/scripts/e2e-portal.mjs" "$PORTAL_URL" "$API_URL/v1"

echo
echo "════ 3/3  Mobile on a real device"
# Never guess the device. Grabbing the first attached one will happily install
# onto somebody else's emulator if two are running — set ANDROID_SERIAL, or be
# told which single device was found.
ATTACHED="$(adb devices | awk '/\tdevice$/{print $1}')"
COUNT="$(printf '%s\n' "$ATTACHED" | grep -c . || true)"

if [ -n "${ANDROID_SERIAL:-}" ]; then
  DEVICE="$ANDROID_SERIAL"
elif [ "$COUNT" -eq 1 ]; then
  DEVICE="$ATTACHED"
elif [ "$COUNT" -eq 0 ]; then
  DEVICE=""
else
  fail "$COUNT devices attached ($(echo $ATTACHED | tr '\n' ' ')). Set ANDROID_SERIAL to choose one."
fi

if [ -z "$DEVICE" ]; then
  echo "  … skipped: no Android device attached"
else
  echo "  device: $DEVICE"
  (cd "$ROOT/apps/mobile" && flutter test integration_test -d "$DEVICE")
fi

echo
echo "All end-to-end suites passed."
