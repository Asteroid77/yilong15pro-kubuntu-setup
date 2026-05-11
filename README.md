# 翼龙 15 Pro → Linux（Kubuntu 24.04）迁移/初始化脚本

面向 **翼龙 15 Pro**（笔记本）从 Windows/原系统迁移到 Linux 后的一键初始化脚本，发行版为 **Kubuntu 24.04**，以 **最小安装（Minimal Installation）** 作为基准环境进行补齐与配置。

默认行为：**启动即进入交互式勾选界面**，并且 **默认全选**（回车即按全量执行）。  
在勾选界面按 `Cancel` 或 `Esc` 会 **直接退出脚本且不做任何安装/修改**。

## 功能概览

| 分区 | 内容 | 备注（脚本额外动作） |
| --- | --- | --- |
| 软件源/镜像 | APT / Docker / NPM / Maven / Conda / Go / GitHub 镜像 | 自动应用到对应工具；GitHub 下载支持镜像轮询 |
| 驱动/硬件 | 自动安装推荐驱动；NVIDIA DRM 检测与启用；MT7922 相关 GRUB 参数 | NVIDIA：写入 `nvidia-drm modeset=1` 并更新 initramfs |
| 基础依赖 | 常用 CLI、构建工具、输入法、Wayland 会话、媒体/系统工具等 | 以 Kubuntu 24.04 最小安装为基准补齐 |
| 命令/入口 | `proxy_on` / `proxy_off` | 同时写入 `~/.zshrc`、`~/.bashrc` 与 `~/.local/bin` |
| 常用软件 | 按功能分组安装：浏览器/IDE/通信/办公/远控/容器服务/终端等 | 部分软件通过 GitHub Release/官网直链拉取 `.deb`，容器服务通过 Docker Compose 部署 |
| Plasma 外观 | `plasma_appearance`（Orchis Light + 顶部 Dock 布局） | 可选且默认关闭；安装主题包并重建顶部栏布局 |
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

说明：`--no-interactive` 仍按全量安装执行。若你是 `Konsole / Yakuake` 用户，只想安装 `Atuin + glow + Streamdown`，建议使用默认交互模式并取消勾选 `kitty_terminal`。

注意：`plasma_appearance` 默认在交互列表中关闭；如不希望脚本接管 Plasma 主题和面板布局，请保持不勾选。`--no-interactive` 会按全量路线执行，也会启用该外观步骤。

只配置 WezTerm + tmux GUI tabs：

```bash
bash "scripts/install-wezterm-tmux.sh"
```

预览将执行的动作：

```bash
bash "scripts/install-wezterm-tmux.sh" --dry-run
```

该入口只启用 `wezterm_tmux` 路线：安装/更新 `tmux`、`tmux-resurrect`、`tmux-continuum`，并写入 WezTerm 专用 `.wezterm.lua`、`~/.config/tmux/wezterm.conf` 和 `wezterm-tmux-tab` helper。它不写入 `~/.tmux.conf`，不读取全局 `~/.local/share/tmux/resurrect`，也不安装 Yakuake/Konsole 或 kitty 路线。

### Dry-run（演示模式）

```bash
bash "init.sh" --dry-run
```

说明：dry-run 仅打印将执行的命令，不会修改系统，也不会写入步骤状态文件。

## 使用的源与镜像（详细）

| 工具/场景 | 源/镜像 | 作用 |
| --- | --- | --- |
| APT（Ubuntu） | `mirrors.tuna.tsinghua.edu.cn` | 替换默认 Ubuntu archive/security 镜像 |
| GitHub 下载镜像 | `mirror.ghproxy.com` / `hub.gitmirror.com` / 直连 | 拉取 Release 资产/zip 时容灾与加速；如已配置本地代理则优先直连 GitHub |
| Docker 镜像 | `docker.m.daocloud.io` / `dockerproxy.com` | 写入 `/etc/docker/daemon.json` 作为 registry mirror |
| NPM | `registry.npmmirror.com` | `npm config set registry` |
| Maven | `maven.aliyun.com/repository/public` | 写入 `~/.m2/settings.xml` mirror |
| Conda | `mirrors.tuna.tsinghua.edu.cn/anaconda` | 安装与 channels 配置 |
| Go 下载 | `mirrors.aliyun.com/golang`（失败回退官方） | 优先镜像下载 tar.gz |

