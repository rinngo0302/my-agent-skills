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
- **返信する相手のユーザー名**（例: `@octocat`。返信コメントがある場合は必須）

補足: このスキルに専用の引数定義はないため、必要情報は会話内で渡してもらう（例: `返信先ユーザー名: @octocat`）。

投稿前に指摘リストをユーザーに一覧表示して最終確認を取る：

```
PR: owner/repo#123  件数: 3件
返信先ユーザー名: @octocat

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
座標の直指定は原則禁止とし、`find` で要素を特定して `ref` クリックを最優先する（座標クリックは最後の手段）。

### 3-1. 対象行を探す

```
# ファイル名や行の内容でコメント先を探す
mcp__claude-in-chrome__find  query="ファイル名 または 行内容のキーワード"
```

見つからない場合はスクロールして再検索する：

```
mcp__claude-in-chrome__computer  action="scroll"  coordinate=[760, 400]  scroll_direction="down"
```

`find → スクロール → 再find` を最大3回繰り返しても見つからない場合は、スクリーンショット付きでユーザーに報告して中断する。

### 3-2. 「+」ボタンを表示してクリック

**重要**: `+` ボタンは hover state でのみ DOM に現れる。hover → 即 find → ref クリック の順を崩さないこと。
hover 後にマウスを大きく動かすと hover state が外れてボタンが消えるため、座標クリックは厳禁。

```
# 1. 行番号付近の要素を find で特定してホバーし、「+」を出す
mcp__claude-in-chrome__find  query="対象行のテキスト または 行番号"
mcp__claude-in-chrome__computer  action="hover"  ref="行要素の ref"

# 2. hover 直後（マウスを動かす前）に find で「+」ボタンの ref を取得してクリック
mcp__claude-in-chrome__find  query="Add comment"
mcp__claude-in-chrome__computer  action="left_click"  ref="+ボタンの ref"
```

### 3-3. コメントを入力する

```
# テキストエリアを探してクリック
mcp__claude-in-chrome__find  query="comment text area"
mcp__claude-in-chrome__computer  action="left_click"  ref="テキストエリアの ref"

# コメントを入力
# 返信コメントでは、先頭で返信先ユーザー名を必ずメンションする（例: "@octocat コメント本文"）
mcp__claude-in-chrome__computer  action="type"  text="@返信先ユーザー名 コメント本文"
```

#### マークダウンリストを含むコメントの入力方法

**注意**: GitHub のマークダウンエディタはリスト内で Enter を押すと次の行に `- ` を自動追加する。
`type` で全テキストを一度に入力すると改行のたびに `- ` が重複してネストした箇条書きになる。

正しい入力手順：
1. 最初のリスト項目のみ `- 内容` で type する
2. Enter を押す（GitHub が次の行に `- ` を自動追加する）
3. 以降の項目は `- ` を打たずにコンテンツだけ type する

```
# 例: 5項目のリストを入力する場合
mcp__claude-in-chrome__computer  action="type"  text="本文（リスト前の説明）"
mcp__claude-in-chrome__computer  action="key"   text="Return Return"
mcp__claude-in-chrome__computer  action="type"  text="- 1番目の項目"    # ← 最初だけ「- 」を自分で入力
mcp__claude-in-chrome__computer  action="key"   text="Return"            # GitHub が「- 」を自動追加
mcp__claude-in-chrome__computer  action="type"  text="2番目の項目"       # ← 「- 」は打たない
mcp__claude-in-chrome__computer  action="key"   text="Return"
mcp__claude-in-chrome__computer  action="type"  text="3番目の項目"
# ... 以降同様
mcp__claude-in-chrome__computer  action="key"   text="Return Return"     # リスト終了（空行2つ）
mcp__claude-in-chrome__computer  action="type"  text="締めの文"
```

入力後は必ず Preview タブで表示を確認してから送信すること。

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

# 総評を入力
# - Approve（LGTM）の場合は固定で以下をそのまま入力:
#   :+1:
#   LGTMです！
# - それ以外はユーザーから受け取った内容（なければ空欄）
mcp__claude-in-chrome__find  query="review summary text area"
mcp__claude-in-chrome__computer  action="left_click"  ref="..."
# 例:
# - Approve: text=":+1:\nLGTMです！"
# - それ以外: text="総評テキスト"
mcp__claude-in-chrome__computer  action="type"  text="..."

# レビュー種別を選択（Comment / Approve / Request changes）
# - LGTM の場合は必ず Approve を選択
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
- 「+」ボタンが出ない場合は行番号付近を再ホバーし、`find` で再取得する
- `Submit review` は必ずユーザー最終確認の後に実行する
- UI 操作に3回失敗した場合はユーザーに報告して中断する
- Approve する場合の総評は `:+1:` と `LGTMです！` をそのまま使う
- 座標クリックは原則禁止。`find` + `ref` で失敗した場合のみ最後の手段として使う

## 禁止事項

- コメント本文を勝手に要約・改変しない
- ユーザー確認なしで `Submit review` を押さない
- Claude in Chrome 以外の手段（CLI/API など）に切り替えない
