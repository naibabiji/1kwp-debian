#!/bin/bash

# ============================================
# 打包脚本 - 创建发布包
# ============================================

VERSION="2.0.0"
PACKAGE_NAME="wordpress-installer-v${VERSION}.tar.gz"

echo "📦 开始打包 WordPress 安装脚本..."
echo "版本: $VERSION"
echo ""

# 确保在正确的目录
cd "$(dirname "$0")/.." || exit 1

# 创建发布包
tar -czf "$PACKAGE_NAME" \
    --exclude=".git" \
    --exclude="*.log" \
    --exclude="*.tar.gz" \
    install.sh \
    config.sh \
    lib/ \
    modules/ \
    templates/ \
    scripts/ \
    README.md

if [ $? -eq 0 ]; then
    echo "✅ 打包完成: $PACKAGE_NAME"
    echo ""
    echo "文件大小: $(du -h "$PACKAGE_NAME" | cut -f1)"
    echo ""
    echo "📤 发布步骤:"
    echo "1. 创建 GitHub Release"
    echo "2. 上传 $PACKAGE_NAME"
    echo "3. 更新 README.md 中的下载链接"
else
    echo "❌ 打包失败"
    exit 1
fi
