#!/bin/bash

# 模块: 15 - SSL证书申请
# 描述: 使用Certbot申请Let's Encrypt SSL证书

request_ssl_certificate() {
    log_step 15 $TOTAL_STEPS "申请SSL证书"
    
    # 构建域名参数
    local certbot_domains=""
    for domain in "${DOMAINS[@]}"; do
        certbot_domains="$certbot_domains -d $domain"
    done
    
    # 尝试申请证书
    log_info "运行: certbot --nginx --agree-tos --email $EMAIL $certbot_domains"
    
    if certbot --nginx --agree-tos --no-eff-email --email "$EMAIL" $certbot_domains --non-interactive --redirect 2>> "$INSTALL_LOG"; then
        log_success "SSL 证书申请成功"
        return 0
    else
        log_warning "SSL 证书申请失败，网站将以HTTP运行"
        log_info "您可以稍后手动运行: certbot --nginx"
        return 1
    fi
}
