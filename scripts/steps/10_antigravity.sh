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
    set -e
}

