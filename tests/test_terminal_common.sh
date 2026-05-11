#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/12_terminal_tools.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/13_kitty.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file=$1
  local needle=$2
  grep -qF -- "$needle" "$file" || fail "expected [$file] to contain: $needle"
}

assert_not_contains() {
  local file=$1
  local needle=$2
  if grep -qF -- "$needle" "$file"; then
    fail "expected [$file] to NOT contain: $needle"
  fi
}

assert_file_exists() {
  local file=$1
  [ -f "$file" ] || fail "expected [$file] to exist"
}

assert_equals() {
  local expected=$1
  local actual=$2
  [ "$expected" = "$actual" ] || fail "expected [$expected], got [$actual]"
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARGET_FILE="$TMP_DIR/sample.conf"
cat > "$TARGET_FILE" <<'FILE'
line-1
FILE

backup_file_with_timestamp "$TARGET_FILE"
BACKUP_COUNT=$(find "$TMP_DIR" -maxdepth 1 -type f -name 'sample.conf.bak.*' | wc -l | tr -d ' ')
assert_equals "1" "$BACKUP_COUNT"

upsert_managed_block "$TARGET_FILE" "kubuntu-migrate kitty" $'alpha\nbeta'
assert_file_contains "$TARGET_FILE" '# >>> kubuntu-migrate kitty >>>'
assert_file_contains "$TARGET_FILE" 'alpha'
assert_file_contains "$TARGET_FILE" 'beta'
assert_file_contains "$TARGET_FILE" '# <<< kubuntu-migrate kitty <<<'

upsert_managed_block "$TARGET_FILE" "kubuntu-migrate kitty" $'gamma'
assert_file_contains "$TARGET_FILE" 'gamma'
assert_not_contains "$TARGET_FILE" 'alpha'
BLOCK_COUNT=$(grep -c '^# >>> kubuntu-migrate kitty >>>$' "$TARGET_FILE")
assert_equals "1" "$BLOCK_COUNT"

remove_managed_block "$TARGET_FILE" "kubuntu-migrate kitty"
assert_not_contains "$TARGET_FILE" '# >>> kubuntu-migrate kitty >>>'
assert_not_contains "$TARGET_FILE" '# <<< kubuntu-migrate kitty <<<'
assert_not_contains "$TARGET_FILE" 'gamma'
assert_file_contains "$TARGET_FILE" 'line-1'

NO_MARKER_FILE="$TMP_DIR/no-marker.conf"
cat > "$NO_MARKER_FILE" <<'FILE'
line-1
FILE
before=$(cat "$NO_MARKER_FILE")
remove_managed_block "$NO_MARKER_FILE" "kubuntu-migrate kitty"
assert_equals "$before" "$(cat "$NO_MARKER_FILE")"

START_ONLY_FILE="$TMP_DIR/only-start-marker.conf"
cat > "$START_ONLY_FILE" <<'FILE'
# >>> kubuntu-migrate kitty >>>
line-2
FILE
before=$(cat "$START_ONLY_FILE")
remove_managed_block "$START_ONLY_FILE" "kubuntu-migrate kitty"
assert_equals "$before" "$(cat "$START_ONLY_FILE")"

END_ONLY_FILE="$TMP_DIR/only-end-marker.conf"
cat > "$END_ONLY_FILE" <<'FILE'
# <<< kubuntu-migrate kitty <<<
line-3
FILE
before=$(cat "$END_ONLY_FILE")
remove_managed_block "$END_ONLY_FILE" "kubuntu-migrate kitty"
assert_equals "$before" "$(cat "$END_ONLY_FILE")"

END_BEFORE_START_FILE="$TMP_DIR/end-before-start.conf"
cat > "$END_BEFORE_START_FILE" <<'FILE'
# <<< kubuntu-migrate kitty <<<
line-4
# >>> kubuntu-migrate kitty >>>
line-5
FILE
before_end_before_start=$(cat "$END_BEFORE_START_FILE")
remove_managed_block "$END_BEFORE_START_FILE" "kubuntu-migrate kitty"
assert_equals "$before_end_before_start" "$(cat "$END_BEFORE_START_FILE")"

MULTI_START_FILE="$TMP_DIR/multi-start.conf"
cat > "$MULTI_START_FILE" <<'FILE'
# >>> kubuntu-migrate kitty >>>
line-6
# >>> kubuntu-migrate kitty >>>
line-7
# <<< kubuntu-migrate kitty <<<
line-8
FILE
before_multi_start=$(cat "$MULTI_START_FILE")
remove_managed_block "$MULTI_START_FILE" "kubuntu-migrate kitty"
assert_equals "$before_multi_start" "$(cat "$MULTI_START_FILE")"

assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'mdv'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'mdv()'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'mdstream'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'mdstream()'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'mdrun'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'mdrun()'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'atuin init'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'refreshapps'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.zsh" 'refreshapps()'
assert_file_exists "$ROOT_DIR/scripts/templates/shell/terminal-tools.bash"
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.bash" 'refreshapps'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.bash" 'mdrun'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/terminal-tools.bash" 'mdrun()'
assert_file_contains "$ROOT_DIR/scripts/lib/common.sh" 'tmux_restore|tmux restore for Konsole/Yakuake|off'
assert_file_contains "$ROOT_DIR/scripts/lib/common.sh" 'yakuake_snapshot|Yakuake snapshot tabs|off'
assert_file_contains "$ROOT_DIR/scripts/lib/common.sh" 'wezterm_tmux|WezTerm + tmux GUI tabs|off'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_tmux_restore()'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_tmux_restore_plugins'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_yakuake_snapshot()'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'YakuakeSnapshot.profile'
assert_file_contains "$ROOT_DIR/scripts/templates/konsole/YakuakeSnapshot.profile" 'Command=/home/meteor/DEV/script/bin/yakuake-snapshot-shell'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-shell" 'script -qef'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-shell" 'sessions_dir="$state_dir/sessions"'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-shell" 'current-instance'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-shell" 'previous-session'
assert_file_contains "$ROOT_DIR/scripts/templates/zsh/yakuake-snapshot.zsh" 'preexec'
assert_file_contains "$ROOT_DIR/scripts/templates/zsh/yakuake-snapshot.zsh" 'precmd'
assert_file_contains "$ROOT_DIR/scripts/templates/zsh/yakuake-snapshot.zsh" 'YAKUAKE_SNAPSHOT_TAB_ID'
assert_file_contains "$ROOT_DIR/scripts/templates/zsh/yakuake-snapshot.zsh" 'tmux attach-session -t meteor-tab-'
assert_file_contains "$ROOT_DIR/scripts/templates/zsh/yakuake-snapshot.zsh" 'ignored'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'org.kde.yakuake.addSession'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'runCommandInTerminal'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'tail -n'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'last_command'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'previous-session'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" '[[ "$source_session" != "$current_session" ]] || exit 0'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'tmux attach-session -t meteor-tab-'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'ignored'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'restored-sources'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'declare -A title_counts'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore" 'tabs_dir="$state_dir/tabs"'
assert_file_contains "$ROOT_DIR/scripts/templates/tmux/tmux.conf" 'tmux-resurrect'
assert_file_contains "$ROOT_DIR/scripts/templates/tmux/tmux.conf" 'tmux-continuum'
assert_file_contains "$ROOT_DIR/scripts/templates/tmux/tmux.conf" 'set -g mouse off'
assert_file_contains "$ROOT_DIR/scripts/templates/tmux/tmux.conf" 'set -g window-size latest'
assert_file_contains "$ROOT_DIR/scripts/templates/tmux/tmux.conf" "set -g @continuum-save-interval '1'"
assert_not_contains "$ROOT_DIR/scripts/templates/tmux/tmux.conf" 'client-detached'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/tmux-restore.zsh" 'meteor-tmux-auto'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/tmux-restore.zsh" 'NO_TMUX'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/tmux-restore.zsh" 'tsave()'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/tmux-restore.zsh" 'tmux-save-current'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/tmux-restore.zsh" 'yrestore()'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/tmux-restore.zsh" 'yakuake-tmux-restore-once'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'meteor-tab'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'tmux new-session -d'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'script_dir='
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" '/tmux-managed-sessions" add'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" '/tmux-session-title" set'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'exec tmux attach-session'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'tmux-save-current'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'server_was_running'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'wait_for_restored_session'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'yakuake-restore-tabs'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'YAKUAKE_RESTORE_EXCLUDE'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-auto" 'session_last_attached'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-managed-sessions" 'managed-sessions'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-managed-sessions" 'add)'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-managed-sessions" 'remove)'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-managed-sessions" 'prune)'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-session-title" 'tmux/titles'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-session-title" 'set)'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-session-title" 'get)'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-session-title" 'remove)'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-cleanup" 'meteor-tab-*'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/meteor-tmux-cleanup" 'scripts/save.sh'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-close-current" 'tmux-managed-sessions remove'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-close-current" 'tmux-session-title remove'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/tmux-save-current" 'scripts/save.sh'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-once" 'last-yakuake-restore'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-once" 'pgrep -u "$UID" -x yakuake'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-once" 'meteor-bootstrap'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-once" ':restored'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-once" 'import_unattached_managed_sessions'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-once" 'yakuake-restore-tabs'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-daemon" 'yakuake-tmux-restore-once'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-tmux-restore-daemon" 'sleep'
assert_file_contains "$ROOT_DIR/scripts/templates/autostart/yakuake-tmux-restore.desktop" 'Exec=/home/meteor/DEV/script/bin/yakuake-tmux-restore-daemon'
assert_file_contains "$ROOT_DIR/scripts/templates/autostart/yakuake-tmux-restore.desktop" 'X-KDE-autostart-after=panel'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'org.kde.yakuake.addSession'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'runCommandInTerminal'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'meteor-tab-'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'tmux-managed-sessions list'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'tmux-managed-sessions prune'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'tmux-session-title get'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'tab_title_for_session'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" '#{pane_current_path}'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" '#{session_name} #{session_attached} #{session_created}'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" '$2 == 0'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/yakuake-restore-tabs" 'YAKUAKE_RESTORE_EXCLUDE'
assert_file_contains "$ROOT_DIR/scripts/templates/konsole/TmuxRestore.profile" 'Command=/home/meteor/DEV/script/bin/meteor-tmux-auto'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'TmuxRestore.profile'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'tmux-managed-sessions'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'tmux-session-title'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'tmux-save-current'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'yakuake-tmux-restore-once'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'yakuake-tmux-restore-daemon'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'yakuake-tmux-restore.desktop'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'yakuake-restore-tabs'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_wezterm_tmux()'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_wezterm_tmux_templates'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'wezterm/wezterm.lua'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'tmux/wezterm.conf'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'bin/wezterm-tmux-tab'
assert_file_exists "$ROOT_DIR/scripts/install-wezterm-tmux.sh"
assert_file_contains "$ROOT_DIR/scripts/install-wezterm-tmux.sh" 'persist_selected_features "wezterm_tmux"'
assert_file_contains "$ROOT_DIR/scripts/install-wezterm-tmux.sh" 'install_wezterm_tmux'
assert_file_contains "$ROOT_DIR/scripts/install-wezterm-tmux.sh" '--dry-run'
assert_not_contains "$ROOT_DIR/scripts/install-wezterm-tmux.sh" 'step_12_terminal_tools'
assert_not_contains "$ROOT_DIR/scripts/install-wezterm-tmux.sh" 'install_tmux_restore'
assert_not_contains "$ROOT_DIR/scripts/install-wezterm-tmux.sh" 'install_yakuake_snapshot'
assert_not_contains "$ROOT_DIR/scripts/install-wezterm-tmux.sh" 'install_kitty_terminal'
assert_file_exists "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua"
assert_file_exists "$ROOT_DIR/scripts/templates/tmux/wezterm.conf"
assert_file_exists "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab"
assert_file_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'wezterm-tmux-tab'
assert_file_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'startup-list'
assert_file_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'format-tab-title'
assert_file_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'tab_tmux_sessions'
assert_file_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'tmux_session_name'
assert_file_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" "key = 't'"
assert_file_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" "mods = 'CTRL|SHIFT'"
assert_not_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'tmux_window_index'
assert_not_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'set_title'
assert_not_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'tab_title'
assert_not_contains "$ROOT_DIR/scripts/templates/wezterm/wezterm.lua" 'active_pane.title'
assert_file_contains "$ROOT_DIR/scripts/templates/tmux/wezterm.conf" '@resurrect-dir "$HOME/.local/state/wezterm-tmux/resurrect"'
assert_file_contains "$ROOT_DIR/scripts/templates/tmux/wezterm.conf" '@resurrect-hook-post-save-layout'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'tmux_socket="${WEZTERM_TMUX_SOCKET:-$HOME/.local/state/tmux-wezterm/main.sock}"'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'resurrect_dir="${WEZTERM_TMUX_RESURRECT_DIR:-$HOME/.local/state/wezterm-tmux/resurrect}"'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'startup-list'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'list-sessions'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'new-session'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'rename-session'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'attach-session'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'filter-resurrect'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'reload_config'
assert_file_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'session_attached'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'list-windows -t "$main_session"'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'new-window -t "$main_session"'
assert_not_contains "$ROOT_DIR/scripts/templates/bin/wezterm-tmux-tab" 'rename-window'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'kssh'
assert_file_contains "$ROOT_DIR/scripts/templates/shell/kitty.bash" 'kssh'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'mdv'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'mdv()'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'mdstream'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'mdstream()'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'mdrun'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'mdrun()'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'atuin init'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.zsh" 'refreshapps'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.bash" 'mdv'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.bash" 'mdstream'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.bash" 'mdrun'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.bash" 'atuin init'
assert_not_contains "$ROOT_DIR/scripts/templates/shell/kitty.bash" 'refreshapps'

SNAPSHOT_STATE="$TMP_DIR/snapshot-state"
SNAPSHOT_ROOT="$SNAPSHOT_STATE/yakuake-snapshot"
mkdir -p "$SNAPSHOT_ROOT/sessions/prev/tabs/001" "$SNAPSHOT_ROOT/sessions/prev/tabs/002" "$SNAPSHOT_ROOT/tabs/old-flat"
printf '%s\n' "prev" > "$SNAPSHOT_ROOT/previous-session"
printf '%s\n' "cur" > "$SNAPSHOT_ROOT/current-session"
printf '%s\n' "api" > "$SNAPSHOT_ROOT/sessions/prev/tabs/001/title"
printf '%s\n' "/tmp/prev-one" > "$SNAPSHOT_ROOT/sessions/prev/tabs/001/cwd"
printf '%s\n' "mvn spring-boot:run" > "$SNAPSHOT_ROOT/sessions/prev/tabs/001/last_command"
printf '%s\n' "prev-one-output" > "$SNAPSHOT_ROOT/sessions/prev/tabs/001/output.log"
printf '%s\n' "api" > "$SNAPSHOT_ROOT/sessions/prev/tabs/002/title"
printf '%s\n' "/tmp/prev-two" > "$SNAPSHOT_ROOT/sessions/prev/tabs/002/cwd"
printf '%s\n' "npm run dev" > "$SNAPSHOT_ROOT/sessions/prev/tabs/002/last_command"
printf '%s\n' "prev-two-output" > "$SNAPSHOT_ROOT/sessions/prev/tabs/002/output.log"
printf '%s\n' "garbage" > "$SNAPSHOT_ROOT/tabs/old-flat/title"

FAKE_QDBUS_DIR="$TMP_DIR/fake-qdbus"
mkdir -p "$FAKE_QDBUS_DIR"
cat > "$FAKE_QDBUS_DIR/qdbus6" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

case "${3:-}" in
  org.kde.yakuake.addSession)
    printf 'session-%s\n' "$RANDOM"
    ;;
  org.kde.yakuake.setTabTitle)
    printf 'TITLE=%s\n' "${5:-}" >> "${TEST_QDBUS_LOG:?}"
    ;;
  org.kde.yakuake.runCommandInTerminal)
    printf 'COMMAND=%s\n' "${5:-}" >> "${TEST_QDBUS_LOG:?}"
    ;;
