# 跨工作空间迁移

思路：把 `header.cwd` 改成目标目录，并把日志放到该 cwd 对应的项目目录下。

设目标目录 `TARGET=/path/to/workspace`：

1. 放到 `~/.dsh/sessions/$KEY/<session-id>/`
2. 把 header 里 `"cwd"` 改成 `TARGET`
3. 重新按原生帧格式编码

```bash
ZIP=/path/to/src/dsh-session-session-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.zip
TARGET=/path/to/workspace
KEY="--$(printf '%s' "$TARGET" | sed 's#[/\\:][/\\:]*#-#g; s#^-\{1,\}##')--"
SID=session-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
DEST="$HOME/.dsh/sessions/$KEY/$SID"
mkdir -p "$DEST"

# 1. 先按 zip 的 header cwd 放好，再迁移
./bin/import-session-0.1.5-rc.1.sh "$ZIP" "$DEST"

# 2. 改 header 的 cwd
zstd -dc "$DEST/session.v3.jsonl.zstd" | sed "1s#\"cwd\":\"[^\"]*\"#\"cwd\":\"$TARGET\"#" > /tmp/plain.jsonl

# 3. 重编为 header 帧 + 事件帧
node -e '
const fs=require("node:fs"),z=require("node:zlib");
const [src,out]=process.argv.slice(1);
const c=b=>new Promise((res,rej)=>z.zstdCompress(b,{params:{[z.constants.ZSTD_c_checksumFlag]:1}},(e,r)=>e?rej(e):res(r)));
(async()=>{const s=fs.readFileSync(src),i=s.indexOf(10)+1;
const f=[await c(s.subarray(0,i))];if(i<s.length)f.push(await c(s.subarray(i)));
fs.writeFileSync(out,Buffer.concat(f));})();' /tmp/plain.jsonl "$DEST/session.v3.jsonl.zstd"
```

最后重新运行 `dsh web` 打开界面，导入的对话期望出现在 `Ungrouped` 分类。如需继续之前的对话，请参照 [reconstruct-workspace.md](./reconstruct-workspace.md) 重建 Workspace 域。
