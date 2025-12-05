#!/bin/bash

# 模块: 16 - 安装后优化
# 描述: 执行安装后的优化和信息保存

post_install_optimization() {
    log_info "执行安装后优化..."
    
    # 配置日志轮转
    log_info "配置日志轮转..."
    cat > /etc/logrotate.d/nginx-wordpress <<EOF
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
    
    # 清理APT缓存
    log_info "清理APT缓存..."
    apt-get clean >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    
    log_success "安装后优化完成"
    return 0
}

save_installation_info() {
    log_info "保存安装信息..."
    
    local info_file="/root/${MAIN_DOMAIN}_installation_info.txt"
    local install_end_time=$(date +%s)
    local install_duration=$((install_end_time - INSTALL_START_TIME))
    local minutes=$((install_duration / 60))
    local seconds=$((install_duration % 60))
    
    cat > "$info_file" <<EOF
========================================
WordPress 一键安装信息
========================================
安装时间: $(date)
安装耗时: ${minutes}分${seconds}秒
主域名: ${MAIN_DOMAIN}
所有域名: ${DOMAINS[*]}

=== WordPress 信息 ===
网站地址: https://${MAIN_DOMAIN}
后台地址: https://${MAIN_DOMAIN}/wp-admin
管理员账号: ${ADMIN_USER}
管理员密码: ${ADMIN_PASSWORD}
管理员邮箱: ${EMAIL}

=== 数据库信息 ===
数据库名: ${DB_NAME}
数据库用户: ${DB_USER}
数据库密码: ${DB_PASSWORD}
MariaDB Root密码: ${MYSQL_ROOT_PASSWORD}

=== 服务器信息 ===
服务器IP: ${SERVER_IP}
CPU核心: ${CPU_CORES}
总内存: ${TOTAL_MEM_GB}GB

安装日志: ${INSTALL_LOG}

=== PHP探针信息 ===
探针地址: https://${MAIN_DOMAIN}/${PROBER_FILENAME:-未安装}
探针文件: ${PROBER_PATH:-未安装}
⚠️ 安全提示: 探针会暴露服务器信息，不使用时请删除
  删除命令: rm -f ${PROBER_PATH:-/path/to/prober.php}
========================================
EOF
    
    chmod 600 "$info_file"
    log_success "安装信息已保存到: $info_file"
    
    return 0
}

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
    echo "💡 提示：管理员账号为域名主体 \"${DOMAIN_ROOT}\""
    echo ""
    echo "⏱️ 安装耗时: ${minutes}分${seconds}秒"
    echo "================================================"
    echo ""
    echo "📄 完整安装信息已保存到: /root/${MAIN_DOMAIN}_installation_info.txt"
    echo ""
    
    # 显示探针信息（如果已安装）
    if [ -n "$PROBER_FILENAME" ] && [ -f "$PROBER_PATH" ]; then
        echo "=== 🔍 PHP探针 ==="
        echo "📊 探针地址: https://${MAIN_DOMAIN}/${PROBER_FILENAME}"
        echo "⚠️  安全提示: 不使用时请删除探针文件"
        echo "   删除命令: rm -f ${PROBER_PATH}"
        echo ""
    fi
}
