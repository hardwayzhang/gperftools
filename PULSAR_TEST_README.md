# Pulsar容灾容错测试使用指南

## 文件说明

本目录包含针对Pulsar组件的容灾容错测试设计文档和测试代码框架：

1. **pulsar_fault_tolerance_test_design.md** - 完整的测试用例设计文档
   - 包含22个详细的测试用例
   - 每个测试用例包含测试目的、步骤、预期结果和验证指标
   - 涵盖连接故障、网络异常、消息处理、服务降级等场景

2. **pulsar_fault_tolerance_tests.cpp** - C++测试代码框架
   - 提供了关键测试用例的实现框架
   - 包含测试统计和配置管理
   - 需要根据实际使用的Pulsar客户端库进行调整

3. **pulsar_test_helper.sh** - Bash测试辅助脚本
   - 提供网络故障模拟功能（延迟、丢包、分区）
   - 提供Pulsar服务控制功能（启动、停止、状态检查）
   - 简化测试环境准备和故障模拟

## 快速开始

### 1. 环境准备

```bash
# 确保已安装必要的工具
sudo apt-get install iproute2 iptables curl  # Linux
# 或
brew install iproute2mac  # macOS

# 确保Pulsar集群已部署
# 参考: https://pulsar.apache.org/docs/getting-started-standalone/
```

### 2. 使用测试辅助脚本

```bash
# 检查Pulsar状态
./pulsar_test_helper.sh status

# 模拟网络延迟（500ms）
./pulsar_test_helper.sh delay 500

# 模拟网络丢包（10%）
./pulsar_test_helper.sh loss 10

# 模拟网络分区（阻断Pulsar端口）
./pulsar_test_helper.sh partition

# 恢复网络
./pulsar_test_helper.sh restore

# 停止Pulsar Broker
./pulsar_test_helper.sh stop-broker

# 启动Pulsar Broker
./pulsar_test_helper.sh start-broker
```

### 3. 编译和运行测试代码

```bash
# 注意：需要根据实际项目调整编译配置
# 假设使用Pulsar C++客户端

# 编译（需要链接Pulsar C++客户端库）
g++ -std=c++11 pulsar_fault_tolerance_tests.cpp \
    -lpulsar -lpthread -o pulsar_fault_tolerance_tests

# 运行测试
./pulsar_fault_tolerance_tests pulsar://localhost:6650 test-topic
```

## 测试用例执行建议

### 优先级P0测试用例（必须执行）

这些测试用例覆盖最关键的容灾容错场景：

1. **TC-001: Pulsar Broker连接失败测试**
   ```bash
   # 1. 停止Pulsar Broker
   ./pulsar_test_helper.sh stop-broker
   
   # 2. 运行测试
   ./pulsar_fault_tolerance_tests
   
   # 3. 恢复Pulsar Broker
   ./pulsar_test_helper.sh start-broker
   ```

2. **TC-002: Pulsar Broker部分节点故障测试**
   - 需要多节点Pulsar集群
   - 逐个停止Broker节点，观察主项目行为

3. **TC-004: 网络分区测试**
   ```bash
   # 1. 启动测试
   ./pulsar_fault_tolerance_tests &
   
   # 2. 模拟网络分区
   ./pulsar_test_helper.sh partition
   
   # 3. 等待30秒后恢复
   sleep 30
   ./pulsar_test_helper.sh restore
   ```

4. **TC-007: 消息发送失败重试测试**
   - 测试重试机制和指数退避策略

5. **TC-011: 消费者连接失败测试**
   - 测试消费者重连和消息恢复

6. **TC-014: 服务降级测试**
   - 测试降级策略和备用方案

### 测试执行流程

1. **准备阶段**
   - 部署Pulsar集群（至少3个Broker）
   - 部署主项目和副项目
   - 配置监控和日志收集
   - 验证基础功能正常

2. **执行阶段**
   - 按照优先级执行测试用例
   - 记录测试结果和日志
   - 收集性能指标
   - 验证预期结果

3. **问题修复阶段**
   - 分析测试中发现的问题
   - 修复代码缺陷
   - 重新执行相关测试用例

4. **报告阶段**
   - 整理测试结果
   - 生成测试报告
   - 提供改进建议

## 测试结果验证标准

### 功能验证
- ✅ 连接恢复时间 < 30秒
- ✅ 消息丢失率 < 0.1%
- ✅ 消息重复率 < 0.1%（非幂等场景）
- ✅ 所有错误都被正确捕获和处理

### 性能验证
- ✅ 正常场景响应时间 < 100ms
- ✅ 故障恢复时间 < 60秒
- ✅ 高并发场景成功率 > 99%

### 稳定性验证
- ✅ 测试期间应用不崩溃
- ✅ 无内存泄漏
- ✅ 无连接泄漏
- ✅ 优雅降级

## 集成到CI/CD

可以将测试用例集成到持续集成流程中：

```yaml
# .github/workflows/pulsar-fault-tolerance.yml 示例
name: Pulsar Fault Tolerance Tests

on:
  schedule:
    - cron: '0 2 * * *'  # 每天凌晨2点运行
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Pulsar
        run: |
          # 启动Pulsar集群
          docker-compose up -d pulsar
          ./pulsar_test_helper.sh wait 60
      
      - name: Run P0 Tests
        run: |
          ./pulsar_fault_tolerance_tests
      
      - name: Run Network Partition Test
        run: |
          ./pulsar_test_helper.sh partition &
          sleep 30
          ./pulsar_test_helper.sh restore
      
      - name: Collect Results
        if: always()
        run: |
          # 收集测试结果和日志
          mkdir -p test-results
          # 保存测试报告
```

## 注意事项

1. **权限要求**
   - 网络故障模拟需要root权限（使用sudo）
   - Pulsar服务控制可能需要相应权限

2. **环境隔离**
   - 建议在独立的测试环境中执行
   - 避免影响生产环境

3. **资源准备**
   - 确保有足够的计算和网络资源
   - 长时间运行测试需要监控资源使用

4. **代码适配**
   - 测试代码框架需要根据实际使用的Pulsar客户端库进行调整
   - 需要实现实际的Pulsar连接和消息发送/接收逻辑

5. **监控和日志**
   - 建议配置详细的日志记录
   - 使用监控工具（如Prometheus）收集指标
   - 保存测试过程中的所有日志用于分析

## 扩展测试用例

如果需要添加新的测试用例，可以：

1. 在 `pulsar_fault_tolerance_test_design.md` 中添加测试用例描述
2. 在 `pulsar_fault_tolerance_tests.cpp` 中实现测试类
3. 在 `main()` 函数中注册新测试用例
4. 更新测试执行计划

## 问题反馈

如果在使用过程中遇到问题，请：
1. 检查Pulsar集群状态
2. 查看测试日志
3. 验证网络配置
4. 参考Pulsar官方文档

## 相关资源

- [Apache Pulsar官方文档](https://pulsar.apache.org/docs/)
- [Pulsar C++客户端文档](https://pulsar.apache.org/docs/client-libraries-cpp/)
- [容灾容错设计最佳实践](https://pulsar.apache.org/docs/deployment-fault-tolerance/)

---

**最后更新**: 2024
