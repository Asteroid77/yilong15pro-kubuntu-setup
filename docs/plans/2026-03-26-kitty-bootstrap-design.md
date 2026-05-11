# Kitty 官方最新版安装与终端增强设计文档

**日期：** 2026-03-26
**项目：** KUbuntu Migrate
**目标：** 在现有迁移脚本中新增一条“终端增强”路线，跨 Ubuntu/Debian 环境安装官方最新版 kitty，并一并配置 Markdown 查看与 shell 历史增强能力。

---

## 1. 背景与目标

用户已确认从 `Konsole + Yakuake` 路线迁移到 `kitty`，并希望：

- 使用 **kitty 官方最新版**，不依赖 Ubuntu 24.04 仓库旧版本
- 将安装过程脚本化，便于后续在新环境中直接复用
- 方案 **不绑定桌面环境**，能在 Ubuntu/Debian 系环境复用
- 脚本可 **自动修改** 现有 `~/.zshrc`、`~/.bashrc`、`~/.config/kitty/kitty.conf`
- 一并提供 Markdown 阅读/流式预览能力，以及 shell 历史增强能力

本设计只解决终端与其直接配套工具，不扩展为完整 dotfiles/环境管理系统（YAGNI）。

---

## 2. 范围

### 包含

- 安装 **官方最新版 kitty**
- 写入基础 `kitty.conf`
- 写入 `open-actions.conf`
- 安装 `glow`
- 安装 `Streamdown`
- 安装 `Atuin`
- 自动注入 shell 初始化片段到 `~/.zshrc` / `~/.bashrc`
- 备份被修改文件
- 支持 dry-run、幂等执行、跨 Ubuntu/Debian 复用

### 不包含

- 不处理桌面环境专属行为（如 KDE/Yakuake 迁移逻辑）
- 不自动移除 Konsole/Yakuake
- 不自动设置系统默认终端为 kitty（避免 DE 绑定和过度修改）
- 不引入 tmux 路线
- 不做 git commit

---

## 3. 方案选择

### 备选方案

1. **单文件一键脚本**：简单，但配置与逻辑耦合严重，维护成本高
2. **入口脚本 + 模板目录**：逻辑/配置分离，易维护，适合反复复用
3. **完整环境管理系统**：可扩展但超出当前需求

### 最终方案

采用 **入口脚本 + 模板目录**，并融入现有仓库结构：

- 复用 `scripts/run.sh`
- 复用 `scripts/lib/common.sh`
- 新增 `scripts/steps/12_terminal.sh`
- 新增 `scripts/templates/` 下的 kitty / shell / atuin 模板

这样既符合现有项目结构，也保持 KISS/DRY。

---

## 4. 架构与文件落点

### 新增文件

- `scripts/steps/12_terminal.sh`
- `scripts/templates/kitty/kitty.conf`
- `scripts/templates/kitty/open-actions.conf`
- `scripts/templates/shell/kitty-bootstrap.zsh`
- `scripts/templates/shell/kitty-bootstrap.bash`
- `scripts/templates/atuin/config.toml`
- `docs/plans/2026-03-26-kitty-bootstrap-design.md`
- `docs/plans/2026-03-26-kitty-bootstrap.md`
- `tests/test_terminal_common.sh`

### 修改文件

- `scripts/run.sh`
- `scripts/lib/common.sh`
- `README.md`

### 运行顺序

新增 `step_12_terminal`，放在 `step_11_mt7922` 之后、`step_99_finish` 之前。这样：

- shell 基础环境已就绪
- fonts 已在前序步骤处理
- 终端配置可直接写入用户目录

---

## 5. 安装策略

### 5.1 kitty

- 使用 **kitty 官方 upstream 安装方式**，而非系统仓库
- 安装到用户目录，避免强依赖 root 级系统包版本
- 保持脚本可在 Ubuntu/Debian 多环境运行
- 安装后提供 `kitty` 可执行访问路径与桌面入口修复逻辑

### 5.2 glow

