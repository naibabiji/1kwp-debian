#!/bin/bash

# 模块: 14 - Nginx站点配置
# 描述: 创建WordPress站点的Nginx配置（HTTP-only，Certbot将添加HTTPS）

create_nginx_site_config() {
    log_info "创建 Nginx 站点配置..."
    
    local config_file="/etc/nginx/sites-available/${MAIN_DOMAIN}"
    
    # 构建server_name
    local server_names=""
    for domain in "${DOMAINS[@]}"; do
        server_names="$server_names $domain"
    done
    server_names=$(echo "$server_names" | sed 's/^ //')
    
    # 创建站点配置（初始为HTTP，Certbot将自动添加HTTPS配置）
    cat > "$config_file" <<EOF
# HTTP配置（Certbot将自动添加HTTPS配置和重定向）
server {
    listen 80;
    listen [::]:80;
    server_name ${server_names};
    
    root ${WEB_ROOT};
    index index.php index.html index.htm;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # 禁止访问敏感文件
    location ~* /(\.git|wp-config\.php|wp-config-sample\.php|license\.txt|nginx\.conf|\.htaccess) {
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
