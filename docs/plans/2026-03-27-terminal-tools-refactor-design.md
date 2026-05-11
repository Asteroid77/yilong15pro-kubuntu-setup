# 通用终端增强与 Kitty 路线拆分设计文档

**日期：** 2026-03-27  
**项目：** KUbuntu Migrate  
**目标：** 将现有 `kitty + glow + Streamdown + Atuin` 绑定路线拆成两条独立能力线：一条是适用于 Konsole/Yakuake 等现有终端的“通用终端增强”，另一条是纯可选的 `kitty` 安装路线。

---

## 1. 背景

现有实现把以下能力绑在同一个 feature 中：

- `kitty` 本体安装
- `glow`
- `Streamdown`
- `Atuin`
- shell 注入 `mdv` / `mdstream` / `kssh`
- `kitty` 配置与桌面菜单注入

这条绑定路线适合愿意接受 `kitty` 工作流的用户，但不适合当前用户的主终端使用习惯。用户已经确认：

- 主终端继续使用 `Konsole + Yakuake`
- 只保留通用增强能力：`Atuin + glow + Streamdown`
- `kitty` 降级为独立可选项
- 当前机器需要同步从“kitty 绑定态”迁移回“通用终端增强态”

---

## 2. 目标与非目标

### 目标

- 新增一条独立的通用终端增强路线
- 保留 `kitty`，但收缩为纯 `kitty` 可选项
- 让未来新环境可一键安装 `Atuin + glow + Streamdown`
- 清理当前机器中受控注入的 `kitty` 主路径痕迹
- 保留已安装的 `kitty` 二进制，避免不必要卸载

### 非目标

- 本轮不接入 `tmux` / `tmux-resurrect`
- 不自动卸载 `kitty` 用户态二进制
- 不处理 Konsole/Yakuake 自身的 GUI 标签恢复
- 不做 git commit

---

## 3. 方案选择

### 方案 A：最小拆分

- 在原 `step_12_terminal.sh` 内做条件分支
- 把 `Atuin + glow + Streamdown` 逻辑抽出来，但仍保留大量旧结构

优点：
- 改动最小

缺点：
- feature 边界仍不清晰
- shell 模板和步骤职责继续混杂

### 方案 B：标准拆分（最终采用）

- 新增独立 `terminal_tools` feature
- 新增独立 `step_12_terminal_tools.sh`
- 原 `kitty` 路线收缩成纯 `kitty`，迁移为 `step_13_kitty.sh`
- shell 模板拆成通用增强与 kitty 专属两类

优点：
- 结构清晰
- 通用能力与终端本体彻底解耦
- 后续继续扩展 `tmux` 等增强时不会污染 `kitty`

缺点：
- 改动面中等，需要同步 README、feature 选择、步骤编排、模板和当前机器迁移清理

### 方案 C：激进重做

- 重写整套终端路线

优点：
- 最干净

缺点：
- 超出当前需求，不符合 YAGNI

---

## 4. 设计概览

### 4.1 Feature 拆分

新增/调整两个 feature：

- `terminal_tools|Atuin + glow + Streamdown|on`
- `kitty_terminal|kitty（纯终端可选项）|off`

其中：

- `terminal_tools` 作为主推荐路线，适配 Konsole/Yakuake 等现有终端
- `kitty_terminal` 只代表纯 `kitty` 本体与其专属配置，不再隐式附带通用终端增强

### 4.2 步骤拆分

新增/调整步骤：

- `scripts/steps/12_terminal_tools.sh`
  - 安装 `glow`
  - 安装 `pipx + Streamdown`
  - 安装 `Atuin`
  - 写入 `~/.config/atuin/config.toml`
  - 注入 shell 通用增强块：`mdv` / `mdstream` / `atuin init` / `refreshapps`
  - 执行当前机器迁移清理中的“受控块替换”与“kitty 菜单/配置清理”

- `scripts/steps/13_kitty.sh`
  - 安装 `kitty`
  - 写入 `kitty.conf`
  - 写入 `open-actions.conf`
  - 注入仅 `kitty` 专属的 shell 片段，例如 `kssh`

