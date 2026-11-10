#!/usr/bin/env bash
# 自分が作成した PR(クローズ済み・マージ済み)のレビューコメントを取得し、
# review/<owner>/<repo>/prs/<番号>.json に保存する。
# 前回取得した最後の PR のクローズ日時を state.json に記録し、次回はそれ以降だけを取得する。
#
# 使い方:
#   fetch_reviews.sh <owner/repo> [--since <ISO8601>] [--limit <件数>]
#
#   --since  この日時より後にクローズされた PR を取得する(state.json の記録より優先)
#   --limit  1 回で取得する PR の上限(既定: 100)
#
# 標準出力: 今回新しく保存した PR の一覧(JSON 配列)

set -euo pipefail

usage() {
  echo "usage: $0 <owner/repo> [--since <ISO8601>] [--limit <N>]" >&2
  exit 1
}

[ $# -ge 1 ] || usage
REPO="$1"; shift
case "$REPO" in */*) ;; *) usage ;; esac

SINCE=""
LIMIT=100
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="${2:-}"; shift 2 ;;
    --limit) LIMIT="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

if ! gh auth status &>/dev/null; then
  echo "GitHub CLI が未認証です。gh auth login を実行してください。" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
REVIEW_ROOT="${CODE_REVIEW_LEARN_DIR:-$SKILL_DIR/review}"
OUT_DIR="$REVIEW_ROOT/$REPO"
PR_DIR="$OUT_DIR/prs"
STATE="$OUT_DIR/state.json"
mkdir -p "$PR_DIR"

if [ ! -f "$STATE" ]; then
  jq -n --arg repo "$REPO" \
    '{repo: $repo, last_closed_at: null, last_run_at: null, unsummarized: []}' > "$STATE"
fi

if [ -z "$SINCE" ]; then
  SINCE="$(jq -r '.last_closed_at // empty' "$STATE")"
fi

SEARCH="sort:updated-desc"
if [ -n "$SINCE" ]; then
  SEARCH="closed:>=$SINCE $SEARCH"
  echo "📥 $REPO: $SINCE 以降にクローズされた自分の PR を取得します" >&2
else
  echo "📥 $REPO: 自分のクローズ済み PR を最新 $LIMIT 件まで取得します(初回)" >&2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

gh pr list --repo "$REPO" --author "@me" --state closed --limit "$LIMIT" \
  --search "$SEARCH" \
  --json number,title,url,author,state,createdAt,closedAt,mergedAt,headRefName,baseRefName,files \
  > "$TMP/prs.json"

COUNT="$(jq 'length' "$TMP/prs.json")"
if [ "$COUNT" -ge "$LIMIT" ]; then
  echo "⚠️  上限 $LIMIT 件に達しました。古い PR が残っている可能性があります(--limit を増やして再実行)。" >&2
fi

NEW_NUMBERS=()
for NUM in $(jq -r '.[].number' "$TMP/prs.json"); do
  DEST="$PR_DIR/$NUM.json"
  if [ -f "$DEST" ]; then
    continue
  fi

  echo "  #$NUM を取得中..." >&2
  gh api --paginate "repos/$REPO/pulls/$NUM/reviews" \
    | jq -s 'add // [] | map({id, user: .user.login, user_type: .user.type, state, body, submitted_at})' \
    > "$TMP/reviews.json"
  gh api --paginate "repos/$REPO/pulls/$NUM/comments" \
    | jq -s 'add // [] | map({id, in_reply_to_id, user: .user.login, user_type: .user.type, path, line, original_line, diff_hunk, body, created_at})' \
    > "$TMP/review_comments.json"
  gh api --paginate "repos/$REPO/issues/$NUM/comments" \
    | jq -s 'add // [] | map({id, user: .user.login, user_type: .user.type, body, created_at})' \
    > "$TMP/issue_comments.json"

  jq -n \
    --arg repo "$REPO" \
    --argjson num "$NUM" \
    --slurpfile prs "$TMP/prs.json" \
    --slurpfile reviews "$TMP/reviews.json" \
    --slurpfile rc "$TMP/review_comments.json" \
    --slurpfile ic "$TMP/issue_comments.json" \
    '($prs[0][] | select(.number == $num)) as $pr
     | {
         repo: $repo,
         number: $pr.number,
         title: $pr.title,
         url: $pr.url,
         author: $pr.author.login,
         state: $pr.state,
         created_at: $pr.createdAt,
         closed_at: $pr.closedAt,
         merged_at: $pr.mergedAt,
         head: $pr.headRefName,
         base: $pr.baseRefName,
         files: [$pr.files[]? | {path, additions, deletions}],
         extensions: ([$pr.files[]?.path | capture("\\.(?<ext>[^./]+)$")?.ext] | unique),
         reviews: $reviews[0],
         review_comments: $rc[0],
         issue_comments: $ic[0]
       }' > "$DEST"

  NEW_NUMBERS+=("$NUM")
done

# state.json を更新する(最後のクローズ日時、未要約の PR 番号)
NEW_JSON="$(printf '%s\n' "${NEW_NUMBERS[@]+"${NEW_NUMBERS[@]}"}" | jq -R 'select(length > 0) | tonumber' | jq -s '.')"
MAX_CLOSED="$(jq -r '[.[].closedAt] | max // empty' "$TMP/prs.json")"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq --arg max "$MAX_CLOSED" --arg now "$NOW" --argjson new "$NEW_JSON" '
  .last_closed_at = ([.last_closed_at, (if $max == "" then null else $max end)] | map(select(. != null)) | max)
  | .last_run_at = $now
  | .unsummarized = ((.unsummarized + $new) | unique)
' "$STATE" > "$TMP/state.json" && mv "$TMP/state.json" "$STATE"

echo "✅ 新しく保存した PR: ${#NEW_NUMBERS[@]} 件(保存先: $OUT_DIR)" >&2

jq --argjson new "$NEW_JSON" \
  '[.[] | select(.number as $n | $new | index($n)) | {number, title, closedAt, url}]' \
  "$TMP/prs.json"
