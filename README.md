# hebrew-linguistics-data

A curated, version-controlled corpus of **Hebrew editorial knowledge** — sourced from האקדמיה ללשון העברית, established editorial blogs (e.g., רוביק רוזנטל's *הזירה הלשונית*), and Israeli book-publishing practice.

This repo is the **source of truth** for the runtime CandleKeep book *"Hebrew Linguistic Reference"*, which is read by:

- [`hebrew-book-producer`](https://github.com/yodem/hebrew-book-producer) — agents and skills for the Israeli book-production pipeline.
- [`academic-writer`](https://github.com/yodem/academic-writer) — agents and skills for academic-article writing.

## Layout

```
chapters/
  01-academy-decisions.md
  02-connectives-modern-usage.md
  03-niqqud-rules.md
  04-anti-ai-markers.md
  05-citation-conventions.md
  06-typography-conventions.md
  07-author-register.md
  08-style-fingerprint-baseline.md   # baseline numbers are placeholders, see below
  09-nikud-vs-teamim-unicode.md
scripts/
  sync-to-candlekeep.sh    # uploads / updates the Trove book from chapters/
```

Nine chapters in all.

Each chapter is a Hebrew markdown file with prose guidance and (where useful) embedded JSON code blocks holding structured data — connective tables, banned-opener corpora, niqqud rules, fingerprint baseline metrics. Skills extract the JSON blocks at runtime when they need a programmatic table.

## Contribution

1. Edit a chapter under `chapters/`.
2. `git commit && git push`.
3. Run `bash scripts/sync-to-candlekeep.sh` locally — pushes the rebuilt body into the CandleKeep item.

CandleKeep then has the new content within seconds; both consuming plugins read it on next session start.

> The sync runs locally only. It needs a signed-in Trove account, so the repo has no CI workflow for it.

## Open items

- **Chapter 8 baseline numbers are placeholders.** The values in `08-style-fingerprint-baseline.md` were copied from a demo JSON block in academic-writer's `style-miner.md`, as the chapter's own `provenance` field says; they were never measured on a corpus. Do not treat them as real Hebrew norms. Open item: compute real baselines from a full corpus run.

## Why CandleKeep + GitHub?

- **GitHub** is the audit trail and review surface — diffs are reviewable, history is permanent, the data is shareable beyond the original two plugins.
- **CandleKeep** is the runtime read interface — agents already speak `ck items read`, no new SDK or filesystem layout to learn.

## License

MIT.
