# 贡献指南

感谢你对本项目的关注！

## 如何贡献

### 报告 Bug

在 GitHub Issues 中提交 bug 报告时，请包含：

1. **环境信息**
   - 内核版本：`uname -r`
   - 发行版：`cat /etc/os-release`
   - SSD 型号
   - 内存大小

2. **问题描述**
   - 清晰描述问题
   - 预期行为 vs 实际行为
   - 复现步骤

3. **日志信息**
   - `dmesg` 输出
   - 系统日志（`/var/log/messages` 或 `journalctl`）
   - 测试输出

### 提交功能建议

功能建议应该包含：
- 功能描述
- 使用场景
- 预期收益
- 实现难度评估

### 提交代码

1. **Fork 本仓库**

2. **创建特性分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **进行修改**
   - 遵循现有代码风格
   - 添加必要的注释
   - 更新相关文档

4. **测试**
   ```bash
   # 编译测试
   make M=fs/ext4
   
   # 功能测试
   ./scripts/benchmark.sh
   ```

5. **提交变更**
   ```bash
   git add .
   git commit -m "feat: add xxx feature"
   ```

   提交信息格式：
   - `feat:` 新功能
   - `fix:` Bug 修复
   - `docs:` 文档更新
   - `test:` 测试相关
   - `refactor:` 代码重构

6. **推送分支**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **创建 Pull Request**
   - 清晰描述改动
   - 关联相关 Issue
   - 等待 review

## 代码风格

- 遵循 Linux 内核编码风格
- 使用 Tab 缩进（8 空格宽度）
- 注释使用英文
- 函数名使用下划线分隔

## 测试要求

所有代码改动必须通过：
1. 编译测试（无警告）
2. 功能测试（`benchmark.sh`）
3. 验证测试（`verify.sh`）

## 文档要求

代码改动应该同步更新：
- README.md（如果影响用户使用）
- TECHNICAL.md（如果涉及技术实现）
- CHANGELOG.md（记录变更）

## 问题讨论

- 复杂问题请先在 Issue 中讨论
- 避免提交大型未经讨论的 PR
- 保持友好和专业的沟通

## 许可证

提交代码即表示你同意以 GPL-2.0 许可证发布你的贡献。

---

再次感谢你的贡献！
