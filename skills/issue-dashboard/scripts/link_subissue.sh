#!/usr/bin/env bash
# Link a child issue as a sub-issue of a parent issue via GitHub GraphQL API
# Usage: link_subissue.sh <parent_issue_url> <child_issue_url>

set -euo pipefail

PARENT_URL="${1:?Usage: $0 <parent_issue_url> <child_issue_url>}"
CHILD_URL="${2:?Usage: $0 <parent_issue_url> <child_issue_url>}"

# Extract owner/repo/number from URL (https://github.com/owner/repo/issues/N)
parse_issue() {
  local url="$1"
  echo "$url" | sed -E 's|https://github.com/([^/]+)/([^/]+)/issues/([0-9]+)|\1 \2 \3|'
}

read -r P_OWNER P_REPO P_NUM <<< "$(parse_issue "$PARENT_URL")"

# Get parent issue node ID
PARENT_NODE_ID=$(gh api "repos/${P_OWNER}/${P_REPO}/issues/${P_NUM}" --jq '.node_id')

# Link child as sub-issue using subIssueUrl (no need to fetch child node ID)
gh api graphql -f query="
mutation {
  addSubIssue(input: {
    issueId: \"${PARENT_NODE_ID}\"
    subIssueUrl: \"${CHILD_URL}\"
  }) {
    issue { number }
    subIssue { number }
  }
}" --jq '.data.addSubIssue | "✅ Sub-issue linked: parent #\(.issue.number) ← child #\(.subIssue.number)"'
