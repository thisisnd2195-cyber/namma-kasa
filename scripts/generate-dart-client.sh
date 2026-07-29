#!/usr/bin/env bash
# Regenerates the Flutter app's API client from contracts/openapi.json.
#
# Constitution Principle IV: the backend owns the contract and Flutter consumes
# a generated client. Hand-editing anything under apps/mobile/lib/src/api is a
# defect — change the Zod schema and re-run this instead.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT/contracts/openapi.json"
# A generated package, consumed by the app as a path dependency. It lives
# outside lib/ because a nested package inside lib/ breaks Dart's layout rules.
OUT="$ROOT/apps/mobile/packages/namma_kasa_api"

# Homebrew's openjdk is keg-only, so make it visible without touching the shell profile.
if [ -d /opt/homebrew/opt/openjdk/bin ]; then
  export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
fi

if ! command -v java >/dev/null 2>&1; then
  echo "java is required by openapi-generator. Install it with: brew install openjdk" >&2
  exit 1
fi

echo "Emitting OpenAPI document…"
pnpm --filter @namma-kasa/api openapi >/dev/null

# The plain `dart` generator emits self-contained models with hand-rolled
# serialisation. dart-dio was rejected: it needs a second build_runner pass plus
# json_serializable and copy_with_extension, for no gain at this contract size.
echo "Generating Dart client into ${OUT#"$ROOT/"}…"
rm -rf "$OUT"
pnpm dlx @openapitools/openapi-generator-cli generate \
  --generator-name dart \
  --input-spec "$SPEC" \
  --output "$OUT" \
  --additional-properties=pubName=namma_kasa_api \
  --global-property=apiTests=false,modelTests=false,apiDocs=false,modelDocs=false \
  >/dev/null

echo "Done. Generated code is excluded from our lints (see analysis_options.yaml)."
