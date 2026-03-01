# 🦐 超轻量级 AI 助手 · OpenWrt 打包工程

[![ZeptoClaw](https://img.shields.io/badge/ZeptoClaw-v0.6.1-blue.svg?style=flat-square)](https://github.com/qhkm/zeptoclaw)
[![openwrt-zeptoclaw](https://img.shields.io/badge/openwrt--zeptoclaw-v0.6.1--r1-green.svg?style=flat-square)](https://github.com/LIKE2000-ART/openwrt-zeptoclaw/releases)
[![License](https://img.shields.io/badge/License-Apache--2.0-orange.svg?style=flat-square)](openwrt-zeptoclaw/Makefile)
[![Build](https://img.shields.io/github/actions/workflow/status/LIKE2000-ART/openwrt-zeptoclaw/auto-compile-openwrt-sdk.yml?style=flat-square&label=CI)](https://github.com/LIKE2000-ART/openwrt-zeptoclaw/actions)

> [!CAUTION]
> **🚧 项目状态：实验性 / 打包工程初作 🚧**
>
> 本项目是作者针对 OpenWrt 交叉编译流程的实践仓库，代码主要围绕打包、CI、版本同步脚本展开。
> 项目尚处于 **早期实验阶段**，可能存在未发现的 Bug、构建兼容性问题或运行差异。
> **请勿将本项目用于任何生产环境或关键业务场景！**
> 使用本项目所产生的一切后果，由使用者自行承担。
>
> **🤖 自动化生成与脚本声明**
>
> 本项目（包括 Makefile、init 脚本、GitHub Actions 工作流、版本同步脚本等）
> 在开发过程中使用了 AI 辅助生成和人工校对。
> 作者在此基础上进行了人工审查、调整和测试，但 **无法保证代码完全没有缺陷或安全漏洞**。
> 如果你在意路由器的安全性和稳定性，请在充分理解代码的前提下使用，或等待项目更加成熟后再考虑部署。

---

## 📖 项目简介

> **自研声明**：本项目为个人兴趣驱动的 **第三方社区作品**，与 ZeptoClaw 官方无关。
> 仅对 ZeptoClaw 的 OpenWrt 打包和自动构建流程进行尝试性开发，不代表上游官方立场或质量标准。

本项目为 [ZeptoClaw](https://github.com/qhkm/zeptoclaw) 提供**尝试性的** **OpenWrt IPK/APK 打包编译** 支持，让你可以：

- ✅ 在 OpenWrt 路由器上一键安装部署 ZeptoClaw
- ✅ 通过 UCI + procd 管理 ZeptoClaw 服务
- ✅ 使用 GitHub Actions 自动同步上游版本
- ✅ 自动构建多架构 OpenWrt 软件包并发布到 Releases
- ✅ 复用 OpenWrt SDK 工作流进行跨平台编译

### 什么是 ZeptoClaw？

ZeptoClaw 是一个超轻量级个人 AI 助手，面向资源受限设备和终端场景：

| 特性 | 说明 |
| ------ | ------ |
| 🪶 **轻量运行** | 面向低资源设备的运行设计 |
| 🌍 **多架构** | 可在 ARM / x86 / MIPS 等平台构建 |
| ⚡ **命令行优先** | 以 CLI 和网关模式为核心 |
| 🔧 **可集成** | 适合接入 OpenWrt 的服务管理体系 |

> 🔗 ZeptoClaw 官方仓库：<https://github.com/qhkm/zeptoclaw>

---

## 📦 包含内容

本项目包含一个 OpenWrt 软件包：

### 1. `openwrt-zeptoclaw` — 核心二进制包

| 文件 | 说明 |
| ------ | ------ |
| `openwrt-zeptoclaw/Makefile` | OpenWrt Rust 交叉编译配置，自动从 GitHub 拉取源码并编译 |
| `openwrt-zeptoclaw/files/zeptoclaw.init` | procd init.d 启动脚本，支持 `zeptoclaw gateway` 守护进程模式 |
| `openwrt-zeptoclaw/files/zeptoclaw.config` | UCI 默认配置（enabled/mode/workdir/args） |
| `openwrt-zeptoclaw/sync-zeptoclaw-version.sh` | 自动检测上游 release 并更新 `PKG_VERSION` + `PKG_MIRROR_HASH` |
| `openwrt-zeptoclaw/patches/100-portable-atomic-u64-for-mips.patch` | MIPS 架构 `AtomicU64` 兼容补丁（portable-atomic） |

---

## 📁 目录结构

```text
.
├── openwrt-zeptoclaw/                      # 核心二进制包
│   ├── Makefile                            # OpenWrt Rust 交叉编译 Makefile
│   ├── patches/                            # OpenWrt 源码补丁目录
│   ├── sync-zeptoclaw-version.sh           # 上游版本同步脚本
│   └── files/
│       ├── zeptoclaw.config                # UCI 默认配置
│       └── zeptoclaw.init                  # procd init.d 启动脚本
│
├── .github/
│   ├── dependabot.yml                      # Dependabot 配置
│   └── workflows/
│       ├── auto-compile-openwrt-sdk.yml    # 多架构自动构建并发布
│       ├── dependency-audit.yml            # 依赖审计（手动触发，可选上传产物）
│       └── version-check.yml               # 定时版本检查与自动提 PR
│
└── README.md                               # 本说明文件
```

---

## 🛠️ 编译安装

### 前提条件

- OpenWrt SDK 或完整的 OpenWrt 源码编译环境
- 已安装 `feeds/packages/lang/rust`（Rust 交叉编译器）
- 可访问 GitHub（用于拉取上游源码与 release 元数据）

> [!IMPORTANT]
> **Rust 工具链说明**：ZeptoClaw 使用 Rust 构建，依赖 OpenWrt `lang/rust`。
> 若你的 SDK 工具链较旧，可能需要先更新 feeds 中的 Rust 包。
> 通过 GitHub Actions CI 构建时，工作流会在 SDK 环境中完成依赖准备。

### 方法一：通过 feeds 安装（推荐）

#### 1. 添加源

编辑 OpenWrt 源码根目录下的 `feeds.conf`（或 `feeds.conf.default`），添加：

```bash
src-link zeptoclaw /path/to/openwrt-zeptoclaw
```

#### 2. 更新并安装

```bash
# 更新 feeds
scripts/feeds update zeptoclaw

# 安装 openwrt-zeptoclaw 包
scripts/feeds install -p zeptoclaw openwrt-zeptoclaw
```

#### 3. 配置编译选项

```bash
make menuconfig
```

在菜单中选择：

- `Utilities` → `<*> openwrt-zeptoclaw`（或 `M`）

#### 4. 编译

```bash
# 编译核心包
make package/openwrt-zeptoclaw/compile V=s
```

### 方法二：直接克隆/拷贝源码

```bash
# 拷贝到 package 目录
cp -r openwrt-zeptoclaw/ <openwrt-source>/package/custom_packages/openwrt-zeptoclaw/

# 配置并编译
make menuconfig
make package/custom_packages/openwrt-zeptoclaw/openwrt-zeptoclaw/compile V=s
```

### 方法三：下载预编译包安装

前往 [Releases](https://github.com/LIKE2000-ART/openwrt-zeptoclaw/releases) 下载对应架构包，安装：

```bash
# OpenWrt 24.10+（apk 格式）
apk add --allow-untrusted openwrt-zeptoclaw*.apk

# OpenWrt 23.05 及更早（ipk 格式）
opkg install openwrt-zeptoclaw_*.ipk
```

---

## ⚙️ 配置说明

### UCI 配置 (`/etc/config/zeptoclaw`)

安装后会自动生成 UCI 配置文件，默认配置如下：

```ini
config zeptoclaw 'main'
        option enabled '0'              # 是否启用服务（0=关闭，1=启用）
        option mode 'gateway'           # 启动模式（默认 gateway）
        option workdir '/root/.zeptoclaw'  # 工作目录
        option args ''                  # 额外命令参数
        option rust_log 'info'          # RUST_LOG 日志级别
        option env_file '/etc/zeptoclaw/env' # 环境变量文件
        option respawn_sec '5'          # 崩溃后重启间隔（秒）
```

### `/etc/zeptoclaw` 统一入口

- `/etc/zeptoclaw/env`：可写入 `KEY=VALUE`，服务启动时自动加载（适合 LuCI 传参）。
- `/etc/zeptoclaw/config.json`：由 init 维护为软链接，指向实际工作目录中的 `config.json`。
- 当 `workdir` 设为非默认路径（如 `/opt/.zeptoclaw`）时，init 会自动维护 `/root/.zeptoclaw -> <workdir>`，保证服务与手动 CLI 路径一致。

### 服务管理

```bash
# 启用服务
uci set zeptoclaw.main.enabled='1'
uci commit zeptoclaw

# 开机启动并立即启动
/etc/init.d/zeptoclaw enable
/etc/init.d/zeptoclaw start
```

---

## 📂 工作目录结构

ZeptoClaw 运行时会在工作目录（默认 `/root/.zeptoclaw`）下生成运行数据：

```text
/root/.zeptoclaw/
├── sessions/                 # 会话数据
├── memory/                   # 记忆与状态数据
├── state/                    # 持久化状态
└── ...                       # 由上游程序按需创建
```

---

## 🔧 常用命令

```bash
# 启用/禁用服务
uci set zeptoclaw.main.enabled='1'
uci commit zeptoclaw
/etc/init.d/zeptoclaw restart

# 查看服务状态
/etc/init.d/zeptoclaw status

# 查看版本
zeptoclaw --version

# 查看帮助
zeptoclaw --help

# 网关模式运行（手动）
zeptoclaw gateway
```

---

## ⚠️ 注意事项与免责声明

> [!IMPORTANT]
> **本项目包含 AI 辅助生成代码与自动化脚本。**
> 虽然已尽力测试，但仍可能存在未知的 Bug 或安全隐患。
> **在路由器等关键网络设备上使用时，请格外谨慎，务必做好备份！**

### 🛡️ 安全警告

- ⚠️ ZeptoClaw 与本打包工程均处于持续迭代阶段，**不建议用于生产环境**
- ⚠️ `args` 可透传启动参数，请避免引入高风险命令组合
- ⚠️ 若网关对外开放，请务必配合防火墙与访问控制
- ⚠️ 请确保你理解 AI Agent 在设备上运行的权限边界

### 📝 其他注意事项

1. **版本策略**：`PKG_VERSION` 由 `sync-zeptoclaw-version.sh` 跟随上游 release 更新。  
2. **源码哈希**：`sync-zeptoclaw-version.sh` 会同步更新 `PKG_MIRROR_HASH`，用于 OpenWrt 下载校验。  
3. **包格式差异**：不同 OpenWrt 分支可能输出 `ipk` 或 `apk`。  
4. **编译依赖**：请确保 SDK 的 `lang/rust` 可用并与目标分支兼容。  
5. **MIPS 兼容**：针对 `mips/mipsel` 架构，包构建阶段会应用 portable-atomic 补丁以解决 `AtomicU64` 不可用问题。  

---

## 🔄 升级方法

```bash
# 同步上游版本
cd openwrt-zeptoclaw
./sync-zeptoclaw-version.sh

# 重新编译
make package/openwrt-zeptoclaw/compile V=s

# 在路由器上升级
opkg install --force-reinstall openwrt-zeptoclaw_*.ipk
# 或
apk add --allow-untrusted --force-overwrite openwrt-zeptoclaw*.apk
```

---

## 📋 版本记录

### 2026.03.01 v0.6.1-r1

- ⬆️ 升级 ZeptoClaw 到 `v0.6.1`
- ✅ 版本同步脚本支持自动更新 `PKG_MIRROR_HASH`
- ✅ 修复源码包 HASH 校验失败问题
- ✅ 增加 MIPS `AtomicU64` portable-atomic 兼容补丁
- ✅ 新增 `dependency-audit.yml`（手动触发依赖审计，可选上传产物）

### 2026.02.27 v0.5.9-r1

- 🎉 首次发布 `openwrt-zeptoclaw` 打包工程
- 新增 ZeptoClaw OpenWrt 交叉编译包定义
- 新增 procd 服务脚本与 UCI 默认配置
- 新增版本同步脚本（上游 release 自动检测）
- 新增 GitHub Actions 多架构自动构建与发布流程

---

## 🙏 鸣谢

- [ZeptoClaw](https://github.com/qhkm/zeptoclaw) — 上游项目
- [openwrt-bandix](https://github.com/timsaya/openwrt-bandix) — OpenWrt 打包与 CI 参考
- [sbwml](https://github.com/sbwml) — openwrt-gh-action-sdk 及工具链维护
- [sirpdboy](https://github.com/sirpdboy) — OpenWrt 插件开发与维护
- [OpenWrt](https://openwrt.org) — 自由的嵌入式 Linux 操作系统

---

## 📜 免责声明

本项目为个人学习和实验性质的开源项目，代码包含 AI 辅助生成与人工调整。

- 本项目与 ZeptoClaw 官方 **无任何关联**，不代表其立场或质量标准
- 代码未经全面安全审计，**不保证安全性、稳定性和可靠性**
- 在路由器等网络基础设施上部署未经充分验证的软件存在风险，**使用者需自行承担一切后果**
- 作者不对因使用本项目导致的设备故障、数据丢失、安全事故等承担任何责任
- 如发现 Bug 或安全问题，欢迎提交 Issue

**简而言之：这是一个围绕 OpenWrt 打包与自动化构建的尝试性作品，请务必在非生产环境下谨慎测试。**

---

## 📞 相关链接

| 链接 | 说明 |
| ------ | ------ |
| [ZeptoClaw 官方仓库](https://github.com/qhkm/zeptoclaw) | ZeptoClaw 源码和文档 |
| [本项目 Releases](https://github.com/LIKE2000-ART/openwrt-zeptoclaw/releases) | 预编译包下载 |
| [OpenWrt 官网](https://openwrt.org) | OpenWrt 文档与固件 |

---