### 4.3 模板拆分

新增模板：

- `scripts/templates/shell/terminal-tools.zsh`
- `scripts/templates/shell/terminal-tools.bash`

保留/调整模板：

- `scripts/templates/atuin/config.toml`
- `scripts/templates/kitty/kitty.conf`
- `scripts/templates/kitty/open-actions.conf`
- 将原 `scripts/templates/shell/kitty-bootstrap.zsh`
- 将原 `scripts/templates/shell/kitty-bootstrap.bash`

重构为仅承载 `kitty` 专属内容的模板，或替换为新的 `kitty` 专属模板文件。

---

## 5. 当前机器迁移清理

### 5.1 Shell 管理块迁移

对当前机器：

- 删除 `~/.zshrc` / `~/.bashrc` 中现有 `kubuntu-migrate kitty` 受控块
- 写入新的 `kubuntu-migrate terminal-tools` 受控块

新块只保留：

- `PATH="$HOME/.atuin/bin:$HOME/.local/bin:$PATH"`
- `mdv`
- `mdstream`
- `atuin init`
- `refreshapps`

不再保留：

- `kssh`

### 5.2 Kitty 配置与菜单清理

对当前机器，清理受控生成的：

- `~/.config/kitty/kitty.conf`
- `~/.config/kitty/open-actions.conf`
- `~/.local/share/applications/kitty.desktop`
- `~/.local/share/applications/kitty-open.desktop`

清理前应继续采用时间戳备份策略。

### 5.3 不主动卸载 kitty 二进制

保留：

- `~/.local/kitty`
- `~/.local/bin/kitty`
- `~/.local/bin/kitten`

理由：

- 避免额外破坏
- 保留后续手动试用或备用空间

---

## 6. 公共能力与职责边界

### 通用终端增强负责

- `Atuin`
- `glow`
- `Streamdown`
- shell 常用函数：
  - `mdv`
  - `mdstream`
  - `refreshapps`

### kitty 负责

- `kitty` upstream 安装
- `kitty` 配置文件
- 桌面菜单入口
- `kitty` 专属 shell 助手：
  - `kssh`

这样未来即使完全不选 `kitty`，用户仍可正常获得通用终端增强。

---

## 7. 测试与验证策略

本次调整采用 4 层验证：

### 7.1 helper / 注入逻辑测试

扩展 `tests/test_terminal_common.sh`，验证：

- 受控块追加/替换
- 备份函数
- `kitty` desktop 重写 helper
- 通用 `terminal-tools` shell 模板包含 `mdv` / `mdstream` / `atuin init`
- `kitty` shell 模板不再携带通用增强逻辑

### 7.2 语法检查

运行：

- `bash -n scripts/run.sh`
- `bash -n scripts/lib/common.sh`
- `bash -n scripts/steps/12_terminal_tools.sh`
- `bash -n scripts/steps/13_kitty.sh`

### 7.3 dry-run 验证

运行：

- `bash init.sh --dry-run --no-interactive`

并确认：

- `terminal_tools` 只安装 `Atuin + glow + Streamdown`
- `kitty_terminal` 只处理 `kitty` 本体与专属配置
- 两条路线互不混杂

### 7.4 当前机器落地验证

确认：

- `glow` / `sd` / `atuin` 命令存在
- `~/.zshrc` / `~/.bashrc` 中只有 `kubuntu-migrate terminal-tools`
- `kubuntu-migrate kitty` 管理块已移除
- `~/.config/kitty/*` 和 `kitty.desktop` 已按设计清理
- `kitty` 二进制仍保留

---

## 8. 成功标准

完成后应满足：

- 仓库可以在不安装 `kitty` 的情况下独立提供 `Atuin + glow + Streamdown`
- `kitty` 作为单独可选项存在，不再绑定通用终端增强
- 当前机器从旧的 `kitty` 绑定态平滑迁回通用终端增强态
- dry-run、测试与语法检查通过
- README 能准确说明两条路线的差异
