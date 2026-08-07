#!/usr/bin/env bash
# Catches the dev database's silent backend crashes in the act.
#
# The container's Postgres intermittently logs "server process (PID n) exited
# with exit code 2" and restarts the whole cluster. The dying PID logs nothing —
# no statement, no error, no signal.
#
# Leading theory, evidenced rather than assumed: shared-VM disk contention, not
# a namma-kasa bug. This machine runs several unrelated projects' docker compose
# stacks on one colima VM (4 CPU / 10GiB, virtiofs-backed). The densest crash
# cluster on 2026-08-06 (six crashes in three minutes) exactly overlapped another
# project's ten-container stack being created from cold — image work, a dozen
# processes starting, migrations — and namma-kasa's own log shows the damage
# directly: "autovacuum worker took too long to start; canceled" at the same
# minute, and checkpoint writes of a few hundred buffers (normally sub-second)
# taking 20-40 seconds, both then and as recently as the following night. That
# is I/O queue starvation, not a slow query or a resource limit — nothing here
# was CPU-bound. Sixteen isolated seeded-vitest runs, with nothing else on the
# VM churning, produced zero crashes, which fits: namma-kasa alone doesn't
# generate the contention, only sharing the disk with a concurrent stack does.
#
# This script still earns its keep as an independent check: it names the
# client behind the next dead PID rather than assuming the cause. If the next
# capture shows the crash landing with no other stack in mid-startup on the
# host, that reopens the question.
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
