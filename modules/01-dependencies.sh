#!/bin/bash

# 模块: 01 - 安装基础依赖
# 描述: 检查并安装必需的系统工具

install_basic_dependencies() {
    log_step 1 $TOTAL_STEPS "检查并安装基础依赖"
    
    # 定义必需工具和对应的包
    declare -A required_tools=(
        ["curl"]="curl"
        ["wget"]="wget"
        ["dig"]="dnsutils"
        ["gzip"]="gzip"
        ["tar"]="tar"
        ["grep"]="grep"
        ["sed"]="sed"
        ["awk"]="gawk"
        ["unzip"]="unzip"
    )
    
    local packages_to_install=()
    
    # 检查每个工具
    for tool in "${!required_tools[@]}"; do
        if ! command_exists "$tool"; then
            local pkg="${required_tools[$tool]}"
            log_warning "未找到工具: $tool，需要安装: $pkg"
            packages_to_install+=("$pkg")
        fi
    done
    
    # 如果有包需要安装
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_info "正在安装缺失的依赖包: ${packages_to_install[*]}"
        
        # 去重
        local unique_packages=($(echo "${packages_to_install[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        
        # 更新包列表并安装
        if ! apt-get update -qq; then
            log_error "更新软件包列表失败"
            return 1
        fi
        
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${unique_packages[@]}"; then
            log_error "安装依赖包失败"
            return 1
        fi
        
        log_success "依赖包安装完成"
    else
        log_success "所有基础依赖已满足"
    fi
    
    return 0
}
