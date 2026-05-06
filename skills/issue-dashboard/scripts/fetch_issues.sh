#!/usr/bin/env bash
# Fetch all open issues assigned to the current GitHub user across all repos.
# If the result count equals the limit, doubles the limit and retries until
# all issues are retrieved (GitHub Search API cap: 1000).

set -euo pipefail

if ! gh auth status &>/dev/null; then
  echo '{"error": "GitHub CLI not authenticated. Run: gh auth login"}' >&2
  exit 1
fi

MAX_LIMIT=1000
LIMIT=100

while true; do
  RESULT=$(gh search issues \
    --assignee @me \
    --state open \
    --json title,url,repository,body,labels,number,createdAt \
    --limit "$LIMIT")

  COUNT=$(echo "$RESULT" | jq 'length')

  if [ "$COUNT" -lt "$LIMIT" ]; then
    echo "$RESULT"
    break
  fi

  if [ "$LIMIT" -ge "$MAX_LIMIT" ]; then
    # GitHub Search API hard cap reached
    echo "⚠️  GitHub Search APIの上限（${MAX_LIMIT}件）に達しました。結果が不完全な可能性があります。" >&2
    echo "$RESULT"
    break
  fi

  LIMIT=$(( LIMIT * 2 > MAX_LIMIT ? MAX_LIMIT : LIMIT * 2 ))
  echo "⚠️  ${COUNT}件取得。さらに多い可能性があるため ${LIMIT}件で再取得中..." >&2
done
