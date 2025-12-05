#!/bin/bash

# 模块: 04 - Swap空间配置
# 描述: 为低内存VPS创建Swap空间

create_swap() {
    log_step 4 $TOTAL_STEPS "配置Swap空间"
    
    local swap_size_mb=$1
    local swap_file="/swapfile"
    
    # 检查是否已存在swap
    if swapon --show 2>/dev/null | grep -q "/swap"; then
        log_info "系统已存在Swap，跳过创建"
        return 0
    fi
    
    # 检查内存是否小于1.5GB
    if [ "$TOTAL_MEM_KB" -ge 1572864 ]; then  # 1.5GB = 1572864 KB
        log_info "内存充足(${TOTAL_MEM_GB}GB)，无需创建Swap"
        return 0
    fi
    
    log_info "创建 ${swap_size_mb}MB Swap 空间..."
    
    # 创建swap文件
    if ! fallocate -l ${swap_size_mb}M "$swap_file" 2>/dev/null; then
        # fallocate可能不支持，使用dd
        dd if=/dev/zero of="$swap_file" bs=1M count=$swap_size_mb 2>> "$INSTALL_LOG"
    fi
    
    chmod 600 "$swap_file"
    mkswap "$swap_file" >> "$INSTALL_LOG" 2>&1
    swapon "$swap_file"
    
    # 添加到fstab永久生效
    if ! grep -q "$swap_file" /etc/fstab; then
        echo "$swap_file none swap sw 0 0" >> /etc/fstab
    fi
    
    # 调整swappiness
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
    fi
    
    log_success "Swap 空间创建完成 (${swap_size_mb}MB)"
    return 0
}
