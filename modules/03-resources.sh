#!/bin/bash

# 模块: 03 - 系统资源检测
# 描述: 检测CPU、内存、磁盘空间

get_system_resources() {
    log_step 3 $TOTAL_STEPS "检测系统资源"
    
    # 获取CPU核心数
    CPU_CORES=$(nproc 2>/dev/null || echo 1)
    
    # 获取总内存（KB）
    TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 1048576)
    TOTAL_MEM_GB=$(echo "scale=1; $TOTAL_MEM_KB / 1024 / 1024" | bc 2>/dev/null || echo 1.0)
    
    # 获取可用磁盘空间（GB）
    AVAILABLE_SPACE_GB=$(df -BG / 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo 10)
    
    # 检查磁盘空间（使用整数比较，更可靠）
    AVAILABLE_SPACE_INT=$(echo "$AVAILABLE_SPACE_GB" | awk '{print int($1)}')
    
    if [ "$AVAILABLE_SPACE_INT" -lt 7 ]; then
        log_error "可用磁盘空间不足7GB"
        echo "当前可用: ${AVAILABLE_SPACE_GB}GB"
        return 1
    elif [ "$AVAILABLE_SPACE_INT" -lt 10 ]; then
        log_warning "磁盘空间较少 (${AVAILABLE_SPACE_GB}GB)"
    fi
    
    # 性能优化决策
    if [ "$TOTAL_MEM_KB" -lt 2097152 ]; then  # 2GB
        APPLY_OPTIMIZATION=true
        log_info "检测到内存小于2GB，将应用性能优化配置"
    else
        APPLY_OPTIMIZATION=false
        log_info "内存充足，使用标准配置"
    fi
    
    log_success "系统资源检测完成"
    echo "  CPU核心数: $CPU_CORES"
    echo "  总内存: ${TOTAL_MEM_GB}GB"
    echo "  可用磁盘: ${AVAILABLE_SPACE_GB}GB"
    
    return 0
}
