# Changelog

All notable changes to `hebrew-linguistics-data` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] — 2026-05-01

### Added
- Initial scaffold of the eight curated Hebrew chapters:
  1. `academy-decisions` — binding spelling/grammar decisions from האקדמיה ללשון העברית.
  2. `connectives-modern-usage` — Hebrew logical connectives.
  3. `niqqud-rules` — Academy niqqud rules and practical exceptions.
  4. `anti-ai-markers` — banned/preferred openers and AI tells.
  5. `citation-conventions` — Chicago-Hebrew, APA-Hebrew, and Hazal style.
  6. `typography-conventions` — quotation marks, numerals, RTL/LTR.
  7. `author-register` — register markers (high / journalistic / colloquial).
  8. `style-fingerprint-baseline` — corpus baseline for the voice fingerprinter.
- `scripts/sync-to-candlekeep.sh` — uploads/updates the runtime CandleKeep book.
- `.github/workflows/sync.yml` — runs the sync on push to `main`.
