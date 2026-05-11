#!/bin/bash

terminal_glow_asset_regex() {
    local ARCH
    ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
    case "$ARCH" in
        amd64) echo '^glow_.*_(amd64|x86_64)\.deb$' ;;
        arm64) echo '^glow_.*_(arm64|aarch64)\.deb$' ;;
        *) return 1 ;;
    esac
}

terminal_glow_tar_asset_regex() {
    local ARCH
    ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
    case "$ARCH" in
        amd64) echo '^glow_.*_Linux_x86_64\.tar\.gz$' ;;
        arm64) echo '^glow_.*_Linux_arm64\.tar\.gz$' ;;
        *) return 1 ;;
    esac
}

can_sudo_non_interactive() {
    sudo -n true >/dev/null 2>&1
}

run_pipx() {
    if command -v pipx >/dev/null 2>&1; then
        pipx "$@"
    else
        python3 -m pipx "$@"
    fi
}

terminal_latest_asset_url() {
    local REPO=$1
    local NAME_REGEX=$2
    local API_URL="https://api.github.com/repos/${REPO}/releases/latest"
    local -a CURL_OPTS=(-sSL --connect-timeout 30 --max-time 90)
    [ -n "${PROXY_PORT:-}" ] && CURL_OPTS+=(--proxy "$(proxy_url)")

    curl "${CURL_OPTS[@]}" "$API_URL" | \
        jq -r --arg re "$NAME_REGEX" '.assets[]? | select(.name | test($re)) | .browser_download_url' | head -n 1
}

terminal_template_path() {
    echo "$ROOT_DIR/scripts/templates/$1"
}

install_template_with_backup() {
    local SOURCE_FILE=$1
    local TARGET_FILE=$2

    mkdir -p "$(dirname "$TARGET_FILE")"
    [ -f "$TARGET_FILE" ] && backup_file_with_timestamp "$TARGET_FILE" >/dev/null || true

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "cp $SOURCE_FILE $TARGET_FILE"
        return 0
    fi

    cp -f "$SOURCE_FILE" "$TARGET_FILE"
}

install_glow() {
    if command -v glow >/dev/null 2>&1; then
        warn "glow 已安装"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "download latest glow release (.deb) -> glow.deb"
        dry_echo "sudo apt install -y ./glow.deb"
        return 0
    fi

    if can_sudo_non_interactive; then
        local ASSET_REGEX
        ASSET_REGEX=$(terminal_glow_asset_regex) || {
            warn "当前架构暂未配置 glow 安装规则，跳过 glow"
            return 0
        }

        local GLOW_URL
        GLOW_URL=$(terminal_latest_asset_url "$REPO_GLOW" "$ASSET_REGEX")
        if [ -z "$GLOW_URL" ]; then
            error "未获取到 glow 最新安装包"
            return 1
        fi

        smart_install_deb "glow" "$GLOW_URL" "glow.deb"
        return 0
    fi

    info "当前无法无密码 sudo，改用用户态安装 glow..."
    local TAR_REGEX
    TAR_REGEX=$(terminal_glow_tar_asset_regex) || {
        warn "当前架构暂未配置 glow 用户态安装规则，跳过 glow"
        return 0
    }

    local TAR_URL
    TAR_URL=$(terminal_latest_asset_url "$REPO_GLOW" "$TAR_REGEX")
    if [ -z "$TAR_URL" ]; then
        error "未获取到 glow 用户态安装包"
        return 1
    fi

    mkdir -p "$HOME/.local/bin"
    rm -f "glow.tar.gz"
    download_github_robust "$TAR_URL" "glow.tar.gz"

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    tar -xzf "glow.tar.gz" -C "$TMP_DIR"

    local GLOW_BIN
    GLOW_BIN=$(find "$TMP_DIR" -type f -name glow | head -n 1)
    if [ -z "$GLOW_BIN" ]; then
        rm -rf "$TMP_DIR"
        error "未在 glow 归档中找到可执行文件"
        return 1
    fi

    cp -f "$GLOW_BIN" "$HOME/.local/bin/glow"
    chmod +x "$HOME/.local/bin/glow"
    rm -rf "$TMP_DIR"
}

