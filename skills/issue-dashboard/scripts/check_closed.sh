#!/usr/bin/env bash
# Check if original issues referenced in dashboard issues have been closed
# Usage: bash check_closed.sh

set -euo pipefail

if ! gh auth status &>/dev/null; then
  echo '{"error": "GitHub CLI not authenticated. Run: gh auth login"}' >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Find all dashboard issues by the auto-generated marker in their body
DASHBOARD_ISSUES=$(gh issue list \
  --repo "$REPO" \
  --search "issue-dashboardスキルにより自動生成" \
  --state open \
  --json number,title,body \
  --limit 200)

# Extract all external GitHub issue URLs from issue bodies
URLS=$(echo "$DASHBOARD_ISSUES" \
  | jq -r '.[].body' \
  | grep -oE 'https://github\.com/[^/]+/[^/]+/issues/[0-9]+' \
  | sort -u)

if [ -z "$URLS" ]; then
  echo "ダッシュボードissueに元issueのリンクが見つかりませんでした。"
  exit 0
fi

TOTAL=$(echo "$URLS" | wc -l | tr -d ' ')
echo "元issueのステータスを確認中... (${TOTAL}件)"
echo ""

CLOSED_COUNT=0
OPEN_COUNT=0
NOT_FOUND_COUNT=0

while IFS= read -r url; do
  # Parse owner/repo/number from URL
  repo=$(echo "$url" | sed -E 's|https://github\.com/([^/]+/[^/]+)/issues/[0-9]+|\1|')
  number=$(echo "$url" | grep -oE '[0-9]+$')

  state=$(gh issue view "$number" --repo "$repo" --json state -q '.state' 2>/dev/null || echo "NOT_FOUND")

  case "$state" in
    CLOSED)
      printf "✅ CLOSED:    %s\n" "$url"
      CLOSED_COUNT=$((CLOSED_COUNT + 1))
      ;;
    NOT_FOUND)
      printf "❓ NOT FOUND: %s\n" "$url"
      NOT_FOUND_COUNT=$((NOT_FOUND_COUNT + 1))
      ;;
    *)
      printf "🔵 OPEN:      %s\n" "$url"
      OPEN_COUNT=$((OPEN_COUNT + 1))
      ;;
  esac
done <<< "$URLS"

echo ""
echo "結果: OPEN ${OPEN_COUNT}件 / CLOSED ${CLOSED_COUNT}件 / NOT FOUND ${NOT_FOUND_COUNT}件"
