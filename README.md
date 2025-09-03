# Gentoo 全系统重建脚本

本仓库提供一个 **安全且可恢复的脚本**，用于完全重建 Gentoo Linux 系统。  
它自动执行同步、更新、深度清理，以及运行 `emerge -e @system` 和 `emerge -e @world`，  
同时带有日志记录和检查点机制，确保即使过程中出现问题也能继续。

---

## 功能特点

- 🔄 **完整的重建流程**：
  1. 同步 Portage 树
  2. 更新 `@world`
  3. 移除未使用的依赖（depclean）
  4. 执行 `revdep-rebuild`
  5. 清理 distfiles 和旧的二进制包
  6. 重新编译 `@system`
  7. 重新编译 `@world`
  8. 最终执行 `revdep-rebuild`
  9. 输出总结并检查过时包

- 📜 **完整日志**：  
  所有操作会记录到 `/var/log/gentoo-rebuild/full-rebuild-<时间戳>.log`。

- ⏸ **断点续跑**：  
  如果过程中出错，修复问题后 **重新运行脚本**，它会从失败的步骤继续。

- ⚙️ **并行编译支持**：  
  自动检测 CPU 核心数 (`nproc`)，并设置 `--jobs` / `--load-average`。  
  你也可以手动指定，例如：
  ```bash
  JOBS=4 LOAD_AVG=4 bash full-rebuild-gentoo.sh

* 🛡 **安全机制**：

  * 必须以 root 用户执行
  * 自动备份 `/etc/portage/make.conf` 和 `world` 文件
  * 重建前提示磁盘空间使用情况

---

## 使用方法

### 1. 下载脚本

保存脚本为：

```bash
full-rebuild-gentoo.sh
```

赋予执行权限：

```bash
chmod +x full-rebuild-gentoo.sh
```

### 2. 在 `tmux` 或 `screen` 中运行

由于编译时间可能非常长，建议使用会话管理工具：

```bash
tmux new -s rebuild
./full-rebuild-gentoo.sh
```

### 3. 查看进度

* 日志：`/var/log/gentoo-rebuild/`
* 当前步骤：`/var/tmp/full-rebuild.step`

### 4. 出错后恢复

如果脚本中断：

1. 先解决问题（例如屏蔽坏包、调整 USE flag）。
2. 再次运行脚本：

   ```bash
   ./full-rebuild-gentoo.sh
   ```

   它会从失败的步骤继续执行。

---

## 注意事项

* 本脚本 **不会自动重建内核**。
  如果需要重建内核及模块，请在完成 world 重建后单独执行。

* 如果你希望重复重建更快，建议启用二进制包缓存：

  ```bash
  EMERGE_DEFAULT_OPTS="--buildpkg" emerge -e @world
  ```

* 大规模重建（如 stage4 升级）前，请确保：

  * 磁盘空间充足（`df -h`）
  * 散热良好（编译会长期占用 CPU）

---

## 示例输出

```bash
===== STEP: 06-emerge-e-system =====
>>> 正在重建 system 集合
...
===== STEP: 07-emerge-e-world =====
>>> 正在重建 world 集合
...
### 完成于 2025-09-04 04:30
日志文件: /var/log/gentoo-rebuild/full-rebuild-20250904-0430.log
```

---

## 风险提示

使用风险自负，欢迎改进和贡献！


