#!/usr/bin/env bash

# Licensed to the LF AI & Data foundation under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Milvus Local Development Script for Mac
# This script starts Milvus dependencies in Docker and runs Milvus locally

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
ROOT_DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检测系统类型
unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)    machine=Mac;;
    *)          
        log_error "此脚本仅支持macOS系统"
        exit 1
        ;;
esac

# 检测架构
ARCH=$(uname -m)
case "${ARCH}" in
    arm64|aarch64)  
        log_info "检测到Apple Silicon架构"
        USE_APPLE_SILICON=true
        ;;
    x86_64)     
        log_info "检测到Intel架构"
        USE_APPLE_SILICON=false
        ;;
    *)          
        log_warn "未知架构: ${ARCH}，使用默认配置"
        USE_APPLE_SILICON=false
        ;;
esac

# 检查docker compose是否可用
COMPOSE_CMD="docker compose"
if ! command -v docker &> /dev/null; then
    log_error "Docker未找到，请确保Docker已安装并正在运行"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    log_warn "docker compose未找到，尝试使用docker-compose"
    COMPOSE_CMD="docker-compose"
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker compose和docker-compose都未找到，请安装其中之一"
        exit 1
    fi
fi

# 设置Docker Compose文件路径
COMPOSE_DIR="$ROOT_DIR/deployments/docker/dev"
if [ "$USE_APPLE_SILICON" = true ]; then
    COMPOSE_FILE="$COMPOSE_DIR/docker-compose-apple-silicon-fixed.yml"
else
    COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
fi

# 检查Docker Compose文件是否存在
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Docker Compose文件不存在: $COMPOSE_FILE"
    exit 1
fi

# 设置环境变量
function setup_env() {
    export DOCKER_VOLUME_DIRECTORY="${DOCKER_VOLUME_DIRECTORY:-.}"
    
    # 设置Milvus连接依赖项的环境变量
    export ETCD_ENDPOINTS=localhost:2379
    export MINIO_ADDRESS=localhost:9000
    export PULSAR_ADDRESS=localhost:6650
    
    # 禁用 streaming service 以避免连接问题
    export MILVUS_STREAMING_SERVICE_ENABLED=0
    
    # 设置Milvus数据目录
    export MILVUS_DATA_DIR="/tmp/milvus_data"
    export localStorage__path="$MILVUS_DATA_DIR"
    export rocksmq__path="$MILVUS_DATA_DIR/rocksmq"
    
    # 创建数据目录
    mkdir -p "$MILVUS_DATA_DIR"
    mkdir -p "$MILVUS_DATA_DIR/rocksmq"
    
    log_info "环境变量设置完成"
}

# 检查服务状态
function check_service_health() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=0
    
    log_step "检查服务 $service 健康状态 (端口: $port)"
    
    while [ $attempt -lt $max_attempts ]; do
        if nc -z localhost $port 2>/dev/null; then
            log_info "✅ 服务 $service 已就绪"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    log_error "❌ 服务 $service 启动超时"
    return 1
}

# 启动Docker依赖项
function start_dependencies() {
    log_step "启动Docker依赖项..."
    
    cd "$COMPOSE_DIR"
    
    # # 拉取最新镜像
    # log_info "拉取Docker镜像..."
    # $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" pull
    
    # 启动服务
    log_info "启动依赖服务..."
    $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" up -d
    
    # 检查服务健康状态
    local services_to_check=(
        "etcd:2379"
        "pulsar:6650"
        "minio:9000"
        "azurite:10000"
        "jaeger:16686"
        "gcpnative:4443"
    )
    
    local failed_services=()
    for service_port in "${services_to_check[@]}"; do
        IFS=':' read -r service port <<< "$service_port"
        if ! check_service_health "$service" "$port"; then
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "以下服务启动失败: ${failed_services[*]}"
        log_error "请检查Docker日志: $COMPOSE_CMD -f $(basename "$COMPOSE_FILE") logs"
        return 1
    fi
    
    log_info "✅ 所有依赖服务已启动成功"
    return 0
}

# 停止Docker依赖项
function stop_dependencies() {
    log_step "停止Docker依赖项..."
    
    cd "$COMPOSE_DIR"
    
    $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" down
    
    log_info "✅ 依赖服务已停止"
}

# 显示服务状态
function show_status() {
    log_step "显示服务状态..."
    
    cd "$COMPOSE_DIR"
    
    echo "Docker服务状态:"
    $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" ps
    
    echo ""
    echo "Milvus进程状态:"
    if pgrep -f "milvus" > /dev/null; then
        echo "✅ Milvus进程正在运行"
        ps aux | grep "[m]ilvus"
    else
        echo "❌ Milvus进程未运行"
    fi
    
    echo ""
    echo "端口状态:"
    local ports=(2379 6650 9000 10000 16686 4443 19530)
    for port in "${ports[@]}"; do
        if nc -z localhost $port 2>/dev/null; then
            echo "✅ 端口 $port 已开放"
        else
            echo "❌ 端口 $port 未开放"
        fi
    done
}

