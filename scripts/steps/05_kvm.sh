#!/bin/bash

step_05_kvm() {
    if ! is_step_done "step5_kvm"; then
        log "5. KVM..."
        sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
        sudo adduser "$USER" libvirt 2>/dev/null || true
        sudo adduser "$USER" kvm 2>/dev/null || true
        mark_step_done "step5_kvm"
    fi
}

