#!/bin/bash

# ============================================
# WordPress 一键安装脚本 - 公共函数库
# 版本: 2.0 (模块化版本)
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $msg" >> "$INSTALL_LOG"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $msg" >> "$INSTALL_LOG"
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}[WARNING]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $msg" >> "$INSTALL_LOG"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $msg" >> "$INSTALL_LOG"
}

log_step() {
    local step="$1"
    local total="$2"
    local message="$3"
    echo -e "\n${CYAN}=== 步骤 $step/$total: $message ===${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') === 步骤 $step/$total: $message ===" >> "$INSTALL_LOG"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 下载文件（支持curl和wget降级）
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists "curl"; then
        curl -sSL -o "$output" "$url" 2>> "$INSTALL_LOG"
    elif command_exists "wget"; then
        wget -q -O "$output" "$url" 2>> "$INSTALL_LOG"
    else
        log_error "没有可用的下载工具"
        return 1
    fi
    
    return $?
}

# 生成随机密码
generate_random_password() {
    local length="${1:-16}"
    tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom 2>/dev/null | head -c "$length" || echo "Password$RANDOM$RANDOM"
}

# 提取域名主体
extract_domain_root() {
    local domain="$1"
    
    # 移除协议头和路径
    domain=$(echo "$domain" | sed 's|^https://||; s|^http://||; s|/.*$||')
    
    # 移除www.前缀
    domain=$(echo "$domain" | sed 's|^www\.||')
    
    # 提取第一个点之前的部分（域名主体）
    local root=$(echo "$domain" | cut -d. -f1)
    
    # 清理非法字符，只保留字母数字，移除连字符
    root=$(echo "$root" | tr -cd 'a-zA-Z0-9')
    
    # 确保长度至少为3个字符
    if [ ${#root} -lt 3 ]; then
        root="${root}site"
    fi
    
    # 截断到20个字符
    root=$(echo "$root" | cut -c 1-20)
    
    # 转换为小写
    root=$(echo "$root" | tr '[:upper:]' '[:lower:]')
    
    echo "$root"
}
