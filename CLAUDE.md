# shell-scripts

## このリポジトリの目的

Shellスクリプト群の作成・整理・見直しを行う。

## 基本方針

このリポジトリ内の Shell Script 修正・追加・レビューでは、以下の規約を必ず優先すること。

- 修正は必ず関数単位で行う
- 既存コードの全面書き換えはしない
- まず現状整理、次に問題点抽出、その後に修正を行う
- 既存修正対象は都度指定されたファイルとする
- 新規作成時は用途に応じて `bin` `com` `etc` `log` `rep` `tmp` を使い分ける
- 指示されていないディレクトリ名・ファイル名・構造を勝手に新規作成しない
- 不明点は推測せず停止する
- 既存の関数名・変数名・責務を勝手に再設計しない
- 変更対象外の関数には触れない

## ディレクトリ構成

Shell スクリプト関連ファイルは、用途に応じて以下のディレクトリへ配置する。

- `bin`: 実行ファイル
- `com`: 共通シェルスクリプト
- `etc`: 設定ファイル
- `log`: ログ関連ファイル
- `rep`: 出力レポート
- `tmp`: 一時ファイル

詳細は `rules/shell-common.md` を参照する。

## 必須参照ファイル

以下のファイルを必ず参照すること。

@rules/shell-common.md
@rules/file-header.md
@rules/function-comments.md
@rules/usage.md
@rules/argument-validation.md
@rules/logging.md
@rules/review-policy.md
@rules/config-files.md

@templates/basicTemplate.sh
@templates/file-header-example.md
@templates/function-comment-example.md
@templates/usage-example.md

@skills/shell-review-workflow.md
@skills/shell-fix-workflow.md
@skills/cc-tasks-workflow.md

## 作業別の参照方針

### 新規 Shell Script 作成時

新規 Shell Script を作成する場合は、以下を必ず確認すること。

- `rules/shell-common.md`
- `rules/file-header.md`
- `rules/function-comments.md`
- `rules/usage.md`
- `rules/argument-validation.md`
- `rules/logging.md`
- `rules/config-files.md`
- `templates/basicTemplate.sh`
- `templates/file-header-example.md`
- `templates/function-comment-example.md`
- `templates/usage-example.md`
- `skills/shell-fix-workflow.md`

### 既存 Shell Script 修正時

既存 Shell Script を修正する場合は、以下を必ず確認すること。

- `rules/shell-common.md`
- `rules/function-comments.md`
- `rules/usage.md`
- `rules/argument-validation.md`
- `rules/logging.md`
- `rules/config-files.md`
- `skills/shell-fix-workflow.md`
- 対象ファイルの現在の実装

対象外の関数、対象外のファイル、既存セクション名、既存関数名は勝手に変更しない。

### レビュー時

レビューを行う場合は、以下を必ず確認すること。

- `rules/review-policy.md`
- `skills/shell-review-workflow.md`
- 対象ファイルの現在の実装

レビュー段階では、コード修正を行わない。

### cc-tasks 使用時

cc-tasks を使う作業では、以下を必ず確認すること。

- `skills/cc-tasks-workflow.md`

作業前に task を start する。
作業は feature ブランチで行う。
対象ファイルだけ add する。
main へ merge 後、push と branch 削除まで行う。

## 禁止事項

- 指示されていないファイルを編集しない
- 指示されていないディレクトリを作成しない
- 既存コードを全面書き換えしない
- 対象外の関数に触れない
- 不明点を推測で補完しない
- レビュー段階で git diff が発生する変更を行わない
- 修正段階へ進む前にコードを書き換えない
