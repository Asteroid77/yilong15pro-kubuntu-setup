#!/bin/bash

step_06_fonts() {
    log "6. 字体..."
    mkdir -p "$FONT_DIR"
    if [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
        JBM_URL=$(github_latest_asset_url "$REPO_NERD_FONTS" '^JetBrainsMono\.zip$')
        if [ -n "$JBM_URL" ] && download_github_robust "$JBM_URL" "JetBrainsMono.zip"; then
            mkdir -p "$FONT_DIR/JetBrainsMono"
            unzip -q -o "JetBrainsMono.zip" -d "$FONT_DIR/JetBrainsMono"
            rm -f "JetBrainsMono.zip"
        else
            warn "未获取到 JetBrainsMono Nerd Font 最新下载地址"
        fi
    fi
    if [ ! -d "$FONT_DIR/Inter" ]; then
        INTER_URL=$(github_latest_asset_url "$REPO_INTER" '^Inter-.*\.zip$')
        if [ -n "$INTER_URL" ] && download_github_robust "$INTER_URL" "Inter.zip"; then
            mkdir -p "$FONT_DIR/Inter"
            unzip -q -o "Inter.zip" -d "Inter_tmp"
            find Inter_tmp -name "*.ttf" -print0 | xargs -0 -I {} cp {} "$FONT_DIR/Inter/"
            rm -rf Inter_tmp Inter.zip
        else
            warn "未获取到 Inter 最新下载地址"
        fi
    fi
    if [ ! -d "$FONT_DIR/LXGWWenKai" ]; then
        mkdir -p "$FONT_DIR/LXGWWenKai"
        LXGW_REGULAR_URL=$(github_latest_asset_url "$REPO_LXGW_WENKAI" '^LXGWWenKai-Regular\.ttf$')
        LXGW_BOLD_URL=$(github_latest_asset_url "$REPO_LXGW_WENKAI" '^LXGWWenKai-Bold\.ttf$')
        [ -n "$LXGW_REGULAR_URL" ] && download_github_robust "$LXGW_REGULAR_URL" "$FONT_DIR/LXGWWenKai/LXGWWenKai-Regular.ttf"
        [ -n "$LXGW_BOLD_URL" ] && download_github_robust "$LXGW_BOLD_URL" "$FONT_DIR/LXGWWenKai/LXGWWenKai-Bold.ttf"
        [ -z "$LXGW_REGULAR_URL" ] && warn "未获取到 LXGW WenKai Regular 最新下载地址"
        [ -z "$LXGW_BOLD_URL" ] && warn "未获取到 LXGW WenKai Bold 最新下载地址"
    fi
    fc-cache -fv > /dev/null
}

