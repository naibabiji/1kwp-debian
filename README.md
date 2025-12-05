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
- ✨ **PHP探针** - 自动安装x-prober，随机文件名增强安全


## 📋 系统要求

- **操作系统**: Debian 12 (Bookworm)
- **权限**: Root 用户
- **内存**: 最低 512MB (推荐 1GB+)
- **磁盘**: 最低 7GB 可用空间
- **网络**: 公网IP + 域名解析

## 🚀 快速安装

### 方法一：一键命令（推荐小白用户）

只需复制下面的命令，粘贴到服务器终端，按回车即可开始安装。

**⚠️ 使用前请修改命令中的两个地方：**
- `your@email.com` → 换成你的邮箱（用于SSL证书通知）
- `yourdomain.com` → 换成你的域名

**📋 完整命令：**

```bash
apt-get update -y && apt-get install -y curl bash && curl -fsSL https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/install.sh | bash -s -- your@email.com yourdomain.com
```

**📝 实际示例（直接复制可用）：**

假设你的邮箱是 `admin@vps17.com`，域名是 `vps17.com`：

```bash
apt-get update -y && apt-get install -y curl bash && curl -fsSL https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/install.sh | bash -s -- admin@vps17.com vps17.com
```

### 多域名安装

域名之间用空格隔开，可以添加多个。

**📌 场景1：主域名 + www（最常用）**

同时绑定 `example.com` 和 `www.example.com`：

```bash
apt-get update -y && apt-get install -y curl bash && curl -fsSL https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/install.sh | bash -s -- admin@example.com example.com www.example.com
```

**📌 场景2：添加子域名**

添加子域名如 `blog.example.com`、`shop.example.com`：

```bash
apt-get update -y && apt-get install -y curl bash && curl -fsSL https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/install.sh | bash -s -- admin@example.com example.com www.example.com blog.example.com
```

**📌 场景3：多个子域名**

一次性添加多个子域名：

```bash
apt-get update -y && apt-get install -y curl bash && curl -fsSL https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/install.sh | bash -s -- admin@example.com example.com www.example.com blog.example.com shop.example.com api.example.com
```

> 💡 **提示**：请确保所有域名都已解析到你的服务器IP地址，否则SSL证书申请会失败。

---

### 方法二：克隆仓库（适合开发者）

**第一步：克隆仓库**
```bash
git clone https://github.com/naibabiji/1kwp-debian.git
cd 1kwp-debian
```

**第二步：运行安装脚本**
```bash
chmod +x install.sh
./install.sh your@email.com yourdomain.com
```

##  项目结构

```
1kwp-debian/
├── install.sh          # 主安装脚本
├── config.sh          # 配置文件
├── lib/               # 公共库
│   ├── common.sh     # 公共函数
│   └── validation.sh # 验证函数
├── modules/          # 功能模块（17个）
│   ├── 01-dependencies.sh
│   ├── 02-system-check.sh
│   ├── ...
│   ├── 16-optimize.sh
│   └── 17-prober.sh   # PHP探针安装
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
15. ✅ 安装 PHP 探针
16. ✅ 申请 SSL 证书
17. ✅ 安装后优化

## 📝 安装后

安装完成后，您将获得：

- **网站地址**: https://yourdomain.com
- **后台地址**: https://yourdomain.com/wp-admin
- **管理员账号**: 域名主体（如 vps17）
- **管理员密码**: 随机生成（保存在 `/root/域名_installation_info.txt`）
- **PHP探针**: https://yourdomain.com/tz随机字符.php

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
| **PHP探针** | 探针文件 | `/var/www/yourdomain.com/tz*.php` |
| **安装信息** | 账号密码 | `/root/yourdomain.com_installation_info.txt` |

## 🔍 PHP探针 (x-prober)

安装脚本会自动部署 [x-prober](https://github.com/kmvan/x-prober) PHP探针，方便查看服务器状态。

### 访问方式

探针地址格式：`https://yourdomain.com/tz随机字符.php`

具体地址保存在 `/root/yourdomain.com_installation_info.txt` 文件中。

### ⚠️ 安全警告

> **探针会暴露服务器敏感信息**（PHP版本、扩展列表、系统配置等），可能被攻击者利用！

**建议**：查看完服务器信息后，立即删除探针文件：

```bash
# 查看探针文件名（在安装信息文件中）
grep "探针" /root/yourdomain.com_installation_info.txt

# 删除探针文件
rm -f /var/www/yourdomain.com/tz*.php
```

### 防护措施

本脚本采用以下安全措施：
- 使用随机文件名（`tz` + 8位随机字符），难以被猜测
- 探针地址仅保存在权限为600的root专属文件中

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
