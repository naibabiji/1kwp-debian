#!/bin/bash

# 模块: 10 - 数据库创建
# 描述: 创建WordPress数据库和用户

create_wordpress_database() {
    log_step 11 $TOTAL_STEPS "创建WordPress数据库"
    
    # 生成随机数据库信息
    DB_NAME="wp_$(generate_random_password 8 | tr -dc 'a-z0-9')"
    DB_USER="wp_user_$(generate_random_password 8 | tr -dc 'a-z0-9')"
    DB_PASSWORD=$(generate_random_password 16)
    
    log_info "创建数据库: $DB_NAME"
    log_info "创建用户: $DB_USER"
    
    # 创建数据库和用户
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF 2>> "$INSTALL_LOG"
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
    return 0
}