补充：以下软件使用官网直链/页面解析下载（不经 APT 源），便于对照与排障：

| 软件                  | 下载来源                                                      |
| ------------------- | --------------------------------------------------------- |
| Chrome              | `dl.google.com`                                           |
| VS Code             | `code.visualstudio.com`                                   |
| WeChat              | `dldir1.qq.com`                                           |
| DBeaver CE          | `dbeaver.io`                                              |
| WPS Office          | `linux.wps.cn`（页面） + `wps-linux-personal.wpscdn.cn`（deb）  |
| Obsidian            | `github.com/obsidianmd/obsidian-releases`（GitHub Release） |
| Sublime Merge       | `download.sublimetext.com`（APT 源）                         |

## 驱动

| 类别 | 动作 | 触发条件/备注 |
| --- | --- | --- |
| 通用推荐驱动 | `sudo ubuntu-drivers autoinstall` | 安装 Ubuntu 推荐驱动（含 NVIDIA 等） |
| NVIDIA（Wayland 关键） | 检测 `/sys/module/nvidia_drm/parameters/modeset`，未开启则写入 `options nvidia-drm modeset=1` 并 `update-initramfs -u` | 让 NVIDIA 在 Wayland 下更稳定；需要重启后生效 |
| MT7922 / Wi‑Fi | 写入/更新 `/etc/default/grub` 的 `GRUB_CMDLINE_LINUX_DEFAULT` 并执行 `update-grub` | 检测到 MT7922 与否使用不同默认参数 |

## 基础依赖

以 **Kubuntu 24.04 最小安装**为起点，脚本补齐以下基础包（参考： `scripts/steps/01_core.sh`）。

| 分类 | 安装内容 |
| --- | --- |
| 基础工具 | `curl` `wget` `jq` `grep` `git` `build-essential` `software-properties-qt` `apt-transport-https` `unzip` `net-tools` `wl-clipboard`（提供 `wl-paste`） |
| 性能/运行库 | `libtcmalloc-minimal4` |
| 桌面/会话 | `plasma-workspace-wayland`（Plasma Wayland 会话） |
| 输入法 | `im-config` `fcitx5` `fcitx5-chinese-addons` `fcitx5-rime` `fcitx5-configtool` `fcitx5-config-qt` `kde-config-fcitx5` `fcitx5-frontend-qt6/gtk3/gtk4` `librime-data-*` |
| 系统/多媒体 | `yakuake` `btop` `okular` `wireshark` `calibre` `ffmpegthumbs` |
| CLI 工具 | `bat`（`batcat`）`fd-find`（`fdfind`）`fzf` `ncdu` `tealdeer`（`tldr`） |
| Shell/字体 | `zsh` `fonts-firacode` |
| 交互 UI | `whiptail`（默认交互式勾选依赖） |

## 添加/生成的命令

| 命令 | 位置 | 作用 |
| --- | --- | --- |
| `proxy_on [port]` | `~/.local/bin/proxy_on` + `~/.zshrc`/`~/.bashrc` 函数 | 设置 `http(s)_proxy/all_proxy`（默认读取缓存端口文件） |
| `proxy_off` | `~/.local/bin/proxy_off` + `~/.zshrc`/`~/.bashrc` 函数 | 清理上述代理环境变量 |
| `mdv [file.md]` | `~/.zshrc`/`~/.bashrc` 的 `kubuntu-migrate terminal-tools` 受控片段 | 使用 `glow` 查看 Markdown；无参数时读取标准输入 |
| `mdstream` | `~/.zshrc`/`~/.bashrc` 的 `kubuntu-migrate terminal-tools` 受控片段 | 使用 `Streamdown (sd)` 渲染流式 Markdown |
| `mdrun <command ...>` | `~/.zshrc`/`~/.bashrc` 的 `kubuntu-migrate terminal-tools` 受控片段 | 用 `Streamdown` 包住一个命令并实时渲染其 Markdown 输出 |
| `refreshapps` | `~/.zshrc`/`~/.bashrc` 的 `kubuntu-migrate terminal-tools` 受控片段 | 刷新用户级桌面入口与图标缓存 |
| `t` / `tm` / `tn` / `tclose` / `tsave` / `yrestore` | `~/.zshrc` 的 `kubuntu-migrate tmux-restore` 受控片段 | `tmux_restore` 路线入口；`t` 进入一个独立 `meteor-tab-*` session，`tclose` 关闭当前受控 session 且不再恢复，`tsave` 强制保存，`yrestore` 对当前 Yakuake 实例执行一次外层标签恢复 |
| `meteor-tmux-auto` / `tmux-close-current` / `tmux-save-current` / `yakuake-tmux-restore-once` / `yakuake-restore-tabs` | `~/DEV/script/bin/` | `tmux_restore` 路线内部脚本：为新标签创建新的受控 session、显式关闭当前受控 session、保存当前快照、按 Yakuake 实例执行一次恢复、通过 Yakuake D-Bus 恢复多个外层标签 |
| `TmuxRestore` | `~/.local/share/konsole/TmuxRestore.profile` | Konsole/Yakuake 专用 profile；Command 指向 `meteor-tmux-auto` |
| `wezterm-tmux-tab` | `~/DEV/script/bin/` | `wezterm_tmux` 路线内部脚本：一个 WezTerm GUI tab 对应一个业务 tmux session；使用独立 socket 与独立 resurrect 目录 |
| `kssh <host>` | `~/.zshrc`/`~/.bashrc` 的 `kubuntu-migrate kitty` 受控片段 | 使用 `kitten ssh` 建立 kitty 远程会话 |

