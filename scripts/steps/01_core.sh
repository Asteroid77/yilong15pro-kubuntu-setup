#!/bin/bash

step_01_core() {
    if ! is_step_done "step1_core"; then
        log "1. 安装基础工具与驱动..."
        sudo apt install -y curl wget jq grep git build-essential software-properties-qt \
            apt-transport-https libtcmalloc-minimal4 im-config whiptail \
            fcitx5 fcitx5-chinese-addons fcitx5-rime \
            fcitx5-configtool fcitx5-config-qt kde-config-fcitx5 \
            fcitx5-frontend-qt6 fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 \
            librime-data-luna-pinyin librime-data-stroke librime-data-wubi \
            btop okular wireshark calibre zsh fonts-firacode ffmpegthumbs unzip net-tools wl-clipboard \
            bat fd-find fzf ncdu tealdeer

        info "安装 NVIDIA open driver 580..."
        sudo apt install -y nvidia-driver-580-open

        mark_step_done "step1_core"
    else
        warn "步骤 1 已完成"
    fi
}
