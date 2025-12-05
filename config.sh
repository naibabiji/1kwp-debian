#!/bin/bash

# ============================================
# WordPress 一键安装脚本 - 配置文件
# 版本: 2.0
# ============================================

# 全局变量
DOMAINS=()
EMAIL=""
MAIN_DOMAIN=""
DOMAIN_ROOT=""  # 域名主体，用作管理员账号
WEB_ROOT=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
MYSQL_ROOT_PASSWORD=""
ADMIN_USER=""
ADMIN_PASSWORD=""
SERVER_IP=""
TOTAL_MEM_KB=0
TOTAL_MEM_GB=0
CPU_CORES=0
AVAILABLE_SPACE_GB=0
APPLY_OPTIMIZATION=false
INSTALL_START_TIME=$(date +%s)
INSTALL_LOG="/tmp/wp-install-$(date +%Y%m%d-%H%M%S).log"
PROBER_FILENAME=""    # PHP探针文件名
PROBER_PATH=""        # PHP探针完整路径

# 安装步骤总数
TOTAL_STEPS=15

# 脚本根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
