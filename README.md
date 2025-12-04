当然需要更新！以下是更新后的完整说明文档，所有链接和安装命令都已更正为你的实际 GitHub 地址：

# 1kwp-debian - Debian 12 一键 WordPress 安装脚本

🚀 **一行命令，为 Debian 12 服务器自动完成 WordPress 全环境安装**

**项目地址**：https://github.com/naibabiji/1kwp-debian

## ✨ 项目简介

`1kwp-debian` 是一个针对 **Debian 12 (Bookworm)** 系统的高度自动化 WordPress 安装脚本。它专为 VPS 新手设计，旨在通过最简单的操作（复制 → 粘贴 → 回车），在 5-10 分钟内将一个全新的 Debian 12 服务器转变为功能完整、安全优化的 WordPress 网站。

> 💡 **脚本理念**：将复杂的环境配置抽象为一行命令，让用户专注于网站内容，而非服务器运维。

## 🎯 核心功能

### 🔧 全自动环境部署
- **Web 服务器**：自动安装并配置 Nginx（含 HTTP/2、Gzip 优化）
- **编程语言**：安装 WordPress 官方推荐的 **PHP 8.3** 及所有必要扩展
- **数据库**：配置 MariaDB（Debian 12 官方版本），自动创建数据库和用户
- **安全传输**：自动申请并配置 Let's Encrypt SSL 证书，强制 HTTPS

### 🛡️ 智能安全检查与优化
- **DNS 预检**：安装前验证所有域名是否已解析到服务器，避免中途失败
- **资源检测**：自动识别服务器内存，1GB 小内存 VPS 专用优化（自动创建 Swap、限制进程数）
- **安全加固**：随机生成高强度数据库密码、管理员密码，保护敏感配置文件

### 👤 人性化设计
- **域名主体管理员**：自动提取域名主体作为管理员用户名（如 `github.com` → 账号：`github`），安全且易记
- **纯净系统兼容**：自动检测并安装缺失的基础工具（如 `curl`、`dig` 等）
- **完整日志**：详细安装日志 (`/tmp/wp-install-*.log`) 便于故障排查
- **信息摘要**：安装后清晰显示所有访问凭据和配置详情

## 🚀 快速开始

### 基本要求
- **操作系统**：纯净的 Debian 12 (Bookworm) 系统
- **权限**：Root 用户权限
- **硬件**：至少 1 核 CPU，1GB 内存，10GB 硬盘空间（推荐 2GB 内存以上）
- **网络**：域名已指向服务器 IP（脚本会严格检查）

### 安装命令
```bash
# 使用 curl（推荐）
bash <(curl -s https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/1kwp-debian.sh) 你的邮箱 你的主域名 [其他域名...]

# 使用 wget
bash <(wget -qO- https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/1kwp-debian.sh) 你的邮箱 你的主域名 [其他域名...]
```

### 使用示例
```bash
# 单域名安装（管理员账号：example）
bash <(curl -s https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/1kwp-debian.sh) admin@example.com example.com

# 多域名安装（绑定主域名和 www）
bash <(curl -s https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/1kwp-debian.sh) admin@example.com example.com www.example.com

# 复杂域名安装（绑定多个子域名）
bash <(curl -s https://raw.githubusercontent.com/naibabiji/1kwp-debian/main/1kwp-debian.sh) admin@company.com company.com www.company.com shop.company.com blog.company.com
```

## ⚙️ 参数说明

| 参数位置 | 说明 | 示例 |
|---------|------|------|
| 第 1 个 | **邮箱地址** (必须) - 用于 SSL 证书通知 | `your-email@example.com` |
| 第 2 个 | **主域名** (必须) - 网站主要访问地址，其主体将作为管理员账号 | `yourdomain.com` |
| 第 3-N 个 | **附加域名** (可选) - 需要绑定的其他域名，用空格分隔 | `www.yourdomain.com` `shop.yourdomain.com` |

## 📋 系统要求详解

### ✅ 完全支持
- **操作系统**：Debian 12 "Bookworm" (仅此版本)
- **权限**：Root 用户执行
- **内存**：1GB+ (1GB 内存会自动优化，2GB+ 体验更佳)
- **硬盘**：10GB+ 可用空间 (安装约需 6GB)
- **网络**：80/443 端口开放，域名解析已生效

