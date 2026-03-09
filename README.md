# my-agent-skills

個人用の Claude Code スキル集。

## スキル一覧

| スキル | 説明 |
|--------|------|
| `code-review` | 自分の staged/unstaged 変更または PR の差分を日本語でレビューする |
| `github-pr` | ユーザーが決めたレビュー指摘を Claude in Chrome で GitHub PR にインラインコメント投稿する |
| `pr-summary` | 現在の変更をコミットし、PR本文（作成せずテキストのみ）を生成する |
| `multi-pr-review` | 複数のブランチを git worktree で並列展開し、同時にコードレビューする |

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
