# Cardano Project Memory archive

Preservation archive for the editorial Cardano-ecosystem layer — project descriptions, categorizations, launch dates, taxonomy, and historical state — across the sources that carry that layer today.

**This archive preserves. It does not curate, interpret, score, or rank.**

## What this is

A community-runnable, byte-verifiable, chain-of-custody-documented preservation of the off-chain Cardano-ecosystem editorial record. Built to remain useful when individual community sources disappear.

## Why this exists

The Cardano ecosystem's editorial memory layer — what makes a token "a DeFi project", what a wallet's team says about itself, when a particular DApp launched, which projects have been declared dead by community curators — lives in a small number of off-chain sources that have no equivalent on-chain canonical store. If those sources disappear, the editorial layer disappears with them.

This archive does not aim to recreate any of those sources or to build a replacement product. It preserves the editorial layer with chain-of-custody manifests so that the captured state is byte-verifiable and citable for research.

## Architectural facts every reader should know

1. **The archive uses two capture patterns, depending on the source's terms of service.** Some sources are mirrored as bytes-in-this-archive with full chain-of-custody. Others are pinned via the Wayback Machine: the operator triggers a Wayback Save Page Now capture, records the resulting Wayback URL in a `.custody.json` manifest, and does NOT store the bytes locally. The manifest's `bytes_stored` field distinguishes the two patterns.
2. **`cardanocube.com` content is preserved via wayback-pin, not wayback-mirror.** Cardanocube's Terms of Service do not grant republication rights, so the archive holds Wayback URLs as durable references rather than mirroring the bytes ourselves. Researchers verify by fetching from the recorded Wayback URL and re-computing the manifest's SHA-256 hash.
3. **`taptools.io` is captured from the Wayback Machine.** Live TapTools is a Next.js single-page application returning empty shells; the Wayback Machine holds server-rendered snapshots from the site's pre-SPA era. The archive references and (per the operator's decision) optionally mirrors those Wayback snapshots.
4. **`cardano-foundation/cardano-token-registry` is a bare git mirror clone.** Same pattern used for `cardano-foundation/catalyst-core` in the Cardano Catalyst archive.
5. **The archive does not pursue API tokens, paid subscriptions, or special access.** Every byte that lives in this archive (or every Wayback URL that this archive references) was reached via a publicly-accessible URL. A graduate student with a stock laptop must be able to reproduce every capture or every Wayback re-fetch from scratch.

## What is preserved

Per source:

- **TapTools (via Wayback)** — historical state of the ranking grid (`/api/market/tokens/rankings?subcategory=...`) and per-token / per-collection chart pages from the pre-SPA era. The editorial subcategory taxonomy as it appeared at the captured dates.
- **cardanocube.com (via wayback-pin)** — per-project pages at `/projects/{slug}`, the graveyard catalog at `/projects/graveyard`, the 73-category taxonomy at `/categories`, and the explore index.
- **Built on Cardano (`builtoncardano.com`)** — the Cardano Foundation's curated project directory.
- **`cardano.org/discover`** — the CF project-discovery landing page.
- **`cardano-foundation/cardano-token-registry`** — CIP-26 off-chain token registry as a bare git mirror.
- **DefiLlama (Cardano subset)** — DeFi-only protocol descriptions and TVL series.
- **On-chain query records** — canonical Koios queries for the on-chain identifiers that ground the editorial layer (token policy IDs, collection policy IDs, etc.). Not the on-chain bytes themselves; the chain self-preserves.

Per-source READMEs in each subfolder describe the capture method, the chain-of-custody specifics, and any source-specific known gaps.

## What is not preserved

- Trader UX — portfolio screens, alerts, watchlists, charts of price action.
- Computed metrics that are reproducible from on-chain state (token prices, holders count, DEX pair listings, TVL).
- Editorial content whose preservation would violate explicit redistribution restrictions and for which Wayback Machine pinning is impractical.
- Forward-looking projections, recommendations, or rankings derived from the editorial content.

## How to use

**Browse:** each per-source subfolder mirrors the source's URL structure where the bytes are stored, or carries `.custody.json` reference manifests where the wayback-pin pattern applies.

**Verify:** run `_verify/verify-artifact.sh PATH` to check a single mirrored artifact's SHA-256 against its manifest. For wayback-pin manifests, fetch the recorded `wayback_url`, compute SHA-256 of the response, and compare to the manifest's `sha256` field — the match proves the captured content is what was originally observed.

**Cite:** every captured artifact or pinned reference is citable via its SHA-256 hash plus its `wayback_url` (mandatory for wayback-pin entries, supplementary for wayback-mirror entries).

## How to contribute

Class E (researcher capture) contributions are welcomed. See `CONTRIBUTING.md` for the chain-of-custody manifest schema and the review checklist. The same contribution pathway used by the Cardano Catalyst archive applies here.

## Methodology

The full Project Memory methodology lives at the Cardano Delegation Observatory repository:
- [docs/CARDANO_MEMORY_LAYER.md](https://github.com/cryptoleo79/cardano-delegation-observatory/blob/main/docs/CARDANO_MEMORY_LAYER.md) — the meta-methodology governing all memory layers (Governance, Treasury, Catalyst, Project).
- [docs/PROJECT_MEMORY_REGISTRY.md](https://github.com/cryptoleo79/cardano-delegation-observatory/blob/main/docs/PROJECT_MEMORY_REGISTRY.md) — the per-source registry this archive operates against.

The methodology defines the source authority hierarchy (Class A through E), the chain-of-custody requirements, the wayback-pin vs wayback-mirror pattern selection, what the archive explicitly does NOT do, and the capture lifecycle.

## License

See `LICENSE` for the archive's code (Apache 2.0). See `NOTICE` for the multi-layer license model that applies to captured content. Note in particular that captures from sources with restrictive terms of service (e.g., cardanocube's "All rights reserved") use the wayback-pin pattern — the archive holds references rather than the redistributed bytes, respecting the upstream ToS while preserving the chain-of-custody.

## Acknowledgements

This archive's existence depends on the Wayback Machine (`web.archive.org`), which is the load-bearing upstream for both the mirror and the pin capture patterns. It also depends on the public availability of `cardanocube.com`, `builtoncardano.com`, `cardano.org`, `cardano-foundation/cardano-token-registry`, and `defillama.com/protocols/Cardano` at the times of their respective captures. None of these endorse this archive; all are gratefully cited.
