---
name: issue-dashboard
description: 複数のGitHubリポジトリにまたがってアサインされているissueを一括管理するスキル。ghコマンドで全リポジトリのアサインissueを自動取得し、ターミナルに一覧表示後、AIがテーマ別にグルーピングしてこのリポジトリ（my-agent-skills）のissueとして登録する。「issueをまとめて」「アサインされているissueを確認したい」「issue dashboard」「/issue-dashboard」などと言われたときに使用する。「元issueがクローズされたか確認して」「クローズ確認」と言われた場合はStep 5を実行する。
---

# Issue Dashboard

複数リポジトリのアサインissueを収集→表示→グルーピング→登録する5ステップのワークフロー。

## ワークフロー

```
Step 1:   gh でアサインissueを全リポジトリから取得
Step 1.5: 除外するリポジトリをユーザーに選択させる（複数選択可）
Step 2:   ターミナルに一覧表示してユーザーに確認
Step 3:   Claudeがリポジトリ別・ドメイン別にグルーピング案を提示
Step 4:   ユーザー承認後、このリポジトリのissueに登録（重複チェックあり）
Step 5:   [フォローアップ] 元issueのクローズ状況を確認
```

**ドライランモード:** ユーザーが「ドライラン」「dry run」「確認だけ」と言った場合、Step 3 のグループ案表示で止める。Step 4 の issue 登録は行わない。

## Step 1: Issue とラベルの取得

以下を並行して実行する。

**アサインissueを取得:**

```bash
bash ~/Project/my-agent-skills/skills/issue-dashboard/scripts/fetch_issues.sh
```

スクリプトが失敗した場合はフォールバックとして直接実行:

```bash
gh search issues --assignee @me --state open \
  --json title,url,repository,body,labels,number,createdAt \
  --limit 100
```

**登録先リポジトリの既存ラベルを取得:**

```bash
gh label list --json name,description --limit 100
```

取得したラベル一覧を記憶しておく。Step 3 のラベル選定はこのリストの中からのみ行う。

## Step 1.5: 除外リポジトリの選択

取得したissueからユニークなリポジトリ名一覧を抽出し、リポジトリが2件以上ある場合は `AskUserQuestion` で除外するリポジトリを選択させる。

- `multiSelect: true` で複数選択可能にする
- 選択肢はユニークなリポジトリ名（最大4件まで表示）
- リポジトリが5件以上ある場合は件数が多い順に上位4件を表示し、残りは自動追加される "Other" に自由入力してもらう
- 質問文の例: 「除外するリポジトリを選択してください（不要なら何も選択せず続けてください）」
- 選択されたリポジトリのissueは以降のステップで除外する

リポジトリが1件のみの場合はこのステップをスキップする。

## Step 2: ターミナルへの一覧表示

取得したJSONを解析し、以下の形式でターミナルに表示する:

```
[N件のアサインissueが見つかりました]

#1  owner/repo — Issue Title
    URL: https://github.com/...
    作成日: YYYY-MM-DD
    ラベル: bug, frontend

#2  owner/repo2 — Another Issue Title
    ...
```

表示後、ユーザーに「このissueをグルーピングして登録しますか？」と確認する。

## Step 3: リポジトリ別グルーピング＋ラベル選定

**グルーピング方針: リポジトリを第一軸、テーマを第二軸とする。**

グルーピングを行う:
1. リポジトリ単位で分割（各リポジトリが親issueになる）
2. 各リポジトリ内でissueのタイトル・本文・ラベルを分析し、**ビジネスドメイン・機能領域**でサブグループ化（各テーマが子issueになる）
3. リポジトリ内のissueが1件のみの場合は子issue不要、親issueに直接記載

**グルーピング基準 — 技術レイヤーではなくドメインで分ける:**

- ✅ 良い例（ドメイン軸）: 認証・ログイン / 決済・課金 / 通知・メール / ユーザープロフィール / 検索・フィルタ / ダッシュボード・レポート / オンボーディング / 設定・環境構築
- ❌ 避ける例（技術レイヤー軸）: フロントエンド / バックエンド / API / インフラ / UI

issueのタイトル・本文からユーザーが何の機能に触れているかを読み取り、その機能名をグループ名にする。技術的な実装手段（フロントエンド実装、APIエンドポイント追加など）ではなく、ユーザーが利用する機能・画面・概念を軸にすること。

各グループに **Step 1 で取得したラベル一覧の中から** 最も適切なものを1〜2個選定する。リストにないラベルは使用しない。

グルーピング案を以下の形式で提示する:

```
【グループ案】

📦 owner/repo (5件)  ラベル: enhancement
  🔴 ログイン・認証 (2件)  ラベル: bug
    - [#12: Fix OAuth token expiry](https://github.com/owner/repo/issues/12)
    - [#18: Session management bug](https://github.com/owner/repo/issues/18)
  🟡 ダッシュボード (2件)  ラベル: enhancement
    - [#7: Dark mode implementation](https://github.com/owner/repo/issues/7)
    - [#9: Responsive layout fix](https://github.com/owner/repo/issues/9)
  📝 未分類 (1件)  ラベル: (なし)
    - [#3: Update dependencies](https://github.com/owner/repo/issues/3)

📦 owner/repo2 (2件)  ラベル: documentation
  🟡 開発者向けドキュメント (2件)  ラベル: documentation
    - [#5: Add API reference](https://github.com/owner/repo2/issues/5)
    - [#8: Update README](https://github.com/owner/repo2/issues/8)

📦 owner/repo3 (1件)  ラベル: enhancement
  - [#2: Add 2FA support](https://github.com/owner/repo3/issues/2)
```

