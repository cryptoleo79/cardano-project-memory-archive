#!/usr/bin/env bash
# verify-artifact.sh — verify a single captured artifact against its custody manifest.
#
# Usage:
#   _verify/verify-artifact.sh PATH_TO_ARTIFACT
#
# Exit codes:
#   0  artifact OK
#   1  artifact file missing
#   2  manifest file missing
#   3  manifest schema validation failed
#   4  SHA-256 mismatch (corruption or tamper)
#
# Verifies:
#   - the artifact exists
#   - the {artifact}.custody.json sidecar exists
#   - the sidecar's sha256 matches the freshly-computed SHA-256 of the artifact bytes
#   - the sidecar contains the required schema fields
#
# Does NOT verify:
#   - source_url still resolves (network-dependent; covered by verify-archive.sh's optional --network mode)
#   - wayback_url is reachable (same)

set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 PATH_TO_ARTIFACT" >&2
  exit 64
fi

artifact="$1"
manifest="${artifact}.custody.json"

if [ ! -f "$artifact" ]; then
  echo "FAIL: artifact missing: $artifact" >&2
  exit 1
fi

if [ ! -f "$manifest" ]; then
  echo "FAIL: manifest missing: $manifest" >&2
  exit 2
fi

# Required field presence — minimal schema check without jsonschema dependency.
for field in schema source_url capture_date capture_method capture_operator sha256 content_type source_authority_class; do
  if ! jq -e ".\"$field\"" "$manifest" >/dev/null 2>&1; then
    echo "FAIL: manifest missing required field: $field ($manifest)" >&2
    exit 3
  fi
done

schema_value=$(jq -r .schema "$manifest")
if [ "$schema_value" != "custody-v1" ]; then
  echo "FAIL: manifest schema is not custody-v1: $schema_value ($manifest)" >&2
  exit 3
fi

class_value=$(jq -r .source_authority_class "$manifest")
case "$class_value" in
  A|B|C|D|E) ;;
  *) echo "FAIL: source_authority_class not in {A,B,C,D,E}: $class_value ($manifest)" >&2; exit 3 ;;
esac

expected_sha=$(jq -r .sha256 "$manifest")
if ! printf '%s' "$expected_sha" | grep -Eq '^[a-f0-9]{64}$'; then
  echo "FAIL: manifest sha256 is not lowercase 64-hex: $expected_sha ($manifest)" >&2
  exit 3
fi

actual_sha=$(sha256sum "$artifact" | awk '{print $1}')

if [ "$expected_sha" != "$actual_sha" ]; then
  echo "FAIL: sha256 mismatch on $artifact" >&2
  echo "  expected (from manifest): $expected_sha" >&2
  echo "  actual   (recomputed):    $actual_sha" >&2
  exit 4
fi

echo "OK: $artifact (class=$class_value, sha256=${expected_sha:0:16}...)"
exit 0
