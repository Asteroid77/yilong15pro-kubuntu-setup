#!/bin/bash

step_10_compose_services() {
    log "10. 容器服务（Docker Compose）..."

    local ENABLE_XUNLEI=0

    is_feature_enabled "xunlei" && ENABLE_XUNLEI=1

    if [ "$ENABLE_XUNLEI" -eq 0 ]; then
        warn "未勾选迅雷，跳过"
        return 0
    fi

    if ! command -v docker >/dev/null 2>&1; then
        warn "未检测到 Docker，请先勾选 Docker 项或手动安装后重试"
        return 0
    fi

    local COMPOSE_DIR="$HOME/docker-settings"
    local COMPOSE_FILE="$COMPOSE_DIR/docker-compose-daily.yml"
    local ENV_FILE="$COMPOSE_DIR/.env.daily"
    local THUNDER_DIR="$HOME/thunder"

    local HOST_UID HOST_GID
    HOST_UID=$(id -u)
    HOST_GID=$(id -g)

    mkdir -p "$COMPOSE_DIR"
    if [ "$ENABLE_XUNLEI" -eq 1 ]; then
        mkdir -p "$THUNDER_DIR/downloads" "$THUNDER_DIR/data" "$THUNDER_DIR/cache"
        chown -R "$HOST_UID:$HOST_GID" "$THUNDER_DIR" 2>/dev/null || \
            sudo chown -R "$HOST_UID:$HOST_GID" "$THUNDER_DIR"
    fi

    write_file "$ENV_FILE" <<EOF
HOST_UID=$HOST_UID
HOST_GID=$HOST_GID
HOME_DIR=$HOME
EOF

    write_file "$COMPOSE_FILE" <<'EOF'
services:
EOF
    if [ "$ENABLE_XUNLEI" -eq 1 ]; then
        append_file "$COMPOSE_FILE" <<'EOF'
  xunlei:
    container_name: thunder
    image: cnk3x/xunlei:latest
    restart: unless-stopped
    hostname: r66s
    privileged: true
    ports:
      - "5055:2345/tcp"
    environment:
      XL_UID: ${HOST_UID}
      XL_GID: ${HOST_GID}
    volumes:
      - ${HOME_DIR}/thunder/downloads:/xunlei/downloads
      - ${HOME_DIR}/thunder/data:/xunlei/data
      - ${HOME_DIR}/thunder/cache:/xunlei/var/packages/pan-xunlei-com
EOF
    fi

    local -a COMPOSE_CMD=()
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD=(docker compose)
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD=(docker-compose)
    else
        warn "未检测到 docker compose/docker-compose，已生成文件但未启动容器"
        return 0
    fi

    compose_run() {
        if "${COMPOSE_CMD[@]}" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"; then
            return 0
        fi
        info "当前用户执行 compose 失败，尝试 sudo..."
        if [ "${COMPOSE_CMD[0]}" = "docker" ]; then
            sudo docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
        else
            sudo docker-compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
        fi
    }

    compose_run config >/dev/null
    local -a TARGET_SERVICES=()
    [ "$ENABLE_XUNLEI" -eq 1 ] && TARGET_SERVICES+=("xunlei")
    compose_run up -d "${TARGET_SERVICES[@]}"

    info "已部署服务：${TARGET_SERVICES[*]}"
    info "compose 文件：$COMPOSE_FILE"
}
