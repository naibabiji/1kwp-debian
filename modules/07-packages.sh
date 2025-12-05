#!/bin/bash

# 模块: 07 - 软件包安装
# 描述: 安装Nginx, MariaDB, PHP 8.3及相关扩展

install_packages() {
    log_step 8 $TOTAL_STEPS "安装软件包"
    
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
