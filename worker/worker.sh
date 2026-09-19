#!/bin/bash


set -u

TARGET="${TARGET:-8.8.8.8}"

timestamp=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
out=$(ping -c 1 -W 1 "$TARGET" 2>&1)
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
  success=true
  latency=$(sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p' <<<"$out")
  error=""
else
  success=false
  latency=""
  case $exit_code in
    1) error="no reply" ;;
    *) error="ping exit $exit_code: $out" ;;
  esac
fi


psql -q -v ON_ERROR_STOP=1 \
  -v ts="$timestamp" -v target="$TARGET" -v ok="$success" \
  -v lat="$latency" -v err="$error" <<'SQL'
INSERT INTO checks (ts, check_type, target, success, latency_ms, error)
VALUES (:'ts', 'ping', :'target', :'ok', NULLIF(:'lat', '')::real, NULLIF(:'err', ''));
SQL
