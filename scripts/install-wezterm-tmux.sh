#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/12_terminal_tools.sh"

usage() {
    cat <<'EOF'
用法: scripts/install-wezterm-tmux.sh [--dry-run|-n] [--help|-h]

说明:
  - 只安装 WezTerm + tmux GUI tabs 路线
  - 写入 ~/.wezterm.lua、~/.config/tmux/wezterm.conf、~/DEV/script/bin/wezterm-tmux-tab
  - 安装/更新 tmux-resurrect 与 tmux-continuum 插件
  - 不写入 ~/.tmux.conf，不读取全局 tmux resurrect 目录
EOF
}

for ARG in "$@"; do
    case "$ARG" in
        --dry-run|-n) DRY_RUN=1 ;;
        --help|-h) usage; exit 0 ;;
        *)
            error "未知参数: $ARG"
            usage
            exit 2
            ;;
    esac
done

if [ "$DRY_RUN" -eq 1 ]; then
    enable_dry_run_shims
fi

init_workdirs
persist_selected_features "wezterm_tmux"
install_wezterm_tmux