ユーザーにグループ名・ラベルの変更や統合・分割の希望を確認する。

**ドライランモードの場合はここで終了。** Step 4 には進まない。

## Step 4: このリポジトリへのissue登録（親子構造）

ユーザーが承認したら、**リポジトリごとに親issueを作成し、テーマグループを子issue（Sub-issue）として紐付ける。**

**登録先リポジトリ:** 現在のリポジトリ（`gh repo view --json nameWithOwner -q .nameWithOwner` で取得）

### 4-0. 重複チェック

各リポジトリの親issue を作成する前に、同名issueが既に存在するか確認する:

```bash
gh issue list \
  --search "【{owner/repo}】アサインissueまとめ" \
  --state open --json number,url --limit 1
```

既存issueが見つかった場合、ユーザーに選択させる:
- **更新**: 既存issueをクローズ（`gh issue close {number} --reason "not planned"`）してから新規作成
- **スキップ**: このリポジトリの親issueの作成をスキップ

### 4-1. 親issueを作成

```bash
PARENT_URL=$(gh issue create \
  --title "【{owner/repo}】アサインissueまとめ" \
  --label "{選定したラベル}" \
  --body "$(cat <<'EOF'
## 対象リポジトリ
{owner/repo} のアサインissue一覧

## 元issue一覧
- [ ] [Issue Title](https://github.com/owner/repo/issues/N) — owner/repo#N
...

## 備考
このissueはissue-dashboardスキルにより自動生成されました（{日付}）。
EOF
)")
```

### 4-2. 子issueを作成してSub-issueとして紐付け

テーマグループごとに子issueを作成し、`scripts/link_subissue.sh` で親に紐付ける:

```bash
CHILD_URL=$(gh issue create \
  --title "【{owner/repo}】{テーマ名}" \
  --label "{選定したラベル}" \
  --body "$(cat <<'EOF'
## 概要
{テーマの説明}

## 元issue一覧
- [ ] [Issue Title](https://github.com/owner/repo/issues/N) — owner/repo#N
- [ ] [Issue Title](https://github.com/owner/repo/issues/N) — owner/repo#N

## 備考
このissueはissue-dashboardスキルにより自動生成されました（{日付}）。
EOF
)")

# 親issueのSub-issueとして登録
bash ~/Project/my-agent-skills/skills/issue-dashboard/scripts/link_subissue.sh "$PARENT_URL" "$CHILD_URL"
```

### 4-3. 完了報告

全グループの登録完了後、作成したissueのURLツリーを表示する:

```
✅ 登録完了

📦 owner/repo → {PARENT_URL}
  └─ ログイン・認証     → {CHILD_URL_1}
  └─ ダッシュボード     → {CHILD_URL_2}

📦 owner/repo2 → {PARENT_URL_2}
  └─ 開発者向けドキュメント → {CHILD_URL_3}
```

## Step 5: クローズ確認（フォローアップ）

「元issueがクローズされたか確認して」「クローズ確認」と言われた場合に実行する。

`scripts/check_closed.sh` を実行して、ダッシュボードissueに記載された元issueの現在ステータスを一括チェックする:

```bash
bash ~/Project/my-agent-skills/skills/issue-dashboard/scripts/check_closed.sh
```

出力例:

```
元issueのステータスを確認中... (12件)

✅ CLOSED: https://github.com/owner/repo/issues/12
✅ CLOSED: https://github.com/owner/repo/issues/18
🔵 OPEN:   https://github.com/owner/repo2/issues/5
🔵 OPEN:   https://github.com/owner/repo2/issues/8
❓ NOT FOUND: https://github.com/owner/repo3/issues/2

結果: OPEN 2件 / CLOSED 2件 / NOT FOUND 1件
```

クローズ済み元issueが見つかった場合、対応するダッシュボードissueのチェックボックスを更新するかユーザーに確認する。

## ユーザーへの質問

ユーザーに選択や確認を求める場面では必ず `AskUserQuestion` ツールを使う。該当する場面:

- Step 2: グルーピングして登録するか確認するとき
- Step 3: グループ名・ラベルの変更・統合・分割の希望を確認するとき
- Step 4-0: 重複issueが見つかったとき（更新 or スキップの選択）
- Step 5: クローズ済み元issueに対応するダッシュボードissueを更新するか確認するとき

## 注意事項

- `gh auth status` でGitHub認証済みであることを確認してから実行する
- issue件数が多い場合（20件超）はグルーピング前にフィルタリングを提案する
- 本文が長いissueは要約して記載する
- Sub-issue機能はGitHub側で有効になっている必要がある（2024年以降のリポジトリでは通常利用可）