## 终端路线

| 路线 | 适用场景 | 安装内容 | Shell 片段/命令 |
| --- | --- | --- | --- |
| `terminal_tools` | 继续使用 `Konsole`、`Yakuake` 等现有终端 | `Atuin + glow + Streamdown` | 注入 `mdv` / `mdstream` / `mdrun` / `refreshapps` 与 `atuin init` |
| `yakuake_snapshot` | 希望恢复 Yakuake 标签布局、目录、最后命令和最后输出，但不恢复进程 | 普通 shell + `script` 输出日志 + Yakuake D-Bus 恢复脚本 | 注入 `YakuakeSnapshot` profile、`ysnap-restore`；不使用 tmux，不接管鼠标/复制 |
| `tmux_restore` | 需要 Konsole/Yakuake 标签在重启/崩溃后尽量恢复 | `tmux + tmux-resurrect + tmux-continuum` | 注入 `kubuntu-migrate tmux-restore`；默认提供 `t` / `tclose` / `tsave` / `yrestore`，设置 `AUTO_TMUX=1` 后新标签自动进入独立 `meteor-tab-*` session |
| `wezterm_tmux` | 希望用 WezTerm GUI tabs 恢复终端工作区 | WezTerm 配置 + 独立 tmux socket/config/resurrect state | 写入 `~/.wezterm.lua`、`~/.config/tmux/wezterm.conf`、`wezterm-tmux-tab`；一个 WezTerm GUI tab 对应一个业务 tmux session |
| `kitty_terminal` | 想单独启用 kitty 官方最新版 | 仅安装 kitty 与其配置/桌面入口 | 仅注入 `kssh` |

说明：
- 交互勾选里 `terminal_tools` 默认开启，`yakuake_snapshot`、`tmux_restore`、`wezterm_tmux` 和 `kitty_terminal` 默认关闭。
- `kitty_terminal` 不再隐式安装 `Atuin + glow + Streamdown`。
- 对 `Konsole / Yakuake` 用户，基础增强推荐启用 `terminal_tools`；需要重启/崩溃后恢复终端工作区时再启用 `tmux_restore`。
- `yakuake_snapshot` 是普通终端体验优先的恢复方案：保存每个标签的目录、最后命令和输出日志，恢复时用 Yakuake D-Bus 重建普通 shell 标签并展示最后输出。它不能恢复正在运行的进程，但可以让用户按 `↑` 重新执行最后命令。
- `tmux_restore` 使用“一个外层标签 = 一个 `meteor-tab-*` tmux session”的恢复模型。`TmuxRestore` profile 的 Command 永远只为新标签创建新的受控 session，不做恢复判定，避免按 `+` 时唤回历史内容。恢复动作由独立的 `yakuake-tmux-restore-once` / `yrestore` 负责：它按当前 Yakuake 进程实例只执行一次，先确保 tmux-continuum 有机会恢复 sessions，再通过 Yakuake D-Bus 为受控清单中的未连接 `meteor-tab-*` sessions 重建外层标签，避免把历史实验 session 全部拉回。恢复标签名优先使用 tmux window 名，其次使用 pane 当前目录名。主动关闭且不希望恢复时，在对应标签内运行 `tclose`；Yakuake/Konsole 本身没有可靠的“关闭某个标签前执行命令”的 hook。默认不强制接管每个新标签；推荐在 Konsole/Yakuake 里手动选择 `TmuxRestore` profile 来启用自动恢复入口。若需要全局自动接管，可在 shell 环境设置 `AUTO_TMUX=1`；若需要临时裸 shell，可用 `NO_TMUX=1 zsh`。
- `wezterm_tmux` 是独立路线，不读取 `~/.tmux.conf` 和全局 `~/.local/share/tmux/resurrect`。它固定使用 socket `~/.local/state/tmux-wezterm/main.sock`、配置 `~/.config/tmux/wezterm.conf`、保存目录 `~/.local/state/wezterm-tmux/resurrect`，避免 Konsole/Yakuake 实验状态污染 WezTerm。恢复事实源是业务 tmux sessions；一个 WezTerm GUI tab 对应一个业务 session，GUI tab 标题来自 tmux session name，tab 内部可继续使用 tmux windows/panes。`Ctrl+Shift+T` 新建一个业务 session 和对应 GUI tab，`Ctrl+Shift+R` 重命名当前业务 session。保存快照时会过滤 `wezterm-tech-*`、旧 `wezterm-tab-*`、`meteor-tab-*` 和旧 `main` 状态。关闭并重开 WezTerm 时，`gui-startup` 会按业务 sessions 重建 GUI tabs。

