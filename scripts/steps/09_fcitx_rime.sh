#!/bin/bash

step_09_fcitx_rime() {
    log "9. 薄荷输入法..."
    RIME_DIR="$HOME/.local/share/fcitx5/rime"
    if [ ! -f "$RIME_DIR/rime_mint.schema.yaml" ]; then
        mkdir -p "$RIME_DIR"
        if download_github_robust "https://github.com/Mintimate/oh-my-rime/archive/refs/heads/main.zip" "oh-my-rime.zip"; then
            unzip -q -o "oh-my-rime.zip" -d "oh-my-rime-tmp"
            cp -r oh-my-rime-tmp/oh-my-rime-main/* "$RIME_DIR/"
            rm -rf oh-my-rime-tmp oh-my-rime.zip
            write_file "$RIME_DIR/default.custom.yaml" <<EOF
patch:
  "menu/page_size": 10
  schema_list:
    - { schema: rime_mint }
    - { schema: double_pinyin_flypy }
    - { schema: wubi86_jidian }
EOF
            info "薄荷输入法配置已下载"
        fi
    fi
    mkdir -p "$HOME/.config/autostart"
    if [ ! -f "$HOME/.config/autostart/fcitx5.desktop" ]; then
        write_file "$HOME/.config/autostart/fcitx5.desktop" << EOF
[Desktop Entry]
Name=Fcitx 5
Exec=fcitx5
Type=Application
EOF
    fi

    rewrite_keep_only_xmodifiers "/etc/environment" "etc_environment"
    rewrite_keep_only_xmodifiers "$HOME/.xprofile" "xprofile"
    rewrite_keep_only_xmodifiers "$HOME/.pam_environment" "pam_environment"
    im-config -n none 2>/dev/null || true

    restart_fcitx5_if_graphical
}
