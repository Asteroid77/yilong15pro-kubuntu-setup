#!/bin/bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/lib/common.sh"

usage() {
    cat <<'EOF'
用法: ./init.sh [--dry-run|-n] [--no-interactive]

  --dry-run, -n            仅打印命令，不实际执行
  --no-interactive         不进入交互勾选（直接按默认：安装全部）
  --help, -h               显示帮助

说明:
  - 默认进入交互勾选，且默认全选
  - 交互勾选使用 whiptail（如未安装会自动安装）
  - 可选项列表见 scripts/lib/common.sh: select_install_features
EOF
}

for ARG in "$@"; do
    case "$ARG" in
        --dry-run|-n) DRY_RUN=1 ;;
        --select|--interactive) INTERACTIVE=1 ;;
        --no-interactive) INTERACTIVE=0 ;;
        --help|-h) usage; exit 0 ;;
    esac
done

if [ "$DRY_RUN" -eq 1 ]; then
    enable_dry_run_shims
fi

init_workdirs

if [ "$INTERACTIVE" -eq 1 ] && [ "$DRY_RUN" -eq 1 ]; then
    warn "DRY-RUN + --interactive：跳过交互选择（默认安装全部）"
    INTERACTIVE=0
fi

if [ "$INTERACTIVE" -eq 1 ]; then
    ensure_whiptail_installed
    select_install_features || exit $?
fi

# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/00_sources.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/01_core.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/02_clash.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/03_mpv.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/03_apps.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/04_dev.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/05_kvm.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/06_fonts.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/07_shell.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/08_typora.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/09_fcitx_rime.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/10_antigravity.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/11_mt7922.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/steps/99_finish.sh"

main() {
    step_00_sources
    step_01_core
    step_02_clash
    step_03_mpv
    step_03_apps
    step_04_dev
    step_05_kvm
    step_06_fonts
    step_07_shell
    step_08_typora
    step_09_fcitx_rime
    step_10_antigravity
    step_11_mt7922
    step_99_finish
}

main
