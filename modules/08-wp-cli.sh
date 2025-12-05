#!/bin/bash

# 模块: 08 - WP-CLI安装
# 描述: 安装WordPress命令行工具

install_wp_cli() {
    log_step 9 $TOTAL_STEPS "安装WP-CLI"
    
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
