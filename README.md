# cc-cli

**Claude Code 多账号/API Key 快速切换工具**

在终端一条命令切换 Claude Code 的 API Key、中转 API 或 OAuth 账号，不用手动改配置文件。

## 功能亮点

- **多 Profile 管理** — 同时存储多个 API Key / OAuth 账号，随时切换
- **第三方中转支持** — 支持 `--url` 指定自定义 Base URL（如 runapi、openrouter 等）
- **一键连通测试** — `cc test` 验证 API Key 是否有效
- **临时切换执行** — `cc exec` 在不改全局状态下临时使用某个 profile 执行命令
- **标签分组** — `--tag` 给 profile 打标签，`cc list --tag` 按标签过滤
- **fzf 交互选择** — `cc use` 无参数时弹出交互式选择器（需安装 fzf）
- **Tab 补全** — 子命令和 profile 名称自动补全
- **导入导出** — `cc export` / `cc import-file` 跨机器迁移配置
- **并发安全** — 文件锁防止多终端同时写配置
- **Key 脱敏显示** — list / show 只显示 key 头尾，不泄露完整密钥

## 依赖

| 依赖 | 必选 | 安装方式 |
|------|------|----------|
| bash >= 4.0 | 是 | 系统自带 |
| jq | 是 | `sudo apt install jq` / `brew install jq` |
| curl | 是 | `sudo apt install curl` / `brew install curl` |
| fzf | 否 | `sudo apt install fzf` / `brew install fzf`（用于交互选择） |

## 安装

### 方式一：一键安装（推荐）

```bash
git clone https://github.com/hyf/cc-cli.git
cd cc-cli
bash install.sh
source ~/.bashrc
```

安装脚本会自动：
1. 检测依赖是否满足
2. 复制 `cc` 到 `~/.local/bin/`
3. 复制补全脚本到 `~/.bash_completion.d/`
4. 在 `~/.bashrc` 中添加 wrapper 函数
5. 初始化 `~/.cc-profiles/` 数据目录

### 方式二：手动安装

```bash
# 1. 复制主脚本
cp cc ~/.local/bin/cc
chmod +x ~/.local/bin/cc

# 2. 复制补全脚本
mkdir -p ~/.bash_completion.d
cp completions/cc.bash ~/.bash_completion.d/cc

# 3. 确保 ~/.local/bin 在 PATH 中
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# 4. 在 ~/.bashrc 末尾添加以下内容
cat >> ~/.bashrc << 'EOF'

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
EOF

# 5. 生效
source ~/.bashrc
```

## 快速上手

```bash
# 添加一个官方 API Key
cc add work --key sk-ant-api03-xxxxxxxxxxxx

# 添加一个第三方中转 API
cc add runapi --key sk-xxx --url https://runapi.co --tag dev

# 添加 OAuth 官方账号
cc add personal --oauth

# 查看所有 profile
cc list

# 切换到 work
cc use work

# 测试连通性
cc test work
```

## 完整命令参考

### `cc list [--tag <TAG>]`

列出所有 profile。当前激活的用 `▶` 标记。

```bash
cc list             # 列出全部
cc list --tag dev   # 只显示标签为 dev 的 profile
```

输出示例：
```
Profile 列表:

       名称               类型     标签     标识
  ────────────────────────────────────────────────────────────────────────
    official             oauth      -          OAuth 登录
  ▶ runapi               api_key    dev        sk-mHy***KDbD @ https://runapi.co
    work                 api_key    prod       sk-ant***-xxx
```

### `cc current`

查看当前激活的 profile 详细信息。

### `cc add <名称> [选项]`

添加新 profile。

| 选项 | 说明 |
|------|------|
| `--key <KEY>` | API Key（与 --oauth 二选一） |
| `--oauth` | OAuth 认证（与 --key 二选一） |
| `--url <URL>` | 自定义 Base URL（第三方中转 API） |
| `--tag <TAG>` | 标签（可选） |

```bash
cc add my-key --key sk-ant-api03-xxx
cc add proxy --key sk-xxx --url https://example.com --tag test
cc add personal --oauth --tag personal
```

### `cc use [名称]`

切换到指定 profile。

- **有参数**：直接切换到指定 profile
- **无参数**：如果安装了 fzf，弹出交互式选择器；否则提示手动指定

```bash
cc use work     # 直接切换
cc use          # fzf 交互选择
```

切换 API Key 类型 profile 时，工具会自动：
1. 更新 `~/.claude/config.json`
2. 更新环境变量 `ANTHROPIC_API_KEY` / `ANTHROPIC_BASE_URL`
3. 自动启动 `claude`

切换 OAuth 类型时，会执行 `claude /logout` + `claude /login` 流程。

### `cc edit <名称> [选项]`

就地修改 profile 属性，不用先删再加。

```bash
cc edit work --key sk-new-key-xxx      # 更新 key
cc edit work --url https://new-api.com # 更新 URL
cc edit work --url ""                  # 清除 URL
cc edit work --tag production          # 更新标签
```

如果修改的是当前激活的 profile，会自动重新生效。

### `cc test [名称]`

测试 profile 的 API 连通性。无参数时测试当前激活的 profile。