ensure_pipx_ready() {
    if command -v pipx >/dev/null 2>&1 || python3 -m pipx --version >/dev/null 2>&1; then
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "python3 -m pip install --user pipx"
        return 0
    fi

    if can_sudo_non_interactive; then
        sudo apt install -y pipx python3-venv
    else
        python3 -m pip install --user pipx
    fi
}

install_streamdown() {
    export PATH="$HOME/.local/bin:$PATH"
    if command -v sd >/dev/null 2>&1; then
        warn "Streamdown 已安装"
        return 0
    fi

    ensure_pipx_ready
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "pipx install streamdown"
        return 0
    fi

    if run_pipx list 2>/dev/null | grep -q 'package streamdown '; then
        with_proxy_env run_pipx upgrade streamdown
    else
        with_proxy_env run_pipx install streamdown
    fi
}

install_atuin() {
    export PATH="$HOME/.atuin/bin:$HOME/.local/bin:$PATH"
    if command -v atuin >/dev/null 2>&1 || [ -x "$HOME/.atuin/bin/atuin" ]; then
        warn "Atuin 已安装"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive"
        return 0
    fi

    with_proxy_env bash -lc 'curl --proto "=https" --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive'
}

install_terminal_tools_templates() {
    info "写入 terminal tools 模板..."
    install_template_with_backup "$(terminal_template_path "atuin/config.toml")" "$HOME/.config/atuin/config.toml"
}

install_shell_terminal_tools_bootstrap() {
    info "注入 kubuntu-migrate terminal-tools shell 片段..."

    local ZSH_CONTENT
    local BASH_CONTENT
    ZSH_CONTENT=$(cat "$(terminal_template_path "shell/terminal-tools.zsh")")
    BASH_CONTENT=$(cat "$(terminal_template_path "shell/terminal-tools.bash")")

    [ -f "$HOME/.zshrc" ] && backup_file_with_timestamp "$HOME/.zshrc" >/dev/null || true
    [ -f "$HOME/.bashrc" ] && backup_file_with_timestamp "$HOME/.bashrc" >/dev/null || true

    upsert_managed_block "$HOME/.zshrc" "kubuntu-migrate terminal-tools" "$ZSH_CONTENT"
    upsert_managed_block "$HOME/.bashrc" "kubuntu-migrate terminal-tools" "$BASH_CONTENT"
}

install_tmux_restore_package() {
    if command -v tmux >/dev/null 2>&1; then
        warn "tmux 已安装"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "sudo apt install -y tmux"
        return 0
    fi

    sudo apt install -y tmux "${APT_PROXY_ARGS[@]}"
}

install_tmux_restore_plugin() {
    local REPO=$1
    local TARGET=$2

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "git clone/update https://github.com/${REPO}.git -> $TARGET"
        return 0
    fi

    mkdir -p "$(dirname "$TARGET")"
    if [ -d "$TARGET/.git" ]; then
        with_proxy_env git -C "$TARGET" pull --ff-only || warn "更新 $REPO 失败，保留现有版本"
    else
        rm -rf "$TARGET"
        with_proxy_env git clone "https://github.com/${REPO}.git" "$TARGET"
    fi
}

install_tmux_restore_plugins() {
    install_tmux_restore_plugin "$REPO_TMUX_RESURRECT" "$HOME/.tmux/plugins/tmux-resurrect"
    install_tmux_restore_plugin "$REPO_TMUX_CONTINUUM" "$HOME/.tmux/plugins/tmux-continuum"
}

