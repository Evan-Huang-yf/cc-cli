#!/usr/bin/env bash
# cc-cli 一键安装脚本
# 项目地址: https://github.com/Evan-Huang-yf/cc-cli

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 安装路径
INSTALL_BIN="$HOME/.local/bin"
INSTALL_COMPLETION="$HOME/.bash_completion.d"
PROFILES_DIR="$HOME/.cc-profiles"
BASHRC="$HOME/.bashrc"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}cc-cli 安装程序${NC}"
echo -e "────────────────────────────"
echo ""

# ========== 1. 依赖检测 ==========
echo -e "${CYAN}[1/5] 检测依赖...${NC}"

check_dep() {
    local cmd="$1"
    local hint="$2"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
        return 0
    else
        echo -e "  ${RED}✗${NC} $cmd — $hint"
        return 1
    fi
}

deps_ok=true

# Bash 版本检测
bash_version="${BASH_VERSINFO[0]}"
if [ "$bash_version" -ge 4 ]; then
    echo -e "  ${GREEN}✓${NC} bash (版本 ${BASH_VERSION})"
else
    echo -e "  ${RED}✗${NC} bash (当前 ${BASH_VERSION}，需要 >= 4.0)"
    deps_ok=false
fi

check_dep "jq"   "安装: sudo apt install jq / brew install jq"   || deps_ok=false
check_dep "curl" "安装: sudo apt install curl / brew install curl" || deps_ok=false

# fzf 是可选依赖
if command -v fzf &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} fzf (可选，用于交互选择)"
else
    echo -e "  ${YELLOW}○${NC} fzf (可选，安装后 cc use 支持交互选择)"
fi

if [ "$deps_ok" = false ]; then
    echo ""
    echo -e "${RED}缺少必要依赖，请先安装后重试${NC}"
    exit 1
fi

echo ""

# ========== 2. 创建目录 ==========
echo -e "${CYAN}[2/5] 创建目录...${NC}"

mkdir -p "$INSTALL_BIN"
mkdir -p "$INSTALL_COMPLETION"
mkdir -p "$PROFILES_DIR"

echo -e "  ${GREEN}✓${NC} $INSTALL_BIN"
echo -e "  ${GREEN}✓${NC} $INSTALL_COMPLETION"
echo -e "  ${GREEN}✓${NC} $PROFILES_DIR"
echo ""

# ========== 3. 复制文件 ==========
echo -e "${CYAN}[3/5] 安装文件...${NC}"

# 检查源文件是否存在
if [ ! -f "$SCRIPT_DIR/cc" ]; then
    echo -e "  ${RED}✗${NC} 找不到 cc 脚本，请确认在项目目录下运行 install.sh"
    exit 1
fi

cp "$SCRIPT_DIR/cc" "$INSTALL_BIN/cc"
chmod +x "$INSTALL_BIN/cc"
echo -e "  ${GREEN}✓${NC} cc → $INSTALL_BIN/cc"

if [ -f "$SCRIPT_DIR/completions/cc.bash" ]; then
    cp "$SCRIPT_DIR/completions/cc.bash" "$INSTALL_COMPLETION/cc"
    echo -e "  ${GREEN}✓${NC} cc.bash → $INSTALL_COMPLETION/cc"
else
    echo -e "  ${YELLOW}○${NC} 补全脚本未找到，跳过"
fi

echo ""

# ========== 4. 配置 bashrc ==========
echo -e "${CYAN}[4/5] 配置 shell...${NC}"

# 检查 PATH 是否包含 ~/.local/bin
if [[ ":$PATH:" != *":$INSTALL_BIN:"* ]]; then
    echo -e "  ${YELLOW}⚠${NC} ~/.local/bin 不在 PATH 中"

    if ! grep -q 'export PATH=.*\.local/bin' "$BASHRC" 2>/dev/null; then
        echo '' >> "$BASHRC"
        echo '# cc-cli: 确保 ~/.local/bin 在 PATH 中' >> "$BASHRC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
        echo -e "  ${GREEN}✓${NC} 已添加 PATH 配置到 .bashrc"
    else
        echo -e "  ${GREEN}✓${NC} PATH 配置已存在"
    fi
fi

# 检查并添加 cc wrapper 函数
CC_MARKER="# cc-cli: Claude Code 账号切换工具"

if grep -qF "$CC_MARKER" "$BASHRC" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} cc wrapper 已存在于 .bashrc"
else
    cat >> "$BASHRC" << 'BASHRC_BLOCK'

# cc-cli: Claude Code 账号切换工具
[ -f "$HOME/.cc-profiles/env.sh" ] && source "$HOME/.cc-profiles/env.sh"
[ -f "$HOME/.bash_completion.d/cc" ] && source "$HOME/.bash_completion.d/cc"
cc() {
    command cc "$@"
    local ret=$?
    [ -f "$HOME/.cc-profiles/env.sh" ] && source "$HOME/.cc-profiles/env.sh"
    if [ "${1:-}" = "use" ] || [ "${1:-}" = "switch" ]; then
        claude
    fi
    return $ret
}
BASHRC_BLOCK
    echo -e "  ${GREEN}✓${NC} 已添加 cc wrapper 到 .bashrc"
fi

# 初始化 profiles.json
if [ ! -f "$PROFILES_DIR/profiles.json" ]; then
    echo '{"profiles":{},"active":""}' > "$PROFILES_DIR/profiles.json"
    echo -e "  ${GREEN}✓${NC} 已初始化 profiles.json"
else
    echo -e "  ${GREEN}✓${NC} profiles.json 已存在，保留现有数据"
fi

echo ""

# ========== 5. 完成 ==========
echo -e "${CYAN}[5/5] 安装完成！${NC}"
echo ""
echo -e "────────────────────────────"
echo -e "${GREEN}${BOLD}✓ cc-cli 安装成功${NC}"
echo ""
echo -e "下一步："
echo -e "  1. 执行以下命令使配置生效："
echo -e "     ${BOLD}source ~/.bashrc${NC}"
echo ""
echo -e "  2. 添加你的第一个 profile："
echo -e "     ${BOLD}cc add my-key --key sk-ant-api03-xxx${NC}"
echo ""
echo -e "  3. 查看帮助："
echo -e "     ${BOLD}cc help${NC}"
echo ""
