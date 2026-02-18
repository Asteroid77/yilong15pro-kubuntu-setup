#!/bin/bash

step_07_shell() {
    log "7. Shell & System..."
    if command -v zsh &>/dev/null && [ "$SHELL" != "$(which zsh)" ]; then
        sudo chsh -s "$(which zsh)" "$USER"
    fi
    if ! command -v starship &>/dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    if ! command -v zoxide &>/dev/null; then
        run_remote_bash_installer "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
    fi

    append_if_missing "$HOME/.zshrc" "eval \"\$(starship init zsh)\""
    append_if_missing "$HOME/.zshrc" "eval \"\$(zoxide init zsh)\""
    append_if_missing "$HOME/.zshrc" "export PATH=\"\$PATH:/usr/local/go/bin\""
    append_if_missing "$HOME/.zshrc" "export PATH=\"\$HOME/.local/share/fnm:\$PATH\""
    append_if_missing "$HOME/.zshrc" "eval \"\$(fnm env)\""
    if [ -d "$HOME/.sdkman" ]; then
        append_if_missing "$HOME/.zshrc" "export SDKMAN_DIR=\"\$HOME/.sdkman\""
        append_if_missing "$HOME/.zshrc" "[[ -s \"\$HOME/.sdkman/bin/sdkman-init.sh\" ]] && source \"\$HOME/.sdkman/bin/sdkman-init.sh\""
    fi
    sudo timedatectl set-local-rtc 1 --adjust-system-clock

    # tealdeer: 通过 ghfast.top 加速下载 tldr-pages
    local TLDR_PAGES_DIR="$HOME/.cache/tealdeer/tldr-pages"
    if [ ! -d "$TLDR_PAGES_DIR" ]; then
        info "下载 tldr-pages（ghfast.top 加速）..."
        local TLDR_ZIP="/tmp/tldr.zip"
        local TLDR_TEMP="/tmp/tldr-temp"
        if [ "$DRY_RUN" -eq 1 ]; then
            dry_echo "curl -L -o $TLDR_ZIP https://ghfast.top/https://github.com/tldr-pages/tldr/archive/refs/heads/main.zip"
            dry_echo "unzip -q $TLDR_ZIP -d $TLDR_TEMP"
            dry_echo "mkdir -p $TLDR_PAGES_DIR && mv $TLDR_TEMP/tldr-main/pages $TLDR_PAGES_DIR/"
        else
            curl -L -o "$TLDR_ZIP" "https://ghfast.top/https://github.com/tldr-pages/tldr/archive/refs/heads/main.zip"
            unzip -q "$TLDR_ZIP" -d "$TLDR_TEMP"
            mkdir -p "$TLDR_PAGES_DIR"
            mv "$TLDR_TEMP/tldr-main/pages" "$TLDR_PAGES_DIR/"
            rm -rf "$TLDR_ZIP" "$TLDR_TEMP"
            log "tldr-pages 已安装至 $TLDR_PAGES_DIR"
        fi
    else
        warn "tldr-pages 已存在，跳过"
    fi

    # 别名：bat / fd / helpme
    append_if_missing "$HOME/.zshrc" "alias bat='batcat'"
    append_if_missing "$HOME/.zshrc" "alias fd='fdfind'"
    append_if_missing "$HOME/.zshrc" "alias helpme='tldr --list | fzf --preview \"tldr {}\" --preview-window=right:70% | xargs tldr'"
}

