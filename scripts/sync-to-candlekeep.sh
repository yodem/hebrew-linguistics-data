#!/usr/bin/env bash
# sync-to-candlekeep.sh — concatenate the eight chapters and upsert them into
# the runtime CandleKeep book "Hebrew Linguistic Reference".
#
# Source of truth = chapters/*.md in this repo.
# Runtime cache    = one CandleKeep item titled "Hebrew Linguistic Reference".
#
# The CandleKeep item ID is stored in scripts/.candlekeep-item-id (untracked,
# created on first run). On subsequent runs, the script does an idempotent
# `trove items put --expect-version` against the recorded ID (Trove is the renamed CandleKeep).
#
# Requires: trove CLI on PATH, signed in to the personal account.
# Env: DRY_RUN=1 builds and checks only; FIXES="<gap id> ..." closes those reader requests when the write lands.
# Trove limits: every top-level `# ` section is one page, at most 20,000 bytes; at most 1,000 pages.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHAPTERS_DIR="${REPO_ROOT}/chapters"
ID_FILE="${REPO_ROOT}/scripts/.candlekeep-item-id"
TITLE="Hebrew Linguistic Reference"
DESCRIPTION="Curated Hebrew editorial knowledge — Academy decisions, connectives, niqqud, anti-AI markers, citation conventions, typography, register, fingerprint baseline. Source: github.com/yodem/hebrew-linguistics-data"
TMP_BODY="$(mktemp)"
trap 'rm -f "${TMP_BODY}"' EXIT

if ! command -v trove >/dev/null 2>&1; then
  echo "ERROR: trove CLI not on PATH (see https://heytrove.ai)" >&2
  exit 1
fi

# Build the combined body — banner first, then each chapter file in order.
{
  cat <<HEADER
# ${TITLE}

> Synced from \`yodem/hebrew-linguistics-data\` on $(date -u +"%Y-%m-%dT%H:%M:%SZ").
> Edits made directly in CandleKeep WILL be overwritten on the next sync.
> Source-of-truth edits go to: https://github.com/yodem/hebrew-linguistics-data

---
HEADER

  for chapter in "${CHAPTERS_DIR}"/[0-9][0-9]-*.md; do
    [ -f "${chapter}" ] || continue
    echo
    echo "<!-- chapter: $(basename "${chapter}" .md) -->"
    echo
    cat "${chapter}"
    echo
    echo "---"
  done
} > "${TMP_BODY}"

CHARS=$(wc -c < "${TMP_BODY}" | tr -d ' ')
echo "Built combined body — ${CHARS} chars across $(ls -1 "${CHAPTERS_DIR}"/[0-9][0-9]-*.md | wc -l | tr -d ' ') chapters."

# Refuse before writing if any page breaks Trove's limits (a `# ` line inside a code fence is not a page).
python3 - "${TMP_BODY}" <<'PY'
import sys
pages, cur, fence = [], [], False
for line in open(sys.argv[1], encoding="utf-8").read().split("\n"):
    if line.startswith("```"):
        fence = not fence
    if not fence and line.startswith("# "):
        pages.append(cur); cur = []
    cur.append(line)
pages.append(cur)
sizes = [len("\n".join(p).encode()) for p in pages if p]
bad = [(i + 1, n) for i, n in enumerate(sizes) if n > 20000]
print("pages: %d, largest: %d bytes" % (len(sizes), max(sizes)))
if bad or len(sizes) > 1000:
    sys.exit("ERROR: over Trove limits: %s" % bad)
PY

if [ "${DRY_RUN:-0}" = "1" ]; then echo "DRY_RUN: built and checked, nothing written."; exit 0; fi

FIX_ARGS=()
for g in ${FIXES:-}; do FIX_ARGS+=(--fixes "$g"); done

if [ -s "${ID_FILE}" ]; then
  ITEM_ID=$(cat "${ID_FILE}")
  V=$(trove items history "${ITEM_ID}" --json --no-session | python3 -c 'import sys, json; print(json.load(sys.stdin)["currentVersion"])')
  echo "Updating existing Trove item ${ITEM_ID} (version ${V})…"
  trove items put "${ITEM_ID}" -f "${TMP_BODY}" --expect-version "${V}" ${FIX_ARGS[@]+"${FIX_ARGS[@]}"} --no-session
  echo "  ✔ updated."
else
  echo "Creating new Trove item titled \"${TITLE}\"…"
  CREATE_OUTPUT=$(trove items import "${TMP_BODY}" --title "${TITLE}" --json --no-session)
  NEW_ID=$(printf '%s' "${CREATE_OUTPUT}" | python3 -c 'import sys, json; d = json.load(sys.stdin); print(d.get("id") or d.get("item", {}).get("id") or "")')
  if [ -z "${NEW_ID}" ]; then
    echo "ERROR: could not parse item ID from trove output:" >&2
    echo "${CREATE_OUTPUT}" >&2
    exit 1
  fi
  echo "${NEW_ID}" > "${ID_FILE}"
  echo "  ✔ created with id ${NEW_ID} (recorded in scripts/.candlekeep-item-id)"
fi

echo
echo "Done. The Trove book \"${TITLE}\" is now in sync with this repo."
echo "Both hebrew-book-producer and academic-writer plugins will pick up the"
echo "new content on their next session-start Trove load."
