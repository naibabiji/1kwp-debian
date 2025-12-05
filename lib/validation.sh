#!/bin/bash

# ============================================
# WordPress 一键安装脚本 - 验证函数库
# ============================================

# 验证域名格式（支持包含数字的域名）
validate_domain() {
    local domain="$1"
    
    # 去除可能的协议前缀和路径
    domain=$(echo "$domain" | sed 's|^https://||; s|^http://||; s|/.*$||')
    
    # 域名格式验证（支持包含数字的域名如vps17.com）
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9-]{1,63})*\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

# 验证邮箱格式
validate_email() {
    local email="$1"
    
    if [[ ! "$email" == *"@"* ]]; then
        return 1
    fi
    
    return 0
}

# 解析域名获取IP
resolve_domain() {
    local domain="$1"
    local ip=""
    
    # 优先使用dig
    if command_exists "dig"; then
        ip=$(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
        if [ -n "$ip" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # 使用nslookup
    if command_exists "nslookup"; then
        ip=$(nslookup "$domain" 2>/dev/null | grep 'Address:' | tail -n1 | awk '{print $2}')
        echo "$ip"
    fi
}
