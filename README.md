# 翼龙 15 Pro → Linux（Kubuntu 24.04）迁移/初始化脚本

面向 **翼龙 15 Pro**（笔记本）从 Windows/原系统迁移到 Linux 后的“一键初始化”脚本，目标发行版为 **Kubuntu 24.04**，并以 **最小安装（Minimal Installation）** 作为基准环境进行补齐与配置。

默认行为：**启动即进入交互式勾选界面**，并且 **默认全选**（回车即按全量执行）。  
在勾选界面按 `Cancel` 或 `Esc` 会 **直接退出脚本且不做任何安装/修改**。

## 功能概览（分区表格）

| 分区 | 内容 | 备注（脚本额外动作） |
| --- | --- | --- |
| 软件源/镜像 | APT / Docker / NPM / Maven / Conda / Go / GitHub 镜像 | 自动应用到对应工具；GitHub 下载支持镜像轮询 |
| 驱动/硬件 | 自动安装推荐驱动；NVIDIA DRM 检测与启用；MT7922 相关 GRUB 参数 | NVIDIA：写入 `nvidia-drm modeset=1` 并更新 initramfs |
| 基础依赖 | 常用 CLI、构建工具、输入法、Wayland 会话、媒体/系统工具等 | 以 Kubuntu 24.04 最小安装为基准补齐 |
| 命令/入口 | `proxy_on` / `proxy_off` | 同时写入 `~/.zshrc`、`~/.bashrc` 与 `~/.local/bin` |
| 常用软件 | 按功能分组安装：浏览器/IDE/通信/办公/远控/下载/终端等 | 部分软件通过 GitHub Release/官网直链拉取 `.deb` |
| 代理 | 默认提示并使用本地代理端口（可跳过） | 影响 APT/GitHub 下载/Docker systemd proxy 等 |

## 运行方式

### 默认执行（checkbox，默认全选）

```bash
bash "init.sh"
```

说明：交互界面依赖 `whiptail`，脚本会自动执行 `sudo apt install -y whiptail`。

### 不进入交互（全量安装）

```bash
bash "init.sh" --no-interactive
```

### Dry-run（演示模式）

```bash
bash "init.sh" --dry-run
```

说明：dry-run 仅打印将执行的命令，不会修改系统，也不会写入步骤状态文件。

## 使用的源与镜像（详细）

| 工具/场景 | 源/镜像 | 作用 |
| --- | --- | --- |
| APT（Ubuntu） | `mirrors.tuna.tsinghua.edu.cn` | 替换默认 Ubuntu archive/security 镜像 |
| GitHub 下载镜像 | `ghfast.top` / `mirror.ghproxy.com` / `hub.gitmirror.com` / 直连 | 拉取 Release 资产/zip 时容灾与加速 |
| Docker 镜像 | `docker.m.daocloud.io` / `dockerproxy.com` | 写入 `/etc/docker/daemon.json` 作为 registry mirror |
| NPM | `registry.npmmirror.com` | `npm config set registry` |
| Maven | `maven.aliyun.com/repository/public` | 写入 `~/.m2/settings.xml` mirror |
| Conda | `mirrors.tuna.tsinghua.edu.cn/anaconda` | 安装与 channels 配置 |
| Go 下载 | `mirrors.aliyun.com/golang`（失败回退官方） | 优先镜像下载 tar.gz |

补充：以下软件使用官网直链/页面解析下载（不经 APT 源），便于对照与排障：

| 软件 | 下载来源 |
| --- | --- |
| Chrome | `dl.google.com` |
| VS Code | `code.visualstudio.com` |
| WeChat | `dldir1.qq.com` |
| DBeaver CE | `dbeaver.io` |
| WPS Office | `linux.wps.cn`（页面） + `wps-linux-personal.wpscdn.cn`（deb） |
| Typora | `download.typora.io` |
| Sublime Merge | `download.sublimetext.com`（APT 源） |

## 驱动初始化（详细）

| 类别 | 动作 | 触发条件/备注 |
| --- | --- | --- |
| 通用推荐驱动 | `sudo ubuntu-drivers autoinstall` | 安装 Ubuntu 推荐驱动（含 NVIDIA 等） |
| NVIDIA（Wayland 关键） | 检测 `/sys/module/nvidia_drm/parameters/modeset`，未开启则写入 `options nvidia-drm modeset=1` 并 `update-initramfs -u` | 让 NVIDIA 在 Wayland 下更稳定；需要重启后生效 |
| MT7922 / Wi‑Fi | 写入/更新 `/etc/default/grub` 的 `GRUB_CMDLINE_LINUX_DEFAULT` 并执行 `update-grub` | 检测到 MT7922 与否使用不同默认参数 |

## 基础依赖（详细）

说明：此处以 **Kubuntu 24.04 最小安装**为起点，脚本补齐以下基础包（节选自 `scripts/steps/01_core.sh`）。

