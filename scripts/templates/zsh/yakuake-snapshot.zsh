# Managed by KUbuntu Migrate
# Records lightweight Yakuake tab state for file-based restore.

__yakuake_snapshot_record() {
  [[ -n "${YAKUAKE_SNAPSHOT_TAB_ID:-}" ]] || return 0
  [[ -n "${YAKUAKE_SNAPSHOT_TAB_DIR:-}" ]] || return 0
  if [[ "${YAKUAKE_SNAPSHOT_LAST_COMMAND:-}" == *"tmux attach-session -t meteor-tab-"* ]]; then
    mkdir -p "$YAKUAKE_SNAPSHOT_TAB_DIR"
    : >"$YAKUAKE_SNAPSHOT_TAB_DIR/ignored"
    return 0
  fi
  mkdir -p "$YAKUAKE_SNAPSHOT_TAB_DIR"
  printf '%s\n' "$PWD" >"$YAKUAKE_SNAPSHOT_TAB_DIR/cwd"
  printf '%s\n' "${YAKUAKE_SNAPSHOT_LAST_COMMAND:-}" >"$YAKUAKE_SNAPSHOT_TAB_DIR/last_command"
  printf '%s\n' "${YAKUAKE_SNAPSHOT_TITLE:-$(basename "$PWD")}" >"$YAKUAKE_SNAPSHOT_TAB_DIR/title"
}

__yakuake_snapshot_preexec() {
  YAKUAKE_SNAPSHOT_LAST_COMMAND="$1"
  __yakuake_snapshot_record
}

__yakuake_snapshot_precmd() {
  __yakuake_snapshot_record
}

ysnap-title() {
  YAKUAKE_SNAPSHOT_TITLE="${*:-$(basename "$PWD")}"
  __yakuake_snapshot_record
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __yakuake_snapshot_preexec
add-zsh-hook precmd __yakuake_snapshot_precmd
