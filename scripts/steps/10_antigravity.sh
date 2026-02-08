#!/bin/bash

step_10_antigravity() {
    log "10. Antigravity..."
    set +e
    if ! is_feature_enabled "antigravity"; then
        warn "未勾选 Antigravity，跳过"
    fi
    if is_feature_enabled "antigravity" && ! is_pkg_installed "antigravity"; then
        build_apt_proxy_args
        if curl_with_proxy "https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg" 10 | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg; then
            echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
            sudo apt update "${APT_PROXY_ARGS[@]}"
            sudo apt install -y antigravity "${APT_PROXY_ARGS[@]}"
        fi
    fi

    if is_feature_enabled "antigravity"; then
        local MANAGER_URL
        local MANAGER_FILE="antigravity-manager.deb"
        local MANAGER_PKG=""

        MANAGER_URL=$(github_latest_deb_url "$REPO_ANTIGRAVITY_MANAGER")
        if [ -n "$MANAGER_URL" ]; then
            if download_github_robust "$MANAGER_URL" "$MANAGER_FILE" && check_deb_valid "$MANAGER_FILE"; then
                MANAGER_PKG=$(dpkg-deb -f "$MANAGER_FILE" Package 2>/dev/null || true)
                if [ -n "$MANAGER_PKG" ] && is_pkg_installed "$MANAGER_PKG"; then
                    warn "Antigravity-Manager 已安装"
                else
                    info "安装 Antigravity-Manager..."
                    sudo apt install -y "./$MANAGER_FILE"
                fi
            else
                warn "Antigravity-Manager 包下载或校验失败，跳过"
            fi
        else
            warn "未获取到 Antigravity-Manager 最新下载地址，跳过"
        fi
    fi

    set -e
}
