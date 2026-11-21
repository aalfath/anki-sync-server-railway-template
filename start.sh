#!/bin/sh
# Start script for Anki Sync Server on Railway.
set -eu

# Listen on Railway's PORT (8080 if unset) on all IPv4 interfaces. (The server
# formats host:port without brackets, so an IPv6 host such as "::" won't bind.)
export SYNC_PORT="${PORT:-${SYNC_PORT:-8080}}"
export SYNC_HOST="${SYNC_HOST:-0.0.0.0}"

# All collections and media are stored on the volume.
export SYNC_BASE="${SYNC_BASE:-/anki_data}"
mkdir -p "$SYNC_BASE"

# First account: built from ANKI_USERNAME and ANKI_PASSWORD (the template
# generates the password), unless SYNC_USER1 is set explicitly. Extra accounts
# can be added as SYNC_USER2, SYNC_USER3, ... in "user:password" format.
if [ -z "${SYNC_USER1:-}" ]; then
  if [ -z "${ANKI_PASSWORD:-}" ]; then
    echo "start.sh: set ANKI_PASSWORD (or SYNC_USER1=user:password) before starting." >&2
    exit 1
  fi
  ANKI_USERNAME="${ANKI_USERNAME:-anki}"
  case "$ANKI_USERNAME" in
    *:*) echo "start.sh: ANKI_USERNAME must not contain ':'." >&2; exit 1 ;;
  esac
  export SYNC_USER1="${ANKI_USERNAME}:${ANKI_PASSWORD}"
fi

# Largest accepted sync request in MB (upstream default 100).
export MAX_SYNC_PAYLOAD_MEGS="${MAX_SYNC_PAYLOAD_MEGS:-100}"
export RUST_LOG="${RUST_LOG:-anki=info}"

echo "start.sh: Anki Sync Server $(python -c 'import anki.buildinfo as b; print(b.version)') on ${SYNC_HOST} port ${SYNC_PORT}, data in ${SYNC_BASE}"
exec python -m anki.syncserver