install_tmux_restore_templates() {
    info "写入 tmux restore 模板..."

    install_template_with_backup "$(terminal_template_path "tmux/tmux.conf")" "$HOME/.tmux.conf"
    install_template_with_backup "$(terminal_template_path "bin/meteor-tmux-auto")" "$HOME/DEV/script/bin/meteor-tmux-auto"
    install_template_with_backup "$(terminal_template_path "bin/meteor-tmux-cleanup")" "$HOME/DEV/script/bin/meteor-tmux-cleanup"
    install_template_with_backup "$(terminal_template_path "bin/tmux-managed-sessions")" "$HOME/DEV/script/bin/tmux-managed-sessions"
    install_template_with_backup "$(terminal_template_path "bin/tmux-session-title")" "$HOME/DEV/script/bin/tmux-session-title"
    install_template_with_backup "$(terminal_template_path "bin/tmux-close-current")" "$HOME/DEV/script/bin/tmux-close-current"
    install_template_with_backup "$(terminal_template_path "bin/tmux-save-current")" "$HOME/DEV/script/bin/tmux-save-current"
    install_template_with_backup "$(terminal_template_path "bin/yakuake-tmux-restore-once")" "$HOME/DEV/script/bin/yakuake-tmux-restore-once"
    install_template_with_backup "$(terminal_template_path "bin/yakuake-tmux-restore-daemon")" "$HOME/DEV/script/bin/yakuake-tmux-restore-daemon"
    install_template_with_backup "$(terminal_template_path "bin/yakuake-restore-tabs")" "$HOME/DEV/script/bin/yakuake-restore-tabs"
    install_template_with_backup "$(terminal_template_path "konsole/TmuxRestore.profile")" "$HOME/.local/share/konsole/TmuxRestore.profile"
    install_template_with_backup "$(terminal_template_path "autostart/yakuake-tmux-restore.desktop")" "$HOME/.config/autostart/yakuake-tmux-restore.desktop"

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "chmod +x $HOME/DEV/script/bin/meteor-tmux-auto $HOME/DEV/script/bin/meteor-tmux-cleanup $HOME/DEV/script/bin/tmux-managed-sessions $HOME/DEV/script/bin/tmux-session-title $HOME/DEV/script/bin/tmux-close-current $HOME/DEV/script/bin/tmux-save-current $HOME/DEV/script/bin/yakuake-tmux-restore-once $HOME/DEV/script/bin/yakuake-tmux-restore-daemon $HOME/DEV/script/bin/yakuake-restore-tabs"
    else
        chmod +x "$HOME/DEV/script/bin/meteor-tmux-auto" "$HOME/DEV/script/bin/meteor-tmux-cleanup" "$HOME/DEV/script/bin/tmux-managed-sessions" "$HOME/DEV/script/bin/tmux-session-title" "$HOME/DEV/script/bin/tmux-close-current" "$HOME/DEV/script/bin/tmux-save-current" "$HOME/DEV/script/bin/yakuake-tmux-restore-once" "$HOME/DEV/script/bin/yakuake-tmux-restore-daemon" "$HOME/DEV/script/bin/yakuake-restore-tabs"
    fi
}

install_shell_tmux_restore_bootstrap() {
    info "注入 kubuntu-migrate tmux-restore shell 片段..."

    local ZSH_CONTENT
    ZSH_CONTENT=$(cat "$(terminal_template_path "shell/tmux-restore.zsh")")

    [ -f "$HOME/.zshrc" ] && backup_file_with_timestamp "$HOME/.zshrc" >/dev/null || true
    upsert_managed_block "$HOME/.zshrc" "kubuntu-migrate tmux-restore" "$ZSH_CONTENT"
}

install_tmux_restore() {
    if ! is_feature_enabled "tmux_restore"; then
        warn "未勾选 tmux_restore 路线，跳过"
        return 0
    fi

    install_tmux_restore_package
    install_tmux_restore_plugins
    install_tmux_restore_templates
    install_shell_tmux_restore_bootstrap
}

