#!/usr/bin/env bash
# cc-cli 一键安装脚本
# 项目地址: https://github.com/Evan-Huang-yf/cc-cli
# 支持 bash 和 zsh（Linux / macOS）

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
PROFILES_DIR="$HOME/.cc-profiles"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 解析命令行参数
FORCE_SHELL=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --shell)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}错误: --shell 需要指定 bash 或 zsh${NC}"
                exit 1
            fi
            if [[ "$2" != "bash" && "$2" != "zsh" ]]; then
                echo -e "${RED}错误: --shell 只支持 bash 或 zsh，收到: $2${NC}"
                exit 1
            fi
            FORCE_SHELL="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: bash install.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --shell bash|zsh  强制指定目标 shell（默认自动检测）"
            echo "  -h, --help        显示帮助信息"
            exit 0
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            echo "用法: bash install.sh [--shell bash|zsh]"
            exit 1
            ;;
    esac
done

# 检测用户默认 shell（可通过 --shell 覆盖）
detect_shell() {
    local user_shell
    user_shell=$(basename "${SHELL:-/bin/bash}")
    echo "$user_shell"
}

if [[ -n "$FORCE_SHELL" ]]; then
    USER_SHELL="$FORCE_SHELL"
else
    USER_SHELL=$(detect_shell)
fi

echo -e "${BOLD}cc-cli 安装程序${NC}"
echo -e "────────────────────────────"
if [[ -n "$FORCE_SHELL" ]]; then
    echo -e "  目标 shell: ${CYAN}${USER_SHELL}${NC} (通过 --shell 指定)"
else
    echo -e "  检测到 shell: ${CYAN}${USER_SHELL}${NC}"
fi
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

# Bash 版本检测（cc 脚本需要 bash >= 4.0 来执行）
if command -v bash &>/dev/null; then
    bash_version=$(bash -c 'echo ${BASH_VERSINFO[0]}')
    bash_full=$(bash -c 'echo ${BASH_VERSION}')
    if [ "$bash_version" -ge 4 ]; then
        echo -e "  ${GREEN}✓${NC} bash (版本 ${bash_full})"
    else
        echo -e "  ${RED}✗${NC} bash (当前 ${bash_full}，需要 >= 4.0)"
        if [[ "$OSTYPE" == darwin* ]]; then
            echo -e "      ${YELLOW}macOS 自带 bash 版本过低，请执行: brew install bash${NC}"
        fi
        deps_ok=false
    fi
else
    echo -e "  ${RED}✗${NC} bash 未安装"
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
mkdir -p "$PROFILES_DIR"

echo -e "  ${GREEN}✓${NC} $INSTALL_BIN"
echo -e "  ${GREEN}✓${NC} $PROFILES_DIR"

# 根据 shell 类型创建补全目录
if [ "$USER_SHELL" = "zsh" ]; then
    INSTALL_COMPLETION="$HOME/.zsh_completion.d"
    mkdir -p "$INSTALL_COMPLETION"
    echo -e "  ${GREEN}✓${NC} $INSTALL_COMPLETION"
else
    INSTALL_COMPLETION="$HOME/.bash_completion.d"
    mkdir -p "$INSTALL_COMPLETION"
    echo -e "  ${GREEN}✓${NC} $INSTALL_COMPLETION"
fi

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

if [ "$USER_SHELL" = "zsh" ]; then
    if [ -f "$SCRIPT_DIR/completions/cc.zsh" ]; then
        cp "$SCRIPT_DIR/completions/cc.zsh" "$INSTALL_COMPLETION/_cc"
        echo -e "  ${GREEN}✓${NC} cc.zsh → $INSTALL_COMPLETION/_cc"
    else
        echo -e "  ${YELLOW}○${NC} zsh 补全脚本未找到，跳过"
    fi
else
    if [ -f "$SCRIPT_DIR/completions/cc.bash" ]; then
        cp "$SCRIPT_DIR/completions/cc.bash" "$INSTALL_COMPLETION/cc"
        echo -e "  ${GREEN}✓${NC} cc.bash → $INSTALL_COMPLETION/cc"
    else
        echo -e "  ${YELLOW}○${NC} bash 补全脚本未找到，跳过"
    fi
fi

echo ""

# ========== 4. 配置 shell RC 文件 ==========
echo -e "${CYAN}[4/5] 配置 shell...${NC}"

# 根据 shell 类型选择 RC 文件
if [ "$USER_SHELL" = "zsh" ]; then
    RCFILE="$HOME/.zshrc"
else
    RCFILE="$HOME/.bashrc"
fi

# 确保 RC 文件存在
touch "$RCFILE"

# 检查 PATH 是否包含 ~/.local/bin
if [[ ":$PATH:" != *":$INSTALL_BIN:"* ]]; then
    echo -e "  ${YELLOW}⚠${NC} ~/.local/bin 不在 PATH 中"

    if ! grep -q 'export PATH=.*\.local/bin' "$RCFILE" 2>/dev/null; then
        echo '' >> "$RCFILE"
        echo '# cc-cli: 确保 ~/.local/bin 在 PATH 中' >> "$RCFILE"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RCFILE"
        echo -e "  ${GREEN}✓${NC} 已添加 PATH 配置到 $(basename "$RCFILE")"
    else
        echo -e "  ${GREEN}✓${NC} PATH 配置已存在"
    fi
fi

# 检查并添加 cc wrapper 函数
CC_MARKER="# cc-cli: Claude Code 账号切换工具"

if grep -qF "$CC_MARKER" "$RCFILE" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} cc wrapper 已存在于 $(basename "$RCFILE")"
else
    if [ "$USER_SHELL" = "zsh" ]; then
        cat >> "$RCFILE" << 'RCBLOCK'

# cc-cli: Claude Code 账号切换工具
[ -f "$HOME/.cc-profiles/env.sh" ] && source "$HOME/.cc-profiles/env.sh"
fpath=($HOME/.zsh_completion.d $fpath)
autoload -Uz compinit && compinit -C
cc() {
    command cc "$@"
    local ret=$?
    [ -f "$HOME/.cc-profiles/env.sh" ] && source "$HOME/.cc-profiles/env.sh"
    if [ "${1:-}" = "use" ] || [ "${1:-}" = "switch" ]; then
        claude
    fi
    return $ret
}
RCBLOCK
    else
        cat >> "$RCFILE" << 'RCBLOCK'

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
RCBLOCK
    fi
    echo -e "  ${GREEN}✓${NC} 已添加 cc wrapper 到 $(basename "$RCFILE")"
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
if [ "$USER_SHELL" = "zsh" ]; then
    echo -e "     ${BOLD}source ~/.zshrc${NC}"
else
    echo -e "     ${BOLD}source ~/.bashrc${NC}"
fi
echo ""
echo -e "  2. 添加你的第一个 profile："
echo -e "     ${BOLD}cc add my-key --key sk-ant-api03-xxx${NC}"
echo ""
echo -e "  3. 查看帮助："
echo -e "     ${BOLD}cc help${NC}"
echo ""
