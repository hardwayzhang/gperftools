#!/bin/bash
#
# Pulsar容灾容错测试辅助脚本
# 提供网络故障模拟、Pulsar服务控制等功能
#

set -e

# 配置
PULSAR_BROKER_PORT=6650
PULSAR_HTTP_PORT=8080
NETWORK_INTERFACE="eth0"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 命令未找到，请先安装"
        exit 1
    fi
}

# 模拟网络延迟
simulate_network_delay() {
    local delay_ms=${1:-500}
    print_info "模拟网络延迟: ${delay_ms}ms"
    check_command tc
    
    # 清除现有规则
    tc qdisc del dev $NETWORK_INTERFACE root 2>/dev/null || true
    
    # 添加延迟规则
    tc qdisc add dev $NETWORK_INTERFACE root netem delay ${delay_ms}ms
    
    print_info "网络延迟已设置，按Ctrl+C恢复"
    trap "restore_network" INT TERM
    sleep infinity
}

# 模拟网络丢包
simulate_network_loss() {
    local loss_percent=${1:-10}
    print_info "模拟网络丢包: ${loss_percent}%"
    check_command tc
    
    # 清除现有规则
    tc qdisc del dev $NETWORK_INTERFACE root 2>/dev/null || true
    
    # 添加丢包规则
    tc qdisc add dev $NETWORK_INTERFACE root netem loss ${loss_percent}%
    
    print_info "网络丢包已设置，按Ctrl+C恢复"
    trap "restore_network" INT TERM
    sleep infinity
}

# 模拟网络分区（阻断Pulsar端口）
simulate_network_partition() {
    print_info "模拟网络分区（阻断Pulsar端口 ${PULSAR_BROKER_PORT}）"
    check_command iptables
    
    # 添加阻断规则
    iptables -A OUTPUT -p tcp --dport $PULSAR_BROKER_PORT -j DROP
    iptables -A INPUT -p tcp --sport $PULSAR_BROKER_PORT -j DROP
    
    print_info "网络分区已设置，使用 'restore_network' 命令恢复"
}

# 恢复网络
restore_network() {
    print_info "恢复网络配置..."
    
    # 恢复tc规则
    if command -v tc &> /dev/null; then
        tc qdisc del dev $NETWORK_INTERFACE root 2>/dev/null || true
        print_info "已清除网络延迟/丢包规则"
    fi
    
    # 恢复iptables规则
    if command -v iptables &> /dev/null; then
        iptables -D OUTPUT -p tcp --dport $PULSAR_BROKER_PORT -j DROP 2>/dev/null || true
        iptables -D INPUT -p tcp --sport $PULSAR_BROKER_PORT -j DROP 2>/dev/null || true
        print_info "已清除网络分区规则"
    fi
    
    print_info "网络配置已恢复"
}

# 停止Pulsar Broker
stop_pulsar_broker() {
    local broker_name=${1:-"pulsar-broker"}
    print_info "停止Pulsar Broker: ${broker_name}"
    
    if command -v docker &> /dev/null; then
        docker stop $broker_name 2>/dev/null || print_warn "Docker容器 ${broker_name} 未运行"
    elif command -v systemctl &> /dev/null; then
        systemctl stop pulsar 2>/dev/null || print_warn "Pulsar服务未运行"
    else
        print_warn "未找到Docker或systemctl，请手动停止Pulsar Broker"
    fi
}

# 启动Pulsar Broker
start_pulsar_broker() {
    local broker_name=${1:-"pulsar-broker"}
    print_info "启动Pulsar Broker: ${broker_name}"
    
    if command -v docker &> /dev/null; then
        docker start $broker_name 2>/dev/null || print_warn "Docker容器 ${broker_name} 启动失败"
    elif command -v systemctl &> /dev/null; then
        systemctl start pulsar 2>/dev/null || print_warn "Pulsar服务启动失败"
    else
        print_warn "未找到Docker或systemctl，请手动启动Pulsar Broker"
    fi
}

# 检查Pulsar Broker状态
check_pulsar_status() {
    local url=${1:-"http://localhost:${PULSAR_HTTP_PORT}"}
    print_info "检查Pulsar状态: ${url}"
    
    if command -v curl &> /dev/null; then
        if curl -s "${url}/admin/v2/brokers/health" > /dev/null; then
            print_info "Pulsar Broker运行正常"
            return 0
        else
            print_error "Pulsar Broker未响应"
            return 1
        fi
    else
        print_warn "curl未安装，无法检查Pulsar状态"
        return 1
    fi
}

# 等待Pulsar Broker就绪
wait_for_pulsar() {
    local max_wait=${1:-60}
    local wait_time=0
    
    print_info "等待Pulsar Broker就绪（最多等待 ${max_wait} 秒）..."
    
    while [ $wait_time -lt $max_wait ]; do
        if check_pulsar_status; then
            print_info "Pulsar Broker已就绪"
            return 0
        fi
        
        sleep 2
        wait_time=$((wait_time + 2))
        echo -n "."
    done
    
    echo ""
    print_error "Pulsar Broker在 ${max_wait} 秒内未就绪"
    return 1
}

# 生成测试消息
generate_test_messages() {
    local count=${1:-1000}
    local size=${2:-1024}
    local topic=${3:-"test-topic"}
    
    print_info "生成测试消息: ${count} 条，每条 ${size} 字节，Topic: ${topic}"
    
    # 这里应该调用实际的测试消息生成脚本
    # python3 generate_test_messages.py --count $count --size $size --topic $topic
    print_warn "请实现测试消息生成逻辑"
}

# 显示使用说明
usage() {
    cat << EOF
Pulsar容灾容错测试辅助脚本

用法:
    $0 <command> [options]

命令:
    delay <ms>              模拟网络延迟（毫秒），默认500ms
    loss <percent>          模拟网络丢包（百分比），默认10%
    partition               模拟网络分区（阻断Pulsar端口）
    restore                 恢复网络配置
    stop-broker [name]      停止Pulsar Broker
    start-broker [name]     启动Pulsar Broker
    status [url]            检查Pulsar状态
    wait [seconds]          等待Pulsar就绪
    generate [count] [size] [topic]  生成测试消息

示例:
    $0 delay 1000           # 模拟1秒网络延迟
    $0 loss 20              # 模拟20%网络丢包
    $0 partition            # 模拟网络分区
    $0 restore              # 恢复网络
    $0 stop-broker          # 停止Pulsar Broker
    $0 start-broker         # 启动Pulsar Broker
    $0 status               # 检查Pulsar状态
    $0 wait 30              # 等待Pulsar就绪（最多30秒）

EOF
}

# 主函数
main() {
    case "${1:-}" in
        delay)
            simulate_network_delay ${2:-500}
            ;;
        loss)
            simulate_network_loss ${2:-10}
            ;;
        partition)
            simulate_network_partition
            ;;
        restore)
            restore_network
            ;;
        stop-broker)
            stop_pulsar_broker ${2:-}
            ;;
        start-broker)
            start_pulsar_broker ${2:-}
            ;;
        status)
            check_pulsar_status ${2:-}
            ;;
        wait)
            wait_for_pulsar ${2:-60}
            ;;
        generate)
            generate_test_messages ${2:-1000} ${3:-1024} ${4:-"test-topic"}
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