```bash
cc test work    # 测试指定 profile
cc test         # 测试当前激活的
```

输出示例：
```
测试 profile: work
  Endpoint: https://api.anthropic.com/v1/messages
  ✓ 连接成功 (HTTP 200)
  模型响应: claude-haiku-4-5-20251001
```

### `cc exec <名称> -- <命令>`

临时使用某个 profile 执行命令，**不改变全局状态**。适合一次性操作或脚本中使用。

```bash
# 用 work profile 的环境跑一个命令
cc exec work -- env | grep ANTHROPIC

# 用 work profile 临时启动 claude
cc exec work -- claude "你好"
```

### `cc rm <名称>`

删除 profile。如果删除的是当前激活的，会提示切换到其他 profile。

### `cc rename <旧名> <新名>`

重命名 profile。

### `cc show <名称>`

查看 profile 的完整详情（类型、创建时间、标签、状态等）。

### `cc export [--file <路径>]`

导出所有 profiles。

```bash
cc export                        # 输出到 stdout（JSON 格式）
cc export --file backup.json     # 输出到文件
```

### `cc import-file <路径>`

从文件导入 profiles。合并模式，同名 profile 不会被覆盖。

```bash
cc import-file backup.json
```

### `cc backup`

备份当前配置到 `~/.cc-profiles/backups/`，自动保留最近 10 份。

### `cc help`

显示帮助信息。

## 配置文件说明

cc-cli 使用以下文件：

```
~/.cc-profiles/
├── profiles.json          # 所有 profile 数据（JSON 格式）
├── env.sh                 # 当前激活 profile 的环境变量（自动生成）
├── .lock                  # 文件锁（并发控制，自动管理）
├── .config_backup.json    # 上次切换前的 config.json 备份
└── backups/               # cc backup 的备份目录
    ├── profiles_20260329_120000.json
    └── config_20260329_120000.json
```

### profiles.json 结构

```json
{
  "profiles": {
    "work": {
      "type": "api_key",
      "key": "sk-ant-api03-xxxxxxxxxxxx",
      "tag": "production",
      "created": "2026-03-29T07:00:00Z"
    },
    "proxy": {
      "type": "api_key",
      "key": "sk-xxxxxxxxxxxx",
      "url": "https://example.com",
      "tag": "dev",
      "created": "2026-03-29T08:00:00Z"
    },
    "personal": {
      "type": "oauth",
      "created": "2026-03-29T09:00:00Z"
    }
  },
  "active": "work"
}
```

### 环境变量

切换 profile 后，以下环境变量会自动设置：

| 环境变量 | 说明 |
|----------|------|
| `ANTHROPIC_API_KEY` | API Key（API Key 类型 profile） |
| `ANTHROPIC_BASE_URL` | 自定义 Base URL（仅当 profile 配置了 --url 时） |

## Wrapper 函数说明

`~/.bashrc` 中的 wrapper 函数是必要的，因为：

1. **环境变量生效**：脚本是子进程，无法修改父 shell 的环境变量。wrapper 在当前 shell 中 `source env.sh`，让环境变量生效。
2. **自动启动 claude**：切换 profile 后自动启动 Claude Code CLI。

如果你不需要自动启动 claude，可以删掉 wrapper 中的 `claude` 那一行。

## 命令别名

大部分命令支持简写：

| 简写 | 完整命令 |
|------|----------|
| `cc ls` | `cc list` |
| `cc cur` | `cc current` |
| `cc del` | `cc rm` |
| `cc mv` | `cc rename` |
| `cc info` | `cc show` |

## FAQ

### Q: 支持 zsh 吗？

当前主要支持 bash。zsh 用户需要：
1. 将 `~/.bashrc` 中的 wrapper 函数改放到 `~/.zshrc`
2. 补全脚本需要适配 zsh 的补全系统（compdef）

后续版本计划加入原生 zsh 支持。

### Q: API Key 安全吗？

当前版本 API Key 以明文存储在 `~/.cc-profiles/profiles.json` 中。建议：
- 确保该文件权限为 `600`（`chmod 600 ~/.cc-profiles/profiles.json`）
- 不要将 `~/.cc-profiles/` 目录上传到任何公开仓库
- 后续版本计划接入系统 keyring 加密存储

### Q: 两个终端同时切换会冲突吗？

不会。cc-cli 使用 `flock` 文件锁，写操作（add、use、edit、rm、rename）互斥执行。

### Q: cc 和系统的 C 编译器 cc 冲突怎么办？

安装后 `cc` 会覆盖系统的 C 编译器命令。如果你需要使用 C 编译器，可以：
- 直接使用 `gcc` 或 `clang`
- 使用完整路径 `/usr/bin/cc`
- 或者将工具重命名为其他名称（如 `ccs`），修改 `~/.local/bin/` 中的文件名和 `.bashrc` 中的 wrapper 函数名即可

## 卸载

```bash
cd cc-cli
bash uninstall.sh
```

或手动卸载：

```bash
rm ~/.local/bin/cc
rm ~/.bash_completion.d/cc
# 编辑 ~/.bashrc，删除 cc-cli 相关区块（搜索 "cc-cli" 关键字）
# 可选：rm -rf ~/.cc-profiles
```

## 协议

MIT License
