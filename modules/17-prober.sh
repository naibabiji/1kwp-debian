#!/bin/bash

# 模块: 17 - PHP探针安装
# 描述: 下载并安装 x-prober PHP探针，使用随机文件名增强安全性

install_php_prober() {
    log_info "安装 PHP 探针..."
    
    # 生成随机文件名: tz + 8位随机字符
    local random_str=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 8 || echo "$(date +%s | md5sum | head -c 8)")
    PROBER_FILENAME="tz${random_str}.php"
    PROBER_PATH="${WEB_ROOT}/${PROBER_FILENAME}"
    
    log_info "探针文件名: $PROBER_FILENAME"
    
    # 下载 x-prober
    local prober_url="https://github.com/kmvan/x-prober/raw/master/dist/prober.php"
    
    if download_file "$prober_url" "$PROBER_PATH"; then
        # 验证文件是否下载成功
        if [ -f "$PROBER_PATH" ] && [ -s "$PROBER_PATH" ]; then
            # 设置正确权限
            chown www-data:www-data "$PROBER_PATH"
            chmod 644 "$PROBER_PATH"
            
            log_success "PHP探针安装成功"
            log_info "探针地址: https://${MAIN_DOMAIN}/${PROBER_FILENAME}"
            return 0
        else
            log_warning "探针文件下载可能不完整"
            rm -f "$PROBER_PATH" 2>/dev/null
            PROBER_FILENAME=""
            PROBER_PATH=""
            return 1
        fi
    else
        log_warning "PHP探针下载失败，将跳过探针安装"
        PROBER_FILENAME=""
        PROBER_PATH=""
        return 1
    fi
}
