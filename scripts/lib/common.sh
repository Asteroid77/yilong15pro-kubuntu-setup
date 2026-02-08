#!/bin/bash
# shellcheck disable=SC2032,SC2033

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

readonly -a GITHUB_MIRRORS=(
    "https://ghfast.top/"
    "https://mirror.ghproxy.com/"
    "https://hub.gitmirror.com/"
    ""
)

readonly CACHE_DIR="$HOME/Downloads/kubuntu_master_cache"
readonly STATE_DIR="$CACHE_DIR/.state"
readonly PROXY_PORT_FILE="$STATE_DIR/proxy_port"
readonly SELECTED_FEATURES_FILE="$STATE_DIR/selected_features"
PROXY_PORT=""
APT_PROXY_ARGS=()
DRY_RUN=${DRY_RUN:-0}
INTERACTIVE=${INTERACTIVE:-1}
SELECTED_FEATURES_LIST=""
SELECTED_FEATURES_LIST_SET=0

readonly UBUNTU_MIRROR="mirrors.tuna.tsinghua.edu.cn"
readonly -a DOCKER_MIRRORS=("https://docker.m.daocloud.io" "https://dockerproxy.com")
readonly NPM_MIRROR="https://registry.npmmirror.com/"
readonly MAVEN_MIRROR="https://maven.aliyun.com/repository/public"
readonly CONDA_MIRROR_BASE="https://mirrors.tuna.tsinghua.edu.cn/anaconda"
readonly MINICONDA_INSTALLER="${CONDA_MIRROR_BASE}/miniconda/Miniconda3-latest-Linux-x86_64.sh"
readonly GITHUB_API_BASE="https://api.github.com"
readonly QQ_DOWNLOAD_PAGE="https://im.qq.com/linuxqq/index.shtml"
readonly GO_DL_JSON="https://go.dev/dl/?mode=json"
readonly GO_MIRROR_BASE="https://mirrors.aliyun.com/golang"
readonly FONT_DIR="$HOME/.local/share/fonts"

readonly REPO_CLASH_VERGE="clash-verge-rev/clash-verge-rev"
readonly REPO_NERD_FONTS="ryanoasis/nerd-fonts"
readonly REPO_INTER="rsms/inter"
readonly REPO_LXGW_WENKAI="lxgw/LxgwWenKai"
readonly REPO_TABBY="Eugeny/tabby"
readonly REPO_MOTRIX="agalwood/Motrix"
readonly REPO_RUSTDESK="rustdesk/rustdesk"
readonly REPO_ANTIGRAVITY_MANAGER="lbjlaq/Antigravity-Manager"
readonly REPO_OBSIDIAN="obsidianmd/obsidian-releases"