esac
SCRIPT
chmod +x "$FAKE_QDBUS_DIR/qdbus6"

QDBUS_LOG="$TMP_DIR/qdbus.log"
(
  export PATH="$FAKE_QDBUS_DIR:$PATH"
  export XDG_STATE_HOME="$SNAPSHOT_STATE"
  export TEST_QDBUS_LOG="$QDBUS_LOG"
  bash "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore"
)

assert_file_contains "$QDBUS_LOG" 'TITLE=api'
assert_file_contains "$QDBUS_LOG" 'TITLE=api (2)'
assert_file_contains "$QDBUS_LOG" 'spring-boot:run'
assert_file_contains "$QDBUS_LOG" 'npm'
assert_file_contains "$QDBUS_LOG" 'dev'
assert_not_contains "$QDBUS_LOG" 'garbage'
assert_file_exists "$SNAPSHOT_ROOT/restored-sources/cur/prev"

QDBUS_LOG_BEFORE=$(cat "$QDBUS_LOG")
(
  export PATH="$FAKE_QDBUS_DIR:$PATH"
  export XDG_STATE_HOME="$SNAPSHOT_STATE"
  export TEST_QDBUS_LOG="$QDBUS_LOG"
  bash "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore"
)
assert_equals "$QDBUS_LOG_BEFORE" "$(cat "$QDBUS_LOG")"

