#compdef cc
# cc 命令的 zsh Tab 补全脚本

_cc_profiles() {
    local -a profiles
    if [ -f ~/.cc-profiles/profiles.json ]; then
        profiles=(${(f)"$(jq -r '.profiles | keys[]' ~/.cc-profiles/profiles.json 2>/dev/null)"})
    fi
    _describe 'profile' profiles
}

_cc() {
    local -a commands
    commands=(
        'list:列出所有 profile'
        'ls:列出所有 profile'
        'current:查看当前激活的 profile'
        'cur:查看当前激活的 profile'
        'add:添加新 profile'
        'use:切换到指定 profile'
        'switch:切换到指定 profile'
        'edit:修改 profile 属性'
        'test:测试 profile 连通性'
        'login:强制刷新 OAuth 登录'
        'exec:临时使用某 profile 执行命令'
        'rm:删除 profile'
        'del:删除 profile'
        'rename:重命名 profile'
        'mv:重命名 profile'
        'show:查看 profile 详情'
        'info:查看 profile 详情'
        'export:导出 profiles'
        'import-file:从文件导入 profiles'
        'backup:备份当前配置'
        'update:从 GitHub 更新到最新版本'
        'import:导入当前已有的 key'
        'help:显示帮助'
    )

    _arguments -C \
        '1:command:->command' \
        '*::arg:->args'

    case "$state" in
        command)
            _describe 'cc command' commands
            ;;
        args)
            case "${words[1]}" in
                use|switch|rm|del|remove|show|info|edit|test|login|exec|rename|mv)
                    if [ "$CURRENT" -eq 2 ]; then
                        _cc_profiles
                    else
                        case "${words[CURRENT-1]}" in
                            --key|--url|--tag|--file|-f)
                                ;;
                            *)
                                case "${words[1]}" in
                                    edit)
                                        _arguments '*:option:(--key --url --tag)'
                                        ;;
                                    exec)
                                        _arguments '*:option:(--)'
                                        ;;
                                esac
                                ;;
                        esac
                    fi
                    ;;
                add)
                    case "${words[CURRENT-1]}" in
                        --key|--url|--tag)
                            ;;
                        *)
                            _arguments '*:option:(--key --url --oauth --tag)'
                            ;;
                    esac
                    ;;
                list|ls)
                    _arguments '*:option:(--tag)'
                    ;;
                export)
                    _arguments '*:option:(--file)'
                    ;;
                import-file)
                    _files
                    ;;
            esac
            ;;
    esac
}

_cc "$@"
