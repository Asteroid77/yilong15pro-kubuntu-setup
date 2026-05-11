# Changelog

## 2026-05-12

### refactor
- core: 面向 Kubuntu 26.04，移除默认 Wayland 会话安装、MT7922 GRUB 兼容设置和 NVIDIA DRM modeset 写入，改为安装 `nvidia-driver-580-open`。
- dev: 移除 Miniconda，改为安装 `uv`。
- terminal: 移除 kitty 和 Tabby，保留 WezTerm 作为唯一终端路线，并在 `wezterm_tmux` 中安装 WezTerm 本体。

### refactor
- common: 新增图形会话相关公共函数（`is_graphical_session`、`run_if_graphical`）以及 Fcitx5 重载公共封装，减少步骤脚本重复判断。

## 2026-02-08

### feat
- core: 更新输入法依赖组合，补齐 `fcitx5-configtool`、`kde-config-fcitx5`、`fcitx5-frontend-qt6/gtk4`，并加入 `wl-clipboard`（提供 `wl-paste`）。
- fcitx: 在 Rime 配置步骤后增加 Fcitx5 重载调用，安装后可即时生效。
