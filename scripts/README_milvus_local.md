# Milvus本地开发脚本使用说明

本脚本专门为Mac用户设计，用于在Docker中启动Milvus依赖项，在本地运行Milvus服务。

## 系统要求

- macOS系统
- Docker Desktop
- 已编译的Milvus二进制文件 (`make milvus`)

## 功能特性

- 🔧 **自动架构检测**: 自动检测Apple Silicon (M1/M2)或Intel架构
- 🐳 **Docker依赖管理**: 在Docker中管理etcd、pulsar、minio等依赖项
- 🏠 **本地Milvus**: 在本地运行Milvus服务，便于调试
- 📊 **健康检查**: 自动检查所有服务的健康状态
- 📋 **状态监控**: 实时显示服务状态和端口信息

## 使用方法

### 1. 完整启动（推荐）

```bash
# 启动所有服务（Docker依赖 + 本地Milvus）
./scripts/start_milvus_local.sh up

# 停止所有服务
./scripts/start_milvus_local.sh down
```

### 2. 分步操作

```bash
# 仅启动Docker依赖项
./scripts/start_milvus_local.sh deps-up

# 仅启动本地Milvus
./scripts/start_milvus_local.sh milvus-start

# 仅停止本地Milvus
./scripts/start_milvus_local.sh milvus-stop

# 仅停止Docker依赖项
./scripts/start_milvus_local.sh deps-down
```

### 3. 状态和日志

```bash
# 查看所有服务状态
./scripts/start_milvus_local.sh status

# 查看Milvus日志
./scripts/start_milvus_local.sh logs

# 查看特定服务日志
./scripts/start_milvus_local.sh logs etcd
./scripts/start_milvus_local.sh logs pulsar
```

### 4. 其他操作

```bash
# 重启所有服务
./scripts/start_milvus_local.sh restart

# 显示帮助信息
./scripts/start_milvus_local.sh -h
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| Milvus | 19530 | 主服务端口 |
| etcd | 2379 | 元数据存储 |
| Pulsar | 6650 | 消息队列 |
| Minio | 9000 | 对象存储 |
| Minio Console | 9001 | 对象存储控制台 |
| Azurite | 10000 | Azure存储模拟 |
| Jaeger | 16686 | 链路追踪UI |
| GCP Native | 4443 | GCP存储模拟 |

## 数据目录

- **Milvus数据**: `/tmp/milvus_data`
- **Docker卷**: `./volumes/` (相对于docker-compose文件)
- **日志文件**: `/tmp/standalone.log`

## 故障排除

### 1. 服务启动失败

```bash
# 检查Docker状态
docker ps -a

# 查看特定服务日志
./scripts/start_milvus_local.sh logs <service_name>

# 重启Docker Desktop
```

### 2. 端口冲突

```bash
# 检查端口占用
lsof -i :19530
lsof -i :2379

# 停止占用端口的进程
kill -9 <PID>
```

### 3. Milvus连接问题

```bash
# 检查环境变量
echo $ETCD_ENDPOINTS
echo $MINIO_ADDRESS

# 验证依赖服务
./scripts/start_milvus_local.sh status
```

### 4. 权限问题

```bash
# 创建数据目录
mkdir -p /tmp/milvus_data
chmod 755 /tmp/milvus_data

# 给脚本执行权限
chmod +x scripts/start_milvus_local.sh
```

## 配置文件

### Apple Silicon (M1/M2)
使用 `docker-compose-apple-silicon-fixed.yml`，包含：
- Apple Silicon优化的镜像
- 正确的etcd配置
- 健康检查设置

### Intel架构
使用 `docker-compose.yml`，包含：
- 标准amd64镜像
- 完整的服务配置

## 开发提示

1. **编译Milvus**: 使用脚本前先运行 `make milvus`
2. **日志查看**: 使用 `tail -f /tmp/standalone.log` 实时查看日志
3. **环境变量**: 脚本自动设置所需的环境变量
4. **数据清理**: 停止服务后可以清理 `/tmp/milvus_data` 目录

## 镜像信息

脚本使用的Docker镜像：
- `docker.1ms.run/milvusdb/etcd:v3.5.18-r1`
- `milvusdb/pulsar:v2.8.2-m1`
- `docker.1ms.run/minio/minio:RELEASE.2024-05-28T17-19-04Z`
- `mcr.microsoft.com/azure-storage/azurite:latest`
- `docker.1ms.run/jaegertracing/all-in-one:latest`
- `docker.1ms.run/fsouza/fake-gcs-server:latest`

## 支持

如果遇到问题，请检查：
1. Docker Desktop是否正常运行
2. 所有依赖服务是否正常启动
3. 端口是否被占用
4. 日志文件中的错误信息 