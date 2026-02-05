# Kubuntu 24.04 初始化脚本

本仓库提供 `init.sh` 一键初始化脚本，用于 Kubuntu 24.04 的基础工具、开发环境、字体与常用软件安装，并包含代理、镜像、交互勾选与dry-run能力。

## 功能概览

- 国内软件源替换（清华镜像）
- 基础依赖、输入法、驱动、常用软件（含 GoldenDict-ng）
- Docker（含镜像加速）、Java/Maven、Node.js、Go、Miniconda
- 字体安装（JetBrainsMono Nerd Font / Inter / LXGW WenKai）
- Shell 环境（zsh / starship / zoxide）
- Typora 安装与 Electron 沙盒权限修复
- Antigravity 安装
- **MT7922 Wi‑Fi 检测**：自动设置 GRUB 参数并提示蓝牙注意事项
- **dry-run**：仅打印命令，不执行、不写状态
- **交互勾选**：以“打钩”方式选择要安装的软件项（使用 `whiptail`，脚本会自动安装）
- **proxy_on/proxy_off**：生成同名命令与 shell 函数，便于一键开关本地代理环境变量

## 运行方式

### 正常执行（checkbox，默认）

```bash
bash "init.sh"
```

说明：交互界面依赖 `whiptail`，脚本会自动执行 `sudo apt install -y whiptail`（你已确认）。
在勾选界面按 `Cancel` 或 `Esc` 会直接退出脚本，不会执行任何安装。

### 不进入交互（全量安装）

```bash
bash "init.sh" --no-interactive
```

### Dry-run（演示模式）

```bash
bash "init.sh" --dry-run
```

说明：dry-run 仅打印将执行的命令，不会修改系统，也不会写入步骤状态文件。

## MT7922 网卡说明

如果检测到 MT7922 网卡，脚本会将 `/etc/default/grub` 中的：

```
GRUB_CMDLINE_LINUX_DEFAULT='quiet splash pci=noaer acpi_backlight=vendor pcie_aspm=off mem_sleep_default=deep i8042.reset i8042.nomux'
```

写入/更新到目标值，并自动执行 `update-grub`。  
同时会提示：

> MT7922 蓝牙当前仍不成熟；睡眠之前请关闭蓝牙。

## 代理与镜像

- GitHub 资源支持多镜像轮询
- APT、Docker、NPM、Maven、Conda 镜像已预置
- 代理端口可交互输入并缓存
- 提供 `proxy_on`/`proxy_off`（写入 `~/.zshrc`、`~/.bashrc` 与 `~/.local/bin`）

## 结构说明

- `init.sh`：入口脚本（转调到 `scripts/run.sh`）
- `scripts/run.sh`：调度器（解析参数、初始化环境、按顺序执行步骤）
- `scripts/lib/common.sh`：公共函数库（代理、下载、交互选择、通用工具函数等）
- `scripts/steps/*`：按步骤拆分的子脚本
- `sub.yaml`：备用/相关配置（如需）

## 注意事项

- 脚本包含大量 `sudo` 操作，请在确认内容后执行。
- 第一次执行建议先 `--dry-run` 预览操作。
- 若修改了 GRUB 参数，需重启系统生效。
