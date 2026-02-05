#!/bin/bash

step_03_apps() {
    log "3. 常用软件..."
    if is_feature_enabled "goldendict"; then
        if ! is_pkg_installed "goldendict-ng"; then
            info "安装 GoldenDict-ng..."
            build_apt_proxy_args
            sudo apt update "${APT_PROXY_ARGS[@]}"
            sudo apt install -y goldendict-ng "${APT_PROXY_ARGS[@]}"
        else
            warn "GoldenDict-ng 已安装"
        fi
    else
        warn "未勾选 GoldenDict-ng，跳过"
    fi

    if is_feature_enabled "chrome"; then
        smart_install_deb "google-chrome-stable" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "chrome.deb"
    else
        warn "未勾选 Chrome，跳过"
    fi
    if is_feature_enabled "vscode"; then
        smart_install_deb "code" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" "vscode.deb"
    else
        warn "未勾选 VS Code，跳过"
    fi
    if is_feature_enabled "wechat"; then
        smart_install_deb "wechat" "https://dldir1.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb" "wechat.deb"
    else
        warn "未勾选 WeChat，跳过"
    fi
    if is_feature_enabled "dbeaver"; then
        smart_install_deb "dbeaver-ce" "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb" "dbeaver.deb"
    else
        warn "未勾选 DBeaver，跳过"
    fi

    if is_feature_enabled "wps"; then
        if ! is_pkg_installed "wps-office"; then
            info "安装 WPS Office..."
            WPS_URL=$(wps_latest_deb_url 2>/dev/null || true)
            if [ -n "$WPS_URL" ]; then
                smart_install_deb "wps-office" "$WPS_URL" "wps-office.deb"
            else
                warn "未抓取到 WPS 下载地址，跳过"
            fi
        else
            warn "WPS Office 已安装"
        fi
    else
        warn "未勾选 WPS，跳过"
    fi

    if is_feature_enabled "sublime_merge" && ! is_pkg_installed "sublime-merge"; then
        info "安装 Sublime Merge..."
        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
        echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        build_apt_proxy_args
        sudo apt update "${APT_PROXY_ARGS[@]}"
        sudo apt install -y sublime-merge "${APT_PROXY_ARGS[@]}"
    else
        is_feature_enabled "sublime_merge" && warn "Sublime Merge 已安装" || warn "未勾选 Sublime Merge，跳过"
    fi

    if is_feature_enabled "qq" && ! is_pkg_installed "linuxqq"; then
        [ -f "qq.deb" ] && ! check_deb_valid "qq.deb" && rm "qq.deb"
        if [ ! -f "qq.deb" ]; then
            QQ_URL=$(qq_latest_deb_url)
            if [ -n "$QQ_URL" ]; then
                smart_download "$QQ_URL" "qq.deb"
            else
                warn "未获取到最新 QQ 下载地址，跳过"
            fi
        fi
        [ -f "qq.deb" ] && smart_install_deb "linuxqq" "local_check" "qq.deb"
    else
        is_feature_enabled "qq" && warn "Linux QQ 已安装" || warn "未勾选 Linux QQ，跳过"
    fi

    install_github_smart() {
        local REPO=$1 PKG=$2
        local FILE
        FILE=$(basename "$REPO")
        if is_pkg_installed "$PKG"; then
            warn "$PKG 已安装"
            return
        fi
        local URL
        URL=$(github_latest_deb_url "$REPO")
        if [ -n "$URL" ]; then
            download_github_robust "$URL" "${FILE}.deb"
            smart_install_deb "$PKG" "github_robust" "${FILE}.deb"
        else
            warn "API 失败: $REPO"
        fi
    }
    install_github_smart "$REPO_TABBY" "tabby-terminal"
    install_github_smart "$REPO_MOTRIX" "motrix"
    install_github_smart "$REPO_RUSTDESK" "rustdesk"
}

