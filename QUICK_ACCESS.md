# 🚀 Milvus 快速访问指南

## 🌟 一键启动和访问

```bash
# 1. 启动所有服务
./scripts/start_milvus_local.sh up

# 2. 查看服务状态
./scripts/open_milvus_ui.sh

# 3. 打开所有Web界面
./scripts/open_milvus_ui.sh open
```

## 🎯 主要服务

### Milvus 主服务
- **端口**: `19530`
- **连接**: `localhost:19530`
- **协议**: gRPC
- **健康检查**: `curl http://localhost:19530/health`

## 🌐 Web UI 界面 (可点击访问)

### [MinIO 控制台](http://localhost:9001)
- **URL**: http://localhost:9001
- **用户名**: `minioadmin`
- **密码**: `minioadmin`
- **用途**: 对象存储管理

### [Pulsar 管理界面](http://localhost:18080)
- **URL**: http://localhost:18080
- **用途**: 消息队列管理

### [Jaeger 追踪界面](http://localhost:16686)
- **URL**: http://localhost:16686
- **用途**: 分布式追踪和性能监控

## 📋 完整端口列表

| 服务 | 端口 | 访问地址 | 用途 |
|------|------|---------|------|
| **Milvus** | 19530 | `localhost:19530` | 主服务 |
| **MinIO控制台** | 9001 | [http://localhost:9001](http://localhost:9001) | 对象存储管理 |
| **Pulsar管理** | 18080 | [http://localhost:18080](http://localhost:18080) | 消息队列管理 |
| **Jaeger追踪** | 16686 | [http://localhost:16686](http://localhost:16686) | 分布式追踪 |
| **etcd** | 2379 | `localhost:2379` | 元数据存储 |
| **Pulsar** | 6650 | `localhost:6650` | 消息队列 |
| **MinIO API** | 9000 | `localhost:9000` | 对象存储API |
| **Azurite** | 10000 | `localhost:10000` | Azure存储模拟 |
| **GCP Native** | 4443 | `localhost:4443` | GCP存储模拟 |

## 🔧 快速命令

```bash
# 服务管理
./scripts/start_milvus_local.sh up          # 启动所有服务
./scripts/start_milvus_local.sh down        # 停止所有服务
./scripts/start_milvus_local.sh status      # 查看服务状态
./scripts/start_milvus_local.sh restart     # 重启所有服务

# 分步管理
./scripts/start_milvus_local.sh deps-up     # 仅启动Docker依赖
./scripts/start_milvus_local.sh milvus-start # 仅启动Milvus

# Web UI访问
./scripts/open_milvus_ui.sh                 # 显示访问信息
./scripts/open_milvus_ui.sh open            # 打开所有Web界面
./scripts/open_milvus_ui.sh minio           # 仅打开MinIO控制台

# 日志查看
./scripts/start_milvus_local.sh logs        # 查看Milvus日志
./scripts/start_milvus_local.sh logs etcd   # 查看etcd日志
```

## 📱 客户端连接示例

### Python
```python
from pymilvus import connections
connections.connect("default", host="localhost", port="19530")
```

### Go
```go
c, err := client.NewGrpcClient(context.Background(), "localhost:19530")
```

### Node.js
```javascript
const client = new MilvusClient("localhost:19530");
```

## 🔍 故障排除

```bash
# 检查端口是否开放
nc -z localhost 19530

# 查看所有端口状态
for port in 19530 2379 6650 9000 9001 10000 16686 4443; do
    nc -z localhost $port && echo "✅ Port $port" || echo "❌ Port $port"
done

# 重启服务
./scripts/start_milvus_local.sh restart
```

## 📚 详细文档

- [完整访问指南](docs/MILVUS_ACCESS_GUIDE.md)
- [使用说明](scripts/README_milvus_local.md)
- [配置详情](MILVUS_LOCAL_SETUP.md) 