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
# adb is what finds the device, and Android Studio does not put it on PATH. Same
# story as the JDK below: resolve it here rather than let the suite depend on the
# caller's shell. A genuinely missing SDK is a skip, not a failure — under
# `set -e` an unresolved `adb` would otherwise abort the whole run with 127
# *after* the API and portal legs had already passed.
if ! command -v adb >/dev/null 2>&1; then
  for candidate in \
    "${ANDROID_HOME:-}/platform-tools" \
    "${ANDROID_SDK_ROOT:-}/platform-tools" \
    "$HOME/Library/Android/sdk/platform-tools"; do
    [ -x "$candidate/adb" ] && export PATH="$candidate:$PATH" && break
  done
fi

# Never guess the device. Grabbing the first attached one will happily install
# onto somebody else's emulator if two are running — set ANDROID_SERIAL, or be
# told which single device was found.
if command -v adb >/dev/null 2>&1; then
  SKIP_REASON="no Android device attached"
  ATTACHED="$(adb devices | awk '/\tdevice$/{print $1}')"
else
  SKIP_REASON="adb not found — install Android platform-tools or set ANDROID_HOME"
  ATTACHED=""
fi
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
  echo "  … skipped: $SKIP_REASON"
else
  # Gradle needs a JDK, and "Unable to locate a Java Runtime" is a confusing way
  # to be told the suite depends on the caller's shell. Resolve it here instead.
  if [ -z "${JAVA_HOME:-}" ]; then
    for candidate in \
      "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
      /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home; do
      [ -x "$candidate/bin/java" ] && export JAVA_HOME="$candidate" && break
    done
  fi
  [ -n "${JAVA_HOME:-}" ] || fail "no JDK found — set JAVA_HOME (Android Gradle needs JDK 17)"
  export PATH="$JAVA_HOME/bin:$PATH"

  echo "  device: $DEVICE"
  echo "  jdk:    $JAVA_HOME"
  (cd "$ROOT/apps/mobile" && flutter test integration_test -d "$DEVICE")
fi

echo
echo "All end-to-end suites passed."
