#!/bin/bash
#
# 准备 RPM 构建环境
#
# 使用方法: ./prepare-rpm.sh [kernel-version] [rpm-version] [rpm-release]
#

set -e

KERNEL_VERSION="${1:-2.6.39}"
RPM_VERSION="${2:-1.0.0}"
RPM_RELEASE="${3:-1}"
KERNEL_SRC="/usr/src/linux-${KERNEL_VERSION}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "准备 RPM 构建环境..."

# 创建 rpmbuild 目录结构
echo "创建 rpmbuild 目录..."
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# 复制编译好的模块
echo "复制 ext4 模块..."
mkdir -p ~/rpmbuild/BUILD/ext4-module
cp "$KERNEL_SRC/fs/ext4/ext4.ko" ~/rpmbuild/BUILD/ext4-module/

# 复制配置文件
echo "复制配置文件..."
cp "$PROJECT_ROOT/docs/sysctl.conf" ~/rpmbuild/BUILD/99-ssd-delalloc.conf

# 创建安装/卸载脚本
echo "创建安装脚本..."
cat > ~/rpmbuild/BUILD/install-module.sh << 'EOF'
#!/bin/bash
# RPM 安装后脚本

KERNEL_VERSION=$(uname -r)
MODULE_PATH="/lib/modules/${KERNEL_VERSION}/kernel/fs/ext4/ext4.ko"

echo "安装 ext4 delalloc SSD fix 模块..."

# 备份原模块（只备份一次）
if [ -f "$MODULE_PATH" ] && [ ! -f "${MODULE_PATH}.orig" ]; then
    echo "备份原始模块: ${MODULE_PATH}.orig"
    cp "$MODULE_PATH" "${MODULE_PATH}.orig"
fi

# 安装新模块
echo "安装新模块..."
cp /usr/share/ext4-delalloc-ssd-fix/ext4.ko "$MODULE_PATH"

# 更新 initramfs
echo "更新 initramfs..."
INITRAMFS="/boot/initramfs-${KERNEL_VERSION}.img"
if [ -f "$INITRAMFS" ] && [ ! -f "${INITRAMFS}.orig" ]; then
    echo "备份原始 initramfs: ${INITRAMFS}.orig"
    cp "$INITRAMFS" "${INITRAMFS}.orig"
fi

dracut -f "$INITRAMFS" "$KERNEL_VERSION"

echo "✓ 模块安装完成"
EOF

cat > ~/rpmbuild/BUILD/configure-system.sh << 'EOF'
#!/bin/bash
# 配置系统参数和挂载选项

echo "配置系统参数..."

# 配置 sysctl
SYSCTL_CONF="/etc/sysctl.d/99-ssd-delalloc.conf"
if [ ! -f "$SYSCTL_CONF" ]; then
    echo "安装 sysctl 配置: $SYSCTL_CONF"
    cp /usr/share/ext4-delalloc-ssd-fix/99-ssd-delalloc.conf "$SYSCTL_CONF"
    sysctl -p "$SYSCTL_CONF"
else
    echo "sysctl 配置已存在，跳过"
fi

# 配置 fstab (添加 commit=1)
FSTAB="/etc/fstab"
if [ -f "$FSTAB" ] && [ ! -f "${FSTAB}.orig" ]; then
    echo "备份 fstab: ${FSTAB}.orig"
    cp "$FSTAB" "${FSTAB}.orig"
fi

echo "检查 fstab 中的 ext4 挂载选项..."
if grep -q "ext4.*defaults" "$FSTAB" && ! grep -q "commit=1" "$FSTAB"; then
    echo "添加 commit=1 选项到 ext4 挂载..."
    sed -i 's/\(ext4.*defaults\)/\1,commit=1/' "$FSTAB"
    echo "✓ fstab 已更新"
else
    echo "fstab 已包含 commit=1 或不需要修改"
fi

echo "✓ 系统配置完成"
EOF

cat > ~/rpmbuild/BUILD/uninstall-module.sh << 'EOF'
#!/bin/bash
# RPM 卸载前脚本

KERNEL_VERSION=$(uname -r)
MODULE_PATH="/lib/modules/${KERNEL_VERSION}/kernel/fs/ext4/ext4.ko"

echo "卸载 ext4 delalloc SSD fix 模块..."

# 1. 恢复原模块
if [ -f "${MODULE_PATH}.orig" ]; then
    echo "恢复原始模块..."
    cp "${MODULE_PATH}.orig" "$MODULE_PATH"
    rm -f "${MODULE_PATH}.orig"

    # 更新 initramfs
    INITRAMFS="/boot/initramfs-${KERNEL_VERSION}.img"
    if [ -f "${INITRAMFS}.orig" ]; then
        echo "恢复原始 initramfs..."
        cp "${INITRAMFS}.orig" "$INITRAMFS"
        rm -f "${INITRAMFS}.orig"
    else
        echo "重新生成 initramfs..."
        dracut -f "$INITRAMFS" "$KERNEL_VERSION"
    fi
else
    echo "警告: 未找到原始模块备份"
fi

# 2. 恢复 fstab
FSTAB="/etc/fstab"
if [ -f "${FSTAB}.orig" ]; then
    echo "恢复原始 fstab..."
    cp "${FSTAB}.orig" "$FSTAB"
    rm -f "${FSTAB}.orig"
else
    echo "警告: 未找到原始 fstab 备份"
fi

# 3. 删除 sysctl 配置
SYSCTL_CONF="/etc/sysctl.d/99-ssd-delalloc.conf"
if [ -f "$SYSCTL_CONF" ]; then
    echo "删除 sysctl 配置..."
    rm -f "$SYSCTL_CONF"

    # 恢复默认 sysctl 参数
    echo "恢复默认系统参数..."
    sysctl -w vm.dirty_ratio=20 > /dev/null 2>&1
    sysctl -w vm.dirty_background_ratio=10 > /dev/null 2>&1
    sysctl -w vm.dirty_writeback_centisecs=500 > /dev/null 2>&1
    sysctl -w vm.dirty_expire_centisecs=3000 > /dev/null 2>&1
fi

echo ""
echo "✓ 卸载完成"
echo ""
echo "已恢复的文件:"
echo "  - ext4.ko 模块"
echo "  - initramfs"
echo "  - /etc/fstab"
echo "  - sysctl 参数"
echo ""
echo "请重启系统使更改生效"
EOF

chmod +x ~/rpmbuild/BUILD/*.sh

echo "✓ RPM 构建环境准备完成"
