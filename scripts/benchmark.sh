#!/bin/bash
#
# Benchmark script for testing I/O performance and stability
#

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_info() {
    echo "[INFO] $1"
}

# Check if stress-ng is available
if ! command -v stress-ng > /dev/null; then
    echo_error "stress-ng not found. Please install it first."
    echo_info "CentOS/RHEL: yum install stress-ng"
    echo_info "Ubuntu/Debian: apt-get install stress-ng"
    exit 1
fi

# Default parameters
WORKERS=${1:-3}
DURATION=${2:-60}

echo "========================================"
echo "  I/O Stress Test"
echo "========================================"
echo ""
echo_info "Workers: $WORKERS"
echo_info "Duration: ${DURATION}s"
echo ""

# Clear dmesg
dmesg -c > /dev/null 2>&1

# Record start time
START_TIME=$(date +%s)

# Run test
echo_info "Starting stress-ng..."
if timeout $((DURATION + 10)) stress-ng --iomix $WORKERS --timeout ${DURATION}s; then
    echo_success "Test completed successfully!"
    TEST_RESULT="PASS"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo_error "Test timed out (hung)"
        TEST_RESULT="FAIL (timeout)"
    else
        echo_error "Test failed with exit code: $EXIT_CODE"
        TEST_RESULT="FAIL (error)"
    fi
fi

# Record end time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "========================================"
echo "  Test Results"
echo "========================================"
echo "Result: $TEST_RESULT"
echo "Elapsed time: ${ELAPSED}s"
echo ""

# Check for D-state processes
D_STATE_COUNT=$(ps aux | grep " D " | wc -l)
echo "D-state processes: $D_STATE_COUNT"

# Check kernel errors
KERNEL_ERRORS=$(dmesg | grep -i "bug\|error\|panic\|hung" | wc -l)
echo "Kernel errors: $KERNEL_ERRORS"

# Check remaining stress-ng processes
REMAINING_PROCS=$(pgrep stress-ng | wc -l)
echo "Remaining stress-ng processes: $REMAINING_PROCS"

echo ""

if [ "$TEST_RESULT" == "PASS" ] && [ $KERNEL_ERRORS -eq 0 ]; then
    echo_success "System is stable under I/O stress"
    exit 0
else
    echo_error "System showed instability"
    exit 1
fi
