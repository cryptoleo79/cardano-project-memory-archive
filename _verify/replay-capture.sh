#!/usr/bin/env bash
# replay-capture.sh — replay a recorded capture command and compare to the
# archived bytes.
#
# Usage:
#   _verify/replay-capture.sh PATH_TO_ARTIFACT
#
# Reads the artifact's .custody.json, extracts capture_method, attempts to
# replay the same command against source_url (or wayback_url if present),
# and reports whether the replayed bytes match the archived bytes.
#
# CAVEAT: content drift since capture_date is expected for many sources.
# A replay producing different bytes is not necessarily an integrity failure;
# it may simply reflect that the source has changed. The replay's value is
# transparency about the capture method, not byte equality verification
# (which is verify-artifact.sh's job via SHA-256 + manifest).
#
# Exit codes:
#   0 replay completed (regardless of match)
#   1 artifact or manifest missing
#   2 capture_method cannot be replayed (e.g., git clone, manual screenshot)

set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 PATH_TO_ARTIFACT" >&2
  exit 64
fi

artifact="$1"
manifest="${artifact}.custody.json"

if [ ! -f "$artifact" ] || [ ! -f "$manifest" ]; then
  echo "FAIL: artifact or manifest missing: $artifact" >&2
  exit 1
fi

method=$(jq -r .capture_method "$manifest")
source_url=$(jq -r .source_url "$manifest")
wayback_url=$(jq -r '.wayback_url // empty' "$manifest")

echo "Replaying capture for: $artifact"
echo "  source_url:    $source_url"
echo "  wayback_url:   ${wayback_url:-<none>}"
echo "  method:        $method"

# Match supported capture methods.
case "$method" in
  curl*)
    tmpfile=$(mktemp)
    target_url="${wayback_url:-$source_url}"
    # Use the same UA the method recorded.
    ua=$(printf '%s' "$method" | sed -n 's/.*--user-agent[= ]\([^ ]*\).*/\1/p' | tr -d '"')
    if [ -z "$ua" ]; then ua="cdo-preserve-replay/1.0"; fi
    if curl -sL --user-agent "$ua" "$target_url" -o "$tmpfile"; then
      replay_sha=$(sha256sum "$tmpfile" | awk '{print $1}')
      archived_sha=$(jq -r .sha256 "$manifest")
      if [ "$replay_sha" = "$archived_sha" ]; then
        echo "MATCH: replay bytes are identical to archived bytes (sha256=${replay_sha:0:16}...)"
      else
        echo "DRIFT: replay bytes differ from archived bytes"
        echo "  archived sha256: ${archived_sha:0:16}..."
        echo "  replay   sha256: ${replay_sha:0:16}..."
        echo "  This is informational; content drift since capture_date is expected."
      fi
      rm -f "$tmpfile"
      exit 0
    else
      echo "FAIL: curl replay failed (network or URL issue)" >&2
      rm -f "$tmpfile"
      exit 0
    fi
    ;;
  "git clone --mirror"*)
    echo "NOT REPLAYABLE BY THIS SCRIPT: git clone --mirror requires re-cloning a multi-MB repository." >&2
    echo "  To verify: run 'git clone --mirror $source_url' separately and compare with 'catalyst-core/repo.git'." >&2
    exit 2
    ;;
  *)
    echo "NOT REPLAYABLE: unknown capture_method type: $method" >&2
    exit 2
    ;;
esac
