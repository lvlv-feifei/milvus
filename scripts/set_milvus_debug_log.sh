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

# Milvus Debug Log Configuration Script

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
ROOT_DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

CONFIG_FILE="$ROOT_DIR/configs/milvus.yaml"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

function show_current_log_level() {
    local current_level=$(grep -A 5 "^log:" "$CONFIG_FILE" | grep "level:" | awk '{print $2}' | head -1)
    echo "当前日志级别: $current_level"
}

function set_log_level() {
    local level=$1
    
    if [[ ! "$level" =~ ^(debug|info|warn|error|panic|fatal)$ ]]; then
        log_error "无效的日志级别: $level"
        log_error "有效的日志级别: debug, info, warn, error, panic, fatal"
        return 1
    fi
    
    # 备份原配置文件
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    log_info "配置文件已备份为: $CONFIG_FILE.bak"
    
    # 修改日志级别
    sed -i.tmp "s/level: [a-zA-Z]*/level: $level/" "$CONFIG_FILE"
    rm -f "$CONFIG_FILE.tmp"
    
    log_info "日志级别已设置为: $level"
    
    # 显示相关配置
    echo ""
    echo "相关配置:"
    grep -A 5 "^log:" "$CONFIG_FILE" | head -6
}

function restore_config() {
    if [ -f "$CONFIG_FILE.bak" ]; then
        mv "$CONFIG_FILE.bak" "$CONFIG_FILE"
        log_info "配置文件已恢复"
    else
        log_warn "未找到备份文件"
    fi
}

function show_usage() {
    echo "Milvus 日志级别配置脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  debug         设置日志级别为 debug (最详细)"
    echo "  info          设置日志级别为 info (默认)"
    echo "  warn          设置日志级别为 warn"
    echo "  error         设置日志级别为 error"
    echo "  show          显示当前日志级别"
    echo "  restore       恢复原始配置"
    echo ""
    echo "示例:"
    echo "  $0 debug      # 启用 debug 日志"
    echo "  $0 info       # 恢复到 info 级别"
    echo "  $0 show       # 查看当前配置"
    echo ""
    echo "注意："
    echo "  - 修改后需要重启 Milvus 才能生效"
    echo "  - 可以使用 ./scripts/start_milvus_local.sh restart 重启"
    echo "  - debug 级别会产生大量日志，建议仅在调试时使用"
}

function main() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        exit 1
    fi
    
    case "${1:-}" in
        debug|info|warn|error|panic|fatal)
            set_log_level "$1"
            echo ""
            log_warn "请重启 Milvus 使配置生效:"
            echo "  ./scripts/start_milvus_local.sh restart"
            ;;
        show)
            show_current_log_level
            ;;
        restore)
            restore_config
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            log_error "未知命令: ${1:-}"
            show_usage
            exit 1
            ;;
    esac
}

main "$@" 