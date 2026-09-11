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

附件库中已存在的对象会跳过，重复导入幂等。

依赖：`unzip`、`node`。

## 跨工作空间迁移

若直接运行脚本，启动时会报错。请参照 [cross-workspace.md](./docs/cross-workspace.md) 完成迁移。
