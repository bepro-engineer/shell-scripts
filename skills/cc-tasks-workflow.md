# cc-tasks ワークフロー

## 目的

このファイルは、cc-tasks を使った作業開始から終了までの固定手順を定義する。

## 開始から終了までの固定手順

1. cc-tasks の対象タスクを開始する

```bash
node ./dist/cli/index.js start タスク番号
```

例

```bash
node ./dist/cli/index.js start 6
```

2. 作業ブランチへ切り替わったことを確認する

```bash
git branch --show-current
git status
```

3. 対象ファイルを修正する

例

```bash
vi /home/bepro/projects/shell-scripts/com/logger.shrc
```

4. 構文確認を行う

```bash
bash -n 対象ファイル
```

例

```bash
bash -n com/logger.shrc
```

5. 差分確認を行う

```bash
git diff -- 対象ファイル
```

例

```bash
git diff -- com/logger.shrc
```

6. 問題なければ対象ファイルだけをステージする

```bash
git add 対象ファイル
```

例

```bash
git add com/logger.shrc
```

7. ローカルブランチへコミットする

```bash
git commit -m "修正内容"
git status
```

例

```bash
git commit -m "refactor: extract message expansion handling"
git status
```

8. 作業ブランチをリモートへ push する

```bash
git push -u origin 作業ブランチ名
```

例

```bash
git push -u origin feature/task-6-responsibility
```

9. GitHub 上で `main` と作業ブランチの差分を確認する

ここは確認だけです。マージはしません。

10. `main` へ戻る

```bash
git switch main
```

11. ローカルの `main` へ作業ブランチをマージする

```bash
git merge 作業ブランチ名
```

例

```bash
git merge feature/task-6-responsibility
```

12. マージ済み `main` をリモートへ反映する

```bash
git push origin main
```

13. ローカルの作業ブランチを削除する

```bash
git branch -d 作業ブランチ名
```

例

```bash
git branch -d feature/task-6-responsibility
```

14. リモートの作業ブランチを削除する

```bash
git push origin --delete 作業ブランチ名
```

例

```bash
git push origin --delete feature/task-6-responsibility
```

15. 最終確認を行う

```bash
git status
git branch -vv
node ./dist/cli/index.js list
```

## task6 を実名で置き換えた完全版

```bash
node ./dist/cli/index.js start 6
git branch --show-current
git status
vi /home/bepro/projects/shell-scripts/com/logger.shrc
bash -n com/logger.shrc
git diff -- com/logger.shrc
git add com/logger.shrc
git commit -m "refactor: extract message expansion handling"
git status
git push -u origin feature/task-6-responsibility
git switch main
git merge feature/task-6-responsibility
git push origin main
git branch -d feature/task-6-responsibility
git push origin --delete feature/task-6-responsibility
git status
git branch -vv
node ./dist/cli/index.js list
```
