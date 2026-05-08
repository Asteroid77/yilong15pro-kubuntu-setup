#!/bin/bash

plasma_appearance_is_plasma_session() {
    [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] || [ -n "${KDE_SESSION_VERSION:-}" ]
}

plasma_appearance_apply_theme() {
    info "安装并应用 Orchis Light 外观..."

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "sudo apt install -y orchis-kde qt5-style-kvantum papirus-icon-theme"
        dry_echo "lookandfeeltool --apply com.github.vinceliuice.Orchis"
        dry_echo "kwriteconfig5 --file kdeglobals --group Icons --key Theme Papirus-Light"
        dry_echo "kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme breeze_cursors"
        dry_echo "kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle kvantum"
        dry_echo "kvantummanager --set Orchis"
        return 0
    fi

    sudo apt install -y orchis-kde qt5-style-kvantum papirus-icon-theme

    if command -v lookandfeeltool >/dev/null 2>&1; then
        lookandfeeltool --apply com.github.vinceliuice.Orchis || warn "Orchis 全局主题应用失败"
    else
        warn "未找到 lookandfeeltool，跳过全局主题应用"
    fi

    if command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file kdeglobals --group Icons --key Theme Papirus-Light
        kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme breeze_cursors
        kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle kvantum
    else
        warn "未找到 kwriteconfig5，跳过细分主题配置"
    fi

    if command -v kvantummanager >/dev/null 2>&1; then
        kvantummanager --set Orchis || warn "Kvantum Orchis 应用失败"
    else
        warn "未找到 kvantummanager，跳过 Kvantum 主题配置"
    fi
}

plasma_appearance_apply_topbar_layout() {
    local APPLETS_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    local BACKUP_FILE="${APPLETS_FILE}.kubuntu-migrate-backup-$(date +%Y%m%d-%H%M%S)"

    info "应用顶部菜单 + 居中 Dock + 右侧状态栏布局..."

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "cp $APPLETS_FILE $BACKUP_FILE"
        dry_echo "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript <topbar-layout>"
        return 0
    fi

    if ! plasma_appearance_is_plasma_session; then
        warn "当前不是 KDE Plasma 会话，跳过 Plasma 布局"
        return 0
    fi

    if ! command -v qdbus >/dev/null 2>&1; then
        warn "未找到 qdbus，跳过 Plasma 布局"
        return 0
    fi

    [ -f "$APPLETS_FILE" ] && cp "$APPLETS_FILE" "$BACKUP_FILE"

    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
panels().forEach(function(p) { p.remove(); });

desktops().forEach(function(d) {
  d.widgets().forEach(function(w) {
    if (w.type === 'org.kde.plasma.kickoff' ||
        w.type === 'org.kde.plasma.icontasks' ||
        w.type === 'org.kde.plasma.systemtray' ||
        w.type === 'org.kde.plasma.digitalclock' ||
        w.type === 'org.kde.plasma.panelspacer' ||
        w.type === 'org.kde.plasma.marginsseparator') {
      w.remove();
    }
  });
});

var top = new Panel;
top.location = 'top';
top.height = 44;
top.addWidget('org.kde.plasma.kickoff');
top.addWidget('org.kde.plasma.panelspacer');
var tasks = top.addWidget('org.kde.plasma.icontasks');
tasks.currentConfigGroup = ['General'];
tasks.writeConfig('fill', false);
tasks.writeConfig('groupingStrategy', 1);
tasks.writeConfig('showOnlyCurrentDesktop', false);
tasks.writeConfig('showOnlyCurrentActivity', false);
top.addWidget('org.kde.plasma.panelspacer');
top.addWidget('org.kde.plasma.systemtray');
top.addWidget('org.kde.plasma.digitalclock');
" || warn "Plasma 顶部栏布局应用失败"
}

step_14_plasma_appearance() {
    log "14. Plasma 外观与布局（可选）..."

    if ! is_feature_enabled "plasma_appearance"; then
        warn "未勾选 plasma_appearance 路线，跳过"
        return 0
    fi

    plasma_appearance_apply_theme
    plasma_appearance_apply_topbar_layout

    command -v kbuildsycoca5 >/dev/null 2>&1 && kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
    log "Plasma 外观与顶部栏布局已完成（必要时注销重登以完全生效）"
}
