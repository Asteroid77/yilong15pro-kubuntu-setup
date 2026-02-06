#!/bin/bash

step_01_core() {
    if ! is_step_done "step1_core"; then
        log "1. 安装基础工具与驱动..."
        sudo apt install -y curl wget jq grep git build-essential software-properties-qt \
            apt-transport-https libtcmalloc-minimal4 im-config whiptail \
            fcitx5 fcitx5-chinese-addons fcitx5-rime fcitx5-config-qt \
            fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5 \
            librime-data-luna-pinyin librime-data-stroke librime-data-wubi \
            plasma-workspace-wayland \
            yakuake btop okular wireshark calibre zsh fonts-firacode ffmpegthumbs unzip net-tools \
            gitg

        info "安装显卡驱动..."
        sudo ubuntu-drivers autoinstall

        if is_nvidia_driver_available; then
            if nvidia_drm_modeset_enabled; then
                log "NVIDIA DRM modeset 已开启"
            else
                info "检测到 NVIDIA 模块但 DRM modeset 未开启，尝试开启..."
                enable_nvidia_drm_modeset
                warn "NVIDIA DRM modeset 需要重启后生效"
            fi
        else
            info "未检测到 NVIDIA 模块，跳过 DRM 检查"
        fi

        mark_step_done "step1_core"
    else
        warn "步骤 1 已完成"
    fi
}
