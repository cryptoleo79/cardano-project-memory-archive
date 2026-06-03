#!/usr/bin/env bash
# verify-session.sh — verify a capture session's rollup hash.
#
# Usage:
#   _verify/verify-session.sh PATH_TO_CAPTURE_LOG.json
#
# Reads the per-session CAPTURE_LOG.json, walks every artifact whose
# .custody.json references this session_id (via capture_session_id field),
# recomputes the rollup SHA-256 (sorted sha256 list), and compares to the
# session log's rollup_sha256.
#
# Exit codes:
#   0  session OK
#   1  session log missing or malformed
#   2  no artifacts found for this session
#   3  rollup hash mismatch

set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 PATH_TO_CAPTURE_LOG.json" >&2
  exit 64
fi

session_log="$1"
cd "$(dirname "$0")/.."  # archive repo root
session_log="$(realpath --relative-to=. "$session_log")"

if [ ! -f "$session_log" ]; then
  echo "FAIL: session log missing: $session_log" >&2
  exit 1
fi

session_id=$(jq -r .capture_session_id "$session_log" 2>/dev/null || echo "")
expected_rollup=$(jq -r .rollup_sha256 "$session_log" 2>/dev/null || echo "")

if [ -z "$session_id" ] || [ -z "$expected_rollup" ]; then
  echo "FAIL: session log missing capture_session_id or rollup_sha256: $session_log" >&2
  exit 1
fi

# Find every .custody.json that references this session_id.
matching_manifests=$(find . -name '*.custody.json' -type f -exec sh -c \
  'jq -e --arg sid "$1" ".capture_session_id == \$sid" "$2" >/dev/null 2>&1 && echo "$2"' _ "$session_id" {} \;)

if [ -z "$matching_manifests" ]; then
  echo "FAIL: no artifacts found for session_id: $session_id" >&2
  exit 2
fi

# Collect per-file sha256 values, sort, then rollup-hash.
actual_rollup=$(
  for m in $matching_manifests; do
    jq -r .sha256 "$m"
  done | sort | sha256sum | awk '{print $1}'
)

if [ "$expected_rollup" != "$actual_rollup" ]; then
  echo "FAIL: rollup hash mismatch for session $session_id" >&2
  echo "  expected: $expected_rollup" >&2
  echo "  actual:   $actual_rollup" >&2
  echo "  manifests counted: $(echo "$matching_manifests" | wc -l)" >&2
  exit 3
fi

count=$(echo "$matching_manifests" | wc -l)
echo "OK: session $session_id ($count artifacts, rollup=${expected_rollup:0:16}...)"
exit 0
