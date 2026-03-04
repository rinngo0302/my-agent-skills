---
name: github-pr
description: "ユーザーが指定したレビュー指摘を GitHub PR にインラインコメントとして投稿するスキル。ユーザーが指摘内容・ファイル・行番号を伝えると、Claude in Chrome で GitHub UI を操作してコメントを投稿する。"
compatibility: "Claude in Chrome MCP が必要。"
---

# GitHub PR レビューコメント投稿

ユーザーからレビュー指摘の内容を受け取り、Claude in Chrome で GitHub PR にインラインコメントを投稿する。

## 前提条件（Claude in Chrome 専用）

- GitHub にログイン済みであること（必要なら 2FA を完了済み）
- 対象 PR にレビューコメントを投稿できる権限があること
- `https://github.com/{owner}/{repo}/pull/{番号}/files` を表示できること

## ステップ1: 指摘内容の確認

ユーザーから以下を受け取る。不足している場合は AskUserQuestion で確認する。

- **PR の URL または番号**（例: `#123` / `https://github.com/org/repo/pull/123`）
- **指摘リスト**（ファイルパス・行番号・コメント内容）

投稿前に指摘リストをユーザーに一覧表示して最終確認を取る：

```
PR: owner/repo#123  件数: 3件

1. src/app.ts:42  — 「この分岐は early return にすると読みやすいです」
2. src/utils.ts:88 — 「N+1 クエリが発生しています」
3. README.md:12   — 「誤字: 設定方法 → 設定方法」

レビュー種別: Request changes
```

## ステップ2: GitHub PR ページを開く

```
# タブ状況を確認して新しいタブを作成
mcp__claude-in-chrome__tabs_context_mcp
mcp__claude-in-chrome__tabs_create_mcp

# PR の Files Changed ページに移動
mcp__claude-in-chrome__navigate  url="https://github.com/{owner}/{repo}/pull/{番号}/files"

# 表示を確認
mcp__claude-in-chrome__computer  action="screenshot"
```

ログインしていない場合はユーザーに手動ログインを依頼して待つ。

## ステップ3: インラインコメントの投稿

指摘リストを上から順に1件ずつ投稿する。

### 3-1. 対象行を探す

```
# ファイル名や行の内容でコメント先を探す
mcp__claude-in-chrome__find  query="ファイル名 または 行内容のキーワード"
```

見つからない場合はスクロールして再検索する：

```
mcp__claude-in-chrome__computer  action="scroll"  coordinate=[760, 400]  scroll_direction="down"
```

### 3-2. 「+」ボタンを表示してクリック

```
# 行番号付近にホバーして「+」を出す
mcp__claude-in-chrome__computer  action="hover"  coordinate=[行番号の x, y]

# スクリーンショットで「+」の位置を確認してからクリック
mcp__claude-in-chrome__computer  action="screenshot"
mcp__claude-in-chrome__computer  action="left_click"  coordinate=[+ボタンの x, y]
```

### 3-3. コメントを入力する

```
# テキストエリアを探してクリック
mcp__claude-in-chrome__find  query="comment text area"
mcp__claude-in-chrome__computer  action="left_click"  ref="テキストエリアの ref"

# コメントを入力
mcp__claude-in-chrome__computer  action="type"  text="コメント本文"
```

### 3-4. レビューに追加する

```
# 1件目
mcp__claude-in-chrome__find  query="Start a review"
mcp__claude-in-chrome__computer  action="left_click"  ref="..."

# 2件目以降
mcp__claude-in-chrome__find  query="Add review comment"
mcp__claude-in-chrome__computer  action="left_click"  ref="..."
```

### 3-5. 失敗時の再試行（ブラウザ操作のみ）

UI 操作が失敗した場合は、次の順で再試行する。

1. スクリーンショットを取得して現状を確認する
2. 対象ファイル・行を `find` で再検索する
3. 行番号付近を再ホバーして「+」ボタンを出し直す
4. ページを再読み込みして、`/files` ページへ戻って再実行する

## ステップ4: レビューの送信

全コメント投稿後、`Submit review` の直前でユーザーに最終確認を取ってから実行する。

```
# レビュー送信ダイアログを開く
mcp__claude-in-chrome__find  query="Finish your review"
mcp__claude-in-chrome__computer  action="left_click"  ref="..."

# 総評を入力（ユーザーから受け取った内容。なければ空欄）
mcp__claude-in-chrome__find  query="review summary text area"
mcp__claude-in-chrome__computer  action="left_click"  ref="..."
mcp__claude-in-chrome__computer  action="type"  text="総評テキスト"

# レビュー種別を選択（Comment / Approve / Request changes）
mcp__claude-in-chrome__find  query="Request changes radio"
mcp__claude-in-chrome__computer  action="left_click"  ref="..."

# 送信
mcp__claude-in-chrome__find  query="Submit review"
mcp__claude-in-chrome__computer  action="left_click"  ref="..."
```

## 完了報告

投稿完了後に以下を報告する：

- 成功件数 / 失敗件数
- 失敗した指摘とその理由（要素未検出・行ズレなど）

## 注意事項

- コメントの内容はユーザーが決めたものをそのまま投稿する（勝手に改変しない）
- 各操作の前後でスクリーンショットを撮って状態を確認する
- 「+」ボタンが出ない場合は行番号付近を再ホバーする
- `Submit review` は必ずユーザー最終確認の後に実行する
- UI 操作に3回失敗した場合はユーザーに報告して中断する

## 禁止事項

- コメント本文を勝手に要約・改変しない
- ユーザー確認なしで `Submit review` を押さない
- Claude in Chrome 以外の手段（CLI/API など）に切り替えない
