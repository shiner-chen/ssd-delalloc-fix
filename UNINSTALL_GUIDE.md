# RPM 卸载指南

## 概述

本文档说明如何安全卸载 `ext4-delalloc-ssd-fix` RPM 包，并验证系统已完全恢复到安装前的状态。

## 卸载脚本功能

RPM 的 preuninstall 脚本会自动执行以下操作：

### 1. 恢复 ext4.ko 模块
```bash
# 从备份恢复原始模块
cp /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko.orig \
   /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko

# 删除备份文件
rm -f /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko.orig
```

### 2. 恢复 initramfs
```bash
# 从备份恢复原始 initramfs
cp /boot/initramfs-2.6.39.img.orig \
   /boot/initramfs-2.6.39.img

# 删除备份文件
rm -f /boot/initramfs-2.6.39.img.orig
```

### 3. 恢复 /etc/fstab
```bash
# 从备份恢复原始 fstab（移除 commit=1）
cp /etc/fstab.orig /etc/fstab

# 删除备份文件
rm -f /etc/fstab.orig
```

### 4. 删除 sysctl 配置并恢复默认参数
```bash
# 删除配置文件
rm -f /etc/sysctl.d/99-ssd-delalloc.conf

# 恢复默认系统参数
sysctl -w vm.dirty_ratio=20                    # 从 2 恢复到 20
sysctl -w vm.dirty_background_ratio=10         # 从 1 恢复到 10
sysctl -w vm.dirty_writeback_centisecs=500     # 从 30 恢复到 500
sysctl -w vm.dirty_expire_centisecs=3000       # 从 300 恢复到 3000
```

## 卸载步骤

### 方法 1: 使用 RPM 命令（推荐）

```bash
rpm -e ext4-delalloc-ssd-fix
```

**预期输出：**
```
卸载 ext4 delalloc SSD fix 模块...
恢复原始模块...
恢复原始 initramfs...
恢复原始 fstab...
删除 sysctl 配置...
恢复默认系统参数...

✓ 卸载完成

已恢复的文件:
  - ext4.ko 模块
  - initramfs
  - /etc/fstab
  - sysctl 参数

请重启系统使更改生效
```

### 方法 2: 手动卸载（备用方案）

如果 RPM 卸载失败，可以手动执行：

```bash
# 1. 恢复模块
cp /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko.orig \
   /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko

# 2. 恢复 initramfs
cp /boot/initramfs-2.6.39.img.orig \
   /boot/initramfs-2.6.39.img

# 3. 恢复 fstab
cp /etc/fstab.orig /etc/fstab

# 4. 删除 sysctl 配置
rm -f /etc/sysctl.d/99-ssd-delalloc.conf

# 5. 恢复默认 sysctl 参数
sysctl -w vm.dirty_ratio=20
sysctl -w vm.dirty_background_ratio=10
sysctl -w vm.dirty_writeback_centisecs=500
sysctl -w vm.dirty_expire_centisecs=3000

# 6. 删除 RPM 包（强制）
rpm -e --nodeps ext4-delalloc-ssd-fix

# 7. 重启
reboot
```

## 卸载验证

卸载后，在重启前验证文件已恢复：

### 1. 验证备份文件已删除

```bash
ls -l /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko.orig
# 应该显示: No such file or directory

ls -l /boot/initramfs-2.6.39.img.orig
# 应该显示: No such file or directory

ls -l /etc/fstab.orig
# 应该显示: No such file or directory
```

✅ 所有 .orig 备份文件应该已被删除

### 2. 验证 fstab 已恢复

```bash
grep ext4 /etc/fstab
```

**预期结果：** 不应包含 `commit=1` 选项
```
UUID=xxx / ext4 defaults 1 1
UUID=xxx /boot ext4 defaults 1 2
```

### 3. 验证 sysctl 配置已删除

```bash
ls -l /etc/sysctl.d/99-ssd-delalloc.conf
# 应该显示: No such file or directory
```

### 4. 验证 sysctl 参数已恢复默认值

```bash
sysctl vm.dirty_ratio vm.dirty_background_ratio \
       vm.dirty_writeback_centisecs vm.dirty_expire_centisecs
```

**预期输出：**
```
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10
vm.dirty_writeback_centisecs = 500
vm.dirty_expire_centisecs = 3000
```

### 5. 验证 RPM 包已卸载

```bash
rpm -q ext4-delalloc-ssd-fix
# 应该显示: package ext4-delalloc-ssd-fix is not installed
```

## 重启后验证

卸载后必须重启系统以加载原始模块。重启后验证：

### 1. 验证模块版本

```bash
modinfo ext4 | grep -E "filename|srcversion"
```

模块应该是原始版本（没有我们的修补）

