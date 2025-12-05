#!/bin/bash

# ============================================
# WordPress 一键安装脚本 - 主程序
# 版本: 2.0 (模块化版本)
# 描述: 自动安装 WordPress + Nginx + MariaDB + PHP 8.3 + SSL
# 特点: 使用域名主体作为管理员用户名
# ============================================

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# 远程安装引导逻辑
# ============================================
# 如果本地找不到依赖库（说明是curl运行或文件缺失），则自动拉取仓库
if [ ! -f "$SCRIPT_DIR/lib/common.sh" ] || [ ! -f "$SCRIPT_DIR/lib/validation.sh" ]; then
    echo "检测到远程运行模式，正在准备安装环境..."
    
    # 检查是否为 root 用户
    if [ "$(id -u)" != "0" ]; then
        echo "❌ 错误: 本脚本需要 root 权限运行"
        echo "请使用: sudo bash $0 $@"
        exit 1
    fi

    # 安装 git (如果不存在)
    if ! command -v git &> /dev/null; then
        echo "正在安装 Git..."
        if [ -f /etc/debian_version ]; then
            apt-get update -qq
            apt-get install -y -qq git
        elif [ -f /etc/redhat-release ]; then
            yum install -y -q git
        else
            echo "❌ 无法自动安装 Git，请手动安装后重试"
            exit 1
        fi
    fi

    # 创建临时目录
    INSTALL_DIR="/tmp/1kwp-installer-$(date +%s)"
    echo "正在克隆安装脚本到: $INSTALL_DIR"
    
    # 克隆仓库
    git clone --depth=1 https://github.com/naibabiji/1kwp-debian.git "$INSTALL_DIR"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "❌ 克隆仓库失败，请检查网络连接"
        exit 1
    fi

    # 赋予执行权限并运行
    echo "正在启动安装程序..."
    chmod +x "$INSTALL_DIR/install.sh"
    
    # 传递所有参数给新脚本
    exec "$INSTALL_DIR/install.sh" "$@"
    
    # 正常情况下不会执行到这里
    exit 0
fi

# ============================================
# 本地运行逻辑
# ============================================

# 加载配置和库
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/validation.sh"

# 加载所有模块
for module in "$SCRIPT_DIR/modules"/*.sh; do
    source "$module"
done

# 主函数
main() {
    clear
    echo "================================================"
    echo "      WordPress 一键安装脚本 for Debian 12"
    echo "     版本 2.0 (模块化 + PHP 8.3)"
    echo "================================================"
    echo ""
    echo "📝 特点:"
    echo "  • 使用域名主体作为管理员账号 (如 vps17.com → 账号: vps17)"
    echo "  • PHP 8.3 (WordPress官方推荐)"
    echo "  • 自动配置SSL证书 (Let's Encrypt)"
    echo "  • 针对低内存VPS优化 (自动创建Swap)"
    echo "  • 模块化设计，易维护"
    echo ""
    
    # 检查参数
    if [ $# -lt 2 ]; then
        echo "❌ 使用方法: $0 <邮箱> <域名1> [域名2] [域名3] ..."
        echo ""
        echo "📋 示例:"
        echo "  $0 user@vps17.com vps17.com"
        echo "  $0 user@vps17.com vps17.com www.vps17.com"
        echo ""
        echo "📝 说明:"
        echo "  1. 第一个参数必须是邮箱地址（用于SSL证书通知）"
        echo "  2. 后续参数为需要绑定的域名，至少一个，支持多个"
        echo "  3. 主域名的域名主体将作为管理员账号 (如 vps17.com → 账号: vps17)"
        echo "  4. 脚本仅支持 Debian 12 系统，且需要 root 权限"
        echo ""
        exit 1
    fi
    
    # 参数解析
    EMAIL="$1"
    shift
    
    # 验证邮箱格式
    if ! validate_email "$EMAIL"; then
        log_error "第一个参数必须是邮箱地址"
        echo "您输入的是: $EMAIL"
        exit 1
    fi
    
    # 收集域名（去重）
    declare -A domain_map
    for domain in "$@"; do
        # 去除可能的协议前缀和路径
        domain=$(echo "$domain" | sed 's|^https://||; s|^http://||; s|/.*$||')
        
        # 域名格式验证
        if ! validate_domain "$domain"; then
            log_warning "域名格式可能不正确: $domain，但仍将继续处理"
        fi
        domain_map["$domain"]=1
    done
    
    DOMAINS=("${!domain_map[@]}")
    
    if [ ${#DOMAINS[@]} -eq 0 ]; then
        log_error "至少需要提供一个有效的域名"
        exit 1
    fi
    
    # 显示参数信息
    echo "📋 安装参数:"
    echo "  📧 邮箱: $EMAIL"
    echo "  🌐 域名: ${DOMAINS[*]}"
    echo "  👤 管理员账号将使用: $(extract_domain_root "${DOMAINS[0]}") (来自域名主体)"
    echo ""
    echo "⚠️  注意: 请确保所有域名已解析到本服务器IP"
    echo ""
    echo "按 Enter 继续安装，或按 Ctrl+C 取消..."
    read -r
    
    # 开始安装
    run_installation
}

# 安装流程
run_installation() {
    log_info "开始WordPress安装流程..."
    echo "安装日志: $INSTALL_LOG"
    echo ""
    
    # 执行所有安装步骤
    install_basic_dependencies || exit 1
    check_system || exit 1
    get_system_resources || exit 1
    create_swap 2048 || exit 1
    get_server_ip || exit 1
    check_dns_resolution || exit 1
    add_php_repository || exit 1
    install_packages || exit 1
    install_wp_cli || exit 1
    configure_mariadb || exit 1
    create_wordpress_database || exit 1
    configure_php_fpm || exit 1
    configure_nginx || exit 1
    install_wordpress || exit 1
    create_nginx_site_config || exit 1
    install_php_prober || log_warning "PHP探针安装失败，但不影响WordPress运行"
    
    # 申请SSL证书（如果失败继续）
    request_ssl_certificate || log_warning "SSL证书未安装，网站将以HTTP运行"
    
    # 安装后优化
    post_install_optimization || log_warning "安装后优化步骤有警告"
    
    # 保存信息并显示摘要
    save_installation_info
    show_installation_summary
    
    log_success "🎊 安装流程全部完成！"
    return 0
}

# 脚本入口点
main "$@"
