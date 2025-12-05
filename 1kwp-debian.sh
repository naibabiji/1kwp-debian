#!/bin/bash

# ============================================
# WordPress 一键安装脚本 for Debian 12
# 版本: 1.0 (PHP 8.3 + 域名管理员版)
# 描述: 自动安装 WordPress + Nginx + MariaDB + PHP 8.3 + SSL
# 特点: 使用域名主体作为管理员用户名
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
DOMAINS=()
EMAIL=""
MAIN_DOMAIN=""
DOMAIN_ROOT=""  # 域名主体，用作管理员账号
WEB_ROOT=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
MYSQL_ROOT_PASSWORD=""
ADMIN_USER=""
ADMIN_PASSWORD=""
SERVER_IP=""
TOTAL_MEM_KB=0
TOTAL_MEM_GB=0
CPU_CORES=0
AVAILABLE_SPACE_GB=0
APPLY_OPTIMIZATION=false
INSTALL_START_TIME=$(date +%s)
INSTALL_LOG="/tmp/wp-install-$(date +%Y%m%d-%H%M%S).log"

# 输出函数
log_info() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $msg" >> "$INSTALL_LOG"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $msg" >> "$INSTALL_LOG"
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}[WARNING]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $msg" >> "$INSTALL_LOG"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $msg" >> "$INSTALL_LOG"
}

log_step() {
    local step="$1"
    local total="$2"
    local message="$3"
    echo -e "\n${CYAN}=== 步骤 $step/$total: $message ===${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') === 步骤 $step/$total: $message ===" >> "$INSTALL_LOG"
}