- 通过官方 release 的 `.deb` 资产安装（优先 amd64）
- 复用现有 GitHub Release 获取逻辑

### 5.3 Streamdown

- 使用 `pipx` 安装，避免污染系统 Python
- 若缺少 `pipx` 或运行环境依赖，则由脚本补齐最小依赖

### 5.4 Atuin

- 使用官方安装方式或稳定的二进制安装方式获取最新版
- shell 初始化由本项目脚本统一注入，不依赖第三方安装器自行改 rc 文件

---

## 6. 配置策略

### kitty 配置

基础 `kitty.conf` 应覆盖：

- 字体族/字号的安全默认值
- 滚动回看与分页器体验
- 鼠标/复制粘贴基本行为
- 适合 SSH/长输出的默认设置
- `open-actions.conf` 支持通过外部程序打开文件/链接

### shell 注入策略

使用受控 marker 片段，例如：

- `# >>> kubuntu-migrate kitty >>>`
- `# <<< kubuntu-migrate kitty <<<`

规则：

- 存在旧块则替换
- 不存在则追加
- 修改前先做时间戳备份

### Markdown 工具体验

脚本会为 shell 注入便捷能力，例如：

- `mdv file.md`：使用 `glow` 查看 Markdown
- `mdstream`：使用 `Streamdown` 处理流式 Markdown

### Atuin 集成

在 shell 中注入最小初始化，不覆盖用户已有历史配置逻辑。

---

## 7. 幂等与安全性

### 幂等

- 已安装组件重复执行时应跳过或升级式处理
- shell 注入块必须可重复更新，不得重复追加
- kitty 配置文件写入采用模板覆盖 + 备份，而非无界拼接

### 备份

修改前备份：

- `~/.zshrc.bak.<timestamp>`
- `~/.bashrc.bak.<timestamp>`
- `~/.config/kitty/kitty.conf.bak.<timestamp>`
- `~/.config/kitty/open-actions.conf.bak.<timestamp>`

### 错误处理

- 主体使用 `set -e` 风格保持失败即停
- 对“可选增强项”可局部 `warn`，避免单一非关键工具中断整个 kitty 主路径
- 最终汇总安装结果与后续手工操作提示

---

## 8. 测试与验证策略

由于仓库当前没有现成 shell 测试框架，本次采用最小可维护验证方案：

### 测试

新增一个轻量 shell 测试脚本：

- `tests/test_terminal_common.sh`

用于验证新增公共函数，例如：

- 受控块替换/追加
- 备份函数行为
- 基础文件注入逻辑

### 验证

至少执行：

1. `bash -n` 对新增/修改脚本做语法检查
2. 运行 `tests/test_terminal_common.sh`
3. 运行 `bash init.sh --dry-run --no-interactive`
4. 检查 dry-run 输出中包含 kitty/glow/atuin/streamdown 相关动作

必要时再补充针对模板生成结果的本地临时目录验证。

---

## 9. 取舍说明

### 为什么不直接继续用 Konsole/Yakuake 路线

用户已经明确接受迁移到 kitty，且不再强依赖下拉式终端，因此应聚焦 kitty 主路径，而不是继续扩展 KDE 终端路线。

### 为什么不默认引入 tmux

用户当前重点是 kitty + 会话 + Markdown + 历史增强；kitty 新版具备足够的 session 能力，tmux 不是当前必须项，避免超出需求。

### 为什么不自动设置系统默认终端

不同桌面环境的默认终端设置差异较大，强行修改会带来桌面耦合和回滚复杂度，不符合“不绑定桌面环境”的目标。

---

## 10. 成功标准

完成后应满足：

- 在 Ubuntu/Debian 新环境中，可通过现有迁移仓库一键执行终端安装步骤
- 安装的是 **官方最新版 kitty**，而不是系统仓库旧版
- `kitty`、`glow`、`Streamdown`、`Atuin` 均能成功调用
- `~/.zshrc` / `~/.bashrc` 自动注入且幂等
- 生成基础 kitty 配置，可直接投入使用
- dry-run 与最小测试通过

