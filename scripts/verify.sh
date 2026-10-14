#!/bin/bash
#
# Verification script for ext4 writeback batch limit patch
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

echo_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

echo_info() {
    echo "[INFO] $1"
}

PASS_COUNT=0
FAIL_COUNT=0

check_item() {
    local name="$1"
    local condition="$2"
    
    echo -n "Checking $name... "
    if eval "$condition"; then
        echo_pass "$name"
        ((PASS_COUNT++))
        return 0
    else
        echo_fail "$name"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "================================"
echo "  Configuration Verification"
echo "================================"
echo ""

# Check 1: Kernel version
KERNEL_VERSION=$(uname -r)
echo_info "Kernel version: $KERNEL_VERSION"
echo ""

# Check 2: ext4 module version
echo "1. ext4 module version:"
MOD_VERSION=$(modinfo ext4 | grep srcversion | awk '{print $2}')
echo "   srcversion: $MOD_VERSION"
if [ -n "$MOD_VERSION" ]; then
    echo_pass "ext4 module loaded"
    ((PASS_COUNT++))
else
    echo_fail "ext4 module not found"
    ((FAIL_COUNT++))
fi
echo ""

# Check 3: Mount options
echo "2. Root partition mount options:"
MOUNT_OPTS=$(mount | grep "on / " | grep -o "rw.*" | cut -d' ' -f1)
echo "   $MOUNT_OPTS"
if echo "$MOUNT_OPTS" | grep -q "commit=1"; then
    echo_pass "commit=1 is active"
    ((PASS_COUNT++))
else
    echo_fail "commit=1 is NOT active"
    ((FAIL_COUNT++))
fi
echo ""

# Check 4: delalloc status
echo "3. delalloc status:"
if mount | grep "on / " | grep -q "nodelalloc"; then
    echo_fail "delalloc is DISABLED (nodelalloc)"
    ((FAIL_COUNT++))
else
    echo_pass "delalloc is ENABLED"
    ((PASS_COUNT++))
fi
echo ""

# Check 5: Sysctl parameters
echo "4. Sysctl parameters:"
DIRTY_RATIO=$(sysctl -n vm.dirty_ratio)
DIRTY_BG_RATIO=$(sysctl -n vm.dirty_background_ratio)
DIRTY_WB_CS=$(sysctl -n vm.dirty_writeback_centisecs)
DIRTY_EXP_CS=$(sysctl -n vm.dirty_expire_centisecs)

echo "   vm.dirty_ratio = $DIRTY_RATIO (expected: 2)"
echo "   vm.dirty_background_ratio = $DIRTY_BG_RATIO (expected: 1)"
echo "   vm.dirty_writeback_centisecs = $DIRTY_WB_CS (expected: 30)"
echo "   vm.dirty_expire_centisecs = $DIRTY_EXP_CS (expected: 300)"

if [ "$DIRTY_RATIO" -le 5 ] && [ "$DIRTY_BG_RATIO" -le 2 ]; then
    echo_pass "Sysctl parameters are optimized"
    ((PASS_COUNT++))
else
    echo_fail "Sysctl parameters are NOT optimized"
    ((FAIL_COUNT++))
fi
echo ""

# Check 6: Storage type
echo "5. Storage device:"
ROOT_DEV=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
if [ -b "$ROOT_DEV" ]; then
    if [ -e "/sys/block/$(basename $ROOT_DEV)/queue/rotational" ]; then
        ROTATIONAL=$(cat /sys/block/$(basename $ROOT_DEV)/queue/rotational)
        if [ "$ROTATIONAL" -eq 0 ]; then
            echo_pass "Root is on SSD (rotational=0)"
            ((PASS_COUNT++))
        else
            echo_fail "Root is on HDD (rotational=1) - NOT recommended!"
            ((FAIL_COUNT++))
        fi
    else
        echo_info "Cannot determine storage type"
    fi
fi
echo ""

# Summary
echo "================================"
echo "  Summary"
echo "================================"
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo_pass "All checks passed! System is properly configured."
    exit 0
else
    echo_fail "Some checks failed. Please review the configuration."
    exit 1
fi
