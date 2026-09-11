# dsh-session-log-import
一个简单的脚本，可用于导入之前导出的 session log。

## 用法
```sh
./bin/import-session-0.1.5-rc.1.sh <session-export.zip> <destination-session-dir>
```

示例：
```sh
./bin/import-session-0.1.5-rc.1.sh /path/to/src/dsh-session-session-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.zip ~/.dsh/sessions/--path-to-workspace--/session-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 说明

写入：

- `<dest>/session.v3.jsonl.zstd`
- `<dest>/session.lock`
- `<attachroot>/v1/objects/<h[0:2]>/<h[2:]>`

`<dest>` 位于 `$DSH_HOME/sessions/` 下时，`<attachroot>` 为 `$DSH_HOME/attachments`；路径中含 `/sessions/` 时，则为 `<dest>/../../attachments`。

依赖：`unzip`、`node`。
