#!/bin/bash

step_03_mpv() {
    if ! is_feature_enabled "mpv_uosc_thumbfast"; then
        warn "未勾选 MPV/uosc/thumbfast，跳过"
        return 0
    fi

    log "3. MPV + uosc + thumbfast..."

    if ! command -v mpv &>/dev/null; then
        info "安装 MPV..."
        sudo apt install -y mpv
    else
        warn "MPV 已安装"
    fi

    local MPV_DIR="$HOME/.config/mpv"
    local SCRIPTS_DIR="$MPV_DIR/scripts"
    local SCRIPT_OPTS_DIR="$MPV_DIR/script-opts"
    mkdir -p "$SCRIPTS_DIR" "$SCRIPT_OPTS_DIR"

    info "安装/更新 uosc..."
    run_remote_bash_installer "https://raw.githubusercontent.com/tomasklaen/uosc/master/installers/unix.sh" || true

    info "安装/更新 thumbfast..."
    if [ ! -d "$SCRIPTS_DIR/thumbfast" ]; then
        with_proxy_env git clone "https://github.com/po5/thumbfast.git" "$SCRIPTS_DIR/thumbfast" || true
    else
        warn "thumbfast 已存在"
    fi
    if [ -e "$SCRIPTS_DIR/thumbfast/thumbfast.lua" ] && [ ! -e "$SCRIPTS_DIR/thumbfast.lua" ]; then
        ln -sf "$SCRIPTS_DIR/thumbfast/thumbfast.lua" "$SCRIPTS_DIR/thumbfast.lua" 2>/dev/null || true
    fi

    local MPV_CONF="$MPV_DIR/mpv.conf"
    local INPUT_CONF="$MPV_DIR/input.conf"
    local CONF_MARKER="# >>> kubuntu-migrate mpv (uosc) >>>"
    local INPUT_MARKER="# >>> kubuntu-migrate mpv (uosc keys) >>>"

    mkdir -p "$MPV_DIR"

    if [ ! -f "$MPV_CONF" ] || ! grep -qF "$CONF_MARKER" "$MPV_CONF" 2>/dev/null; then
        append_file "$MPV_CONF" <<EOF

$CONF_MARKER
# --- 基础设置 ---
hwdec=auto-safe
save-position-on-quit=yes
volume=100
keep-open=yes

# --- uosc 必须设置（禁用原生界面）---
osc=no
osd-bar=no
border=no
# <<< kubuntu-migrate mpv (uosc) <<<
EOF
    else
        warn "已检测到 MPV 配置标记，跳过写入 mpv.conf"
    fi

    if [ ! -f "$INPUT_CONF" ] || ! grep -qF "$INPUT_MARKER" "$INPUT_CONF" 2>/dev/null; then
        append_file "$INPUT_CONF" <<'EOF'

# >>> kubuntu-migrate mpv (uosc keys) >>>
# 右键唤起 uosc 菜单 (类似 PotPlayer)
MOUSE_BTN2   script-binding uosc/menu

# Tab 键查看视频信息/时间轴
TAB          script-binding uosc/toggle-ui

# 播放控制
SPACE        cycle pause
m            no-osd cycle mute

# 滚轮控制音量
WHEEL_UP     no-osd add volume 2
WHEEL_DOWN   no-osd add volume -2
# <<< kubuntu-migrate mpv (uosc keys) <<<
EOF
    else
        warn "已检测到 MPV 按键标记，跳过写入 input.conf"
    fi
}

