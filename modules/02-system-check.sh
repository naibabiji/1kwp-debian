#!/bin/bash

# 模块: 02 - 系统检查
# 描述: 检查操作系统版本和权限

check_system() {
    log_step 2 $TOTAL_STEPS "检查系统环境"
    
    # 检查是否为Debian 12
    if ! grep -q "Debian GNU/Linux 12" /etc/os-release 2>/dev/null; then
        log_error "此脚本仅支持 Debian 12 系统"
        echo "检测到的系统信息:"
        cat /etc/os-release 2>/dev/null || echo "无法读取系统信息"
        return 1
    fi
    
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then 
        log_error "请使用 root 用户运行此脚本"
        return 1
    fi
    
    log_success "系统检查通过: Debian 12, Root权限"
    return 0
}