SNAPSHOT_STATE_NO_PREV="$TMP_DIR/snapshot-state-no-prev"
SNAPSHOT_ROOT_NO_PREV="$SNAPSHOT_STATE_NO_PREV/yakuake-snapshot"
mkdir -p "$SNAPSHOT_ROOT_NO_PREV/sessions/cur/tabs/001"
printf '%s\n' "cur" > "$SNAPSHOT_ROOT_NO_PREV/current-session"
printf '%s\n' "self" > "$SNAPSHOT_ROOT_NO_PREV/sessions/cur/tabs/001/title"
printf '%s\n' "/tmp/self" > "$SNAPSHOT_ROOT_NO_PREV/sessions/cur/tabs/001/cwd"
printf '%s\n' "echo self" > "$SNAPSHOT_ROOT_NO_PREV/sessions/cur/tabs/001/last_command"
printf '%s\n' "self-output" > "$SNAPSHOT_ROOT_NO_PREV/sessions/cur/tabs/001/output.log"
QDBUS_SELF_LOG="$TMP_DIR/qdbus-self.log"
(
  export PATH="$FAKE_QDBUS_DIR:$PATH"
  export XDG_STATE_HOME="$SNAPSHOT_STATE_NO_PREV"
  export TEST_QDBUS_LOG="$QDBUS_SELF_LOG"
  bash "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore"
)
[ ! -e "$QDBUS_SELF_LOG" ] || fail "restore must not read current-session when previous-session is absent"

