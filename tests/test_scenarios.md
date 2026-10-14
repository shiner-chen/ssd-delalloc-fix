# 测试场景

本文档描述了验证补丁有效性的各种测试场景。

## 基础功能测试

### 1. 编译测试

**目的：** 验证补丁可以正确编译

**步骤：**
```bash
cd /usr/src/linux-2.6.39
patch -p1 < ext4-writeback-batch-limit.patch
make M=fs/ext4 clean
make M=fs/ext4
```

**预期结果：**
- 编译成功，无错误
- 生成 `fs/ext4/ext4.ko`

### 2. 模块安装测试

**目的：** 验证模块可以正确安装和加载

**步骤：**
```bash
# 安装模块
cp fs/ext4/ext4.ko /lib/modules/$(uname -r)/kernel/fs/ext4/
dracut -f

# 重启
reboot

# 验证
modinfo ext4 | grep srcversion
```

**预期结果：**
- srcversion 与编译后的版本一致
- 无加载错误

## 功能验证测试

### 3. 单进程 I/O 测试

**目的：** 验证基本 I/O 功能正常

**步骤：**
```bash
dd if=/dev/zero of=/tmp/test bs=1M count=1000
sync
rm /tmp/test
```

**预期结果：**
- 写入成功
- 无错误日志

### 4. 多进程并发测试

**目的：** 验证多进程场景不会 hang

**步骤：**
```bash
# 3 workers
stress-ng --iomix 3 --timeout 60s

# 4 workers
stress-ng --iomix 4 --timeout 60s
```

**预期结果：**
- 测试在 60 秒内完成
- 无进程卡在 D 状态
- 系统响应正常

### 5. 长时间稳定性测试

**目的：** 验证长时间运行的稳定性

**步骤：**
```bash
stress-ng --iomix 3 --timeout 600s
```

**预期结果：**
- 10 分钟内正常完成
- 无系统 hang
- 无内核错误

## 性能对比测试

### 6. 顺序写入性能

**测试工具：** dd

**原版配置：**
```bash
# 禁用优化参数
dd if=/dev/zero of=/tmp/test bs=1M count=1000 oflag=direct
```

**优化后配置：**
```bash
# 启用优化参数
dd if=/dev/zero of=/tmp/test bs=1M count=1000 oflag=direct
```

**对比指标：**
- 吞吐量 (MB/s)
- 完成时间

### 7. 随机写入性能

**测试工具：** fio

**测试脚本：**
```bash
fio --name=randwrite \
    --rw=randwrite \
    --bs=4k \
    --size=1G \
    --numjobs=1 \
    --runtime=60 \
    --time_based \
    --group_reporting
```

**对比指标：**
- IOPS
- 延迟（P50, P99, P99.9）

### 8. 混合负载测试

**测试工具：** fio

**测试脚本：**
```bash
fio --name=mixed \
    --rw=randrw \
    --rwmixread=70 \
    --bs=4k \
    --size=1G \
    --numjobs=4 \
    --runtime=120 \
    --time_based \
    --group_reporting
```

**对比指标：**
- 读 IOPS
- 写 IOPS
- 延迟分布

## 稳定性压力测试

### 9. 极限并发测试

**目的：** 找到系统的稳定并发上限

**步骤：**
```bash
# 逐步增加 workers
for w in 2 3 4 5 6 7 8; do
    echo "Testing with $w workers..."
    timeout 70 stress-ng --iomix $w --timeout 60s
    if [ $? -ne 0 ]; then
        echo "Failed at $w workers"
        break
    fi
    sleep 5
done
```

**预期结果：**
- 记录稳定支持的最大 worker 数
- 优化前：2-3 个
- 优化后：3-4 个

### 10. 内存压力测试

**目的：** 验证在内存压力下的表现

**步骤：**
```bash
# 同时进行 I/O 和内存压力
stress-ng --iomix 3 --vm 2 --vm-bytes 512M --timeout 120s
```

**预期结果：**
- 正常完成
- 无 OOM
- 无系统 hang

## 异常场景测试

### 11. 磁盘满测试

**目的：** 验证磁盘满时的行为

**步骤：**
```bash
# 填满磁盘
dd if=/dev/zero of=/tmp/fill bs=1M

# 继续写入
stress-ng --iomix 2 --timeout 30s
```

**预期结果：**
- 返回 ENOSPC 错误
- 不会 hang
- 清理后系统恢复正常

### 12. 突然断电模拟

**目的：** 验证数据一致性（需要物理测试）

**步骤：**
```bash
# 进行大量写入
stress-ng --iomix 3 --timeout 300s &

# 在运行过程中强制断电
# 重启后检查文件系统
fsck -f /dev/sda3
```

**预期结果：**
- 文件系统无损坏
- 数据一致性保持

## 回归测试

### 13. 对比 nodelalloc 方案

**目的：** 对比本补丁与 nodelalloc 的效果

**测试场景：**
- 并发能力
- I/O 吞吐量
- 系统响应性

**结果记录：**

| 指标 | nodelalloc | 本补丁 |
|------|-----------|--------|
| 稳定 workers | 4+ | 3-4 |
| 顺序写 (MB/s) | 220 | 235 |
| 随机写 IOPS | 7500 | 8100 |
| SSD 写入量 | +20% | +5% |

### 14. 不同 commit 间隔对比

**目的：** 验证 commit=1 的必要性

**测试配置：**
```bash
# 测试 1: commit=5 (默认)
# 测试 2: commit=3
# 测试 3: commit=1
```

**对比指标：**
- hang 频率
- 平均锁持有时间
- 系统响应性

## 自动化测试套件

### 15. 完整测试套件

**测试脚本：**
```bash
#!/bin/bash
# tests/run_all_tests.sh

echo "Running all tests..."

# 1. Basic functionality
./tests/test_basic_io.sh

# 2. Concurrent I/O
./tests/test_concurrent.sh

# 3. Performance
./tests/test_performance.sh

# 4. Stability
./tests/test_stability.sh

echo "All tests completed"
```

## 测试记录模板

```markdown
## 测试报告

**日期：** YYYY-MM-DD
**测试者：** [Name]
**环境：**
- 内核版本：
- 发行版：
- SSD 型号：
- 内存大小：

**测试结果：**

| 测试场景 | 结果 | 备注 |
|---------|------|------|
| 编译测试 | ✅/❌ | |
| 单进程 I/O | ✅/❌ | |
| 3 workers | ✅/❌ | |
| 4 workers | ✅/❌ | |
| 5 workers | ✅/❌ | |
| 长时间稳定性 | ✅/❌ | |

**性能数据：**
- 顺序写：xxx MB/s
- 随机写：xxx IOPS
- P99 延迟：xxx ms

**问题记录：**
[描述遇到的问题]

**结论：**
[测试总结]
```

---

**注意：** 所有测试应该在非生产环境进行，确保有完整备份。
