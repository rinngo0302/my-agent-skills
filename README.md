# my-agent-skills

個人用の Claude Code スキル集。

## スキル一覧

| スキル | 説明 |
|--------|------|
| `code-review` | staged/unstaged の変更または PR の差分を日本語でレビューする |

## 使い方

### 方法1: グローバルスキルとして登録する（複数リポジトリで使うならこれ）

`~/.claude/skills/` に置いたスキルは GitHub もマーケットプレイスも不要で、すべてのプロジェクトから自動認識される。

```bash
# このリポジトリをクローン（任意の場所でOK）
git clone https://github.com/rinngo0302/my-agent-skills ~/Project/my-agent-skills

# ~/.claude/skills/ にシンボリックリンクを作成
mkdir -p ~/.claude/skills
ln -s ~/Project/my-agent-skills/code-review ~/.claude/skills/code-review
```

以降は Claude Code を起動するだけでどのプロジェクトからでもスキルが使える。

### 方法2: 特定のプロジェクトだけで使う

```bash
# 作業リポジトリのルートで実行
ln -s ~/Project/my-agent-skills/code-review .claude/skills/code-review
```

### シンボリックリンクの確認・削除

```bash
ls -la ~/.claude/skills/code-review    # 確認（グローバル）
rm ~/.claude/skills/code-review        # 削除（グローバル）
```
