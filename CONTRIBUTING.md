# Contributing to the Cardano Project Memory archive

The same contribution pathway used by the Cardano Catalyst archive applies here. See the [CONTRIBUTING.md](https://github.com/cryptoleo79/cardano-catalyst-archive/blob/main/CONTRIBUTING.md) at the Catalyst archive repository for the full Class E researcher contribution workflow.

Two archive-specific points:

1. **Capture pattern selection.** Each contribution must declare whether it uses the wayback-mirror pattern (bytes stored in this archive, full SHA-256 + sidecar) or the wayback-pin pattern (Wayback URL referenced, `bytes_stored: false` in the manifest). The choice depends on the source's Terms of Service. When in doubt, default to wayback-pin: it's the more conservative choice that respects upstream rights.
2. **Source classification.** Class E researcher contributions are accepted as primary records when no Class A-D source covers the content. For sources that overlap with existing per-source subfolders, contributions extend that subfolder's INDEX.json and follow the same capture-method conventions documented in the per-source README.

## Methodology

This archive is governed by:
- [docs/CARDANO_MEMORY_LAYER.md](https://github.com/cryptoleo79/cardano-delegation-observatory/blob/main/docs/CARDANO_MEMORY_LAYER.md) — meta-methodology for all memory layers.
- [docs/PROJECT_MEMORY_REGISTRY.md](https://github.com/cryptoleo79/cardano-delegation-observatory/blob/main/docs/PROJECT_MEMORY_REGISTRY.md) — per-source registry.
- The forthcoming docs/PROJECT_MEMORY_CAPTURE_PLAN.md will specify per-source operational details.

If a contribution falls outside the scope of these documents, open an issue or pull request to revise the methodology first.
