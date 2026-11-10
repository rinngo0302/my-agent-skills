#!/usr/bin/env bash
# 保存した PR の JSON を、要約しやすいテキスト(スレッドごと)にして表示する。
# HTML コメント、画像タグ、bot の補足用 <details>(AI 向けプロンプトなど)は除く。
# 「Outside diff range comments」などの指摘を含む <details> は残す。
#
# 使い方: show_threads.sh <prs/番号.json>

set -euo pipefail
[ $# -eq 1 ] || { echo "usage: $0 <pr.json>" >&2; exit 1; }

jq -r '
  def clean: (. // "")
    | gsub("<!--[\\s\\S]*?-->"; "")
    | gsub("<details>\\s*<summary>[^<]*(Prompt for AI|Learnings|Analysis chain|Review details|Committable suggestion|Tip|Note)[\\s\\S]*?</details>"; "")
    | gsub("</?(details|summary)>"; "")
    | gsub("<img[^>]*>"; "[画像]")
    | gsub("\n{3,}"; "\n\n")
    | sub("^\\s+"; "") | sub("\\s+$"; "");

  "# #\(.number) \(.title)",
  "状態: \(.state) / 作成: \(.created_at) / クローズ: \(.closed_at)",
  "作成者: \(.author // "不明") / 拡張子: \(.extensions | join(", "))",
  "",
  "## レビュー本文",
  (.reviews[] | select((.body | clean) != "")
    | "- [\(.user)] \(.state) \(.submitted_at)\n\(.body | clean)\n"),
  "",
  "## インラインコメント(スレッド単位)",
  ( .review_comments as $all
    | $all[] | select(.in_reply_to_id == null) as $root
    | "### \($root.path):\($root.line // $root.original_line // "?")",
      "```diff\n\(($root.diff_hunk // "") | split("\n") | .[-6:] | join("\n"))\n```",
      ( [$root] + [$all[] | select(.in_reply_to_id == $root.id)]
        | .[] | "- [\(.user)] \(.body | clean)" ),
      ""
  ),
  "## 会話コメント",
  (.issue_comments[] | select((.body | clean) != "")
    | "- [\(.user)] \(.created_at)\n\(.body | clean)\n")
' "$1"
