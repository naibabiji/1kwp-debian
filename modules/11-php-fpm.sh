#!/bin/bash

# 模块: 11 - PHP-FPM配置
# 描述: 配置PHP-FPM性能参数

configure_php_fpm() {
    log_step 12 $TOTAL_STEPS "配置PHP-FPM"
    
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
        cat > /etc/php/8.3/fpm/conf.d/10-opcache.ini <<EOF
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
