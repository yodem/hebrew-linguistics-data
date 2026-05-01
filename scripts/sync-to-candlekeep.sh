#!/usr/bin/env bash
# sync-to-candlekeep.sh — concatenate the eight chapters and upsert them into
# the runtime CandleKeep book "Hebrew Linguistic Reference".
#
# Source of truth = chapters/*.md in this repo.
# Runtime cache    = one CandleKeep item titled "Hebrew Linguistic Reference".
#
# The CandleKeep item ID is stored in scripts/.candlekeep-item-id (untracked,
# created on first run). On subsequent runs, the script does an idempotent
# `ck items put` against the recorded ID.
#
# Requires: ck CLI on PATH, ck auth complete (run `ck auth login` once).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHAPTERS_DIR="${REPO_ROOT}/chapters"
ID_FILE="${REPO_ROOT}/scripts/.candlekeep-item-id"
TITLE="Hebrew Linguistic Reference"
DESCRIPTION="Curated Hebrew editorial knowledge — Academy decisions, connectives, niqqud, anti-AI markers, citation conventions, typography, register, fingerprint baseline. Source: github.com/yodem/hebrew-linguistics-data"
TMP_BODY="$(mktemp)"
trap 'rm -f "${TMP_BODY}"' EXIT

if ! command -v ck >/dev/null 2>&1; then
  echo "ERROR: ck CLI not on PATH. Install with: curl -fsSL https://candlekeep.dev/install.sh | sh" >&2
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

if [ -s "${ID_FILE}" ]; then
  ITEM_ID=$(cat "${ID_FILE}")
  echo "Updating existing CandleKeep item ${ITEM_ID}…"
  ck items put "${ITEM_ID}" -f "${TMP_BODY}"
  echo "  ✔ updated."
else
  echo "Creating new CandleKeep item titled \"${TITLE}\"…"
  CREATE_OUTPUT=$(ck --json items create "${TITLE}" \
    --description "${DESCRIPTION}" \
    --content "$(cat "${TMP_BODY}")")
  # Extract the new item ID from the JSON output.
  NEW_ID=$(printf '%s' "${CREATE_OUTPUT}" | python3 -c 'import sys, json; d = json.load(sys.stdin); print(d.get("id") or d.get("item", {}).get("id") or "")')
  if [ -z "${NEW_ID}" ]; then
    echo "ERROR: could not parse item ID from ck output:" >&2
    echo "${CREATE_OUTPUT}" >&2
    exit 1
  fi
  echo "${NEW_ID}" > "${ID_FILE}"
  echo "  ✔ created with id ${NEW_ID} (recorded in scripts/.candlekeep-item-id)"
fi

echo
echo "Done. The CandleKeep book \"${TITLE}\" is now in sync with this repo."
echo "Both hebrew-book-producer and academic-writer plugins will pick up the"
echo "new content on their next session-start CandleKeep load."
