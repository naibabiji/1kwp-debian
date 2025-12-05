#!/bin/bash

# 模块: 06 - PHP仓库配置
# 描述: 添加Sury PHP 8.3仓库

add_php_repository() {
    log_step 7 $TOTAL_STEPS "配置PHP 8.3仓库"
    
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
