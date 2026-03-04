# my-agent-skills

自分のためのAgent Skillsを管理するリポジトリです。

## 概要

このリポジトリは、GitHub Copilotなどのエージェントに使用するカスタムスキル（プロンプト・指示）を一元管理するためのものです。

## ディレクトリ構成

```
my-agent-skills/
├── README.md           # このファイル
└── skills/             # スキル一覧
    ├── _template.md    # 新規スキル作成用テンプレート
    ├── coding/         # コーディング関連スキル
    ├── writing/        # ライティング関連スキル
    └── review/         # レビュー関連スキル
```

## スキルの追加方法

1. `skills/_template.md` をコピーして適切なカテゴリフォルダに配置する
2. テンプレートの各項目を埋める
3. プルリクエストまたは直接コミットで追加する

## スキル一覧

| スキル名 | カテゴリ | 説明 |
|----------|----------|------|
| [コードレビュー](skills/review/code-review.md) | review | コードレビューの観点と手順 |
| [コミットメッセージ生成](skills/coding/commit-message.md) | coding | 良いコミットメッセージの書き方 |
| [ドキュメント作成](skills/writing/documentation.md) | writing | ドキュメントの構成と記述方針 |
