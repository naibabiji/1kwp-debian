#!/bin/bash

# 模块: 13 - WordPress安装
# 描述: 下载和配置WordPress

install_wordpress() {
    log_step 14 $TOTAL_STEPS "安装WordPress"
    
    # 设置主域名和管理员用户名
    MAIN_DOMAIN="${DOMAINS[0]}"
    DOMAIN_ROOT=$(extract_domain_root "$MAIN_DOMAIN")
    WEB_ROOT="/var/www/${MAIN_DOMAIN}"
    ADMIN_USER="$DOMAIN_ROOT"
    
    # 创建网站目录
    mkdir -p "$WEB_ROOT"
    cd "$WEB_ROOT" || return 1
    
    # 下载最新WordPress
    log_info "下载 WordPress 核心文件..."
    if ! download_file "https://wordpress.org/latest.tar.gz" "/tmp/latest.tar.gz"; then
        log_error "下载 WordPress 失败"
        return 1
    fi
    
    tar -xzf /tmp/latest.tar.gz --strip-components=1
    rm -f /tmp/latest.tar.gz
    
    # 生成安全密钥
    ADMIN_PASSWORD=$(generate_random_password 16)
    local auth_keys=$(download_file "https://api.wordpress.org/secret-key/1.1/salt/" "-")
    
    if [ -z "$auth_keys" ]; then
        log_warning "无法获取安全密钥，使用本地生成"
        auth_keys=$(cat <<KEYS
define('AUTH_KEY',         '$(generate_random_password 64)');
define('SECURE_AUTH_KEY',  '$(generate_random_password 64)');
define('LOGGED_IN_KEY',    '$(generate_random_password 64)');
define('NONCE_KEY',        '$(generate_random_password 64)');
define('AUTH_SALT',        '$(generate_random_password 64)');
define('SECURE_AUTH_SALT', '$(generate_random_password 64)');
define('LOGGED_IN_SALT',   '$(generate_random_password 64)');
define('NONCE_SALT',       '$(generate_random_password 64)');
KEYS
)
    fi
    
    # 创建wp-config.php
    cat > wp-config.php <<EOF
<?php
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

${auth_keys}

\$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('WP_POST_REVISIONS', 3);
define('AUTOSAVE_INTERVAL', 120);
define('EMPTY_TRASH_DAYS', 7);
define('WP_AUTO_UPDATE_CORE', 'minor');
define('FORCE_SSL_ADMIN', true);
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '256M');
define('DISALLOW_FILE_EDIT', true);

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF
    
    chmod 640 wp-config.php
    
    # 使用WP-CLI安装WordPress
    log_info "配置 WordPress..."
    /usr/local/bin/wp core install \
        --url="https://${MAIN_DOMAIN}" \
        --title="${MAIN_DOMAIN}" \
        --admin_user="${ADMIN_USER}" \
        --admin_password="${ADMIN_PASSWORD}" \
        --admin_email="${EMAIL}" \
        --skip-email \
        --allow-root 2>> "$INSTALL_LOG"
    
    if [ $? -ne 0 ]; then
        log_warning "使用备选用户名重试..."
        ADMIN_USER="${DOMAIN_ROOT}1"
        /usr/local/bin/wp core install \
            --url="https://${MAIN_DOMAIN}" \
            --title="${MAIN_DOMAIN}" \
            --admin_user="${ADMIN_USER}" \
            --admin_password="${ADMIN_PASSWORD}" \
            --admin_email="${EMAIL}" \
            --skip-email \
            --allow-root 2>> "$INSTALL_LOG"
    fi
    
    # 设置固定链接
    /usr/local/bin/wp rewrite structure '/%postname%/' --hard --allow-root 2>> "$INSTALL_LOG"
    
    # 最后统一设置文件权限 (修复可能因root运行WP-CLI导致的权限问题)
    log_info "设置文件权限..."
    chown -R www-data:www-data "$WEB_ROOT"
    find "$WEB_ROOT" -type d -exec chmod 755 {} \;
    find "$WEB_ROOT" -type f -exec chmod 644 {} \;
    
    log_success "WordPress 安装完成"
    log_info "管理员用户名: $ADMIN_USER"
    return 0
}
