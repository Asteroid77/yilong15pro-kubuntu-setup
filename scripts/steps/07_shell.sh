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
}

