#!/bin/bash

step_11_mt7922() {
    log "11. Wi-Fi..."
    if has_mt7922_wifi; then
        ensure_grub_cmdline_linux_default "quiet splash pci=noaer pcie_aspm=off mem_sleep_default=deep i8042.reset i8042.nomux btusb.enable_autosuspend=n"
        warn "MT7922 驱动尚不成熟"
    else
        ensure_grub_cmdline_linux_default "quiet splash mem_sleep_default=deep i8042.reset i8042.nomux btusb.enable_autosuspend=n"
        info "未检测到 MT7922，使用默认 GRUB 调整"
    fi
}