# 提取域名主体
extract_domain_root() {
    local domain="$1"
    
    # 移除协议头和路径
    domain=$(echo "$domain" | sed 's|^https://||; s|^http://||; s|/.*$||')
    
    # 移除www.前缀
    domain=$(echo "$domain" | sed 's|^www\.||')
    
    # 提取第一个点之前的部分（域名主体）
    local root=$(echo "$domain" | cut -d. -f1)
    
    # 清理非法字符，只保留字母数字，移除连字符
    root=$(echo "$root" | tr -cd 'a-zA-Z0-9')
    
    # 确保长度至少为3个字符
    if [ ${#root} -lt 3 ]; then
        root="${root}site"
    fi
    
    # 截断到20个字符（WordPress用户名最长60字符，但保持合理长度）
    root=$(echo "$root" | cut -c 1-20)
    
    # 转换为小写（WordPress用户名是区分大小写的，但统一用小写更友好）
    root=$(echo "$root" | tr '[:upper:]' '[:lower:]')
    
    echo "$root"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 安装基础依赖
install_basic_dependencies() {
    log_step 1 14 "检查并安装基础依赖"
    
    # 定义必需工具和对应的包
    declare -A required_tools=(
        ["curl"]="curl"
        ["wget"]="wget"
        ["dig"]="dnsutils"
        ["gzip"]="gzip"
        ["tar"]="tar"
        ["grep"]="grep"
        ["sed"]="sed"
        ["awk"]="gawk"
        ["unzip"]="unzip"
    )
    
    local packages_to_install=()
    local critical_missing=0
    
    # 检查每个工具
    for tool in "${!required_tools[@]}"; do
        if ! command_exists "$tool"; then
            local pkg="${required_tools[$tool]}"
            log_warning "未找到工具: $tool，需要安装: $pkg"
            packages_to_install+=("$pkg")
            
            # 标记关键工具缺失
            if [[ "$tool" == "curl" || "$tool" == "wget" || "$tool" == "dig" ]]; then
                critical_missing=$((critical_missing + 1))
            fi
        fi
    done
    
    # 检查网络工具：至少需要curl或wget
    if ! command_exists "curl" && ! command_exists "wget"; then
        log_warning "系统缺少网络下载工具，将安装curl"
        packages_to_install+=("curl")
        critical_missing=$((critical_missing + 1))
    fi
    
    # 检查DNS工具：至少需要dig或nslookup
    if ! command_exists "dig" && ! command_exists "nslookup"; then
        log_warning "系统缺少DNS查询工具，将安装dnsutils"
        packages_to_install+=("dnsutils")
        critical_missing=$((critical_missing + 1))
    fi
    
    # 如果有包需要安装
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_info "正在安装缺失的依赖包: ${packages_to_install[*]}"
        
        # 去重
        local unique_packages=($(echo "${packages_to_install[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        
        # 更新包列表并安装
        if ! apt-get update -qq; then
            log_error "更新软件包列表失败，请检查网络连接"
            return 1
        fi
        
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${unique_packages[@]}"; then
            log_error "安装依赖包失败"
            log_info "请尝试手动运行: apt-get update && apt-get install -y ${unique_packages[*]}"
            return 1
        fi
        
        log_success "依赖包安装完成"
    else
        log_success "所有基础依赖已满足"
    fi
    
    # 最后检查关键工具
    if ! command_exists "curl" && ! command_exists "wget"; then
        log_error "网络工具安装失败，脚本无法继续"
        return 1
    fi
    
    if ! command_exists "dig" && ! command_exists "nslookup"; then
        log_error "DNS工具安装失败，脚本无法继续"
        return 1
    fi
    
    return 0
}

# 下载文件（支持curl和wget降级）
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists "curl"; then
        curl -sSL -o "$output" "$url" 2>> "$INSTALL_LOG"
    elif command_exists "wget"; then
        wget -q -O "$output" "$url" 2>> "$INSTALL_LOG"
    else
        log_error "没有可用的下载工具"
        return 1
    fi
    
    return $?
}

# 生成随机密码
generate_random_password() {
    local length="${1:-16}"
    tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom 2>/dev/null | head -c "$length" || echo "Password$RANDOM$RANDOM"
}

# 检查系统
check_system() {
    log_step 2 14 "检查系统环境"
    
    # 检查是否为Debian 12
    if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
        log_error "此脚本仅支持 Debian 12 系统"
        echo "检测到的系统信息:"
        cat /etc/os-release 2>/dev/null || echo "无法读取系统信息"
        return 1
    fi
    
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then 
        log_error "请使用 root 用户运行此脚本"
        return 1
    fi
    
    log_success "系统检查通过: Debian 12, Root权限"
    return 0
}

# 获取系统资源信息
get_system_resources() {
    log_step 3 14 "检测系统资源"
    
    # 获取CPU核心数
    CPU_CORES=$(nproc 2>/dev/null || echo 1)
    
    # 获取总内存（KB）
    TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 1048576)
    TOTAL_MEM_GB=$(echo "scale=1; $TOTAL_MEM_KB / 1024 / 1024" | bc 2>/dev/null || echo 1.0)
    
    # 获取可用磁盘空间（GB）
    AVAILABLE_SPACE_GB=$(df -BG / 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo 10)
    
    # 检查磁盘空间（使用整数比较，更可靠）
    # 将小数转换为整数进行比较
    AVAILABLE_SPACE_INT=$(echo "$AVAILABLE_SPACE_GB" | awk '{print int($1)}')
    
    if [ "$AVAILABLE_SPACE_INT" -lt 7 ]; then
        log_error "可用磁盘空间不足7GB"
        echo "当前可用: ${AVAILABLE_SPACE_GB}GB"
        echo "安装需要约6GB空间，请清理磁盘空间或扩容后再运行脚本"
        return 1
    elif [ "$AVAILABLE_SPACE_INT" -lt 10 ]; then
        log_warning "磁盘空间较少 (${AVAILABLE_SPACE_GB}GB)"
        echo "安装可以继续，但建议后续监控磁盘使用情况"
    fi
    
    # 性能优化决策
    if [ "$TOTAL_MEM_KB" -lt 2097152 ]; then  # 2GB = 2097152 KB
        APPLY_OPTIMIZATION=true
        log_info "检测到内存小于2GB (${TOTAL_MEM_GB}GB)，将应用性能优化配置"
    else
        APPLY_OPTIMIZATION=false
        log_info "内存充足(${TOTAL_MEM_GB}GB)，使用标准配置"
    fi
    
    log_success "系统资源检测完成"
    echo "  CPU核心数: $CPU_CORES"
    echo "  总内存: ${TOTAL_MEM_GB}GB"
    echo "  可用磁盘: ${AVAILABLE_SPACE_GB}GB"
    echo ""
    return 0
}

# 创建Swap空间
create_swap() {
    log_step 4 14 "配置Swap空间"
    
    local swap_size_mb=$1
    local swap_file="/swapfile"
    
    # 检查是否已存在swap
    if swapon --show 2>/dev/null | grep -q "/swap"; then
        log_info "系统已存在Swap，跳过创建"
        return 0
    fi
    
    # 检查内存是否小于1.5GB
    if [ "$TOTAL_MEM_KB" -ge 1572864 ]; then  # 1.5GB = 1572864 KB
        log_info "内存充足(${TOTAL_MEM_GB}GB)，无需创建Swap"
        return 0
    fi
    
    log_info "创建 ${swap_size_mb}MB Swap 空间..."
    
    # 创建swap文件
    if ! fallocate -l ${swap_size_mb}M "$swap_file" 2>/dev/null; then
        # fallocate可能不支持，使用dd
        dd if=/dev/zero of="$swap_file" bs=1M count=$swap_size_mb 2>> "$INSTALL_LOG"
    fi
    
    chmod 600 "$swap_file"
    mkswap "$swap_file" >> "$INSTALL_LOG" 2>&1
    swapon "$swap_file"
    
    # 添加到fstab永久生效
    if ! grep -q "$swap_file" /etc/fstab; then
        echo "$swap_file none swap sw 0 0" >> /etc/fstab
    fi
    
    # 调整swappiness
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
    fi
    
    log_success "Swap 空间创建完成 (${swap_size_mb}MB)"
    return 0
}

# 获取服务器公网IP
get_server_ip() {
    log_step 5 14 "获取服务器公网IP"
    
    local ip=""
    local ip_sources=(
        "https://api.ipify.org"
        "https://icanhazip.com"
        "https://checkip.amazonaws.com"
    )
    
    for source in "${ip_sources[@]}"; do
        log_info "尝试从 $source 获取IP..."
        ip=$(download_file "$source" "-")
        ip=$(echo "$ip" | tr -d '[:space:]')
        
        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            SERVER_IP="$ip"
            log_success "服务器公网IP: $SERVER_IP"
            return 0
        fi
        sleep 1
    done
    
    # 如果上面的API都失败了，尝试从网络接口获取
    ip=$(ip addr show 2>/dev/null | grep -E 'inet (172|192|10)' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d/ -f1)
    if [[ -n "$ip" ]]; then
        SERVER_IP="$ip"
        log_warning "使用本地IP: $SERVER_IP (可能不是公网IP，SSL证书可能无法申请)"
        return 0
    fi
    
    log_error "无法获取服务器IP地址，但将继续安装"
    log_info "请确保域名已正确解析到服务器"
    SERVER_IP="未知"
    return 0
}

# 解析域名获取IP
resolve_domain() {
    local domain="$1"
    local ip=""
    
    # 优先使用dig
    if command_exists "dig"; then
        ip=$(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
        if [ -n "$ip" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # 使用nslookup
    if command_exists "nslookup"; then
        ip=$(nslookup "$domain" 2>/dev/null | grep 'Address:' | tail -n1 | awk '{print $2}')
        echo "$ip"
    fi
}

# 检查域名解析
check_dns_resolution() {
    log_step 6 14 "检查域名解析"
    
    local unresolved_domains=()
    local resolved_ip=""
    
    log_info "正在检查 ${#DOMAINS[@]} 个域名的解析..."
    
    for domain in "${DOMAINS[@]}"; do
        log_info "检查域名: $domain"
        resolved_ip=$(resolve_domain "$domain")
        
        if [ -z "$resolved_ip" ]; then
            unresolved_domains+=("$domain (无DNS记录)")
            log_warning "$domain → 无DNS记录"
        elif [ "$SERVER_IP" != "未知" ] && [ "$resolved_ip" != "$SERVER_IP" ]; then
            unresolved_domains+=("$domain → $resolved_ip")
            log_warning "$domain → $resolved_ip (非本服务器IP: $SERVER_IP)"
        else
            log_success "$domain 解析正确: $resolved_ip"
        fi
    done
    
    if [ ${#unresolved_domains[@]} -gt 0 ]; then
        log_error "以下域名解析有问题:"
        for domain_info in "${unresolved_domains[@]}"; do
            echo "  ❌ $domain_info"
        done
        
        if [ "$SERVER_IP" != "未知" ]; then
            echo ""
            echo "请执行以下操作："
            echo "1. 登录您的域名控制台"
            echo "2. 为每个域名添加A记录："
            echo "   记录类型: A"
            echo "   记录值: $SERVER_IP"
            echo "3. 等待DNS生效（通常5-60分钟）"
            echo "4. 重新运行此脚本"
        else
            echo ""
            echo "无法获取服务器IP，请确保域名已正确解析"
        fi
        
        if [ ${#DOMAINS[@]} -eq ${#unresolved_domains[@]} ]; then
            log_error "所有域名均未解析，脚本停止"
            return 1
        else
            log_warning "部分域名解析有问题，但将继续安装"
            echo "只有解析正确的域名可以正常访问"
            return 0
        fi
    fi
    
    log_success "域名解析检查完成"
    return 0
}

# 添加PHP 8.3仓库（Sury）
add_php_repository() {
    log_step 7 15 "配置PHP 8.3仓库"
    
    # 检查是否已添加仓库
    if [ -f /etc/apt/sources.list.d/php.list ]; then
        log_info "PHP仓库已存在，跳过配置"
        return 0
    fi
    
    log_info "添加Sury PHP仓库..."
    
    # 安装必要的依赖
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 >> "$INSTALL_LOG" 2>&1; then
        log_error "安装仓库依赖失败"
        return 1
    fi
    
    # 添加Sury GPG密钥
    log_info "添加GPG密钥..."
    if command_exists "curl"; then
        curl -sSL https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg 2>> "$INSTALL_LOG"
    elif command_exists "wget"; then
        wget -q https://packages.sury.org/php/apt.gpg -O /etc/apt/trusted.gpg.d/php.gpg 2>> "$INSTALL_LOG"
    else
        log_error "无法下载GPG密钥"
        return 1
    fi
    
    # 添加仓库源
    log_info "添加仓库源..."
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    
    # 更新软件包列表
    log_info "更新软件包列表..."
    if ! apt-get update -qq 2>> "$INSTALL_LOG"; then
        log_error "更新软件包列表失败"
        return 1
    fi
    
    log_success "PHP 8.3仓库配置完成"
    return 0
}

# 安装软件包
install_packages() {
    log_step 8 15 "安装软件包"
    
    log_info "更新软件包列表..."
    if ! apt-get update -qq; then
        log_error "更新软件包列表失败"
        return 1
    fi
    
    # PHP 8.3 及相关扩展
    local packages=(
        "nginx"
        "mariadb-server"
        "mariadb-client"
        "php8.3"
        "php8.3-fpm"
        "php8.3-mysql"
        "php8.3-curl"
        "php8.3-gd"
        "php8.3-mbstring"
        "php8.3-xml"
        "php8.3-zip"
        "php8.3-bcmath"
        "php8.3-intl"
        "php8.3-soap"
        "certbot"
        "python3-certbot-nginx"
    )
    
    log_info "正在安装 ${#packages[@]} 个软件包..."
    
    local total=${#packages[@]}
    local current=0
    local failed_packages=()
    
    # 分组安装以提高效率
    for package in "${packages[@]}"; do
        current=$((current + 1))
        echo -ne "\r${BLUE}[$((current*100/total))%]${NC} 安装软件包: $package"
        
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$package" >> "$INSTALL_LOG" 2>&1; then
            failed_packages+=("$package")
        fi
    done
    
    echo ""
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_warning "以下包安装失败: ${failed_packages[*]}"
        log_info "尝试单独安装失败的包..."
        
        for package in "${failed_packages[@]}"; do
            if DEBIAN_FRONTEND=noninteractive apt-get install -y "$package" >> "$INSTALL_LOG" 2>&1; then
                log_info "重装成功: $package"
            else
                log_error "包安装失败: $package"
                return 1
            fi
        done
    fi
    
    log_success "软件包安装完成"
    return 0
}

# 安装WP-CLI
install_wp_cli() {
    log_step 9 15 "安装WP-CLI"
    
    local wp_cli_path="/usr/local/bin/wp"
    
    if [ -f "$wp_cli_path" ]; then
        log_info "WP-CLI 已存在，跳过安装"
        return 0
    fi
    
    log_info "下载 WP-CLI..."
    if ! download_file "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" "/tmp/wp-cli.phar"; then
        log_error "下载 WP-CLI 失败"
        return 1
    fi
    
    mv /tmp/wp-cli.phar "$wp_cli_path"
    chmod +x "$wp_cli_path"
    
    log_success "WP-CLI 安装完成"
    return 0
}

# 配置MariaDB
configure_mariadb() {
    log_step 10 15 "配置MariaDB"
    
    # 生成随机root密码
    MYSQL_ROOT_PASSWORD=$(generate_random_password 16)
    
    log_info "配置MariaDB安全设置..."
    
    # 停止MariaDB服务以进行安全配置
    systemctl stop mariadb 2>/dev/null || true
    
    # 创建安全配置SQL
    cat > /tmp/mysql_secure_install.sql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    # 启动MariaDB并应用安全配置
    systemctl start mariadb
    
    # 等待服务启动
    sleep 5
    
    if ! mysql -u root < /tmp/mysql_secure_install.sql 2>> "$INSTALL_LOG"; then
        log_error "MariaDB安全配置失败"
        rm -f /tmp/mysql_secure_install.sql
        return 1
    fi
    
    rm -f /tmp/mysql_secure_install.sql
    
    # 根据内存大小优化配置
    local innodb_buffer_pool_size="256M"
    local max_connections="100"
    local tmp_table_size="64M"
    local max_heap_table_size="64M"
    
    if [ "$APPLY_OPTIMIZATION" = true ]; then
        innodb_buffer_pool_size="64M"
        max_connections="30"
        tmp_table_size="32M"
        max_heap_table_size="32M"
    fi
    
    # 创建优化配置文件
    cat > /etc/mysql/mariadb.conf.d/60-wordpress-optimization.cnf << EOF
[mysqld]
# 性能优化配置
innodb_buffer_pool_size = ${innodb_buffer_pool_size}
innodb_log_file_size = 64M
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2

# 连接设置
max_connections = ${max_connections}
wait_timeout = 600
interactive_timeout = 600

# 临时表
tmp_table_size = ${tmp_table_size}
max_heap_table_size = ${max_heap_table_size}

# 字符集
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 其他优化
performance_schema = OFF
skip_name_resolve = 1
EOF
    
    # 重启MariaDB
    systemctl restart mariadb
    
    log_success "MariaDB 配置完成"
    return 0
}

# 创建WordPress数据库
create_wordpress_database() {
    log_step 11 15 "创建WordPress数据库"
    
    # 生成随机数据库信息
    DB_NAME="wp_$(generate_random_password 8 | tr -dc 'a-z0-9')"
    DB_USER="wp_user_$(generate_random_password 8 | tr -dc 'a-z0-9')"
    DB_PASSWORD=$(generate_random_password 16)
    
    log_info "创建数据库: $DB_NAME"
    log_info "创建用户: $DB_USER"
    
    # 创建数据库和用户
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF 2>> "$INSTALL_LOG"
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [ $? -ne 0 ]; then
        log_error "创建数据库失败"
        return 1
    fi
    
    log_success "数据库创建完成"
    echo "  数据库名: $DB_NAME"
    echo "  数据库用户: $DB_USER"
    echo "  数据库密码: $DB_PASSWORD"
    return 0
}

# 配置PHP-FPM
configure_php_fpm() {
    log_step 12 15 "配置PHP-FPM"
    
    local php_conf="/etc/php/8.3/fpm/pool.d/www.conf"
    local php_ini="/etc/php/8.3/fpm/php.ini"
    
    # 备份原始配置
    if [ ! -f "${php_conf}.backup" ]; then
        cp "$php_conf" "${php_conf}.backup"
    fi
    
    # 根据内存设置PHP-FPM参数
    local pm_max_children="10"
    local pm_start_servers="3"
    local pm_min_spare_servers="2"
    local pm_max_spare_servers="4"
    
    if [ "$APPLY_OPTIMIZATION" = true ]; then
        pm_max_children="5"
        pm_start_servers="2"
        pm_min_spare_servers="1"
        pm_max_spare_servers="3"
    fi
    
    # 更新PHP-FPM配置
    sed -i "s/^pm = .*/pm = dynamic/" "$php_conf"
    sed -i "s/^pm.max_children = .*/pm.max_children = ${pm_max_children}/" "$php_conf"
    sed -i "s/^pm.start_servers = .*/pm.start_servers = ${pm_start_servers}/" "$php_conf"
    sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = ${pm_min_spare_servers}/" "$php_conf"
    sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = ${pm_max_spare_servers}/" "$php_conf"
    sed -i "s/^pm.max_requests = .*/pm.max_requests = 500/" "$php_conf"
    
    # 增加PHP内存限制
    sed -i "s/^;*memory_limit = .*/memory_limit = 256M/" "$php_ini"
    sed -i "s/^;*max_execution_time = .*/max_execution_time = 300/" "$php_ini"
    sed -i "s/^;*upload_max_filesize = .*/upload_max_filesize = 64M/" "$php_ini"
    sed -i "s/^;*post_max_size = .*/post_max_size = 64M/" "$php_ini"
    sed -i "s/^;*max_input_time = .*/max_input_time = 300/" "$php_ini"
    
    # 启用OPcache
    if ! grep -q "opcache.enable=1" /etc/php/8.3/fpm/conf.d/10-opcache.ini 2>/dev/null; then
        cat > /etc/php/8.3/fpm/conf.d/10-opcache.ini << EOF
zend_extension=opcache.so
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF
    fi
    
    # 重启PHP-FPM
    systemctl restart php8.3-fpm
    
    log_success "PHP-FPM 配置完成"
    echo "  运行模式: dynamic"
    echo "  最大子进程: $pm_max_children"
    echo "  内存限制: 256M"
    return 0
}

# 配置Nginx
configure_nginx() {
    log_step 13 15 "配置Nginx"
    
    # 根据CPU核心数设置worker进程
    local worker_processes=$CPU_CORES
    if [ $worker_processes -gt 2 ]; then
        worker_processes=2
    fi
    
    # 创建优化的Nginx主配置
    cat > /etc/nginx/nginx.conf << EOF
user www-data;
worker_processes ${worker_processes};
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;

events {
    worker_connections 768;
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 64M;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # 日志格式
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # 测试Nginx配置
    if ! nginx -t >> "$INSTALL_LOG" 2>&1; then
        log_error "Nginx 配置测试失败"
        return 1
    fi
    
    systemctl restart nginx
    systemctl enable nginx
    
    log_success "Nginx 配置完成"
    echo "  Worker进程数: $worker_processes"
    echo "  Gzip压缩: 已启用"
    return 0
}

# 创建网站目录和设置权限
create_web_directory() {
    log_step 14 15 "创建网站目录"
    
    MAIN_DOMAIN="${DOMAINS[0]}"
    DOMAIN_ROOT=$(extract_domain_root "$MAIN_DOMAIN")
    WEB_ROOT="/var/www/${MAIN_DOMAIN}"
    
    # 设置管理员用户名
    ADMIN_USER="$DOMAIN_ROOT"
    
    # 创建目录
    mkdir -p "$WEB_ROOT"
    
    # 设置正确的所有权
    chown -R www-data:www-data "$WEB_ROOT"
    
    # 设置安全的目录权限
    find "$WEB_ROOT" -type d -exec chmod 755 {} \;
    find "$WEB_ROOT" -type f -exec chmod 644 {} \;
    
    log_success "网站目录创建完成: $WEB_ROOT"
    log_info "管理员用户名设置为: $ADMIN_USER (来自域名主体)"
    return 0
}

# 下载和配置WordPress
install_wordpress() {
    log_step 15 15 "安装WordPress"
    
    cd "$WEB_ROOT" || return 1
    
    # 下载最新WordPress
    log_info "下载 WordPress 核心文件..."
    if ! download_file "https://wordpress.org/latest.tar.gz" "/tmp/latest.tar.gz"; then
        log_error "下载 WordPress 失败"
        return 1
    fi
    
    tar -xzf /tmp/latest.tar.gz --strip-components=1
    rm -f /tmp/latest.tar.gz
    
    # 设置文件权限
    chown -R www-data:www-data "$WEB_ROOT"
    find "$WEB_ROOT" -type d -exec chmod 755 {} \;
    find "$WEB_ROOT" -type f -exec chmod 644 {} \;
    
    # 生成安全密钥
    ADMIN_PASSWORD=$(generate_random_password 16)
    local auth_keys=$(download_file "https://api.wordpress.org/secret-key/1.1/salt/" "-")
    
    if [ -z "$auth_keys" ]; then
        log_warning "无法获取安全密钥，使用本地生成"
        auth_keys=$(cat << EOF
define('AUTH_KEY',         '$(generate_random_password 64)');
define('SECURE_AUTH_KEY',  '$(generate_random_password 64)');
define('LOGGED_IN_KEY',    '$(generate_random_password 64)');
define('NONCE_KEY',        '$(generate_random_password 64)');
define('AUTH_SALT',        '$(generate_random_password 64)');
define('SECURE_AUTH_SALT', '$(generate_random_password 64)');
define('LOGGED_IN_SALT',   '$(generate_random_password 64)');
define('NONCE_SALT',       '$(generate_random_password 64)');
EOF
)
    fi
    
    # 创建wp-config.php
    cat > wp-config.php << EOF
<?php
/**
 * WordPress基础配置文件。
 */

// **数据库设置** - 具体信息来自您的主机提供商。 //
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

/**#@+
 * 身份认证密钥。
 */
${auth_keys}
/**#@-*/

/**
 * WordPress数据表前缀。
 */
\$table_prefix = 'wp_';

/**
 * 开发者专用：WordPress调试模式。
 */
define('WP_DEBUG', false);
if (WP_DEBUG) {
    define('WP_DEBUG_LOG', true);
    define('WP_DEBUG_DISPLAY', false);
    @ini_set('display_errors', 0);
}

/* 性能优化设置 */
define('WP_POST_REVISIONS', 3);
define('AUTOSAVE_INTERVAL', 120);
define('EMPTY_TRASH_DAYS', 7);
define('WP_AUTO_UPDATE_CORE', 'minor');

/* 强制SSL（后台） */
define('FORCE_SSL_ADMIN', true);

/* 增加内存限制 */
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '256M');

/* 禁用文件编辑 */
define('DISALLOW_FILE_EDIT', true);

/* 至此为止，请勿继续修改。请使用WordPress管理后台进行设置。 */

/** 绝对路径。 */
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

/** 设置WordPress变量和包含文件。 */
require_once ABSPATH . 'wp-settings.php';
EOF
    
    # 保护wp-config.php
    chmod 640 wp-config.php
    
    # 使用WP-CLI安装WordPress
    log_info "配置 WordPress..."
    log_info "使用管理员用户名: $ADMIN_USER"
    
    /usr/local/bin/wp core install \
        --url="https://${MAIN_DOMAIN}" \
        --title="${MAIN_DOMAIN}" \
        --admin_user="${ADMIN_USER}" \
        --admin_password="${ADMIN_PASSWORD}" \
        --admin_email="${EMAIL}" \
        --skip-email \
        --allow-root 2>> "$INSTALL_LOG"
    
    if [ $? -ne 0 ]; then
        log_error "WordPress 安装失败"
        log_info "尝试使用备选用户名..."
        # 如果域名主体作为用户名失败，尝试添加数字后缀
        ADMIN_USER="${DOMAIN_ROOT}1"
        /usr/local/bin/wp core install \
            --url="https://${MAIN_DOMAIN}" \
            --title="${MAIN_DOMAIN}" \
            --admin_user="${ADMIN_USER}" \
            --admin_password="${ADMIN_PASSWORD}" \
            --admin_email="${EMAIL}" \
            --skip-email \
            --allow-root 2>> "$INSTALL_LOG"
        
        if [ $? -ne 0 ]; then
            log_error "WordPress 安装失败，使用默认用户名"
            ADMIN_USER="admin"
            /usr/local/bin/wp core install \
                --url="https://${MAIN_DOMAIN}" \
                --title="${MAIN_DOMAIN}" \
                --admin_user="${ADMIN_USER}" \
                --admin_password="${ADMIN_PASSWORD}" \
                --admin_email="${EMAIL}" \
                --skip-email \
                --allow-root 2>> "$INSTALL_LOG"
        fi
    fi
    
    if [ $? -ne 0 ]; then
        log_error "WordPress 安装完全失败"
        return 1
    fi
    
    # 设置固定链接
    /usr/local/bin/wp rewrite structure '/%postname%/' --hard --allow-root 2>> "$INSTALL_LOG"
    
    # 禁用不必要的功能
    /usr/local/bin/wp config set AUTOMATIC_UPDATER_DISABLED true --raw --allow-root 2>> "$INSTALL_LOG"
    
    log_success "WordPress 安装完成"
    log_info "管理员用户名: $ADMIN_USER"
    return 0
}

# 创建Nginx站点配置
create_nginx_site_config() {
    log_info "创建 Nginx 站点配置..."
    
    local config_file="/etc/nginx/sites-available/${MAIN_DOMAIN}"
    
    # 构建server_name
    local server_names=""
    for domain in "${DOMAINS[@]}"; do
        server_names="$server_names $domain"
    done
    server_names=$(echo "$server_names" | sed 's/^ //')
    
    # 创建站点配置
    cat > "$config_file" << EOF
# HTTP重定向到HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${server_names};
    
    # 重定向到HTTPS
    return 301 https://\$server_name\$request_uri;
}

# HTTPS配置
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${server_names};
    
    root ${WEB_ROOT};
    index index.php index.html index.htm;
    
    # SSL证书位置（将由Certbot自动更新）
    ssl_certificate /etc/letsencrypt/live/${MAIN_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${MAIN_DOMAIN}/privkey.pem;
    
    # SSL优化设置
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # 禁止访问敏感文件
    location ~* /(\.git|wp-config\.php|wp-config-sample\.php|readme\.html|license\.txt|nginx\.conf|\.htaccess) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问日志文件
    location ~* ^/wp-content/(debug\.log|error_log) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止执行PHP文件的上传目录
    location ~* ^/wp-content/uploads/.*\.php\$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # WordPress永久链接支持
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|pdf|mp4|webm)\$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # PHP处理
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # 安全设置
        fastcgi_param HTTP_PROXY "";
        fastcgi_hide_header X-Powered-By;
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 缓存WordPress管理后台和登录页面
    location ~* /(wp-admin|wp-login\.php) {
        fastcgi_cache_bypass 1;
        fastcgi_no_cache 1;
    }
}
EOF
    
    # 启用站点
    rm -f /etc/nginx/sites-enabled/default
    ln -sf "$config_file" "/etc/nginx/sites-enabled/"
    
    # 测试Nginx配置
    if nginx -t >> "$INSTALL_LOG" 2>&1; then
        systemctl reload nginx
        log_success "Nginx 站点配置完成并已启用"
    else
        log_error "Nginx 配置测试失败"
        return 1
    fi
    
    return 0
}

# 申请SSL证书
request_ssl_certificate() {
    log_info "申请 SSL 证书..."
    
    # 构建域名参数
    local certbot_domains=""
    for domain in "${DOMAINS[@]}"; do
        certbot_domains="$certbot_domains -d $domain"
    done
    
    # 尝试申请证书
    log_info "运行: certbot --nginx --agree-tos --no-eff-email --email $EMAIL $certbot_domains --non-interactive --redirect"
    
    if certbot --nginx --agree-tos --no-eff-email --email "$EMAIL" $certbot_domains --non-interactive --redirect 2>> "$INSTALL_LOG"; then
        log_success "SSL 证书申请成功"
        
        # 测试自动续期
        log_info "测试SSL证书自动续期..."
        if certbot renew --dry-run 2>> "$INSTALL_LOG"; then
            log_success "SSL 证书自动续期测试通过"
        else
            log_warning "SSL 证书自动续期测试失败，请手动检查"
        fi
        
        return 0
    else
        log_warning "SSL 证书申请失败，网站将以HTTP运行"
        log_info "您可以稍后手动运行: certbot --nginx"
        return 1
    fi
}

# 安装后优化
post_install_optimization() {
    log_info "执行安装后优化..."
    
    # 优化数据库表
    log_info "优化数据库表..."
    cd "$WEB_ROOT" && /usr/local/bin/wp db optimize --allow-root 2>> "$INSTALL_LOG"
    
    # 配置日志轮转
    log_info "配置日志轮转..."
    cat > /etc/logrotate.d/nginx-wordpress << EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
    endscript
}
EOF
    
    # 创建PHP会话目录并设置权限
    local php_session_dir="/var/lib/php/sessions"
    mkdir -p "$php_session_dir"
    chown -R www-data:www-data "$php_session_dir"
    chmod 733 "$php_session_dir"
    
    # 清理APT缓存
    log_info "清理APT缓存..."
    apt-get clean >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    
    # 清理临时文件
    log_info "清理临时文件..."
    rm -rf /tmp/*
    
    log_success "安装后优化完成"
    return 0
}

# 保存安装信息
save_installation_info() {
    log_info "保存安装信息..."
    
    local info_file="/root/${MAIN_DOMAIN}_installation_info.txt"
    local install_end_time=$(date +%s)
    local install_duration=$((install_end_time - INSTALL_START_TIME))
    local minutes=$((install_duration / 60))
    local seconds=$((install_duration % 60))
    
    cat > "$info_file" << EOF
========================================
WordPress 一键安装信息 (域名主体管理员版)
========================================
安装时间: $(date)
安装耗时: ${minutes}分${seconds}秒
主域名: ${MAIN_DOMAIN}
域名主体: ${DOMAIN_ROOT}
所有域名: ${DOMAINS[*]}
网站目录: ${WEB_ROOT}
安装日志: ${INSTALL_LOG}

=== WordPress 信息 ===
网站地址: https://${MAIN_DOMAIN}
后台地址: https://${MAIN_DOMAIN}/wp-admin
管理员账号: ${ADMIN_USER}
管理员密码: ${ADMIN_PASSWORD}
管理员邮箱: ${EMAIL}
📝 提示: 管理员账号为域名主体"${DOMAIN_ROOT}"，方便记忆！

=== 数据库信息 ===
数据库主机: localhost
数据库名: ${DB_NAME}
数据库用户: ${DB_USER}
数据库密码: ${DB_PASSWORD}
MariaDB Root 密码: ${MYSQL_ROOT_PASSWORD}

=== 服务器信息 ===
服务器IP: ${SERVER_IP}
操作系统: Debian 12
CPU核心: ${CPU_CORES}
总内存: ${TOTAL_MEM_GB}GB
安装模式: $(if [ "$APPLY_OPTIMIZATION" = true ]; then echo "性能优化模式 (内存<2GB)"; else echo "标准模式"; fi)

=== 软件版本 ===
PHP版本: 8.3
MariaDB版本: $(mysql --version 2>/dev/null | awk '{print $5}' | tr -d ',' | head -1 || echo "未知")
Nginx版本: $(nginx -v 2>&1 | awk -F'/' '{print $2}' | head -1 || echo "未知")
WordPress版本: $(/usr/local/bin/wp core version --allow-root 2>/dev/null || echo "未知")

=== 优化配置 ===
PHP-FPM子进程: $(grep -E '^pm.max_children' /etc/php/8.3/fpm/pool.d/www.conf 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ' || echo "未知")
MariaDB缓冲池: $(grep -E '^innodb_buffer_pool_size' /etc/mysql/mariadb.conf.d/60-wordpress-optimization.cnf 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ' || echo "未知")
PHP内存限制: $(php -i 2>/dev/null | grep 'memory_limit' | head -1 | awk '{print $3}' || echo "未知")

=== 重要文件位置 ===
Nginx配置: /etc/nginx/sites-available/${MAIN_DOMAIN}
网站根目录: ${WEB_ROOT}
PHP配置: /etc/php/8.3/fpm/pool.d/www.conf
数据库配置: /etc/mysql/mariadb.conf.d/60-wordpress-optimization.cnf

=== 常用命令 ===
重启Nginx: systemctl restart nginx
重启PHP-FPM: systemctl restart php8.3-fpm
重启MariaDB: systemctl restart mariadb
查看Nginx日志: tail -f /var/log/nginx/error.log
查看PHP日志: tail -f /var/log/php8.3-fpm.log
备份数据库: mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${DB_NAME} > backup.sql

=== 后续建议 ===
1. 登录后台后立即更改管理员密码！
2. 安装缓存插件（推荐 WP Super Cache 或 W3 Total Cache）
3. 安装安全插件（推荐 Wordfence Security 或 iThemes Security）
4. 安装图片优化插件（推荐 Smush 或 Imagify）
5. 配置定期备份方案（推荐 UpdraftPlus 或 BackWPup）
6. 考虑使用 Cloudflare 免费 CDN
7. 定期检查 /root/${MAIN_DOMAIN}_installation_info.txt 中的信息
8. 监控服务器资源使用情况（可用 htop 或 glances）

=== 故障排除 ===
1. 网站无法访问: 检查 nginx 和 php8.3-fpm 服务状态
2. 数据库连接错误: 确认数据库服务运行，密码正确
3. SSL证书问题: 运行 certbot renew 手动更新证书
4. 内存不足: 检查内存使用，考虑升级VPS配置

安装脚本版本: 1.0 (PHP 8.3 + 域名主体管理员版)
========================================
EOF
    
    chmod 600 "$info_file"
    log_success "安装信息已保存到: $info_file"
    
    # 也保存一份简略版到网站目录（仅管理员可读）
    cat > "${WEB_ROOT}/installation-info.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>安装信息</title>
    <meta name="robots" content="noindex,nofollow">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #0073aa; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .label { font-weight: bold; color: #0073aa; }
        .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .username { color: #28a745; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>WordPress 安装信息</h1>
        <div class="warning">
            <strong>重要提示:</strong> 此文件包含敏感信息。请在记录必要信息后删除此文件。
        </div>
        <div class="info">
            <p><span class="label">网站地址:</span> <a href="https://${MAIN_DOMAIN}" target="_blank">https://${MAIN_DOMAIN}</a></p>
            <p><span class="label">后台地址:</span> <a href="https://${MAIN_DOMAIN}/wp-admin" target="_blank">https://${MAIN_DOMAIN}/wp-admin</a></p>
            <p><span class="label">管理员账号:</span> <span class="username">${ADMIN_USER}</span> (来自域名主体)</p>
            <p><span class="label">管理员密码:</span> ${ADMIN_PASSWORD}</p>
            <p><span class="label">安装时间:</span> $(date)</p>
            <p><span class="label">完整安装信息:</span> /root/${MAIN_DOMAIN}_installation_info.txt</p>
        </div>
        <p><em>请及时登录后台更改密码，并删除此文件。</em></p>
    </div>
</body>
</html>
EOF
    
    chmod 600 "${WEB_ROOT}/installation-info.html"
    chown www-data:www-data "${WEB_ROOT}/installation-info.html"
}

# 显示安装摘要
show_installation_summary() {
    local install_end_time=$(date +%s)
    local install_duration=$((install_end_time - INSTALL_START_TIME))
    local minutes=$((install_duration / 60))
    local seconds=$((install_duration % 60))
    
    echo ""
    echo "================================================"
    echo "          🎉 WordPress 一键安装完成！"
    echo "================================================"
    echo ""
    echo "✅ 恭喜！您的 WordPress 网站已成功安装。"
    echo ""
    
    echo "=== 📍 访问信息 ==="
    echo "🌐 网站地址: https://${MAIN_DOMAIN}"
    echo "🔐 管理后台: https://${MAIN_DOMAIN}/wp-admin"
    echo "👤 管理员账号: ${ADMIN_USER}"
    echo "🔑 管理员密码: ${ADMIN_PASSWORD}"
    echo "📧 管理员邮箱: ${EMAIL}"
    echo ""
    echo "💡 提示：管理员账号为域名主体 \"${DOMAIN_ROOT}\"，方便记忆！"
    echo ""
    
    if [ ${#DOMAINS[@]} -gt 1 ]; then
        echo "=== 🌐 其他域名 ==="
        for ((i=1; i<${#DOMAINS[@]}; i++)); do
            echo "https://${DOMAINS[$i]}"
        done
        echo ""
    fi
    
    echo "=== ⚙️ 服务器配置优化 ==="
    echo "✓ 系统检测: Debian 12, ${CPU_CORES}核CPU, ${TOTAL_MEM_GB}GB内存"
    
    if [ "$APPLY_OPTIMIZATION" = true ]; then
        if [ "$TOTAL_MEM_KB" -lt 1572864 ]; then
            echo "✓ 已创建 2GB Swap 空间"
        fi
        echo "✓ PHP-FPM 进程优化: 最大5个子进程"
        echo "✓ MariaDB 内存优化: 缓冲池 64MB"
        echo "✓ 针对 1GB 内存VPS深度优化"
    else
        echo "✓ 标准配置模式 (内存充足)"
    fi
    
    echo "✓ PHP版本: 8.3 (WordPress官方推荐)"
    echo "✓ Nginx 配置优化: 启用Gzip，静态文件缓存"
    echo "✓ SSL 证书: 已自动配置"
    echo "✓ 管理员策略: 使用域名主体作为账号，安全易记"
    echo ""
    
    echo "=== ⚠️ 重要提醒 ==="
    echo "1. 安装信息已保存到: /root/${MAIN_DOMAIN}_installation_info.txt"
    echo "2. 请立即登录后台更改管理员密码！"
    echo "3. 数据库密码等敏感信息已妥善保存"
    echo "4. 安装日志: $INSTALL_LOG"
    echo ""
    
    echo "=== 💡 后续建议 ==="
    echo "1. 安装缓存插件: WP Super Cache 或 W3 Total Cache"
    echo "2. 安装安全插件: Wordfence Security 或 iThemes Security"
    echo "3. 安装图片优化插件: Smush 或 Imagify"
    echo "4. 配置备份方案: UpdraftPlus 或 BackWPup"
    echo "5. 考虑使用 Cloudflare 免费 CDN 加速"
    echo ""
    
    echo "⏱️ 安装耗时: ${minutes}分${seconds}秒"
    echo "================================================"
    echo ""
    
    # 显示网站信息文件
    echo "📄 网站目录中已生成 installation-info.html 文件"
    echo "   请在记录信息后删除: rm ${WEB_ROOT}/installation-info.html"
    echo ""
}

# 主安装流程
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
    create_web_directory || exit 1
    install_wordpress || exit 1
    
    # 创建Nginx配置
    create_nginx_site_config || exit 1
    
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

# 主函数
main() {
    clear
    echo "================================================"
    echo "      WordPress 一键安装脚本 for Debian 12"
    echo "     版本 1.0 (PHP 8.3 + 域名主体管理员版)"
    echo "================================================"
    echo ""
    echo "📝 特点:"
    echo "  • 使用域名主体作为管理员账号 (如 vps17.com → 账号: vps17)"
    echo "  • PHP 8.3 (WordPress官方推荐)"
    echo "  • 自动配置SSL证书 (Let's Encrypt)"
    echo "  • 针对低内存VPS优化 (自动创建Swap)"
    echo ""
    
    # 检查参数
    if [ $# -lt 2 ]; then
        echo "❌ 使用方法: $0 <邮箱> <域名1> [域名2] [域名3] ..."
        echo ""
        echo "📋 示例:"
        echo "  $0 user@vps17.com vps17.com"
        echo "  $0 user@vps17.com vps17.com www.vps17.com"
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
    if [[ ! "$EMAIL" == *"@"* ]]; then
        log_error "第一个参数必须是邮箱地址"
        echo "您输入的是: $EMAIL"
        exit 1
    fi
    
    # 收集域名（去重）
    declare -A domain_map
    for domain in "$@"; do
        # 去除可能的协议前缀和路径
        domain=$(echo "$domain" | sed 's|^https://||; s|^http://||; s|/.*$||')
        
        # 简单的域名格式验证
        if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
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
    echo "     脚本将自动检查DNS解析，未解析的域名将无法访问"
    echo ""
    echo "按 Enter 继续安装，或按 Ctrl+C 取消..."
    read -r
    
    # 开始安装
    run_installation
}

# 脚本入口点
main "$@"