| 分类 | 安装内容 |
| --- | --- |
| 基础工具 | `curl` `wget` `jq` `grep` `git` `build-essential` `software-properties-qt` `apt-transport-https` `unzip` `net-tools` |
| 性能/运行库 | `libtcmalloc-minimal4` |
| 桌面/会话 | `plasma-workspace-wayland`（Plasma Wayland 会话） |
| 输入法 | `im-config` `fcitx5` `fcitx5-chinese-addons` `fcitx5-rime` `fcitx5-config-qt` `fcitx5-frontend-gtk2/gtk3/qt5` `librime-data-*` |
| 系统/多媒体 | `yakuake` `btop` `vlc` `okular` `wireshark` `calibre` `ffmpegthumbs` |
| Shell/字体 | `zsh` `fonts-firacode` |
| Git GUI | `gitg` |
| 交互 UI | `whiptail`（默认交互式勾选依赖） |

## 添加/生成的命令（详细）

| 命令 | 位置 | 作用 |
| --- | --- | --- |
| `proxy_on [port]` | `~/.local/bin/proxy_on` + `~/.zshrc`/`~/.bashrc` 函数 | 设置 `http(s)_proxy/all_proxy`（默认读取缓存端口文件） |
| `proxy_off` | `~/.local/bin/proxy_off` + `~/.zshrc`/`~/.bashrc` 函数 | 清理上述代理环境变量 |
| `typora` | `/usr/local/bin/typora` | Typora 安装后创建的软链接（指向 `/opt/typora/Typora`） |

## 常用软件与开发环境

> 说明：默认全选；可在交互界面取消勾选。不同软件来源/额外动作见备注列。

| 功能分区 | 软件 | 安装方式 | 备注（脚本额外工作） |
| --- | --- | --- | --- |
| 词典/阅读 | GoldenDict-ng | APT | 通过代理参数执行 `apt update/install` |
| 浏览器 | Google Chrome | 官网 `.deb` | `smart_install_deb` 自动下载并 `apt install` |
| 开发/IDE | Visual Studio Code | 官网直链 `.deb` | 同上 |
| 开发/IDE | Antigravity | 官方源 | 写入 keyring + source.list 并安装（默认全选可取消） |
| 数据库工具 | DBeaver CE | 官网 `.deb` | 同上 |
| 即时通信 | WeChat | 官网 `.deb` | 同上 |
| 即时通信 | Linux QQ | 官网页面解析最新 `.deb` | 失败则跳过，不中断 |
| 办公 | WPS Office | 从 `linux.wps.cn/wpslinuxlog` 抓取最新 `12.1.2.*` 的 `amd64.deb` | 宽松匹配 + 版本限制，抓取失败跳过 |
| 版本控制 | Sublime Merge | 官方 APT 源 | 导入 GPG key + 写入源 + APT 安装 |
| 终端 | Tabby Terminal | GitHub Release `.deb` | GitHub 镜像轮询下载 |
| 下载 | Motrix | GitHub Release `.deb` | GitHub 镜像轮询下载 |
| 远程控制 | RustDesk | GitHub Release `.deb` | GitHub 镜像轮询下载 |
| 文档写作 | Typora | tar.gz | 安装到 `/opt/typora` 并修复 Electron sandbox 权限、写入 desktop 文件 |
| 终端增强 | Yakuake | APT | 作为下拉终端 |
| 系统监控 | btop | APT |  |
| 多媒体 | VLC | APT |  |
| 文档阅读 | Okular | APT |  |
| 抓包 | Wireshark | APT |  |
| 电子书 | Calibre | APT |  |
| Git GUI | gitg | APT |  |
| Shell | zsh + starship + zoxide | APT + 安装脚本 | 写入 `~/.zshrc` 初始化语句 |
| 字体 | FiraCode / JetBrainsMono Nerd Font / Inter / LXGW WenKai | APT + GitHub Release | `~/.local/share/fonts` 并 `fc-cache` |
| Docker | Docker + Portainer | get.docker.com + Docker Hub | 写入 registry mirror；如设置代理端口则写 systemd proxy drop-in |
| Java/Maven | SDKMan（优先）/ APT（兜底） | 安装脚本 + APT | 写入 `~/.m2/settings.xml` 使用阿里云 Maven 镜像 |
| Node.js | fnm 安装 LTS | 安装脚本 | 设置 NPM 镜像源 |
| CLI 工具 | Claude Code / Codex | `npm -g` | `claude_codex` 选项；依赖 Node |
| Go | tar.gz（镜像优先） | 下载解压 | 安装到 `/usr/local/go`，并在后续步骤写入 `~/.zshrc` 添加 PATH |
| Python/Conda | Miniconda | 安装脚本 | init bash/zsh；配置 TUNA channels |

## 代理（默认使用，可开/关）

脚本默认会走“本地代理”流程：在早期阶段**提示输入代理端口**（可回车跳过），并将端口缓存到 `~/Downloads/kubuntu_master_cache/.state/proxy_port`；后续执行时会优先读取该缓存端口并尽可能使用代理。  
后续会在以下场景使用代理：

| 场景 | 使用方式 |
| --- | --- |
| APT（部分安装步骤） | 通过 `Acquire::http(s)::Proxy` 参数 |
| GitHub 下载 | 镜像轮询失败后，尝试本地代理下载 |
| Docker | 写入 systemd drop-in：`/etc/systemd/system/docker.service.d/http-proxy.conf` |

日常开关：使用 `proxy_on` / `proxy_off`（见上表，主要影响当前终端会话的环境变量）。

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
