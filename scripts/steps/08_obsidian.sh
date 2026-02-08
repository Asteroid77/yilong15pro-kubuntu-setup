#!/bin/bash

step_08_obsidian() {
    log "8. Obsidian..."
    if ! is_feature_enabled "obsidian"; then
        warn "未勾选 Obsidian，跳过"
        return 0
    fi

    if ! is_pkg_installed "obsidian"; then
        local OBSIDIAN_URL
        OBSIDIAN_URL=$(github_latest_deb_url "$REPO_OBSIDIAN")
        if [ -n "$OBSIDIAN_URL" ]; then
            download_github_robust "$OBSIDIAN_URL" "obsidian.deb"
            smart_install_deb "obsidian" "github_robust" "obsidian.deb"
        else
            warn "未获取到 Obsidian 最新下载地址，跳过安装"
        fi
    else
        warn "Obsidian 已安装"
    fi

    info "建议安装 Obsidian 社区插件："
    info "- Custom Attachment Location"
    info "- Editing Toolbar"
    info "- make.md"
    info "- Markdown prettifier"
    info "- Style settings"
    info "- Table Generator"
}
