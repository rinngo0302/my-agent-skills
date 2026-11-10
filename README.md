# my-agent-skills

Claude Code と Codex で使う個人用スキル集。

## スキル一覧

| スキル | 対応環境 | 説明 |
|--------|----------|------|
| `code-review` | Claude / Codex | 自分の staged/unstaged 変更または PR の差分を日本語でレビューする |
| `code-review-learn` | Claude / Codex | 自分の PR に付いたレビューを取得してリポジトリごとにまとめ、`code-review` の観点に加える(`review/` はコミットしない) |
| `pr-summary` | Claude / Codex | PR本文を生成する（PRは作成せず、本文テキストのみ） |
| `sim-use` | Claude / Codex | iOS Simulator / Android Emulator・実機を操作する |
| `grilling` | Claude / Codex | 計画・判断・アイデアを設計ツリーで深掘りする |
| `commit-plan` | Claude / Codex | staged差分をレビューしやすい複数コミットへ分割し、承認後に作成する |
| `github-pr` | Claude のみ | ユーザーが決めたレビュー指摘を Claude in Chrome で GitHub PR にインラインコメント投稿する |
| `issue-dashboard` | 対象外 | 複数リポジトリのアサイン issue を集約・管理する |
| `multi-pr-review` | Claude のみ | 複数のブランチを git worktree で並列展開し、同時にコードレビューする |

`github-pr`、`issue-dashboard`、`multi-pr-review` の Codex 対応は今回の対象外です。

## 使い方

### 方法1: グローバルスキルとして登録する（複数リポジトリで使うならこれ）

`~/.claude/skills/` に置いたスキルは GitHub もマーケットプレイスも不要で、すべてのプロジェクトから自動認識される。

```bash
# このリポジトリをクローン（任意の場所でOK）
git clone https://github.com/rinngo0302/my-agent-skills ~/Project/my-agent-skills

# ~/.claude/skills/ にシンボリックリンクを作成
mkdir -p ~/.claude/skills
ln -s ~/Project/my-agent-skills/skills ~/.claude/

# ~/.claude/agents/ にサブエージェントのシンボリックリンクを作成
mkdir -p ~/.claude/agents
for f in ~/Project/my-agent-skills/agents/*.md; do
  ln -s "$f" ~/.claude/agents/
done
```

以降は Claude Code を起動するだけでどのプロジェクトからでもスキルが使える。

### Codex に登録する

Codex は既存の `~/.codex/skills/.system` を残したまま、対応スキルだけを個別にリンクする。

```bash
mkdir -p ~/.codex/skills

for skill in code-review code-review-learn pr-summary sim-use grilling commit-plan; do
  ln -s ~/Project/my-agent-skills/skills/"$skill" ~/.codex/skills/"$skill"
done
```

リンク先が既に存在する場合は削除・上書きをせず、内容を確認してから対応すること。

以降は Codex を起動するだけで、5スキルをどのプロジェクトからでも使える。

### 方法2: 特定のプロジェクトだけで使う

```bash
# 作業リポジトリのルートで実行
ln -s ~/Project/my-agent-skills/skills .claude/skills
```

### シンボリックリンクの確認・削除

```bash
ls -la ~/.claude/skills    # 確認（グローバル）
rm ~/.claude/skills        # 削除（グローバル）
```

```bash
# Codex のリンク確認（.system が残っていることも確認する）
ls -la ~/.codex/skills
readlink ~/.codex/skills/code-review
readlink ~/.codex/skills/pr-summary
readlink ~/.codex/skills/sim-use
readlink ~/.codex/skills/grilling
readlink ~/.codex/skills/commit-plan

# Codex のリンク削除（対象5スキルのみ）
rm ~/.codex/skills/code-review
rm ~/.codex/skills/pr-summary
rm ~/.codex/skills/sim-use
rm ~/.codex/skills/grilling
rm ~/.codex/skills/commit-plan
```