# 启动Milvus
function start_milvus() {
    log_step "启动Milvus..."
    
    # 检查Milvus二进制文件
    if [ ! -f "$ROOT_DIR/bin/milvus" ]; then
        log_error "Milvus二进制文件不存在: $ROOT_DIR/bin/milvus"
        log_error "请先编译Milvus: make milvus"
        return 1
    fi
    
    # 停止现有的Milvus进程
    if pgrep -f "milvus" > /dev/null; then
        log_info "停止现有Milvus进程..."
        pkill -f "milvus"
        sleep 2
    fi
    
    # 设置环境变量
    setup_env
    
    # 启动Milvus
    cd "$ROOT_DIR"
    log_info "启动Milvus standalone..."
    
    # 使用start_standalone.sh脚本
    if [ -f "$SCRIPT_DIR/start_standalone.sh" ]; then
        $SCRIPT_DIR/start_standalone.sh
    else
        # 直接启动
        nohup ./bin/milvus run standalone --run-with-subprocess > /tmp/milvus_local.log 2>&1 &
    fi
    
    # 等待Milvus启动
    sleep 5
    
    # 检查Milvus是否成功启动
    if check_service_health "milvus" "19530"; then
        log_info "✅ Milvus启动成功"
        log_info "💡 Milvus Web UI: http://localhost:19530"
        log_info "💡 日志文件: /tmp/milvus_local.log 或 /tmp/standalone.log"
    else
        log_error "❌ Milvus启动失败，请检查日志"
        if [ -f "/tmp/milvus_local.log" ]; then
            log_error "查看日志: tail -f /tmp/milvus_local.log"
        fi
        if [ -f "/tmp/standalone.log" ]; then
            log_error "查看日志: tail -f /tmp/standalone.log"
        fi
        return 1
    fi
}

# 停止Milvus
function stop_milvus() {
    log_step "停止Milvus..."
    
    if pgrep -f "milvus" > /dev/null; then
        log_info "停止Milvus进程..."
        pkill -f "milvus"
        sleep 2
        
        # 强制杀死如果还在运行
        if pgrep -f "milvus" > /dev/null; then
            log_warn "强制停止Milvus进程..."
            pkill -9 -f "milvus"
        fi
        
        log_info "✅ Milvus已停止"
    else
        log_info "Milvus未运行"
    fi
}

# 显示日志
function show_logs() {
    local service="${1:-}"
    
    if [ -n "$service" ]; then
        log_step "显示 $service 服务日志..."
        cd "$COMPOSE_DIR"
        $COMPOSE_CMD -f "$(basename "$COMPOSE_FILE")" logs -f "$service"
    else
        log_step "显示Milvus日志..."
        if [ -f "/tmp/standalone.log" ]; then
            tail -f /tmp/standalone.log
        elif [ -f "/tmp/milvus_local.log" ]; then
            tail -f /tmp/milvus_local.log
        else
            log_error "未找到Milvus日志文件"
        fi
    fi
}

# 显示使用帮助
function show_usage() {
    echo "Milvus本地开发脚本 (Mac专用)"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  up                  启动所有服务 (Docker依赖 + 本地Milvus)"
    echo "  down                停止所有服务"
    echo "  deps-up             仅启动Docker依赖项"
    echo "  deps-down           仅停止Docker依赖项"
    echo "  milvus-start        仅启动本地Milvus"
    echo "  milvus-stop         仅停止本地Milvus"
    echo "  status              显示服务状态"
    echo "  logs [service]      显示日志 (不指定service则显示Milvus日志)"
    echo "  restart             重启所有服务"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 up               # 启动完整开发环境"
    echo "  $0 down             # 停止完整开发环境"
    echo "  $0 deps-up          # 仅启动Docker依赖"
    echo "  $0 milvus-start     # 仅启动本地Milvus"
    echo "  $0 status           # 查看服务状态"
    echo "  $0 logs etcd        # 查看etcd日志"
    echo "  $0 logs             # 查看Milvus日志"
    echo ""
    echo "Docker依赖项:"
    if [ "$USE_APPLE_SILICON" = true ]; then
        echo "  - 配置文件: docker-compose-apple-silicon-fixed.yml"
    else
        echo "  - 配置文件: docker-compose.yml"
    fi
    echo "  - etcd:2379 (元数据存储)"
    echo "  - pulsar:6650 (消息队列)"
    echo "  - minio:9000 (对象存储)"
    echo "  - azurite:10000 (Azure存储模拟)"
    echo "  - jaeger:16686 (链路追踪)"
    echo "  - gcpnative:4443 (GCP存储模拟)"
    echo ""
    echo "Milvus:"
    echo "  - 端口: 19530"
    echo "  - 数据目录: /tmp/milvus_data"
    echo "  - 日志: /tmp/standalone.log"
}

# 主函数
function main() {
    local action="${1:-}"
    
    case "$action" in
        -h|--help)
            show_usage
            exit 0
            ;;
        up)
            log_info "启动完整Milvus开发环境..."
            start_dependencies && start_milvus
            ;;
        down)
            log_info "停止完整Milvus开发环境..."
            stop_milvus
            stop_dependencies
            ;;
        deps-up)
            start_dependencies
            ;;
        deps-down)
            stop_dependencies
            ;;
        milvus-start)
            setup_env
            start_milvus
            ;;
        milvus-stop)
            stop_milvus
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "${2:-}"
            ;;
        restart)
            log_info "重启完整Milvus开发环境..."
            stop_milvus
            stop_dependencies
            sleep 2
            start_dependencies && start_milvus
            ;;
        *)
            log_error "未知命令: $action"
            show_usage
            exit 1
            ;;
    esac
}

# 脚本入口
main "$@" 