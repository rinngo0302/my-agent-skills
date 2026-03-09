---
name: multi-pr-review
description: "複数のブランチ（PR）の git worktree を自動作成し、各ブランチを別ターミナルで個別にレビューできるよう準備するスキル。「複数のPRをレビューしたい」「2つのブランチを別々に確認したい」「/multi-pr-review」などと言われたときに使用する。"
---

# Multi PR Review

このスキルが読み込まれたら「Multi PR Review コマンドを読み込みました」と出力してください。

## 手順

### 1. ブランチ名の入力

**必ず AskUserQuestion ツールを使って**以下の質問をする。テキストで聞かずにツールを呼び出すこと。

- question: `レビューしたいブランチ名をカンマ区切りで入力してください。\n例: feature/login, fix/typo, main`

### 2. ブランチ名の正規化

各ブランチ名について、ブランチ名全体の `/` を `_` に置換した文字列をディレクトリ名サフィックスとして使用する（衝突回避のため）。

- `feature/app` → サフィックス: `feature_app`
- `fix/auth/token` → サフィックス: `fix_auth_token`
- `main` → サフィックス: `main`

### 3. Worktree の作成

現在の作業ディレクトリ名を `basename $(pwd)` で取得し、各ブランチに対して worktree を作成する。

```bash
git worktree add ../${DIRNAME}_${SANITIZED_BRANCH} ${BRANCH_FULL_NAME}
```

例: プロジェクトが `my-app`、ブランチが `feature/login` の場合:
```bash
git worktree add ../my-app_feature_login feature/login
```

**エラー処理**: worktree の作成に失敗した場合（ブランチが存在しない、既に worktree が存在するなど）は、そのブランチをスキップしてユーザーに通知する。

### 4. iTerm2 で新しいウィンドウを自動起動

worktree の作成が完了したら、各 worktree に対して iTerm2 の新しいウィンドウを開いて `claude` を起動する。

以下の AppleScript を Bash ツールで実行する（ブランチごとに1回ずつ）:

```bash
osascript <<EOF
tell application "iTerm2"
    create window with default profile
    tell current window
        tell current session
            write text "cd [WORKTREE_ABSOLUTE_PATH] && claude"
        end tell
    end tell
end tell
EOF
```

全ブランチ分の起動が完了したら、以下のメッセージを出力する:

```
各ブランチの iTerm2 ウィンドウを起動しました。

- [BRANCH_NAME_1]: [WORKTREE_ABSOLUTE_PATH_1]
- [BRANCH_NAME_2]: [WORKTREE_ABSOLUTE_PATH_2]

レビューが完了したら、このターミナルで「クリーンアップして」と伝えてください。
```

### 5. Worktree のクリーンアップ（ユーザーの指示を待つ）

ユーザーからクリーンアップの指示があったら、作成した worktree をすべて削除する。

```bash
git worktree remove ../${DIRNAME}_${SANITIZED_BRANCH}
git worktree prune
```

削除に失敗した場合は `--force` を安易に使わず、失敗した worktree と理由をユーザーに通知して対応方針を確認する。
削除完了後、「worktree をクリーンアップしました」とユーザーに通知する。
