#!/bin/bash

step_00_sources() {
    log "0. 配置国内源..."
    if ! grep -q "$UBUNTU_MIRROR" /etc/apt/sources.list 2>/dev/null && ! grep -q "$UBUNTU_MIRROR" /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null; then
        [ -f /etc/apt/sources.list.d/ubuntu.sources ] && { sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak; sudo sed -i "s@//.*archive.ubuntu.com@//${UBUNTU_MIRROR}@g" /etc/apt/sources.list.d/ubuntu.sources; sudo sed -i "s@//.*security.ubuntu.com@//${UBUNTU_MIRROR}@g" /etc/apt/sources.list.d/ubuntu.sources; }
        [ -f /etc/apt/sources.list ] && { sudo sed -i "s@//.*archive.ubuntu.com@//${UBUNTU_MIRROR}@g" /etc/apt/sources.list; sudo sed -i "s@//.*security.ubuntu.com@//${UBUNTU_MIRROR}@g" /etc/apt/sources.list; }
        sudo apt update
    fi
}