install_yakuake_snapshot() {
    if ! is_feature_enabled "yakuake_snapshot"; then
        warn "未勾选 yakuake_snapshot 路线，跳过"
        return 0
    fi

    info "写入 Yakuake snapshot 模板..."
    install_template_with_backup "$(terminal_template_path "bin/yakuake-snapshot-shell")" "$HOME/DEV/script/bin/yakuake-snapshot-shell"
    install_template_with_backup "$(terminal_template_path "bin/yakuake-snapshot-restore")" "$HOME/DEV/script/bin/yakuake-snapshot-restore"
    install_template_with_backup "$(terminal_template_path "zsh/yakuake-snapshot.zsh")" "$HOME/DEV/script/zsh/yakuake-snapshot.zsh"
    install_template_with_backup "$(terminal_template_path "konsole/YakuakeSnapshot.profile")" "$HOME/.local/share/konsole/YakuakeSnapshot.profile"

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "chmod +x $HOME/DEV/script/bin/yakuake-snapshot-shell $HOME/DEV/script/bin/yakuake-snapshot-restore"
    else
        chmod +x "$HOME/DEV/script/bin/yakuake-snapshot-shell" "$HOME/DEV/script/bin/yakuake-snapshot-restore"
    fi

    local ZSH_CONTENT
    ZSH_CONTENT=$(cat "$(terminal_template_path "shell/yakuake-snapshot.zsh")")
    [ -f "$HOME/.zshrc" ] && backup_file_with_timestamp "$HOME/.zshrc" >/dev/null || true
    upsert_managed_block "$HOME/.zshrc" "kubuntu-migrate yakuake-snapshot" "$ZSH_CONTENT"
}

install_wezterm_tmux_templates() {
    info "写入 WezTerm + tmux GUI tabs 模板..."

    install_template_with_backup "$(terminal_template_path "wezterm/wezterm.lua")" "$HOME/.wezterm.lua"
    install_template_with_backup "$(terminal_template_path "tmux/wezterm.conf")" "$HOME/.config/tmux/wezterm.conf"
    install_template_with_backup "$(terminal_template_path "bin/wezterm-tmux-tab")" "$HOME/DEV/script/bin/wezterm-tmux-tab"

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "chmod +x $HOME/DEV/script/bin/wezterm-tmux-tab"
    else
        chmod +x "$HOME/DEV/script/bin/wezterm-tmux-tab"
    fi
}

install_wezterm_tmux() {
    if ! is_feature_enabled "wezterm_tmux"; then
        warn "未勾选 wezterm_tmux 路线，跳过"
        return 0
    fi

    install_tmux_restore_package
    install_tmux_restore_plugins
    install_wezterm_tmux_templates
}

cleanup_legacy_kitty_managed_block() {
    remove_managed_block "$HOME/.zshrc" "kubuntu-migrate kitty"
    remove_managed_block "$HOME/.bashrc" "kubuntu-migrate kitty"
}

cleanup_kitty_managed_files_if_disabled() {
    if is_feature_enabled "kitty_terminal"; then
        return 0
    fi

    info "移除 kitty 受控配置与桌面入口..."
    local -a FILES=(
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/kitty/open-actions.conf"
        "$HOME/.local/share/applications/kitty.desktop"
        "$HOME/.local/share/applications/kitty-open.desktop"
    )

    for FILE in "${FILES[@]}"; do
        if [ -f "$FILE" ]; then
            backup_file_with_timestamp "$FILE" >/dev/null || true
            rm -f "$FILE"
        fi
    done
}

step_12_terminal_tools() {
    log "12. Terminal Tools（终端增强）..."

    if is_feature_enabled "terminal_tools"; then
        install_glow
        install_streamdown
        install_atuin
        install_terminal_tools_templates
        cleanup_legacy_kitty_managed_block
        install_shell_terminal_tools_bootstrap
        cleanup_kitty_managed_files_if_disabled
    else
        warn "未勾选 terminal_tools 路线，跳过"
    fi

    install_tmux_restore
    install_yakuake_snapshot
    install_wezterm_tmux

    log "终端增强步骤已完成"
}
