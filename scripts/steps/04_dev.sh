#!/bin/bash

step_04_dev() {
    log "4. 开发环境..."
    if is_feature_enabled "docker" && ! command -v docker &>/dev/null; then
        info "安装 Docker..."
        curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
        sudo usermod -aG docker "$USER"
    else
        is_feature_enabled "docker" && warn "Docker 已安装" || warn "未勾选 Docker，跳过"
    fi
    if is_feature_enabled "docker"; then
        info "配置 Docker 镜像与代理..."
        sudo mkdir -p /etc/docker
        cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{ "registry-mirrors": ["${DOCKER_MIRRORS[0]}", "${DOCKER_MIRRORS[1]}"] }
EOF
        if [ -n "$PROXY_PORT" ]; then
            sudo mkdir -p /etc/systemd/system/docker.service.d
            cat <<EOF | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:$PROXY_PORT"
Environment="HTTPS_PROXY=http://127.0.0.1:$PROXY_PORT"
EOF
        fi
        sudo systemctl daemon-reload
        sudo systemctl restart docker
        if sudo docker ps -a --format '{{.Names}}' | grep -qx "portainer"; then
            warn "Portainer 容器已存在，跳过创建"
            if ! sudo docker ps --format '{{.Names}}' | grep -qx "portainer"; then
                info "尝试启动已存在的 Portainer 容器..."
                sudo docker start portainer || true
            fi
        else
            sudo docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce:latest || true
        fi
    fi

    if is_feature_enabled "java_maven" && ! (command -v java &>/dev/null && command -v mvn &>/dev/null); then
        info "安装 Java & Maven..."
        if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
            run_remote_bash_installer "https://get.sdkman.io" || true
        fi
        if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
            # shellcheck source=/dev/null
            source "$HOME/.sdkman/bin/sdkman-init.sh"
            sdk install java || true
            sdk install maven || true
            if [ ! -f "$HOME/.m2/settings.xml" ] || ! grep -q "aliyun" "$HOME/.m2/settings.xml"; then
                mkdir -p "$HOME/.m2"
                write_file "$HOME/.m2/settings.xml" << EOF
<settings><mirrors><mirror><id>aliyunmaven</id><mirrorOf>*</mirrorOf><name>Alibaba Cloud</name><url>${MAVEN_MIRROR}</url></mirror></mirrors></settings>
EOF
            fi
        fi
        if ! command -v java &>/dev/null; then
            error "SDKMan 失败，使用 APT"
            sudo apt install -y default-jdk maven
        fi
    else
        is_feature_enabled "java_maven" && warn "Java & Maven 已安装" || warn "未勾选 Java/Maven，跳过"
    fi

    if is_feature_enabled "node" && ! command -v node &>/dev/null; then
        info "安装 Node.js..."
        run_remote_bash_installer "https://fnm.vercel.app/install"
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env)"
        fnm install --lts
        npm config set registry "$NPM_MIRROR"
    else
        is_feature_enabled "node" && warn "Node.js 已安装" || warn "未勾选 Node.js，跳过"
    fi

    if is_feature_enabled "claude_codex" && command -v npm &>/dev/null; then
        if ! command -v claude &>/dev/null; then
            info "安装 Claude Code (npm global)..."
            npm install -g @anthropic-ai/claude-code 2>/dev/null || npm install -g @anthropic/claude-code 2>/dev/null || true
        else
            warn "Claude Code 已安装"
        fi
        if ! command -v codex &>/dev/null; then
            info "安装 Codex (npm global)..."
            npm install -g @openai/codex 2>/dev/null || true
        else
            warn "Codex 已安装"
        fi
    fi

    if is_feature_enabled "go" && ! command -v go &>/dev/null; then
        info "安装 Go (官方二进制包)..."
        GO_VERSION=$(go_latest_version)
        if [ -n "$GO_VERSION" ]; then
            GO_FILE="${GO_VERSION}.linux-amd64.tar.gz"
            GO_URL="${GO_MIRROR_BASE}/${GO_FILE}"
            GO_URL_OFFICIAL="https://go.dev/dl/${GO_FILE}"
            if smart_download "$GO_URL" "$GO_FILE" || smart_download "$GO_URL_OFFICIAL" "$GO_FILE"; then
                info "安装 Go 到 /usr/local/go..."
                sudo rm -rf /usr/local/go
                sudo tar -C /usr/local -xzf "$GO_FILE"
            else
                error "Go 下载失败"
            fi
        else
            warn "未获取到 Go 最新版本，跳过"
        fi
    else
        is_feature_enabled "go" && warn "Go 已安装" || warn "未勾选 Go，跳过"
    fi

    if is_feature_enabled "miniconda" && [ ! -d "$HOME/miniconda3" ]; then
        info "安装 Miniconda..."
        smart_download "$MINICONDA_INSTALLER" "miniconda.sh"
        bash miniconda.sh -b -p "$HOME/miniconda3"
        "$HOME/miniconda3/bin/conda" init bash zsh
        "$HOME/miniconda3/bin/conda" config --add channels "${CONDA_MIRROR_BASE}/pkgs/free/"
        "$HOME/miniconda3/bin/conda" config --set show_channel_urls yes
    else
        is_feature_enabled "miniconda" && warn "Miniconda 已安装" || warn "未勾选 Miniconda，跳过"
    fi
}

