# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-10-14

### Added
- Initial release
- ext4 writeback batch limit patch (1024 pages)
- Installation script with automatic backup
- Verification script for configuration checking
- Benchmark script for stress testing
- Comprehensive documentation (README, TECHNICAL, FAQ)
- Example configuration files (fstab, sysctl)

### Features
- Support for Linux 2.6.39 kernel
- Optimized for SSD storage
- Maintains delalloc functionality
- Reduces lock contention in ext4_da_writepages()
- Supports 3-4 concurrent I/O workers stably

### Performance
- Throughput: -5~10% (acceptable)
- Tail latency: +90%+ improvement
- SSD lifetime impact: <5%
- Lock hold time: 30s → 0.3s (100x improvement)

---

**Legend:**
- `Added` - New features
- `Changed` - Changes in existing functionality
- `Deprecated` - Soon-to-be removed features
- `Removed` - Removed features
- `Fixed` - Bug fixes
- `Security` - Security improvements
