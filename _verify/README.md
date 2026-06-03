# _verify

Researcher-runnable verification tooling for the Cardano Catalyst archive.

These scripts are bash + `sha256sum` + `curl` + `jq` only. No Python, no Node, no compiled binaries. A researcher with a stock Linux or macOS box must be able to run them with no `pip install`.

## Scripts

- `verify-artifact.sh PATH` — verify one artifact: file exists, manifest exists, manifest schema correct, recomputed SHA-256 matches manifest.
- `verify-archive.sh` — walk the entire archive and run `verify-artifact.sh` on every artifact. Print a PASS/FAIL summary. Non-zero exit if any verification fails.
- `verify-session.sh PATH/TO/CAPTURE_LOG.json` — verify a capture session's rollup hash. Locates all manifests carrying that session's `capture_session_id`, recomputes the sorted-SHA-256-list rollup, and compares to the session log's `rollup_sha256`.
- `replay-capture.sh PATH` — replay a recorded `curl` capture command against the same URL. Reports whether the replayed bytes match the archived bytes. Content drift since `capture_date` is expected for many sources and is informational, not an integrity failure.

## Schema

- `schema/custody-v1.json` — JSON Schema (draft 2020-12) for `.custody.json` sidecar manifests. The schema is the authoritative reference for manifest structure; the scripts above implement a subset of the validation (required-field presence + SHA-256 + authority class enum) without requiring a JSON Schema validator.

For full schema validation, a researcher with `ajv-cli` or `python-jsonschema` installed can validate any manifest against `schema/custody-v1.json` directly:

```bash
# with python-jsonschema
python3 -m jsonschema -i some-artifact.html.custody.json _verify/schema/custody-v1.json

# with ajv
ajv validate -s _verify/schema/custody-v1.json -d some-artifact.html.custody.json
```

## Dependencies

```
bash   (any POSIX-ish shell; tested on bash 5.x)
curl   (any recent version)
sha256sum
jq     (any 1.6+)
find
```

If your system lacks `sha256sum` (some macOS), use `shasum -a 256` instead — adjust the scripts accordingly.

## Exit codes

`verify-artifact.sh`:
- 0  artifact OK
- 1  artifact file missing
- 2  manifest file missing
- 3  manifest schema validation failed (missing required field, wrong enum value, etc.)
- 4  SHA-256 mismatch (corruption or tamper)

`verify-archive.sh`:
- 0 if all artifacts verify
- non-zero (count of failures) if any verification failed

`verify-session.sh`:
- 0  session OK
- 1  session log missing or malformed
- 2  no artifacts found for this session
- 3  rollup hash mismatch

`replay-capture.sh`:
- 0 replay completed (regardless of byte match — drift is informational)
- 1 artifact or manifest missing
- 2 capture_method cannot be replayed (e.g., git clone, manual screenshot)

## What these scripts deliberately do NOT do

- They do not modify any file in the archive. Verification is read-only.
- They do not fetch the upstream source unless `replay-capture.sh` is explicitly invoked.
- They do not submit anything to the Wayback Machine.
- They do not edit `.custody.json` manifests. Manifest back-fills (e.g., late Wayback URL completion) are the operator's responsibility, performed via the wrapper script, recorded as separate commits.
- They do not interpret, score, or rank captured content. They verify bytes.