printf '%s\n' "cur" > "$SNAPSHOT_ROOT_NO_PREV/previous-session"
(
  export PATH="$FAKE_QDBUS_DIR:$PATH"
  export XDG_STATE_HOME="$SNAPSHOT_STATE_NO_PREV"
  export TEST_QDBUS_LOG="$QDBUS_SELF_LOG"
  bash "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore"
)
[ ! -e "$QDBUS_SELF_LOG" ] || fail "restore must not read current-session when previous-session equals current-session"

SNAPSHOT_STATE_TMUX="$TMP_DIR/snapshot-state-tmux"
SNAPSHOT_ROOT_TMUX="$SNAPSHOT_STATE_TMUX/yakuake-snapshot"
mkdir -p "$SNAPSHOT_ROOT_TMUX/sessions/prev/tabs/001" "$SNAPSHOT_ROOT_TMUX/sessions/cur/tabs"
printf '%s\n' "prev" > "$SNAPSHOT_ROOT_TMUX/previous-session"
printf '%s\n' "cur" > "$SNAPSHOT_ROOT_TMUX/current-session"
printf '%s\n' "meteor" > "$SNAPSHOT_ROOT_TMUX/sessions/prev/tabs/001/title"
printf '%s\n' "/home/meteor" > "$SNAPSHOT_ROOT_TMUX/sessions/prev/tabs/001/cwd"
printf '%s\n' "tmux attach-session -t meteor-tab-20260511-130843-54100" > "$SNAPSHOT_ROOT_TMUX/sessions/prev/tabs/001/last_command"
printf '%s\n' "tmux-output" > "$SNAPSHOT_ROOT_TMUX/sessions/prev/tabs/001/output.log"
QDBUS_TMUX_LOG="$TMP_DIR/qdbus-tmux.log"
(
  export PATH="$FAKE_QDBUS_DIR:$PATH"
  export XDG_STATE_HOME="$SNAPSHOT_STATE_TMUX"
  export TEST_QDBUS_LOG="$QDBUS_TMUX_LOG"
  bash "$ROOT_DIR/scripts/templates/bin/yakuake-snapshot-restore"
)
[ ! -e "$QDBUS_TMUX_LOG" ] || fail "restore must not restore legacy meteor-tab tmux sessions"

