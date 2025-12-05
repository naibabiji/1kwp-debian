# 1kwp-debian

一键在 Debian 12 上安装 WordPress + Nginx + MariaDB + PHP 8.3 + SSL 的自动化脚本。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian 12](https://img.shields.io/badge/Debian-12-red.svg)](https://www.debian.org/)
[![PHP 8.3](https://img.shields.io/badge/PHP-8.3-blue.svg)](https://www.php.net/)

## ✨ 特点

- 🚀 **一键安装** - 全自动化安装流程
- 🔐 **自动SSL** - Let's Encrypt 证书自动申请和配置
- 👤 **智能账号** - 域名主体作为管理员账号（vps17.com → vps17）
- ⚡ **PHP 8.3** - WordPress 官方推荐版本
- 💾 **内存优化** - 自动检测并优化低内存VPS
- 📦 **模块化** - 易于维护和扩展
- 🐛 **Bug修复** - 修复磁盘检测、域名验证、Nginx配置等问题

## 📋 系统要求

- **操作系统**: Debian 12 (Bookworm)
- **权限**: Root 用户
- **内存**: 最低 512MB (推荐 1GB+)
- **磁盘**: 最低 7GB 可用空间
- **网络**: 公网IP + 域名解析

## 🚀 快速安装

### 方法一：克隆仓库

```bash
# 克隆仓库
git clone https://github.com/naibabiji/1kwp-debian.git
cd 1kwp-debian

# 给予执行权限并运行
chmod +x install.sh
./install.sh your@email.com yourdomain.com
```

### 方法二：一键命令

```bash
# 下载并直接运行
apt-get update -y && apt-get install -y curl bash && curl -fsSL https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/install.sh | bash -s -- your@email.com yourdomain.com
```

### 多域名安装

```bash
./install.sh your@email.com domain.com www.domain.com blog.domain.com
```

##  项目结构

```
1kwp-debian/
├── install.sh          # 主安装脚本
├── config.sh          # 配置文件
├── lib/               # 公共库
│   ├── common.sh     # 公共函数
│   └── validation.sh # 验证函数
├── modules/          # 功能模块（16个）
│   ├── 01-dependencies.sh
│   ├── 02-system-check.sh
│   ├── ...
│   └── 16-optimize.sh
└── scripts/          # 辅助脚本
    └── pack.sh      # 打包脚本
```

## 🔧 安装步骤

1. ✅ 检查基础依赖
2. ✅ 验证系统环境
3. ✅ 检测系统资源
4. ✅ 配置 Swap 空间
5. ✅ 检查网络和DNS
6. ✅ 添加 PHP 8.3 仓库
7. ✅ 安装软件包
8. ✅ 安装 WP-CLI
9. ✅ 配置 MariaDB
10. ✅ 创建数据库
11. ✅ 配置 PHP-FPM
12. ✅ 配置 Nginx
13. ✅ 安装 WordPress
14. ✅ 配置站点
15. ✅ 申请 SSL 证书
16. ✅ 安装后优化

## 📝 安装后

安装完成后，您将获得：

- **网站地址**: https://yourdomain.com
- **后台地址**: https://yourdomain.com/wp-admin
- **管理员账号**: 域名主体（如 vps17）
- **管理员密码**: 随机生成（保存在 `/root/域名_installation_info.txt`）

## 软件安装目录与配置

| 软件 | 类型 | 路径 |
|------|------|------|
| **WordPress** | 网站根目录 | `/var/www/yourdomain.com` |
| | 配置文件 | `/var/www/yourdomain.com/wp-config.php` |
| **Nginx** | 主配置 | `/etc/nginx/nginx.conf` |
| | 站点配置 | `/etc/nginx/conf.d/*.conf` |
| | 日志目录 | `/var/log/nginx/` |
| **PHP 8.3** | FPM配置 | `/etc/php/8.3/fpm/pool.d/www.conf` |
| | php.ini | `/etc/php/8.3/fpm/php.ini` |
| **MariaDB** | 配置文件 | `/etc/mysql/mariadb.conf.d/60-wordpress-optimization.cnf` |
| **安装信息** | 账号密码 | `/root/yourdomain.com_installation_info.txt` |

## 🔐 SSL 证书续期

Let's Encrypt 证书有效期为 **90天**，Certbot 会自动设置定时任务进行续期。

### 检查自动续期状态

```bash
# 查看 Certbot 定时任务
systemctl status certbot.timer

# 测试自动续期（不会真正续期）
certbot renew --dry-run
```

### 手动续期证书

如果自动续期失败，可以手动执行：

```bash
# 续期所有证书
certbot renew

# 续期后重载 Nginx
systemctl reload nginx
```

### 强制重新申请证书

如果证书出现问题，可以重新申请：

```bash
# 重新申请证书（替换 yourdomain.com 为实际域名）
certbot --nginx -d yourdomain.com -d www.yourdomain.com --force-renewal

# 或者删除后重新申请
certbot delete --cert-name yourdomain.com
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| 证书续期失败 | 检查域名是否仍解析到本服务器IP |
| 80端口被占用 | 确保续期时80端口可用：`systemctl stop nginx && certbot renew && systemctl start nginx` |
| 定时任务未运行 | 启用定时任务：`systemctl enable --now certbot.timer` |

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## ⚠️ 免责声明

本脚本仅供学习和测试使用，生产环境请自行评估风险。
