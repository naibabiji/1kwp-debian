#!/bin/bash

# 模块: 12 - Nginx主配置
# 描述: 配置Nginx主配置文件

configure_nginx() {
    log_step 13 $TOTAL_STEPS "配置Nginx"
    
    # 根据CPU核心数设置worker进程
    local worker_processes=$CPU_CORES
    if [ $worker_processes -gt 2 ]; then
        worker_processes=2
    fi
    
    # 创建优化的Nginx主配置
    cat > /etc/nginx/nginx.conf <<EOF
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
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
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
    return 0
}
