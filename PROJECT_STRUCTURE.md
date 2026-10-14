# 项目结构说明

```
linux-2.6.39-ssd-delalloc-fix/
├── README.md                    # 项目主文档（中英文）
├── CHANGELOG.md                 # 版本变更日志
├── LICENSE                      # GPL-2.0 许可证
├── .gitignore                   # Git 忽略文件配置
├── PROJECT_STRUCTURE.md         # 本文件
│
├── patches/                     # 补丁文件目录
│   ├── 0001-ext4-*.patch        # Git 格式补丁（推荐使用）
│   └── ext4-writeback-batch-limit.patch  # 传统格式补丁
│
├── kernel-src/                  # Git 管理的内核源文件
│   ├── fs/ext4/inode.c          # 需要修改的源文件
│   ├── .git/                    # Git 仓库
│   └── README.md                # 补丁生成和维护说明
│
├── docs/                        # 文档目录
│   ├── TECHNICAL.md             # 技术文档（详细原理分析）
│   ├── FAQ.md                   # 常见问题解答
│   ├── CONTRIBUTING.md          # 贡献指南
│   ├── fstab-example            # fstab 配置示例
│   └── sysctl.conf              # sysctl 参数配置示例
│
├── scripts/                     # 脚本工具目录
│   ├── install.sh               # 自动安装脚本
│   ├── verify.sh                # 配置验证脚本
│   └── benchmark.sh             # 性能测试脚本
│
└── tests/                       # 测试相关目录
    └── test_scenarios.md        # 测试场景文档
```

## 文件说明

#### `patches/0001-ext4-*.patch`
- Git 格式的补丁文件（**推荐使用**）
- 包含完整的 commit 信息
- 可用于 `git am` 或 `patch -p1`
- 从 `kernel-src/` 目录生成

#### `patches/ext4-writeback-batch-limit.patch`
- 传统格式补丁
- 修改 `fs/ext4/inode.c`
- 限制 writeback 批次为 1024 页
- 可直接使用 `patch -p1` 应用

### kernel-src 目录

#### `kernel-src/`
**功能：** Git 管理的内核源文件，用于生成和维护补丁

**特性：**
- 只包含需要修改的文件（不是完整内核源码）
- 使用 Git 版本控制
- 保持与内核源码相同的目录结构
- 方便生成标准格式补丁

**内容：**
- `fs/ext4/inode.c` - 需要修改的源文件
- `.git/` - Git 仓库
- `README.md` - 详细使用说明

**使用方法：**
```bash
cd kernel-src
# 查看修改历史
git log

# 修改文件
vim fs/ext4/inode.c

# 提交并生成补丁
git add fs/ext4/inode.c
git commit -m "ext4: Your modification"
git format-patch -1 HEAD -o ../patches/
```

详见 `kernel-src/README.md`

### 核心文件

#### `README.md`
- 项目主文档
- 包含快速开始指南
- 安装步骤详解
- 验证方法

### 补丁文件

#### `docs/TECHNICAL.md`
- 深入的技术分析
- 问题根源剖析
- 解决方案设计
- 性能影响分析
- 与 3.x 内核对比

#### `docs/FAQ.md`
- 35+ 个常见问题
- 涵盖安装、配置、性能、故障排除
- 适合快速查找问题答案

#### `docs/fstab-example`
- `/etc/fstab` 配置示例
- 展示如何添加 `commit=1`

#### `docs/sysctl.conf`
- `/etc/sysctl.d/` 配置文件模板
- 包含所有优化参数
- 带详细注释说明

#### `docs/CONTRIBUTING.md`
- 如何贡献代码
- 代码风格指南
- 提交流程

### 脚本文件

#### `scripts/install.sh`
**功能：** 自动化安装脚本

**特性：**
- 自动检测内核版本
- 备份原始文件
- 应用补丁
- 编译模块
- 更新 initramfs
- 配置 sysctl

**使用：**
```bash
sudo ./scripts/install.sh
```

#### `scripts/verify.sh`
**功能：** 验证配置是否正确

**检查项：**
- ext4 模块版本
- 挂载选项（commit=1）
- delalloc 状态
- sysctl 参数
- 存储设备类型

**使用：**
```bash
./scripts/verify.sh
```

#### `scripts/benchmark.sh`
**功能：** 性能和稳定性测试

**测试内容：**
- 使用 stress-ng 进行 I/O 压力测试
- 检测 D 状态进程
- 检测内核错误
- 记录测试结果

**使用：**
```bash
./scripts/benchmark.sh [workers] [duration]
# 例如：
./scripts/benchmark.sh 3 60  # 3 workers, 60 秒
```

### 测试文件

#### `tests/test_scenarios.md`
- 完整的测试场景列表
- 包括功能测试、性能测试、压力测试
- 提供测试步骤和预期结果
- 测试报告模板

## 使用流程

### 1. 快速开始

```bash
# 克隆项目
git clone https://github.com/your-repo/linux-2.6.39-ssd-delalloc-fix.git
cd linux-2.6.39-ssd-delalloc-fix

# 阅读文档
cat README.md

# 自动安装
sudo ./scripts/install.sh

# 重启系统
sudo reboot

# 验证配置
./scripts/verify.sh

# 运行测试
./scripts/benchmark.sh 3 60
```

### 2. 手动安装

如果自动安装脚本不适用，参考 README.md 的手动安装步骤。

### 3. 故障排除

1. 查看 FAQ.md
2. 运行 verify.sh 检查配置
3. 查看 TECHNICAL.md 了解原理
4. 在 GitHub Issues 提问

## 维护指南

### 更新补丁

如果需要修改补丁：

```bash
# 1. 修改源码
cd /usr/src/linux-2.6.39
vim fs/ext4/inode.c

# 2. 生成新补丁
diff -Naur fs/ext4/inode.c.orig fs/ext4/inode.c > new.patch

# 3. 替换旧补丁
cp new.patch patches/ext4-writeback-batch-limit.patch

# 4. 更新 CHANGELOG.md
```

### 添加新功能

1. 创建分支
2. 修改代码
3. 更新文档
4. 添加测试
5. 提交 PR

### 发布新版本

1. 更新 CHANGELOG.md
2. 更新 README.md 中的版本号
3. 创建 Git tag
4. 发布 Release

## 最佳实践

### 对于用户

1. **阅读顺序：**
   - README.md（了解项目）
   - FAQ.md（常见问题）
   - TECHNICAL.md（深入理解）

2. **使用建议：**
   - 先在测试环境验证
   - 使用自动化脚本
   - 保留原模块备份

### 对于开发者

1. **开发流程：**
   - 先讨论 Issue
   - 创建特性分支
   - 遵循代码风格
   - 编写测试
   - 更新文档
   - 提交 PR

2. **测试要求：**
   - 编译通过
   - 功能测试通过
   - 性能测试无明显退化

## 相关资源

- Linux 内核文档：https://www.kernel.org/doc/
- ext4 文件系统：https://ext4.wiki.kernel.org/
- SSD 优化指南：https://wiki.archlinux.org/title/Solid_state_drive

## 联系方式

- GitHub Issues：报告问题和建议
- Pull Requests：贡献代码
- Discussions：技术讨论

---

**维护者：** [Your Name]  
**最后更新：** 2026-10-14