## Plasma 外观路线（可选）

| 路线 | 默认 | 安装内容 | 布局 |
| --- | --- | --- | --- |
| `plasma_appearance` | 关闭 | `orchis-kde` `qt5-style-kvantum` `papirus-icon-theme` | 顶部常驻栏：`菜单 / Spacer / 应用图标 Dock / Spacer / 系统托盘 / 时钟` |

说明：
- 该路线会应用 `Orchis` light 配色、Plasma 样式、Aurorae 窗口装饰、Kvantum Orchis、`Papirus-Light` 图标和 Breeze 光标。
- 应用布局前会备份 `~/.config/plasma-org.kde.plasma.desktop-appletsrc`，备份文件名包含 `kubuntu-migrate-backup` 和时间戳。
- 非 KDE Plasma 会话、缺少 `qdbus` 或 `lookandfeeltool` 时会跳过对应部分，不中断主流程。
- 这是个人偏好的桌面布局，默认关闭；不想集成主题修改时保持不勾选即可。

## 常用软件与开发环境

> 说明：默认全选；可在交互界面取消勾选。不同软件来源/额外动作见备注列。

| 功能分区 | 软件 | 安装方式 | 备注（脚本额外工作） |
| --- | --- | --- | --- |
| 词典/阅读 | GoldenDict-ng | APT | 通过代理参数执行 `apt update/install` |
| 浏览器 | Google Chrome | 官网 `.deb` | `smart_install_deb` 自动下载并 `apt install` |
| 开发/IDE | Visual Studio Code | 官网直链 `.deb` | 同上 |
| 容器服务 | 迅雷 | Docker Compose（`cnk3x/xunlei`） | 勾选 `xunlei` 时生成/更新 `~/docker-settings/docker-compose-daily.yml` 并启动该服务 |
| 容器服务 | Antigravity-Manager | Docker Compose（`lbjlaq/antigravity-manager`） | 勾选 `antigravity_manager` 时生成/更新同一 compose 文件并启动该服务 |
| 数据库工具 | DBeaver CE | 官网 `.deb` | 同上 |
| 即时通信 | WeChat | 官网 `.deb` | 同上 |
| 即时通信 | Linux QQ | 官网页面解析最新 `.deb` | 失败则跳过，不中断 |
| 办公 | WPS Office | 从 `linux.wps.cn/wpslinuxlog` 抓取最新 `12.1.2.*` 的 `amd64.deb` | 宽松匹配 + 版本限制，抓取失败跳过 |
| 版本控制 | Sublime Merge | 官方 APT 源 | 导入 GPG key + 写入源 + APT 安装 |
| 终端增强 | `terminal_tools`（Atuin + glow + Streamdown） | GitHub Release `.deb` + `pipx` + 官方安装脚本 | 推荐给 `Konsole / Yakuake` 用户；写入 `~/.config/atuin/config.toml`，向 `~/.zshrc` / `~/.bashrc` 注入 `mdv` / `mdstream` / `mdrun` / `refreshapps` |
| 终端恢复 | `tmux_restore`（可选） | APT + GitHub clone | 安装 `tmux`、`tmux-resurrect`、`tmux-continuum`；写入 `~/.tmux.conf`，向 `~/.zshrc` 注入 Konsole/Yakuake 恢复入口，并提供 `yrestore` 重建多个 Yakuake 外层标签 |
| 终端恢复 | `wezterm_tmux`（可选） | APT + GitHub clone + 配置模板 | 安装 `tmux`、`tmux-resurrect`、`tmux-continuum`；写入 WezTerm 专用 `.wezterm.lua`、专用 tmux config 和 `wezterm-tmux-tab` helper；不使用 Yakuake/Konsole 状态 |
| 终端 | `kitty_terminal`（可选） | kitty upstream 二进制包 | 纯 kitty 路线；写入 `~/.config/kitty/kitty.conf` / `open-actions.conf`，向 `~/.zshrc` / `~/.bashrc` 注入 `kssh` |
| Plasma 外观 | `plasma_appearance`（可选） | APT + KDE 配置工具 | Orchis Light + Kvantum + Papirus-Light；重建顶部 Dock 状态栏布局，执行前备份 Plasma 布局 |
| 终端 | Tabby Terminal | GitHub Release `.deb` | GitHub 镜像轮询下载 |
| 远程控制 | RustDesk | GitHub Release `.deb` | GitHub 镜像轮询下载 |
| 文档写作 | Obsidian | GitHub Release `.deb` | 通过 GitHub API 获取最新版并安装；建议安装常用社区插件（见下） |
| 终端增强 | Yakuake | APT | 作为下拉终端 |
| 系统监控 | btop | APT |  |
| 播放器 | MPV + uosc + thumbfast | APT + 安装脚本 + Git clone | 写入 `~/.config/mpv/mpv.conf`/`input.conf`（marker 幂等追加）；thumbfast 会创建 `scripts/thumbfast.lua` 软链 |
| 文档阅读 | Okular | APT |  |
| 抓包 | Wireshark | APT |  |
| 电子书 | Calibre | APT |  |
| Shell | zsh + starship + zoxide | APT + 安装脚本 | 写入 `~/.zshrc` 初始化语句；新增 `bat`/`fd`/`helpme` 别名 |
| CLI 工具 | bat / fd / fzf / ncdu / tealdeer | APT | tealdeer 页面库通过 GitHub 代理/镜像逻辑下载并安装至 `~/.cache/tealdeer/tldr-pages` |
| 字体 | FiraCode / JetBrainsMono Nerd Font / Inter / LXGW WenKai | APT + GitHub Release | `~/.local/share/fonts` 并 `fc-cache` |
| Docker | Docker + Portainer | get.docker.com + Docker Hub | 写入 registry mirror；如设置代理端口则写 systemd proxy drop-in |
| Java/Maven | SDKMan（优先）/ APT（兜底） | 安装脚本 + APT | 写入 `~/.m2/settings.xml` 使用阿里云 Maven 镜像 |
| Node.js | fnm 安装 LTS | 安装脚本 | 设置 NPM 镜像源 |
| npm 工具 | Claude Code / Codex | `npm -g` | `claude_codex` 选项；依赖 Node |
| Go | tar.gz（镜像优先） | 下载解压 | 安装到 `/usr/local/go`，并在后续步骤写入 `~/.zshrc` 添加 PATH |
| Python/Conda | Miniconda | 安装脚本 | init bash/zsh；配置 TUNA channels |

### Obsidian 插件建议

建议在 Obsidian 中安装以下社区插件：

- `Custom Attachment Location`
- `Editing Toolbar`
- `make.md`
- `Markdown prettifier`
- `Style settings`
- `Table Generator`

### IDE 反代（可选）

如果需要为 IDE 场景做反代，可参考：`https://github.com/justlovemaki/AIClient-2-API`。

脚本已内置日常容器服务部署：会生成 `~/docker-settings/docker-compose-daily.yml`，并按勾选项创建 `~/thunder/*` 或 `~/docker-settings/antigravity_tools` 目录。

如果需要为 API/Client 做反代，比如说在CC中使用GPT-5.3-Codex之类的模型，可以参考我的[博客](https://blog.astro777.cfd/posts/guide/using-codex-in-claude-code-cli/)。


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
