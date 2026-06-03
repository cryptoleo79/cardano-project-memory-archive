#!/usr/bin/env bash
# verify-archive.sh — walk the whole archive and verify every manifest.
#
# Usage:
#   _verify/verify-archive.sh
#
# Iterates over every .custody.json sidecar in the archive. For each:
# - If bytes_stored is false (wayback-pin manifest), validate the
#   manifest's schema and required fields without network fetch.
# - Otherwise (wayback-mirror manifest), invoke verify-artifact.sh on
#   the adjacent artifact path.
#
# Reports a summary at the end. Non-zero exit if any verification failed.
# For full wayback-pin verification including a Wayback re-fetch, run
# _verify/verify-pin.sh PATH/TO/manifest.custody.json separately.

set -u
cd "$(dirname "$0")/.."  # archive repo root

pass=0
fail=0
failed_paths=()

while IFS= read -r manifest; do
  if [ "$manifest" = "./_verify/schema/custody-v1.json" ]; then
    continue
  fi
  case "$manifest" in
    */CAPTURE_LOG/*) continue ;;
  esac

  bytes_stored=$(jq -r 'if .bytes_stored == false then "false" else "true" end' "$manifest" 2>/dev/null || echo "true")

  if [ "$bytes_stored" = "false" ]; then
    # wayback-pin manifest. Schema-only check in the walk.
    skip=0
    for field in schema source_url capture_date capture_method capture_operator sha256 content_type source_authority_class wayback_url; do
      if ! jq -e ".\"$field\"" "$manifest" >/dev/null 2>&1; then
        fail=$((fail + 1))
        failed_paths+=("$manifest (pin, missing field: $field)")
        skip=1
        break
      fi
    done
    if [ "$skip" = "1" ]; then continue; fi
    if [ "$(jq -r '.wayback_url' "$manifest")" = "null" ]; then
      fail=$((fail + 1))
      failed_paths+=("$manifest (pin, wayback_url is null)")
      continue
    fi
    pass=$((pass + 1))
  else
    artifact="${manifest%.custody.json}"
    if _verify/verify-artifact.sh "$artifact" >/dev/null 2>&1; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
      failed_paths+=("$artifact")
      _verify/verify-artifact.sh "$artifact" || true
    fi
  fi
done < <(find . -name '*.custody.json' -type f | sort)

echo ""
echo "=== verify-archive.sh summary ==="
echo "PASS: $pass"
echo "FAIL: $fail"
if [ $fail -gt 0 ]; then
  echo "Failed manifests:"
  for p in "${failed_paths[@]}"; do
    echo "  - $p"
  done
fi

echo ""
echo "Note: wayback-pin manifests are verified in this walk by schema check only."
echo "For a full network re-verification including Wayback re-fetch, run:"
echo "  _verify/verify-pin.sh PATH/TO/manifest.custody.json"

exit $fail