FAKE_BIN_DIR="$TMP_DIR/fake-bin"
mkdir -p "$FAKE_BIN_DIR"
cat > "$FAKE_BIN_DIR/wget" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE=${TEST_WGET_LOG:?}
OUT_FILE=""
URL=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -O)
      OUT_FILE=$2
      shift 2
      ;;
    -e)
      printf 'ARG=%s\n' "$2" >> "$LOG_FILE"
      shift 2
      ;;
    http://*|https://*)
      URL=$1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

printf 'URL=%s\n' "$URL" >> "$LOG_FILE"
[ -n "$OUT_FILE" ] && printf 'ok\n' > "$OUT_FILE"
SCRIPT
chmod +x "$FAKE_BIN_DIR/wget"

WGET_LOG="$TMP_DIR/wget.log"
(
  export PATH="$FAKE_BIN_DIR:$PATH"
  export TEST_WGET_LOG="$WGET_LOG"
  PROXY_PORT=7897
  DRY_RUN=0
  rm -f "$TMP_DIR/direct.bin" "$WGET_LOG"
  download_github_robust "https://github.com/example/project/releases/download/v1.0.0/example.tar.gz" "$TMP_DIR/direct.bin"
)

FIRST_URL=$(grep '^URL=' "$WGET_LOG" | head -n 1 | cut -d= -f2-)
assert_equals "https://github.com/example/project/releases/download/v1.0.0/example.tar.gz" "$FIRST_URL"
assert_not_contains "$ROOT_DIR/scripts/steps/07_shell.sh" "ghfast.top"
assert_file_contains "$ROOT_DIR/scripts/steps/07_shell.sh" 'download_github_robust'
assert_not_contains "$ROOT_DIR/scripts/steps/13_kitty.sh" "ghfast.top"
assert_not_contains "$ROOT_DIR/scripts/steps/13_kitty.sh" "kitty.app/bin/kitty"
assert_not_contains "$ROOT_DIR/scripts/steps/13_kitty.sh" "kitty.app/bin/kitten"

