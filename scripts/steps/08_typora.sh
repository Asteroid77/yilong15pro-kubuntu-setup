#!/bin/bash

step_08_typora() {
    log "8. Typora..."
    if ! is_feature_enabled "typora"; then
        warn "未勾选 Typora，跳过"
    fi
    if is_feature_enabled "typora" && [ ! -d "/opt/typora" ]; then
        if smart_download "https://download.typora.io/linux/Typora-linux-x64.tar.gz" "Typora-linux-x64.tar.gz"; then
            sudo tar -xzf "Typora-linux-x64.tar.gz" -C /opt
            [ -d "/opt/bin/Typora-linux-x64" ] && sudo mv /opt/bin/Typora-linux-x64 /opt/typora && sudo rmdir /opt/bin 2>/dev/null
            sudo ln -sf /opt/typora/Typora /usr/local/bin/typora
            cat << 'EOF' | sudo tee /usr/share/applications/typora.desktop > /dev/null
[Desktop Entry]
Name=Typora
Exec=/opt/typora/Typora %U
Icon=/opt/typora/resources/assets/icon/icon_512x512.png
Terminal=false
Type=Application
Categories=Office;TextEditor;
MimeType=text/markdown;
EOF
        fi
    fi
    if is_feature_enabled "typora" && [ -d "/opt/typora" ]; then
        for SANDBOX in "/opt/typora/chrome-sandbox" "/opt/typora/Chrome-sandbox"; do
            if [ -f "$SANDBOX" ]; then
                sudo chown root:root "$SANDBOX"
                sudo chmod 4755 "$SANDBOX"
            fi
        done
    fi
}

