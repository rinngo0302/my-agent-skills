# コミットメッセージ生成

## 概要

`git diff` の内容から適切なコミットメッセージを生成するスキルです。
Conventional Commits 形式に準拠したメッセージを作成します。

## プロンプト

```
以下の git diff を確認して、Conventional Commits 形式のコミットメッセージを生成してください。

形式:
<type>(<scope>): <summary>

[任意の本文]

type の種類:
- feat: 新機能
- fix: バグ修正
- docs: ドキュメントのみの変更
- style: コードの動作に影響しない変更（空白、フォーマット等）
- refactor: バグ修正でも機能追加でもないコード変更
- test: テストの追加・修正
- chore: ビルドプロセスや補助ツールの変更

サマリーは命令形・現在形で50文字以内に収めてください。
```

## 使用例

**入力例:**

```diff
diff --git a/src/auth.js b/src/auth.js
+function validateToken(token) {
+  if (!token) throw new Error('Token is required');
+  return jwt.verify(token, process.env.SECRET);
+}
```

**出力例:**

```
feat(auth): add token validation function
```

## メモ

- scope はファイル名やモジュール名を使う
- 日本語プロジェクトでは日本語サマリーも可
