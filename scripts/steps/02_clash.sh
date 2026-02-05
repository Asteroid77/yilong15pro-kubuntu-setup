#!/bin/bash

step_02_clash() {
    log "2. Clash Verge..."
    if is_feature_enabled "clash_verge"; then
        if ! is_pkg_installed "clash-verge"; then
            URL=$(github_latest_deb_url "$REPO_CLASH_VERGE")
            if [ -n "$URL" ]; then
                download_github_robust "$URL" "clash.deb"
                smart_install_deb "clash-verge" "github_robust" "clash.deb"
            else
                warn "未获取到 Clash Verge 最新下载地址"
            fi
        fi
        if is_pkg_installed "clash-verge"; then
            if ! systemctl is-active --quiet clash-verge-service 2>/dev/null; then
                sudo clash-verge-service-uninstall 2>/dev/null || true
                sudo clash-verge-service-install || true
            fi
        fi
    else
        warn "未勾选 Clash Verge，跳过"
    fi
    load_or_ask_proxy
    ensure_shell_proxy_helpers
}

