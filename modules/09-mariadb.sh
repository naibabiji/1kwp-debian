#!/bin/bash

# 模块: 09 - MariaDB配置
# 描述: 配置MariaDB安全设置和性能优化

configure_mariadb() {
    log_step 10 $TOTAL_STEPS "配置MariaDB"
    
    # 生成随机root密码
    MYSQL_ROOT_PASSWORD=$(generate_random_password 16)
    
    log_info "配置MariaDB安全设置..."
    
    # 停止MariaDB服务以进行安全配置
    systemctl stop mariadb 2>/dev/null || true
    
    # 创建安全配置SQL
    cat > /tmp/mysql_secure_install.sql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    # 启动MariaDB并应用安全配置
    systemctl start mariadb
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
    cat > /etc/mysql/mariadb.conf.d/60-wordpress-optimization.cnf <<EOF
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
