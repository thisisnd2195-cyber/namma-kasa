#!/usr/bin/env bash
# Catches the dev database's silent backend crashes in the act.
#
# The container's Postgres intermittently logs "server process (PID n) exited
# with exit code 2" and restarts the whole cluster. The dying PID logs nothing —
# no statement, no error, no signal — and exit code 2 is _exit(2), the SIGQUIT
# path, not an error Postgres chose to report. Every crash so far has landed
# inside a window when the vitest suite was being run repeatedly; idle hours and
# whole e2e runs have never produced one.
#
# So this does two things, every couple of seconds:
#   1. snapshots pg_stat_activity, so the connection behind the next dead PID is
#      on record even though the PID itself never logs (log_connections=on makes
#      the server log its arrival too — set it once with:
#        ALTER SYSTEM SET log_connections = on; SELECT pg_reload_conf();)
#   2. watches the container log for the crash line, and on seeing one freezes
#      the last minute of snapshots beside the surrounding server log
#
# Usage: scripts/db-crash-watch.sh [output-dir]     (default /tmp/nk-db-crash)
# Leave it running while doing whatever normally provokes the crash, e.g.
#   cd apps/api && for i in 1 2 3; do pnpm seed && pnpm test; done
# Reports land in the output dir as crash-<timestamp>.log.
set -euo pipefail

CONTAINER="${CONTAINER:-namma-kasa-db-1}"
OUT="${1:-/tmp/nk-db-crash}"
mkdir -p "$OUT"
SNAP="$OUT/activity.log"

echo "watching $CONTAINER; snapshots → $SNAP, crash reports → $OUT/"

LAST_CHECK="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
while :; do
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Who is connected right now. The watcher's own psql shows up too; it names
  # itself so it can be told apart from the client under suspicion.
  docker exec "$CONTAINER" psql -U nammakasa -d nammakasa -qAtF' | ' -c "
    SELECT '$TS', pid, usename, application_name,
           coalesce(client_addr::text, 'local'), state,
           to_char(backend_start, 'HH24:MI:SS'),
           left(coalesce(query, ''), 100)
    FROM pg_stat_activity
    WHERE backend_type = 'client backend' AND pid <> pg_backend_pid()
  " >> "$SNAP" 2>/dev/null || echo "$TS | (snapshot failed — recovery in progress?)" >> "$SNAP"

  # Anything crash-shaped since the last look?
  if docker logs --since "$LAST_CHECK" "$CONTAINER" 2>&1 \
      | grep -q "exited with exit code 2"; then
    REPORT="$OUT/crash-$(date -u +%Y%m%dT%H%M%SZ).log"
    {
      echo "════ server log, three minutes around the crash"
      docker logs --since 3m "$CONTAINER" 2>&1 | tail -60
      echo
      echo "════ client connections in the minute before (watcher snapshots)"
      tail -120 "$SNAP"
    } > "$REPORT"
    echo "✗ crash captured → $REPORT"
    # The cluster is now in recovery; give it room and don't re-report the
    # same event from the next iteration's log window.
    sleep 45
  fi

  LAST_CHECK="$TS"
  sleep 2
done
