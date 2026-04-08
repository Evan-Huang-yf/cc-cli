#!/usr/bin/env bash
# cc-cli 卸载脚本
# 支持 bash 和 zsh（Linux / macOS）

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_BIN="$HOME/.local/bin/cc"
BASH_COMPLETION="$HOME/.bash_completion.d/cc"
ZSH_COMPLETION="$HOME/.zsh_completion.d/_cc"
PROFILES_DIR="$HOME/.cc-profiles"

# 检测用户默认 shell
USER_SHELL=$(basename "${SHELL:-/bin/bash}")

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

# 2. 删除补全脚本（两种都检查）
if [ -f "$BASH_COMPLETION" ]; then
    rm "$BASH_COMPLETION"
    echo -e "  ${GREEN}✓${NC} 已删除 $BASH_COMPLETION"
fi

if [ -f "$ZSH_COMPLETION" ]; then
    rm "$ZSH_COMPLETION"
    echo -e "  ${GREEN}✓${NC} 已删除 $ZSH_COMPLETION"
fi

if [ ! -f "$BASH_COMPLETION" ] && [ ! -f "$ZSH_COMPLETION" ]; then
    echo -e "  ${YELLOW}○${NC} 补全脚本不存在，跳过"
fi

# 3. 提示清理 RC 文件
echo ""

# 检查两个 RC 文件
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ] && grep -qF "cc-cli" "$rcfile" 2>/dev/null; then
        echo -e "${YELLOW}请手动编辑 $(basename "$rcfile")，删除以下区块：${NC}"
        echo ""
        echo -e "  ${CYAN}# cc-cli: Claude Code 账号切换工具${NC}"
        echo -e "  ${CYAN}[ -f \"\$HOME/.cc-profiles/env.sh\" ] && source ...${NC}"
        echo -e "  ${CYAN}cc() { ... }${NC}"
        echo ""
        echo -e "  提示: 搜索 ${BOLD}cc-cli${NC} 关键字即可定位"
        echo ""
    fi
done

# 4. 询问是否删除数据目录
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
if [ "$USER_SHELL" = "zsh" ]; then
    echo -e "  请执行 ${BOLD}source ~/.zshrc${NC} 或重开终端使更改生效"
else
    echo -e "  请执行 ${BOLD}source ~/.bashrc${NC} 或重开终端使更改生效"
fi
echo ""
