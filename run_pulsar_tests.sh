#!/bin/bash
#
# Pulsar容灾容错测试执行脚本
# 自动化执行关键测试用例
#

set -e

# 配置
PULSAR_URL=${PULSAR_URL:-"pulsar://localhost:6650"}
TOPIC_NAME=${TOPIC_NAME:-"test-topic"}
TEST_HELPER="./pulsar_test_helper.sh"
TEST_BINARY="./pulsar_fault_tolerance_tests"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# 检查依赖
check_dependencies() {
    print_section "检查依赖"
    
    if [ ! -f "$TEST_HELPER" ]; then
        print_error "测试辅助脚本未找到: $TEST_HELPER"
        exit 1
    fi
    
    if [ ! -x "$TEST_HELPER" ]; then
        chmod +x "$TEST_HELPER"
    fi
    
    if [ ! -f "$TEST_BINARY" ]; then
        print_error "测试二进制文件未找到: $TEST_BINARY"
        print_info "请先编译测试代码: g++ -std=c++11 pulsar_fault_tolerance_tests.cpp -lpulsar -lpthread -o pulsar_fault_tolerance_tests"
        exit 1
    fi
    
    print_success "依赖检查通过"
}

# 检查Pulsar状态
check_pulsar() {
    print_section "检查Pulsar状态"
    
    if $TEST_HELPER status; then
        print_success "Pulsar运行正常"
        return 0
    else
        print_error "Pulsar未运行或无法访问"
        print_info "请先启动Pulsar集群"
        return 1
    fi
}

# 执行TC-001: 连接失败测试
test_tc001_connection_failure() {
    print_section "TC-001: Pulsar Broker连接失败测试"
    
    print_info "步骤1: 停止Pulsar Broker"
    $TEST_HELPER stop-broker
    sleep 2
    
    print_info "步骤2: 运行连接失败测试"
    if $TEST_BINARY "$PULSAR_URL" "$TOPIC_NAME" 2>&1 | grep -q "TC-001.*通过"; then
        print_success "TC-001测试通过"
    else
        print_error "TC-001测试失败"
        return 1
    fi
    
    print_info "步骤3: 恢复Pulsar Broker"
    $TEST_HELPER start-broker
    $TEST_HELPER wait 30
    
    return 0
}

# 执行TC-004: 网络分区测试
test_tc004_network_partition() {
    print_section "TC-004: 网络分区测试"
    
    print_info "步骤1: 启动后台测试"
    $TEST_BINARY "$PULSAR_URL" "$TOPIC_NAME" > /tmp/pulsar_test.log 2>&1 &
    local test_pid=$!
    sleep 2
    
    print_info "步骤2: 模拟网络分区"
    sudo $TEST_HELPER partition
    sleep 5
    
    print_info "步骤3: 等待30秒"
    sleep 30
    
    print_info "步骤4: 恢复网络"
    sudo $TEST_HELPER restore
    sleep 5
    
    print_info "步骤5: 检查测试结果"
    if wait $test_pid; then
        if grep -q "TC-004.*通过" /tmp/pulsar_test.log; then
            print_success "TC-004测试通过"
            return 0
        else
            print_error "TC-004测试失败"
            return 1
        fi
    else
        print_error "测试进程异常退出"
        return 1
    fi
}

# 执行TC-007: 消息发送重试测试
test_tc007_message_retry() {
    print_section "TC-007: 消息发送失败重试测试"
    
    print_info "步骤1: 停止Pulsar Broker"
    $TEST_HELPER stop-broker
    sleep 2
    
    print_info "步骤2: 运行重试测试"
    if $TEST_BINARY "$PULSAR_URL" "$TOPIC_NAME" 2>&1 | grep -q "TC-007.*通过"; then
        print_success "TC-007测试通过"
    else
        print_error "TC-007测试失败"
        return 1
    fi
    
    print_info "步骤3: 恢复Pulsar Broker"
    $TEST_HELPER start-broker
    $TEST_HELPER wait 30
    
    return 0
}

# 执行所有P0优先级测试
run_p0_tests() {
    print_section "执行P0优先级测试用例"
    
    local failed_tests=0
    
    # TC-001
    if ! test_tc001_connection_failure; then
        ((failed_tests++))
    fi
    
    # TC-004
    if ! test_tc004_network_partition; then
        ((failed_tests++))
    fi
    
    # TC-007
    if ! test_tc007_message_retry; then
        ((failed_tests++))
    fi
    
    return $failed_tests
}

# 生成测试报告
generate_report() {
    print_section "生成测试报告"
    
    local report_file="pulsar_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Pulsar容灾容错测试报告"
        echo "生成时间: $(date)"
        echo "Pulsar URL: $PULSAR_URL"
        echo "Topic: $TOPIC_NAME"
        echo ""
        echo "测试结果:"
        if [ -f /tmp/pulsar_test.log ]; then
            cat /tmp/pulsar_test.log
        fi
    } > "$report_file"
    
    print_success "测试报告已生成: $report_file"
}

# 清理
cleanup() {
    print_info "清理测试环境..."
    
    # 恢复网络
    sudo $TEST_HELPER restore 2>/dev/null || true
    
    # 确保Pulsar运行
    $TEST_HELPER start-broker 2>/dev/null || true
    
    print_success "清理完成"
}

# 主函数
main() {
    print_section "Pulsar容灾容错测试套件"
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 检查依赖
    check_dependencies
    
    # 检查Pulsar
    if ! check_pulsar; then
        print_error "Pulsar未就绪，退出测试"
        exit 1
    fi
    
    # 执行测试
    local failed_tests=0
    if run_p0_tests; then
        failed_tests=$?
    fi
    
    # 生成报告
    generate_report
    
    # 输出总结
    print_section "测试总结"
    if [ $failed_tests -eq 0 ]; then
        print_success "所有P0测试用例通过"
        exit 0
    else
        print_error "$failed_tests 个测试用例失败"
        exit 1
    fi
}

# 显示使用说明
usage() {
    cat << EOF
Pulsar容灾容错测试执行脚本

用法:
    $0 [options]

选项:
    -u, --url URL          Pulsar服务URL (默认: pulsar://localhost:6650)
    -t, --topic TOPIC      Topic名称 (默认: test-topic)
    -h, --help            显示此帮助信息

环境变量:
    PULSAR_URL            Pulsar服务URL
    TOPIC_NAME            Topic名称

示例:
    $0
    $0 -u pulsar://pulsar-cluster:6650 -t my-test-topic
    PULSAR_URL=pulsar://localhost:6650 $0

EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            PULSAR_URL="$2"
            shift 2
            ;;
        -t|--topic)
            TOPIC_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "未知选项: $1"
            usage
            exit 1
            ;;
    esac
done

# 执行主函数
main
