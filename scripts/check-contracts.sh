#!/usr/bin/env bash
# Fails when contracts/openapi.json on disk disagrees with the Zod schemas,
# i.e. someone changed a contract without regenerating. Wired into CI via
# `pnpm contracts:check`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT/contracts/openapi.json"

BEFORE="$(cat "$SPEC" 2>/dev/null || echo "")"
pnpm --filter @namma-kasa/api openapi >/dev/null
AFTER="$(cat "$SPEC")"

if [ "$BEFORE" != "$AFTER" ]; then
  echo "contracts/openapi.json is out of date with the Zod schemas." >&2
  echo "Run: pnpm contracts:generate && commit the result." >&2
  exit 1
fi

echo "Contract is in sync."
