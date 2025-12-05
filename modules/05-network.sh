#!/bin/bash

# 模块: 05 - 网络配置
# 描述: 获取服务器IP和检查DNS解析

get_server_ip() {
    log_step 5 $TOTAL_STEPS "获取服务器公网IP"
    
    local ip=""
    local ip_sources=(
        "https://api.ipify.org"
        "https://icanhazip.com"
        "https://checkip.amazonaws.com"
    )
    
    for source in "${ip_sources[@]}"; do
        log_info "尝试从 $source 获取IP..."
        ip=$(download_file "$source" "-")
        ip=$(echo "$ip" | tr -d '[:space:]')
        
        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            SERVER_IP="$ip"
            log_success "服务器公网IP: $SERVER_IP"
            return 0
        fi
        sleep 1
    done
    
    # 如果上面的API都失败了，尝试从网络接口获取
    ip=$(ip addr show 2>/dev/null | grep -E 'inet (172|192|10)' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d/ -f1)
    if [[ -n "$ip" ]]; then
        SERVER_IP="$ip"
        log_warning "使用本地IP: $SERVER_IP (可能不是公网IP)"
        return 0
    fi
    
    log_error "无法获取服务器IP地址，但将继续安装"
    SERVER_IP="未知"
    return 0
}

check_dns_resolution() {
    log_step 6 $TOTAL_STEPS "检查域名解析"
    
    local unresolved_domains=()
    local resolved_ip=""
    
    log_info "正在检查 ${#DOMAINS[@]} 个域名的解析..."
    
    for domain in "${DOMAINS[@]}"; do
        log_info "检查域名: $domain"
        resolved_ip=$(resolve_domain "$domain")
        
        if [ -z "$resolved_ip" ]; then
            unresolved_domains+=("$domain (无DNS记录)")
            log_warning "$domain → 无DNS记录"
        elif [ "$SERVER_IP" != "未知" ] && [ "$resolved_ip" != "$SERVER_IP" ]; then
            unresolved_domains+=("$domain → $resolved_ip")
            log_warning "$domain → $resolved_ip (非本服务器IP: $SERVER_IP)"
        else
            log_success "$domain 解析正确: $resolved_ip"
        fi
    done
    
    if [ ${#unresolved_domains[@]} -gt 0 ]; then
        log_error "以下域名解析有问题:"
        for domain_info in "${unresolved_domains[@]}"; do
            echo "  ❌ $domain_info"
        done
        
        if [ ${#DOMAINS[@]} -eq ${#unresolved_domains[@]} ]; then
            log_error "所有域名均未解析，脚本停止"
            return 1
        else
            log_warning "部分域名解析有问题，但将继续安装"
            return 0
        fi
    fi
    
    log_success "域名解析检查完成"
    return 0
}