log() { echo -e "${GREEN}[DONE] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[SKIP] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
dry_echo() { [ "$DRY_RUN" -eq 1 ] && echo -e "${YELLOW}[DRYRUN] $*${NC}" >&2; }

enable_dry_run_shims() {
    info "DRY-RUN 模式：仅打印命令，不执行，不写入状态文件"
    # Drain stdin so pipelines like `... | sudo tee ...` won't block in dry-run.
    sudo() { dry_echo "sudo $*"; cat >/dev/null || true; return 0; }
    mkdir() { dry_echo "mkdir $*"; return 0; }
    rm() { dry_echo "rm $*"; return 0; }
    cp() { dry_echo "cp $*"; return 0; }
    mv() { dry_echo "mv $*"; return 0; }
    ln() { dry_echo "ln $*"; return 0; }
    tar() { dry_echo "tar $*"; return 0; }
    unzip() { dry_echo "unzip $*"; return 0; }
    systemctl() { dry_echo "systemctl $*"; return 0; }
    docker() { dry_echo "docker $*"; return 0; }
    usermod() { dry_echo "usermod $*"; return 0; }
    adduser() { dry_echo "adduser $*"; return 0; }
    chsh() { dry_echo "chsh $*"; return 0; }
    timedatectl() { dry_echo "timedatectl $*"; return 0; }
    fc-cache() { dry_echo "fc-cache $*"; return 0; }
    im-config() { dry_echo "im-config $*"; return 0; }
    bash() { dry_echo "bash $*"; return 0; }
    wget() { dry_echo "wget $*"; return 0; }
    curl() { dry_echo "curl $*"; return 0; }
    git() { dry_echo "git $*"; return 0; }
    gpg() { dry_echo "gpg $*"; cat >/dev/null || true; return 0; }
    tee() { dry_echo "tee $*"; cat >/dev/null; return 0; }
    touch() { dry_echo "touch $*"; return 0; }
    cd() { dry_echo "cd $*"; return 0; }
}

init_workdirs() {
    mkdir -p "$CACHE_DIR" "$STATE_DIR"
    cd "$CACHE_DIR"
}

# ========================= 代理函数 =========================

proxy_url() { echo "http://127.0.0.1:$PROXY_PORT"; }

check_proxy_port() { nc -z 127.0.0.1 "$1" 2>/dev/null; }

load_or_ask_proxy() {
    if [ "$DRY_RUN" -eq 1 ]; then
        warn "DRY-RUN: 跳过代理配置"
        return 0
    fi
    if [ -f "$PROXY_PORT_FILE" ]; then
        PROXY_PORT=$(cat "$PROXY_PORT_FILE")
        if check_proxy_port "$PROXY_PORT"; then
            info "使用已保存的代理端口: $PROXY_PORT"
            return 0
        fi
        rm -f "$PROXY_PORT_FILE"; PROXY_PORT=""
    fi

    echo ""
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  如需加速下载，请先开启本地代理（如 Clash）${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo ""

    while true; do
        read -r -p "请输入代理端口 (7890/7897/1087，回车跳过): " INPUT_PORT
        [ -z "$INPUT_PORT" ] && { warn "未配置代理"; PROXY_PORT=""; return 0; }
        [[ "$INPUT_PORT" =~ ^[0-9]+$ ]] || { error "请输入数字"; continue; }
        if check_proxy_port "$INPUT_PORT"; then
            PROXY_PORT="$INPUT_PORT"
            write_line "$PROXY_PORT_FILE" "$PROXY_PORT"
            log "代理端口 $PROXY_PORT 连接成功！"
            return 0
        else
            error "端口 $INPUT_PORT 无法连接"
        fi
    done
}

build_apt_proxy_args() {
    APT_PROXY_ARGS=()
    if [ -n "$PROXY_PORT" ]; then
        APT_PROXY_ARGS+=(
            "-o" "Acquire::http::Proxy=$(proxy_url)"
            "-o" "Acquire::https::Proxy=$(proxy_url)"
        )
    fi
}

curl_with_proxy() {
    local URL=$1
    local TIMEOUT=${2:-10}
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "curl_with_proxy $URL (timeout=$TIMEOUT)"
        case "$URL" in
            "${GITHUB_API_BASE}"/repos/*/releases/latest) echo '{"assets":[]}' ;;
            "$GO_DL_JSON") echo '[]' ;;
            "$QQ_DOWNLOAD_PAGE") echo '' ;;
            *) echo '' ;;
        esac
        return 0
    fi
    local -a OPTS=(-sSL --connect-timeout "$TIMEOUT")
    [ -n "$PROXY_PORT" ] && OPTS+=(--proxy "$(proxy_url)")
    curl "${OPTS[@]}" "$URL"
}

ensure_shell_proxy_helpers() {
    local LOCAL_BIN="$HOME/.local/bin"
    local STATE_FILE="$HOME/Downloads/kubuntu_master_cache/.state/proxy_port"
    local MARKER="# >>> kubuntu-migrate proxy helpers >>>"

    mkdir -p "$LOCAL_BIN"

    if [ ! -f "$LOCAL_BIN/proxy_on" ]; then
        write_file "$LOCAL_BIN/proxy_on" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
STATE_FILE="$HOME/Downloads/kubuntu_master_cache/.state/proxy_port"
PORT="${1:-}"
if [ -z "$PORT" ] && [ -r "$STATE_FILE" ]; then
  PORT="$(cat "$STATE_FILE" 2>/dev/null || true)"
fi
if [ -z "$PORT" ]; then
  echo "用法：source proxy_on <port>    或    eval \"$(proxy_on <port>)\"" >&2
  exit 1
fi
PROXY="http://127.0.0.1:${PORT}"
cat <<EOT
export http_proxy="${PROXY}"
export https_proxy="${PROXY}"
export all_proxy="${PROXY}"
export HTTP_PROXY="${PROXY}"
export HTTPS_PROXY="${PROXY}"
export ALL_PROXY="${PROXY}"
export no_proxy="localhost,127.0.0.1,::1"
export NO_PROXY="localhost,127.0.0.1,::1"
EOT
EOF
        chmod +x "$LOCAL_BIN/proxy_on" 2>/dev/null || true
    fi

    if [ ! -f "$LOCAL_BIN/proxy_off" ]; then
        write_file "$LOCAL_BIN/proxy_off" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat <<'EOT'
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
unset no_proxy NO_PROXY
EOT
EOF
        chmod +x "$LOCAL_BIN/proxy_off" 2>/dev/null || true
    fi

    append_if_missing "$HOME/.zshrc" "export PATH=\"\$HOME/.local/bin:\$PATH\""
    append_if_missing "$HOME/.bashrc" "export PATH=\"\$HOME/.local/bin:\$PATH\""

    if [ ! -f "$HOME/.zshrc" ] || ! grep -qF "$MARKER" "$HOME/.zshrc" 2>/dev/null; then
        append_file "$HOME/.zshrc" <<EOF

$MARKER
proxy_on() {
  local port="\${1:-}"
  local state_file="$STATE_FILE"
  if [ -z "\$port" ] && [ -r "\$state_file" ]; then
    port="\$(cat "\$state_file" 2>/dev/null || true)"
  fi
  if [ -z "\$port" ]; then
    echo "用法：proxy_on <port>（或先运行迁移脚本保存端口）" >&2
    return 1
  fi
  local proxy="http://127.0.0.1:\${port}"
  export http_proxy="\$proxy" https_proxy="\$proxy" all_proxy="\$proxy"
  export HTTP_PROXY="\$proxy" HTTPS_PROXY="\$proxy" ALL_PROXY="\$proxy"
  export no_proxy="localhost,127.0.0.1,::1"
  export NO_PROXY="\$no_proxy"
  echo "Proxy ON: \$proxy"
}
proxy_off() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
  unset no_proxy NO_PROXY
  echo "Proxy OFF"
}
# <<< kubuntu-migrate proxy helpers <<<
EOF
    fi

    if [ ! -f "$HOME/.bashrc" ] || ! grep -qF "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
        append_file "$HOME/.bashrc" <<EOF

$MARKER
proxy_on() {
  local port="\${1:-}"
  local state_file="$STATE_FILE"
  if [ -z "\$port" ] && [ -r "\$state_file" ]; then
    port="\$(cat "\$state_file" 2>/dev/null || true)"
  fi
  if [ -z "\$port" ]; then
    echo "用法：proxy_on <port>（或先运行迁移脚本保存端口）" >&2
    return 1
  fi
  local proxy="http://127.0.0.1:\${port}"
  export http_proxy="\$proxy" https_proxy="\$proxy" all_proxy="\$proxy"
  export HTTP_PROXY="\$proxy" HTTPS_PROXY="\$proxy" ALL_PROXY="\$proxy"
  export no_proxy="localhost,127.0.0.1,::1"
  export NO_PROXY="\$no_proxy"
  echo "Proxy ON: \$proxy"
}
proxy_off() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
  unset no_proxy NO_PROXY
  echo "Proxy OFF"
}
# <<< kubuntu-migrate proxy helpers <<<
EOF
    fi
}

with_proxy_env() {
    if [ -n "$PROXY_PORT" ]; then
        http_proxy="$(proxy_url)" https_proxy="$(proxy_url)" "$@"
    else
        "$@"
    fi
}

run_remote_bash_installer() {
    local URL=$1
    with_proxy_env bash -c "curl -fsSL \"\$1\" | bash" _ "$URL"
}

github_latest_asset_url() {
    local REPO=$1 NAME_REGEX=$2
    curl_with_proxy "${GITHUB_API_BASE}/repos/${REPO}/releases/latest" 10 | \
        jq -r --arg re "$NAME_REGEX" '.assets[]? | select(.name | test($re)) | .browser_download_url' | head -n 1
}

github_latest_deb_url() {
    local REPO=$1
    github_latest_asset_url "$REPO" '.*(amd64|x64|x86_64).*\.deb$'
}

go_latest_version() {
    curl_with_proxy "$GO_DL_JSON" 8 | jq -r '.[] | select(.stable==true) | .version' | head -n 1
}

qq_latest_deb_url() {
    curl_with_proxy "$QQ_DOWNLOAD_PAGE" 8 | grep -o 'https://[^"]*qq\.com/[^"]*QQ_[^"]*amd64[^"]*\.deb' | head -n 1
}

wps_latest_deb_url() {
    local HTML
    HTML=$(curl_with_proxy "https://linux.wps.cn/wpslinuxlog" 10) || return 1

    echo "$HTML" | \
        grep -oE "https://wps-linux-personal\\.wpscdn\\.cn/wps/download/ep/Linux2023/[0-9]+/wps-office_12\\.1\\.2\\.[0-9]+\\.[^']*amd64\\.deb" | \
        awk -F'/' '{build=$(NF-1); print build "\t" $0}' | \
        sort -n | tail -n 1 | cut -f2
}

# ========================= 通用函数 =========================

has_mt7922_wifi() {
    command -v lspci &>/dev/null || return 1
    lspci -nn 2>/dev/null | grep -Eiq '(mt7922|7922|14c3:0616|14c3:0626)'
}

ensure_grub_cmdline_linux_default() {
    local DESIRED=$1
    local GRUB_FILE="/etc/default/grub"

    if [ ! -f "$GRUB_FILE" ]; then
        warn "未找到 $GRUB_FILE，跳过 GRUB 配置"
        return 0
    fi

    local TARGET_LINE="GRUB_CMDLINE_LINUX_DEFAULT='${DESIRED}'"
    if grep -qF "$TARGET_LINE" "$GRUB_FILE"; then
        info "GRUB_CMDLINE_LINUX_DEFAULT 已是目标值"
        return 0
    fi

    info "写入 GRUB_CMDLINE_LINUX_DEFAULT（并备份 grub）..."
    sudo cp "$GRUB_FILE" "${GRUB_FILE}.bak.$(date +%Y%m%d-%H%M%S)"

    if grep -qE '^[[:space:]]*GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE"; then
        sudo sed -i "s|^[[:space:]]*GRUB_CMDLINE_LINUX_DEFAULT=.*|${TARGET_LINE}|" "$GRUB_FILE"
    else
        echo "$TARGET_LINE" | sudo tee -a "$GRUB_FILE" >/dev/null
    fi

    if command -v update-grub &>/dev/null; then
        sudo update-grub
        info "GRUB 已更新（建议重启生效）"
    else
        warn "未找到 update-grub，请手动执行 update-grub 并重启"
    fi
}

is_nvidia_driver_available() {
    command -v modinfo &>/dev/null || return 1
    modinfo nvidia_drm &>/dev/null
}

nvidia_drm_modeset_enabled() {
    local PATH_MODESET="/sys/module/nvidia_drm/parameters/modeset"
    [ -r "$PATH_MODESET" ] || return 1
    local VALUE
    VALUE=$(cat "$PATH_MODESET" 2>/dev/null || true)
    [ "$VALUE" = "Y" ] || [ "$VALUE" = "1" ]
}

is_graphical_session() {
    [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || \
    [ "${XDG_SESSION_TYPE:-}" = "x11" ] || \
    [ -n "${WAYLAND_DISPLAY:-}" ] || \
    [ -n "${DISPLAY:-}" ]
}

run_if_graphical() {
    if [ "$#" -eq 0 ]; then
        error "run_if_graphical: 未提供要执行的命令"
        return 1
    fi

    if ! is_graphical_session; then
        info "当前非图形会话，跳过执行: $1"
        return 0
    fi

    "$@"
}

restart_fcitx5_process() {
    if command -v kquitapp5 >/dev/null 2>&1; then
        kquitapp5 fcitx5 >/dev/null 2>&1 || pkill -x fcitx5 >/dev/null 2>&1 || true
    else
        pkill -x fcitx5 >/dev/null 2>&1 || true
    fi
    fcitx5 -d >/dev/null 2>&1 || true
}

restart_fcitx5_if_graphical() {
    if ! command -v fcitx5 >/dev/null 2>&1; then
        return 0
    fi

    run_if_graphical restart_fcitx5_process
}

enable_nvidia_drm_modeset() {
    local CONF="/etc/modprobe.d/nvidia-drm-modeset.conf"
    local LINE="options nvidia-drm modeset=1"
    info "写入: $CONF"
    echo "$LINE" | sudo tee "$CONF" > /dev/null
    if command -v update-initramfs &>/dev/null; then
        info "更新 initramfs..."
        sudo update-initramfs -u
    fi
}

rewrite_keep_only_xmodifiers() {
    local TARGET=$1
    local MODE=$2
    local DESIRED_LINE=""
    local MATCH_RE=""
    case "$MODE" in
        etc_environment)
            DESIRED_LINE="XMODIFIERS=@im=fcitx"
            MATCH_RE='^[[:space:]]*XMODIFIERS='
            ;;
        xprofile)
            DESIRED_LINE="export XMODIFIERS=@im=fcitx"
            MATCH_RE='^[[:space:]]*(export[[:space:]]+)?XMODIFIERS='
            ;;
        pam_environment)
            DESIRED_LINE="XMODIFIERS DEFAULT=@im=fcitx"
            MATCH_RE='^[[:space:]]*XMODIFIERS([[:space:]]+DEFAULT=|=)'
            ;;
        *)
            error "rewrite_keep_only_xmodifiers: 未知模式 $MODE"
            return 1
            ;;
    esac

    local TMP="$STATE_DIR/$(basename "$TARGET").xmodifiers.tmp"
    local FOUND=0
    : > "$TMP"

    if [ -f "$TARGET" ]; then
        local BACKUP="${TARGET}.bak"
        if [[ "$TARGET" == /etc/* ]]; then
            sudo cp -a "$TARGET" "$BACKUP" 2>/dev/null || true
        else
            cp -a "$TARGET" "$BACKUP" 2>/dev/null || true
        fi
    fi

    if [ -f "$TARGET" ]; then
        while IFS= read -r LINE || [ -n "$LINE" ]; do
            if [[ "$LINE" =~ ^[[:space:]]*# ]]; then
                echo "$LINE" >> "$TMP"
                continue
            fi
            if [ -z "${LINE//[[:space:]]/}" ]; then
                echo "" >> "$TMP"
                continue
            fi
            if [[ "$LINE" =~ $MATCH_RE ]]; then
                if [ "$FOUND" -eq 0 ]; then
                    echo "$DESIRED_LINE" >> "$TMP"
                    FOUND=1
                else
                    echo "# $LINE" >> "$TMP"
                fi
                continue
            fi
            echo "# $LINE" >> "$TMP"
        done < "$TARGET"
    fi

    if [ "$FOUND" -eq 0 ]; then
        [ -s "$TMP" ] && echo "" >> "$TMP"
        echo "$DESIRED_LINE" >> "$TMP"
    fi

    if [[ "$TARGET" == /etc/* ]]; then
        sudo cp -f "$TMP" "$TARGET"
    else
        cp -f "$TMP" "$TARGET"
    fi
}

check_deb_valid() {
    [ -f "$1" ] || return 1
    local size_kb
    size_kb=$(du -k "$1" | cut -f1)
    [ "$size_kb" -ge 10 ] || return 1
    dpkg-deb -I "$1" &>/dev/null
}
is_pkg_installed() { dpkg -s "$1" &>/dev/null; }
is_step_done() { [ -f "$STATE_DIR/$1" ]; }
mark_step_done() { touch "$STATE_DIR/$1"; }
write_file() {
    local PATH_TARGET=$1
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "write file: $PATH_TARGET"
        cat >/dev/null
        return 0
    fi
    cat > "$PATH_TARGET"
}

append_file() {
    local PATH_TARGET=$1
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "append file: $PATH_TARGET"
        cat >/dev/null
        return 0
    fi
    cat >> "$PATH_TARGET"
}

write_line() {
    local PATH_TARGET=$1
    local CONTENT=$2
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "write line: $PATH_TARGET -> $CONTENT"
        return 0
    fi
    echo "$CONTENT" > "$PATH_TARGET"
}

append_line() {
    local PATH_TARGET=$1
    local CONTENT=$2
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "append line: $PATH_TARGET -> $CONTENT"
        return 0
    fi
    echo "$CONTENT" >> "$PATH_TARGET"
}

append_if_missing() {
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "append_if_missing: $1 -> $2"
        return 0
    fi
    [ -f "$1" ] || touch "$1"
    grep -qF "$2" "$1" || append_line "$1" "$2"
}

# ========================= 安装项选择 =========================

is_feature_enabled() {
    local ID=$1
    [ "$INTERACTIVE" -eq 0 ] && return 0

    if [ "$SELECTED_FEATURES_LIST_SET" -eq 1 ]; then
        [[ " $SELECTED_FEATURES_LIST " == *" $ID "* ]]
        return $?
    fi

    [ -f "$SELECTED_FEATURES_FILE" ] || return 0
    grep -qw "$ID" "$SELECTED_FEATURES_FILE"
}

persist_selected_features() {
    local VALUE=$1
    SELECTED_FEATURES_LIST="$VALUE"
    SELECTED_FEATURES_LIST_SET=1
    [ "$DRY_RUN" -eq 1 ] && return 0
    write_line "$SELECTED_FEATURES_FILE" "$VALUE"
}

reset_selected_features_to_all() {
    SELECTED_FEATURES_LIST=""
    SELECTED_FEATURES_LIST_SET=0
    [ "$DRY_RUN" -eq 1 ] && return 0
    rm -f "$SELECTED_FEATURES_FILE" 2>/dev/null || true
}

select_install_features() {
    local -a FEATURES=(
        "mpv_uosc_thumbfast|MPV + uosc + thumbfast|on"
        "clash_verge|Clash Verge (代理 GUI)|on"
        "goldendict|GoldenDict-ng|on"
        "chrome|Google Chrome|on"
        "vscode|Visual Studio Code|on"
        "wechat|WeChat|on"
        "dbeaver|DBeaver CE|on"
        "wps|WPS Office|on"
        "sublime_merge|Sublime Merge|on"
        "qq|Linux QQ|on"
        "docker|Docker + Portainer|on"
        "java_maven|Java + Maven (SDKMan/apt)|on"
        "node|Node.js LTS (fnm)|on"
        "claude_codex|Claude Code + Codex (npm -g)|on"
        "go|Go (官方二进制包)|on"
        "miniconda|Miniconda|on"
        "obsidian|Obsidian|on"
        "antigravity|Antigravity + Antigravity-Manager|on"
    )

    echo ""
    echo -e "${BLUE}[INFO] 交互模式：请选择需要安装的软件项${NC}"

    local RESULT=""
    if command -v whiptail &>/dev/null; then
        local -a ARGS=()
        local ITEM
        for ITEM in "${FEATURES[@]}"; do
            IFS="|" read -r ID DESC DEF <<< "$ITEM"
            ARGS+=("$ID" "$DESC" "$DEF")
        done
        RESULT=$(whiptail --title "Kubuntu Migrate" --checklist "选择安装项（空格勾选，回车确认）" 20 86 12 "${ARGS[@]}" 3>&1 1>&2 2>&3) || {
            warn "已取消选择（Cancel/Esc）：退出脚本，不执行安装"
            return 130
        }
        RESULT=${RESULT//\"/}
    else
        warn "未检测到 whiptail：使用文本选择模式"
        local -a IDS=()
        local INDEX=1
        local ITEM
        for ITEM in "${FEATURES[@]}"; do
            IFS="|" read -r ID DESC DEF <<< "$ITEM"
            printf "  [%02d] %-14s %s (默认:%s)\n" "$INDEX" "$ID" "$DESC" "$DEF"
            IDS+=("$ID")
            INDEX=$((INDEX+1))
        done
        echo ""
        echo "输入编号（空格分隔），或输入 all / none，回车确认："
        read -r INPUT || true
        case "${INPUT,,}" in
            all|"")
                reset_selected_features_to_all
                return 0
                ;;
            none)
                persist_selected_features ""
                return 0
                ;;
        esac
        local -a OUT=()
        local TOKEN
        for TOKEN in $INPUT; do
            [[ "$TOKEN" =~ ^[0-9]+$ ]] || continue
            local POS=$((TOKEN-1))
            [ "$POS" -ge 0 ] && [ "$POS" -lt "${#IDS[@]}" ] && OUT+=("${IDS[$POS]}")
        done
        RESULT="${OUT[*]}"
    fi

    if [[ " $RESULT " == *" claude_codex "* ]] && [[ " $RESULT " != *" node "* ]]; then
        info "已选择 claude_codex：自动启用 node"
        RESULT="node $RESULT"
    fi

    persist_selected_features "$RESULT"
}

ensure_whiptail_installed() {
    command -v whiptail &>/dev/null && return 0
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "sudo apt update && sudo apt install -y whiptail"
        return 0
    fi
    info "安装 whiptail（用于交互打钩界面）..."
    sudo apt update
    sudo apt install -y whiptail
}

smart_download() {
    local URL=$1 FILENAME=$2
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "download: $URL -> $FILENAME"
        return 0
    fi
    [ -f "$FILENAME" ] && [ -s "$FILENAME" ] && { info "已存在: $FILENAME"; return 0; }
    [ -f "$FILENAME" ] && rm -f "$FILENAME"
    info "下载: $FILENAME"
    wget -c --inet4-only --show-progress --tries=3 --timeout=15 -O "$FILENAME" "$URL"
}

download_github_robust() {
    local URL=$1 FILENAME=$2
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "download (github): $URL -> $FILENAME"
        return 0
    fi
    [ -f "$FILENAME" ] && [ -s "$FILENAME" ] && { info "已存在: $FILENAME"; return 0; }
    [ -f "$FILENAME" ] && rm -f "$FILENAME"

    info "下载: $FILENAME"
    local SUCCESS=0
    for PROXY in "${GITHUB_MIRRORS[@]}"; do
        echo -ne "${BLUE}  -> ${PROXY:-"直连"} ... ${NC}"
        if wget -q --inet4-only --no-check-certificate --tries=1 --timeout=10 -O "$FILENAME" "${PROXY}${URL}" && [ -s "$FILENAME" ]; then
            echo -e "${GREEN}成功${NC}"; SUCCESS=1; break
        else
            echo -e "${YELLOW}失败${NC}"; rm -f "$FILENAME"
        fi
    done

    if [ $SUCCESS -eq 0 ] && [ -n "$PROXY_PORT" ]; then
        echo -ne "${BLUE}  -> 本地代理... ${NC}"
        if wget -q --inet4-only --tries=2 --timeout=20 -e use_proxy=yes \
            -e http_proxy="http://127.0.0.1:$PROXY_PORT" -e https_proxy="http://127.0.0.1:$PROXY_PORT" \
            -O "$FILENAME" "$URL" && [ -s "$FILENAME" ]; then
            echo -e "${GREEN}成功${NC}"; SUCCESS=1
        fi
    fi

    [ $SUCCESS -eq 0 ] && { error "下载失败: $FILENAME"; return 1; }
    return 0
}

smart_install_deb() {
    local PKG=$1
    local URL=$2
    local FILE=${3:-"${PKG}.deb"}
    if [ "$DRY_RUN" -eq 1 ]; then
        dry_echo "install deb: $PKG ($FILE)"
        return 0
    fi
    is_pkg_installed "$PKG" && { warn "已安装 $PKG"; return; }
    [[ "$URL" != "github_robust" && "$URL" != "local_check" ]] && smart_download "$URL" "$FILE"
    if check_deb_valid "$FILE"; then
        info "安装 $PKG..."
        sudo apt install -y "./$FILE"
    else
        error "包损坏: $FILE"
    fi
}
