#!/usr/bin/env bash
# cc-cli 卸载脚本

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_BIN="$HOME/.local/bin/cc"
INSTALL_COMPLETION="$HOME/.bash_completion.d/cc"
PROFILES_DIR="$HOME/.cc-profiles"
BASHRC="$HOME/.bashrc"

echo -e "${BOLD}cc-cli 卸载程序${NC}"
echo -e "────────────────────────────"
echo ""

# 1. 删除可执行文件
if [ -f "$INSTALL_BIN" ]; then
    rm "$INSTALL_BIN"
    echo -e "  ${GREEN}✓${NC} 已删除 $INSTALL_BIN"
else
    echo -e "  ${YELLOW}○${NC} $INSTALL_BIN 不存在，跳过"
fi

# 2. 删除补全脚本
if [ -f "$INSTALL_COMPLETION" ]; then
    rm "$INSTALL_COMPLETION"
    echo -e "  ${GREEN}✓${NC} 已删除 $INSTALL_COMPLETION"
else
    echo -e "  ${YELLOW}○${NC} $INSTALL_COMPLETION 不存在，跳过"
fi

# 3. 提示清理 bashrc
echo ""
echo -e "${YELLOW}请手动编辑 ~/.bashrc，删除以下区块：${NC}"
echo ""
echo -e "  ${CYAN}# cc-cli: Claude Code 账号切换工具${NC}"
echo -e "  ${CYAN}[ -f \"\$HOME/.cc-profiles/env.sh\" ] && source ...${NC}"
echo -e "  ${CYAN}[ -f \"\$HOME/.bash_completion.d/cc\" ] && source ...${NC}"
echo -e "  ${CYAN}cc() { ... }${NC}"
echo ""
echo -e "  提示: 搜索 ${BOLD}cc-cli${NC} 关键字即可定位"

# 4. 询问是否删除数据目录
echo ""
if [ -d "$PROFILES_DIR" ]; then
    echo -ne "${YELLOW}是否删除配置数据目录 $PROFILES_DIR？(y/N): ${NC}"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        rm -rf "$PROFILES_DIR"
        echo -e "  ${GREEN}✓${NC} 已删除 $PROFILES_DIR"
    else
        echo -e "  ${YELLOW}○${NC} 保留 $PROFILES_DIR"
    fi
fi

# 5. 清理环境变量
unset ANTHROPIC_API_KEY 2>/dev/null || true
unset ANTHROPIC_BASE_URL 2>/dev/null || true

echo ""
echo -e "────────────────────────────"
echo -e "${GREEN}${BOLD}✓ cc-cli 卸载完成${NC}"
echo -e "  请执行 ${BOLD}source ~/.bashrc${NC} 或重开终端使更改生效"
echo ""
