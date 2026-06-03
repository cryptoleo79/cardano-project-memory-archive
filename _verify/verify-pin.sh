#!/usr/bin/env bash
# verify-pin.sh — verify a wayback-pin manifest by re-fetching the
# Wayback Machine URL and checking the SHA-256 hash.
#
# Usage:
#   _verify/verify-pin.sh PATH_TO_CUSTODY_JSON
#
# For wayback-pin captures (bytes_stored: false), this archive does NOT
# hold the source bytes — only a chain-of-custody manifest pointing at
# the Wayback Machine snapshot. Verification proves the captured content
# is what we observed at capture time by re-fetching the Wayback URL,
# re-computing SHA-256, and comparing to the manifest.
#
# Exit codes:
#   0  pin verified (Wayback fetch matches manifest hash)
#   1  manifest file missing
#   2  manifest is not a wayback-pin manifest (bytes_stored not false)
#   3  manifest schema validation failed
#   4  Wayback fetch failed
#   5  SHA-256 mismatch between Wayback fetch and manifest

set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 PATH_TO_CUSTODY_JSON" >&2
  exit 64
fi

manifest="$1"

if [ ! -f "$manifest" ]; then
  echo "FAIL: manifest missing: $manifest" >&2
  exit 1
fi

# Required field presence — minimal schema check.
for field in schema source_url capture_date capture_method capture_operator sha256 content_type source_authority_class; do
  if ! jq -e ".\"$field\"" "$manifest" >/dev/null 2>&1; then
    echo "FAIL: manifest missing required field: $field ($manifest)" >&2
    exit 3
  fi
done

bytes_stored=$(jq -r 'if .bytes_stored == false then "false" else "true" end' "$manifest")
if [ "$bytes_stored" != "false" ]; then
  echo "FAIL: $manifest is not a wayback-pin manifest (bytes_stored=$bytes_stored)" >&2
  echo "  Use verify-artifact.sh for wayback-mirror manifests (bytes_stored: true or absent)." >&2
  exit 2
fi

wayback_url=$(jq -r '.wayback_url // empty' "$manifest")
if [ -z "$wayback_url" ] || [ "$wayback_url" = "null" ]; then
  echo "FAIL: wayback-pin manifest has no wayback_url ($manifest)" >&2
  exit 3
fi

expected_sha=$(jq -r .sha256 "$manifest")
if ! printf '%s' "$expected_sha" | grep -Eq '^[a-f0-9]{64}$'; then
  echo "FAIL: manifest sha256 is not lowercase 64-hex: $expected_sha ($manifest)" >&2
  exit 3
fi

# Fetch from Wayback. Polite client identity.
tmpfile=$(mktemp)
if ! curl -sfL --user-agent "cdo-preserve-verify/1.0" "$wayback_url" -o "$tmpfile"; then
  echo "FAIL: Wayback fetch failed for $wayback_url" >&2
  rm -f "$tmpfile"
  exit 4
fi

actual_sha=$(sha256sum "$tmpfile" | awk '{print $1}')
rm -f "$tmpfile"

if [ "$expected_sha" != "$actual_sha" ]; then
  echo "FAIL: sha256 mismatch on Wayback fetch of $wayback_url" >&2
  echo "  expected (from manifest): $expected_sha" >&2
  echo "  actual   (refetched):     $actual_sha" >&2
  exit 5
fi

class_value=$(jq -r .source_authority_class "$manifest")
echo "OK: $manifest (pin, class=$class_value, sha256=${expected_sha:0:16}...)"
exit 0