APP_DIR="$TMP_DIR/applications"
mkdir -p "$APP_DIR"
cat > "$APP_DIR/kitty.desktop" <<'FILE'
[Desktop Entry]
Type=Application
TryExec=kitty
Exec=kitty
Icon=kitty
FILE

cat > "$APP_DIR/kitty-open.desktop" <<'FILE'
[Desktop Entry]
Type=Application
TryExec=kitty
Exec=kitty +open %U
Icon=kitty
NoDisplay=true
FILE

rewrite_kitty_desktop_entries "$APP_DIR" "/tmp/kitty-prefix"
assert_file_contains "$APP_DIR/kitty.desktop" 'TryExec=/tmp/kitty-prefix/bin/kitty'
assert_file_contains "$APP_DIR/kitty.desktop" 'Exec=/tmp/kitty-prefix/bin/kitty'
assert_file_contains "$APP_DIR/kitty.desktop" 'Icon=/tmp/kitty-prefix/lib/kitty/logo/kitty.png'
assert_file_contains "$APP_DIR/kitty-open.desktop" 'TryExec=/tmp/kitty-prefix/bin/kitty'
assert_file_contains "$APP_DIR/kitty-open.desktop" 'Exec=/tmp/kitty-prefix/bin/kitten +open %U'
assert_file_contains "$APP_DIR/kitty-open.desktop" 'Icon=/tmp/kitty-prefix/lib/kitty/logo/kitty.png'

echo 'PASS: terminal common helpers'
