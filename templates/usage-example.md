# Usage 記載例

## Usage 見本

```text
--------------------------------------
Usage:
  bash listShellDependencies.sh <file_path>

Options:
  -h, --help : Usage を表示

Example:
  bash listShellDependencies.sh /path/to/target.sh
--------------------------------------
```

## usage() 見本

```sh
usage() {
    cat >&2 <<'EOF'
--------------------------------------
Usage:
  bash backupFiles.sh -b <backup_directory>

Options:
  -b backup_directory : バックアップ保存先ディレクトリ

Example:
  bash backupFiles.sh -b /path/to/backup
--------------------------------------
EOF
}
```
