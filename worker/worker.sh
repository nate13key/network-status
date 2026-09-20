#!/bin/bash


set -u

TARGET="${TARGET:-8.8.8.8}"
DNS_NAME="${DNS_NAME:-google.com}"

# bash as PID 1 ignores SIGTERM unless trapped; this makes `docker compose stop` fast
trap 'exit 0' TERM INT

# record TS TYPE TARGET OK LATENCY ERROR   (empty latency/error become NULL)
record() {
  psql -q -v ON_ERROR_STOP=1 \
    -v ts="$1" -v type="$2" -v target="$3" -v ok="$4" -v lat="$5" -v err="$6" <<'SQL'
INSERT INTO checks (ts, check_type, target, success, latency_ms, error)
VALUES (:'ts', :'type', :'target', :'ok', NULLIF(:'lat', '')::real, NULLIF(:'err', ''));
SQL
}

check_ping() {
  local ts out rc ok=false lat="" err=""
  ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
  out=$(ping -c 1 -W 1 "$TARGET" 2>&1)
  rc=$?
  if [ "$rc" -eq 0 ]; then
    ok=true
    lat=$(sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p' <<<"$out")
  elif [ "$rc" -eq 1 ]; then
    err="no reply"
  else
    err="ping exit $rc: $out"
  fi
  record "$ts" ping "$TARGET" "$ok" "$lat" "$err"
}

check_dns() {
  local ts out rc status ok=false lat="" err=""
  ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
  out=$(dig +time=1 +tries=1 "$DNS_NAME" 2>&1)
  rc=$?
  if [ "$rc" -eq 9 ]; then
    err="no reply"                      # dig exit 9 = timed out
  elif [ "$rc" -ne 0 ]; then
    err="dig exit $rc: $out"
  else
    status=$(sed -n 's/.*status: \([A-Z]*\).*/\1/p' <<<"$out")
    if [ "$status" = "NOERROR" ]; then
      ok=true
      lat=$(sed -n 's/.*Query time: \([0-9]*\) msec.*/\1/p' <<<"$out")
    else
      err="status ${status:-unknown}"   # e.g. SERVFAIL, NXDOMAIN
    fi
  fi
  record "$ts" dns "$DNS_NAME" "$ok" "$lat" "$err"
}

next=$(date +%s%3N)
while true; do
  check_ping &
  check_dns &
  wait
  next=$((next + 1000))
  now=$(date +%s%3N)
  if (( next > now )); then
    d=$((next - now))
    sleep "$((d / 1000)).$(printf '%03d' $((d % 1000)))"
  else
    next=$now   # fell behind (slow check); resync instead of bursting to catch up
  fi
done

