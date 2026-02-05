#!/bin/bash

step_99_finish() {
    echo ""
    log "✅ 全部完成！"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    使用指南${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}【字体】${NC}"
    echo -e "  终端/IDE  → JetBrainsMono Nerd Font"
    echo -e "  系统 UI   → Inter"
    echo -e "  中文      → LXGW WenKai"
    echo ""
    echo -e "${BLUE}【薄荷输入法】${NC}"
    echo -e "  ${RED}★ 请注销或重启系统！${NC}"
    echo -e "  重启后：右键托盘键盘图标，选Rime，点「重新部署」"
    echo -e "  然后按 Ctrl+\` 切换方案 (薄荷拼音等)"
    echo ""
    echo -e "${BLUE}【Wayland】${NC}"
    echo -e "  ${RED}★ 请重启系统，并在登录界面选择 Plasma (Wayland) 会话${NC}"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
}

