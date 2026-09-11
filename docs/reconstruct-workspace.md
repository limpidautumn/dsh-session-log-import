# 重建 Workspace 域

用于修复会话 / workspace 绑定问题。

## 步骤
1. 停掉 `dsh web`
2. 执行命令：
```bash
cp ~/.dsh/storages/workspace.json ~/.dsh/storages/workspace.json.bak
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home()/'.dsh/storages/workspace.json'
d = json.loads(p.read_text())
d['global']['initialized'] = False # 重跑 bootstrap
p.write_text(json.dumps(d, ensure_ascii=False, indent=2))
PY
```
3. 重新打开 `dsh web`。
