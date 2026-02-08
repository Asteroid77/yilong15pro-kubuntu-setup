# Changelog

## 2026-02-08

### feat
- core: 更新 Wayland 输入法依赖组合，补齐 `fcitx5-configtool`、`kde-config-fcitx5`、`fcitx5-frontend-qt6/gtk4`，并加入 `wl-clipboard`（提供 `wl-paste`）。
- fcitx: 在 Rime 配置步骤后增加 Fcitx5 重载调用，安装后可即时生效。

### refactor
- common: 新增图形会话相关公共函数（`is_graphical_session`、`run_if_graphical`）以及 Fcitx5 重载公共封装，减少步骤脚本重复判断。

