#!/bin/bash
#
# Installation script for ext4 writeback batch limit patch
# For Linux 2.6.39 kernel on SSD systems
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_info() {
    echo "[INFO] $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo_error "Please run as root"
    exit 1
fi

# Check kernel version
KERNEL_VERSION=$(uname -r)
if [[ ! "$KERNEL_VERSION" == 2.6.39* ]]; then
    echo_warning "This patch is designed for Linux 2.6.39"
    echo_warning "Your kernel: $KERNEL_VERSION"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for kernel source
KERNEL_SRC="/usr/src/linux-${KERNEL_VERSION}"
if [ ! -d "$KERNEL_SRC" ]; then
    KERNEL_SRC="/usr/src/linux-2.6.39"
fi

if [ ! -d "$KERNEL_SRC" ]; then
    echo_error "Kernel source not found at $KERNEL_SRC"
    exit 1
fi

echo_info "Kernel source: $KERNEL_SRC"

# Step 1: Apply patch
echo_info "Step 1: Applying patch..."
cd "$KERNEL_SRC"

# Backup original file
if [ ! -f "fs/ext4/inode.c.orig" ]; then
    cp fs/ext4/inode.c fs/ext4/inode.c.orig
    echo_success "Backed up fs/ext4/inode.c to fs/ext4/inode.c.orig"
fi

# Apply patch
PATCH_FILE="$(dirname $0)/../patches/ext4-writeback-batch-limit.patch"
if patch -p1 --dry-run < "$PATCH_FILE" > /dev/null 2>&1; then
    patch -p1 < "$PATCH_FILE"
    echo_success "Patch applied successfully"
else
    echo_error "Patch failed to apply"
    echo_info "The file may already be patched or modified"
    exit 1
fi

# Step 2: Compile ext4 module
echo_info "Step 2: Compiling ext4 module..."
make M=fs/ext4 clean > /dev/null 2>&1
if make M=fs/ext4; then
    echo_success "ext4 module compiled successfully"
else
    echo_error "Compilation failed"
    exit 1
fi

# Step 3: Install module
echo_info "Step 3: Installing module..."
MOD_PATH="/lib/modules/${KERNEL_VERSION}/kernel/fs/ext4"

# Backup original module
if [ ! -f "${MOD_PATH}/ext4.ko.backup" ]; then
    cp "${MOD_PATH}/ext4.ko" "${MOD_PATH}/ext4.ko.backup"
    echo_success "Backed up original ext4.ko"
fi

# Install new module
cp fs/ext4/ext4.ko "${MOD_PATH}/"
echo_success "Installed new ext4.ko"

# Step 4: Update initramfs
echo_info "Step 4: Updating initramfs..."
if command -v dracut > /dev/null; then
    dracut -f /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}
    echo_success "initramfs updated with dracut"
elif command -v mkinitramfs > /dev/null; then
    mkinitramfs -o /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}
    echo_success "initramfs updated with mkinitramfs"
else
    echo_warning "Neither dracut nor mkinitramfs found"
    echo_warning "Please manually update initramfs"
fi

# Step 5: Configure fstab
echo_info "Step 5: Configuring fstab..."
if grep -q "commit=1" /etc/fstab; then
    echo_info "fstab already contains commit=1"
else
    echo_warning "Please manually add 'commit=1' to your root partition in /etc/fstab"
    echo_info "Example: UUID=xxx / ext4 defaults,commit=1 1 1"
fi

# Step 6: Configure sysctl
echo_info "Step 6: Configuring sysctl parameters..."
SYSCTL_FILE="/etc/sysctl.d/99-ssd-delalloc-optimized.conf"
if [ -f "$SYSCTL_FILE" ]; then
    echo_info "Sysctl config already exists: $SYSCTL_FILE"
else
    cp "$(dirname $0)/../docs/sysctl.conf" "$SYSCTL_FILE"
    echo_success "Created $SYSCTL_FILE"
fi

echo ""
echo_success "Installation completed!"
echo ""
echo_warning "IMPORTANT: You must reboot to apply changes"
echo_info "After reboot, run: $(dirname $0)/verify.sh"
echo ""

