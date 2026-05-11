#!/bin/bash

terminal_kitty_asset_regex() {
    local ARCH
    ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
    case "$ARCH" in
        amd64) echo '^kitty-.*-x86_64\.txz$' ;;
        arm64) echo '^kitty-.*-arm64\.txz$' ;;
        *) return 1 ;;
    esac
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

rewrite_kitty_desktop_entries() {
    local APP_DIR=$1
    local KITTY_PREFIX=$2
    local KITTY_DESKTOP="$APP_DIR/kitty.desktop"
    local KITTY_OPEN_DESKTOP="$APP_DIR/kitty-open.desktop"

    if [ -f "$KITTY_DESKTOP" ]; then
        sed -i "s|^TryExec=kitty$|TryExec=$KITTY_PREFIX/bin/kitty|" "$KITTY_DESKTOP"
        sed -i "s|^Exec=kitty$|Exec=$KITTY_PREFIX/bin/kitty|" "$KITTY_DESKTOP"
        sed -i "s|^Icon=kitty$|Icon=$KITTY_PREFIX/lib/kitty/logo/kitty.png|" "$KITTY_DESKTOP"
        sed -i "s|^Icon=.*kitty\\.png$|Icon=$KITTY_PREFIX/lib/kitty/logo/kitty.png|" "$KITTY_DESKTOP"
    fi

    if [ -f "$KITTY_OPEN_DESKTOP" ]; then
        sed -i "s|^TryExec=kitty$|TryExec=$KITTY_PREFIX/bin/kitty|" "$KITTY_OPEN_DESKTOP"
        sed -i "s|^Exec=kitty +open %U$|Exec=$KITTY_PREFIX/bin/kitten +open %U|" "$KITTY_OPEN_DESKTOP"
        sed -i "s|^Icon=kitty$|Icon=$KITTY_PREFIX/lib/kitty/logo/kitty.png|" "$KITTY_OPEN_DESKTOP"
        sed -i "s|^Icon=.*kitty\\.png$|Icon=$KITTY_PREFIX/lib/kitty/logo/kitty.png|" "$KITTY_OPEN_DESKTOP"
    fi
}

install_upstream_kitty() {
    info "安装/更新 kitty 官方最新版..."
    export PATH="$HOME/.atuin/bin:$HOME/.local/bin:$PATH"
    mkdir -p "$HOME/.local" "$HOME/.local/bin" "$HOME/.local/share/applications"
    local KITTY_PREFIX="$HOME/.local/kitty"

    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "download latest kitty release asset (.txz) -> kitty.txz"
        dry_echo "rm -rf $KITTY_PREFIX"
        dry_echo "mkdir -p $KITTY_PREFIX"
        dry_echo "tar -xJf kitty.txz -C $KITTY_PREFIX"
        dry_echo "ln -sf $KITTY_PREFIX/bin/kitty $HOME/.local/bin/kitty"
        dry_echo "ln -sf $KITTY_PREFIX/bin/kitten $HOME/.local/bin/kitten"
        dry_echo "cp $KITTY_PREFIX/share/applications/kitty.desktop $HOME/.local/share/applications/"
        dry_echo "cp $KITTY_PREFIX/share/applications/kitty-open.desktop $HOME/.local/share/applications/"
        dry_echo "update-desktop-database $HOME/.local/share/applications"
        return 0
    fi

    local KITTY_ASSET_REGEX
    KITTY_ASSET_REGEX=$(terminal_kitty_asset_regex) || {
        error "当前架构暂未配置 kitty 安装规则"
        return 1
    }

    local KITTY_URL
    KITTY_URL=$(terminal_latest_asset_url "$REPO_KITTY" "$KITTY_ASSET_REGEX")
    if [ -z "$KITTY_URL" ]; then
        error "未获取到 kitty 最新安装包"
        return 1
    fi

    download_github_robust "$KITTY_URL" "kitty.txz"
    rm -rf "$KITTY_PREFIX"
    mkdir -p "$KITTY_PREFIX"
    tar -xJf "kitty.txz" -C "$KITTY_PREFIX"

    ln -sf "$KITTY_PREFIX/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$KITTY_PREFIX/bin/kitten" "$HOME/.local/bin/kitten"

    if [ -d "$KITTY_PREFIX/share/applications" ]; then
        cp -f "$KITTY_PREFIX/share/applications/kitty.desktop" "$HOME/.local/share/applications/" 2>/dev/null || true
        cp -f "$KITTY_PREFIX/share/applications/kitty-open.desktop" "$HOME/.local/share/applications/" 2>/dev/null || true
        rewrite_kitty_desktop_entries "$HOME/.local/share/applications" "$KITTY_PREFIX"
    fi

    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
    log "kitty 官方最新版已准备完成"
}

install_kitty_templates() {
    info "写入 kitty 配置模板..."
    install_template_with_backup "$(terminal_template_path "kitty/kitty.conf")" "$HOME/.config/kitty/kitty.conf"
    install_template_with_backup "$(terminal_template_path "kitty/open-actions.conf")" "$HOME/.config/kitty/open-actions.conf"
}

install_shell_kitty_bootstrap() {
    info "注入 kubuntu-migrate kitty shell 片段..."

    local ZSH_CONTENT
    local BASH_CONTENT
    ZSH_CONTENT=$(cat "$(terminal_template_path "shell/kitty.zsh")")
    BASH_CONTENT=$(cat "$(terminal_template_path "shell/kitty.bash")")

    [ -f "$HOME/.zshrc" ] && backup_file_with_timestamp "$HOME/.zshrc" >/dev/null || true
    [ -f "$HOME/.bashrc" ] && backup_file_with_timestamp "$HOME/.bashrc" >/dev/null || true

    upsert_managed_block "$HOME/.zshrc" "kubuntu-migrate kitty" "$ZSH_CONTENT"
    upsert_managed_block "$HOME/.bashrc" "kubuntu-migrate kitty" "$BASH_CONTENT"
}

step_13_kitty() {
    log "13. Kitty（可选）..."

    if ! is_feature_enabled "kitty_terminal"; then
        warn "未勾选 kitty_terminal 路线，跳过"
        return 0
    fi

    install_upstream_kitty
    install_kitty_templates
    install_shell_kitty_bootstrap

    log "kitty 路线已完成（重新打开 shell 后可使用 kssh）"
}
