#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/12_terminal_tools.sh"

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

assert_tree_not_contains() {
  local path=$1
  local needle=$2
  if rg -q --fixed-strings "$needle" "$path"; then
    fail "expected [$path] tree to NOT contain: $needle"
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

upsert_managed_block "$TARGET_FILE" "kubuntu-migrate sample" $'alpha\nbeta'
assert_file_contains "$TARGET_FILE" '# >>> kubuntu-migrate sample >>>'
assert_file_contains "$TARGET_FILE" 'alpha'
assert_file_contains "$TARGET_FILE" 'beta'
assert_file_contains "$TARGET_FILE" '# <<< kubuntu-migrate sample <<<'

upsert_managed_block "$TARGET_FILE" "kubuntu-migrate sample" $'gamma'
assert_file_contains "$TARGET_FILE" 'gamma'
assert_not_contains "$TARGET_FILE" 'alpha'
BLOCK_COUNT=$(grep -c '^# >>> kubuntu-migrate sample >>>$' "$TARGET_FILE")
assert_equals "1" "$BLOCK_COUNT"

remove_managed_block "$TARGET_FILE" "kubuntu-migrate sample"
assert_not_contains "$TARGET_FILE" '# >>> kubuntu-migrate sample >>>'
assert_not_contains "$TARGET_FILE" '# <<< kubuntu-migrate sample <<<'
assert_not_contains "$TARGET_FILE" 'gamma'
assert_file_contains "$TARGET_FILE" 'line-1'

NO_MARKER_FILE="$TMP_DIR/no-marker.conf"
cat > "$NO_MARKER_FILE" <<'FILE'
line-1
FILE
before=$(cat "$NO_MARKER_FILE")
remove_managed_block "$NO_MARKER_FILE" "kubuntu-migrate sample"
assert_equals "$before" "$(cat "$NO_MARKER_FILE")"

START_ONLY_FILE="$TMP_DIR/only-start-marker.conf"
cat > "$START_ONLY_FILE" <<'FILE'
# >>> kubuntu-migrate sample >>>
line-2
FILE
before=$(cat "$START_ONLY_FILE")
remove_managed_block "$START_ONLY_FILE" "kubuntu-migrate sample"
assert_equals "$before" "$(cat "$START_ONLY_FILE")"

END_ONLY_FILE="$TMP_DIR/only-end-marker.conf"
cat > "$END_ONLY_FILE" <<'FILE'
# <<< kubuntu-migrate sample <<<
line-3
FILE
before=$(cat "$END_ONLY_FILE")
remove_managed_block "$END_ONLY_FILE" "kubuntu-migrate sample"
assert_equals "$before" "$(cat "$END_ONLY_FILE")"

END_BEFORE_START_FILE="$TMP_DIR/end-before-start.conf"
cat > "$END_BEFORE_START_FILE" <<'FILE'
# <<< kubuntu-migrate sample <<<
line-4
# >>> kubuntu-migrate sample >>>
line-5
FILE
before_end_before_start=$(cat "$END_BEFORE_START_FILE")
remove_managed_block "$END_BEFORE_START_FILE" "kubuntu-migrate sample"
assert_equals "$before_end_before_start" "$(cat "$END_BEFORE_START_FILE")"

MULTI_START_FILE="$TMP_DIR/multi-start.conf"
cat > "$MULTI_START_FILE" <<'FILE'
# >>> kubuntu-migrate sample >>>
line-6
# >>> kubuntu-migrate sample >>>
line-7
# <<< kubuntu-migrate sample <<<
line-8
FILE
before_multi_start=$(cat "$MULTI_START_FILE")
remove_managed_block "$MULTI_START_FILE" "kubuntu-migrate sample"
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
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'tmux_restore'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'yakuake_snapshot'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'antigravity_manager'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'miniconda'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'CONDA'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'REPO_TABBY'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'REPO_KITTY'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'KITTY_INSTALLER_URL'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'kitty_terminal'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'has_mt7922_wifi'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'is_nvidia_driver_available'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'nvidia_drm_modeset_enabled'
assert_not_contains "$ROOT_DIR/scripts/lib/common.sh" 'enable_nvidia_drm_modeset'
assert_file_contains "$ROOT_DIR/scripts/lib/common.sh" 'uv|uv Python package manager|on'
assert_file_contains "$ROOT_DIR/scripts/lib/common.sh" 'wezterm_tmux|WezTerm + tmux GUI tabs|off'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_wezterm_tmux_plugins'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_wezterm'
assert_file_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'wezterm'
assert_not_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_tmux_restore()'
assert_not_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_tmux_restore'
assert_not_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'install_yakuake_snapshot()'
assert_not_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'TmuxRestore.profile'
assert_not_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'YakuakeSnapshot.profile'
assert_not_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'yakuake'
assert_not_contains "$ROOT_DIR/scripts/steps/12_terminal_tools.sh" 'konsole'
assert_not_contains "$ROOT_DIR/scripts/steps/01_core.sh" 'yakuake'
assert_not_contains "$ROOT_DIR/scripts/steps/01_core.sh" 'plasma-workspace-wayland'
assert_not_contains "$ROOT_DIR/scripts/steps/01_core.sh" 'ubuntu-drivers autoinstall'
assert_not_contains "$ROOT_DIR/scripts/steps/01_core.sh" 'nvidia_drm'
assert_not_contains "$ROOT_DIR/scripts/steps/01_core.sh" 'modeset'
assert_file_contains "$ROOT_DIR/scripts/steps/01_core.sh" 'nvidia-driver-580-open'
assert_not_contains "$ROOT_DIR/scripts/steps/10_compose_services.sh" 'antigravity'
assert_not_contains "$ROOT_DIR/scripts/steps/10_compose_services.sh" 'AGM_'
assert_not_contains "$ROOT_DIR/scripts/steps/10_compose_services.sh" 'ENABLE_AGM'
assert_not_contains "$ROOT_DIR/scripts/steps/10_compose_services.sh" 'antigravity_tools'
assert_tree_not_contains "$ROOT_DIR/scripts/templates" 'yakuake'
assert_tree_not_contains "$ROOT_DIR/scripts/templates" 'konsole'
assert_tree_not_contains "$ROOT_DIR/scripts/templates" 'kitty'
assert_not_contains "$ROOT_DIR/scripts/run.sh" 'step_11_mt7922'
assert_not_contains "$ROOT_DIR/scripts/run.sh" 'steps/11_mt7922.sh'
assert_not_contains "$ROOT_DIR/scripts/run.sh" 'step_13_kitty'
assert_not_contains "$ROOT_DIR/scripts/run.sh" 'steps/13_kitty.sh'
assert_not_contains "$ROOT_DIR/scripts/steps/03_apps.sh" 'REPO_TABBY'
assert_not_contains "$ROOT_DIR/scripts/steps/03_apps.sh" 'tabby-terminal'
assert_not_contains "$ROOT_DIR/scripts/steps/04_dev.sh" 'miniconda'
assert_not_contains "$ROOT_DIR/scripts/steps/04_dev.sh" 'conda'
assert_file_contains "$ROOT_DIR/scripts/steps/04_dev.sh" 'install_uv'
assert_file_contains "$ROOT_DIR/scripts/steps/04_dev.sh" 'https://astral.sh/uv/install.sh'
assert_not_contains "$ROOT_DIR/scripts/steps/99_finish.sh" 'Wayland'
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

echo 'PASS: terminal common helpers'
