# Managed by KUbuntu Migrate
# Auto-enter restorable tmux sessions for Konsole/Yakuake tabs.

export PATH="$HOME/DEV/script/bin:$HOME/.local/bin:$PATH"

tm() {
  local session="${1:-main}"
  tmux new-session -A -s "$session"
}

t() {
  meteor-tmux-auto
}

tn() {
  local name="${1:-$(basename "$PWD")}"
  tmux new-window -n "$name" -c "$PWD"
}

tclose() {
  tmux-close-current
}

tsave() {
  tmux-save-current
}

yrestore() {
  yakuake-tmux-restore-once
}

__meteor_should_auto_tmux() {
  [[ -o interactive ]] || return 1
  [[ -z "${TMUX:-}" ]] || return 1
  [[ -z "${SSH_CONNECTION:-}${SSH_TTY:-}" ]] || return 1
  [[ -z "${NO_TMUX:-}" ]] || return 1
  [[ "${AUTO_TMUX:-}" == "1" ]] || return 1
  [[ -t 0 && -t 1 ]] || return 1
  command -v tmux >/dev/null 2>&1 || return 1

  case "${TERM_PROGRAM:-}" in
    vscode|JetBrains-JediTerm) return 1 ;;
  esac

  case "${TERM:-}" in
    dumb|linux) return 1 ;;
  esac

  return 0
}

if __meteor_should_auto_tmux; then
  exec meteor-tmux-auto
fi