### 2. 验证挂载选项

```bash
mount | grep "on / type ext4"
```

**预期结果：** 不应包含 `commit=1`
```
/dev/sda1 on / type ext4 (rw)
```

### 3. 验证系统参数

```bash
sysctl -a | grep dirty
```

应该显示系统默认值（或 /etc/sysctl.conf 中的配置）

## 完整验证清单

卸载后使用此清单验证系统已完全恢复：

| 检查项 | 命令 | 预期结果 |
|-------|------|---------|
| ext4.ko.orig 已删除 | `ls /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko.orig` | No such file |
| initramfs.orig 已删除 | `ls /boot/initramfs-2.6.39.img.orig` | No such file |
| fstab.orig 已删除 | `ls /etc/fstab.orig` | No such file |
| fstab 无 commit=1 | `grep ext4 /etc/fstab` | 无 commit=1 |
| sysctl 配置已删除 | `ls /etc/sysctl.d/99-ssd-delalloc.conf` | No such file |
| dirty_ratio = 20 | `sysctl vm.dirty_ratio` | 20 |
| dirty_background_ratio = 10 | `sysctl vm.dirty_background_ratio` | 10 |
| dirty_writeback_centisecs = 500 | `sysctl vm.dirty_writeback_centisecs` | 500 |
| dirty_expire_centisecs = 3000 | `sysctl vm.dirty_expire_centisecs` | 3000 |
| RPM 包已卸载 | `rpm -q ext4-delalloc-ssd-fix` | not installed |

**重启后：**

| 检查项 | 命令 | 预期结果 |
|-------|------|---------|
| 原始模块已加载 | `modinfo ext4` | 原始版本 |
| 挂载无 commit=1 | `mount \| grep ext4` | 无 commit=1 |

## 常见问题

### Q1: 卸载时提示"未找到备份文件"？

**原因：** 备份文件可能已被手动删除或损坏

**解决：**
1. 检查 /lib/modules/2.6.39/kernel/fs/ext4/ 目录下是否有其他备份（如 ext4.ko.backup）
2. 如果有其他备份，手动复制：
   ```bash
   cp /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko.backup \
      /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko
   ```
3. 如果没有任何备份，需要从原始内核源代码重新编译 ext4 模块

### Q2: 卸载后系统参数仍然不是默认值？

**原因：** 系统可能在 /etc/sysctl.conf 或其他配置文件中设置了自定义值

**解决：**
```bash
# 检查其他 sysctl 配置
grep -r "dirty" /etc/sysctl.conf /etc/sysctl.d/

# 如果找到自定义配置，那是系统原有的，保持不变即可
```

### Q3: 重启后仍然加载了修改过的模块？

**原因：** initramfs 可能未正确恢复

**解决：**
```bash
# 重新生成 initramfs
dracut -f /boot/initramfs-2.6.39.img 2.6.39
reboot
```

### Q4: fstab 恢复后仍然包含 commit=1？

**原因：** 可能是安装前就有 commit=1 配置

**解决：** 检查 fstab.orig 备份内容，如果原始配置就有 commit=1，那是正常的

## 安全建议

### 卸载前

1. **备份重要数据** - 虽然卸载脚本经过测试，但建议备份重要数据
2. **记录当前配置** - 保存当前的系统配置以便对比
3. **选择维护窗口** - 在低峰期执行卸载操作

### 卸载后

1. **必须重启** - 卸载后必须重启才能加载原始模块
2. **验证功能** - 重启后测试系统功能是否正常
3. **监控性能** - 观察系统是否恢复到原始状态的性能表现

## 紧急回滚

如果卸载后系统无法启动，从 GRUB 进入恢复模式：

1. 重启进入 GRUB 菜单
2. 选择恢复模式（recovery mode）
3. 挂载文件系统为读写：
   ```bash
   mount -o remount,rw /
   ```
4. 检查并修复：
   ```bash
   # 检查模块
   ls -l /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko*
   
   # 如果有备份，恢复
   cp /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko.backup \
      /lib/modules/2.6.39/kernel/fs/ext4/ext4.ko
   
   # 重新生成 initramfs
   dracut -f /boot/initramfs-2.6.39.img 2.6.39
   ```
5. 重启

## 总结

卸载脚本会自动恢复以下所有修改：

✅ ext4.ko 模块恢复
✅ initramfs 恢复
✅ /etc/fstab 恢复（移除 commit=1）
✅ sysctl 配置删除
✅ 系统参数恢复默认值
✅ 所有备份文件清理

卸载后需要重启系统才能完全生效。

---

**文档版本**: 1.0
**最后更新**: 2026-10-14
**适用RPM**: ext4-delalloc-ssd-fix-1.0.0-1.el6.i686