### ❌ 不支持
- Ubuntu、CentOS、其他 Linux 发行版
- 非 Root 用户
- 内存低于 1GB 的服务器
- 无域名或域名未解析的情况

## 🔄 安装流程概述

1.  **参数验证** → 检查邮箱格式、域名去重
2.  **系统检测** → 确认 Debian 12 和 Root 权限
3.  **依赖安装** → 自动安装 `curl`、`dig` 等缺失工具
4.  **资源检测** → 检查内存、磁盘空间，决定优化策略
5.  **DNS 验证** → **关键步骤**：严格检查每个域名的解析情况
6.  **环境安装** → 安装 Nginx、PHP 8.3、MariaDB、Certbot
7.  **服务配置** → 根据内存大小优化 PHP-FPM、MariaDB 配置
8.  **WordPress 安装** → 下载核心、配置数据库、设置管理员（使用域名主体作为用户名）
9.  **SSL 配置** → 自动申请 Let's Encrypt 证书
10. **收尾工作** → 保存安装信息、显示访问凭据

## 📊 性能优化策略

脚本根据检测到的内存大小自动应用不同优化配置：

| 配置项 | 小内存模式 (<2GB) | 标准模式 (≥2GB) |
|--------|-------------------|-----------------|
| **PHP-FPM 子进程** | 最大 5 个 | 最大 10 个 |
| **MariaDB 缓冲池** | 64MB | 256MB |
| **数据库最大连接** | 30 | 100 |
| **Swap 空间** | 自动创建 2GB (内存<1.5GB时) | 不创建 |

## 📁 安装后生成的文件

```
/root/你的域名_installation_info.txt          # 完整安装信息（密码等敏感数据）
/var/www/你的域名/installation-info.html      # 网页版简要信息（登录后请删除）
/tmp/wp-install-YYYYMMDD-HHMMSS.log           # 详细安装日志
```

## 🛠️ 技术栈版本

| 组件 | 版本 | 备注 |
|------|------|------|
| **操作系统** | Debian 12 (Bookworm) | 唯一支持的系统 |
| **PHP** | 8.3.x | WordPress 官方推荐版本 |
| **数据库** | MariaDB 10.11.x | Debian 12 官方仓库 LTS 版本 |
| **Web 服务器** | Nginx 1.22.x | 稳定版本，性能优化 |
| **WordPress** | 最新稳定版 | 安装时从官网下载 |

## ❓ 常见问题

### Q: 为什么脚本执行到 DNS 检查就停止了？
**A**: 脚本在安装前会严格检查每个域名是否已解析到当前服务器 IP。这是为了避免安装到一半才发现网站无法访问。请确保所有域名都已添加 A 记录指向服务器 IP，并等待 DNS 生效（通常 5-60 分钟）。

### Q: 1GB 内存的 VPS 能流畅运行吗？
**A**: 可以。脚本会针对小内存 VPS 自动优化：创建 2GB Swap 空间、限制 PHP 和数据库进程数、调整缓存大小。适合个人博客或小型网站。

### Q: 管理员账号为什么是域名主体？
**A**: 这是脚本的安全易用设计：`github.com` → 账号 `github`。相比默认的 `admin` 更安全（避免广谱攻击），又比完全随机的用户名更容易记忆。

### Q: 安装失败怎么办？
**A**: 检查 `/tmp/wp-install-*.log` 日志文件，里面记录了每个步骤的详细输出。常见原因：DNS 未解析、磁盘空间不足、网络连接问题。

### Q: 如何安装到其他系统（如 Ubuntu）？
**A**: 本脚本**仅支持 Debian 12**。这是为了保证配置的稳定性和可靠性。其他系统请使用专门的脚本。

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献与支持

欢迎提交 Issue 和 Pull Request！

1.  **问题反馈**：请附带安装日志 (`/tmp/wp-install-*.log`)
2.  **功能建议**：详细描述使用场景和期望行为
3.  **代码贡献**：遵循现有代码风格，添加相应注释

---

**让 WordPress 部署变得简单** - 专注于你的内容，服务器配置交给我们。

---
