#!/usr/bin/env bash
# Fetch all open issues assigned to the current GitHub user across all repos

set -euo pipefail

if ! gh auth status &>/dev/null; then
  echo '{"error": "GitHub CLI not authenticated. Run: gh auth login"}' >&2
  exit 1
fi

gh search issues \
  --assignee @me \
  --state open \
  --json title,url,repository,body,labels,number,createdAt \
  --limit 100
