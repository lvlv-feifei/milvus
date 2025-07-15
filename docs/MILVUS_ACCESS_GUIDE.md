# 🎯 Milvus 服务访问完整指南

## 📝 概述

本指南详细介绍了如何访问Milvus及其所有相关依赖项服务，包括Web UI界面、API端点和客户端连接方式。

## 🚀 快速访问

### 一键查看所有服务
```bash
# 显示所有服务的访问信息
./scripts/open_milvus_ui.sh

# 一键打开所有Web界面
./scripts/open_milvus_ui.sh open
```

## 📊 Milvus 主服务

### 基本信息
- **主服务端口**: `localhost:19530`
- **协议**: gRPC
- **用途**: 客户端连接、数据操作、向量搜索

### 连接方式

#### Python客户端
```python
from pymilvus import connections, Collection

# 连接到Milvus
connections.connect("default", host="localhost", port="19530")

# 创建或获取集合
collection = Collection("example_collection")
```

#### Go客户端
```go
import (
    "context"
    "github.com/milvus-io/milvus-sdk-go/v2/client"
)

// 连接到Milvus
ctx := context.Background()
c, err := client.NewGrpcClient(ctx, "localhost:19530")
```

#### Node.js客户端
```javascript
import { MilvusClient } from "@zilliz/milvus2-sdk-node";

// 连接到Milvus
const client = new MilvusClient("localhost:19530");
```

#### Java客户端
```java
import io.milvus.client.MilvusServiceClient;
import io.milvus.param.ConnectParam;

// 连接到Milvus
ConnectParam connectParam = ConnectParam.newBuilder()
    .withHost("localhost")
    .withPort(19530)
    .build();
MilvusServiceClient client = new MilvusServiceClient(connectParam);
```

### 健康检查
```bash
# HTTP健康检查
curl -X GET http://localhost:19530/health

# 返回示例
{"status":"ok"}
```

## 🌐 Web UI 界面

### 1. MinIO 控制台
- **URL**: [http://localhost:9001](http://localhost:9001)
- **用户名**: `minioadmin`
- **密码**: `minioadmin`
- **用途**: 对象存储管理、文件浏览、桶管理

#### 功能特性
- 📁 浏览和管理存储桶
- 📤 上传和下载文件
- 🔐 访问权限管理
- 📊 存储使用情况监控

#### 快速打开
```bash
# 仅打开MinIO控制台
./scripts/open_milvus_ui.sh minio
```

### 2. Pulsar 管理界面
- **URL**: [http://localhost:18080](http://localhost:18080)
- **用途**: 消息队列管理、主题监控、订阅状态

#### 功能特性
- 📈 集群状态监控
- 📮 主题和订阅管理
- 📊 消息吞吐量统计
- 🔍 命名空间管理

#### 快速打开
```bash
# 仅打开Pulsar管理界面
./scripts/open_milvus_ui.sh pulsar
```

### 3. Jaeger 追踪界面
- **URL**: [http://localhost:16686](http://localhost:16686)
- **用途**: 分布式追踪、性能监控、调试

#### 功能特性
- 🔍 分布式请求追踪
- ⏱️ 性能瓶颈分析
- 🐛 错误诊断
- 📊 服务依赖图

#### 快速打开
```bash
# 仅打开Jaeger追踪界面
./scripts/open_milvus_ui.sh jaeger
```

## 🔧 API 端点

### 1. etcd (元数据存储)
- **客户端端口**: `localhost:2379`
- **Peer端口**: `localhost:2380`
- **备用端口**: `localhost:4001`

#### 基本操作
```bash
# 健康检查
curl http://localhost:2379/health

# 查看所有键值对
curl http://localhost:2379/v2/keys?recursive=true

# 使用etcdctl (需要安装etcdctl)
etcdctl --endpoints=localhost:2379 get "" --prefix
```

### 2. MinIO API (对象存储)
- **API端点**: `localhost:9000`
- **协议**: S3兼容API

#### 基本操作
```bash
# 健康检查
curl http://localhost:9000/minio/health/live

# 使用AWS CLI (需要配置credentials)
aws --endpoint-url=http://localhost:9000 s3 ls
```

#### Python示例
```python
import boto3

# 配置MinIO客户端
client = boto3.client('s3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='minioadmin',
    aws_secret_access_key='minioadmin'
)

# 列出桶
response = client.list_buckets()
print(response['Buckets'])
```

### 3. Pulsar (消息队列)
- **服务端口**: `localhost:6650`
- **协议**: Pulsar Protocol

#### 基本操作
```bash
# 集群状态
curl http://localhost:18080/admin/v2/clusters

# 查看命名空间
curl http://localhost:18080/admin/v2/namespaces/public
```

#### Python示例
```python
import pulsar

# 连接到Pulsar
client = pulsar.Client('pulsar://localhost:6650')

# 创建生产者
producer = client.create_producer('my-topic')

# 发送消息
producer.send('Hello Milvus!'.encode('utf-8'))
```

### 4. Azurite (Azure存储模拟)
- **Blob服务**: `localhost:10000`
- **协议**: Azure Storage API

#### 基本操作
```bash
# 测试连接
curl http://localhost:10000/devstoreaccount1?comp=list

# 创建容器
curl -X PUT http://localhost:10000/devstoreaccount1/test-container?restype=container
```

### 5. GCP Native (GCP存储模拟)
- **服务端口**: `localhost:4443`
- **协议**: Google Cloud Storage API

#### 基本操作
```bash
# 测试连接
curl http://localhost:4443/storage/v1/b

# 创建桶
curl -X POST http://localhost:4443/storage/v1/b?project=test-project \
  -H "Content-Type: application/json" \
  -d '{"name": "test-bucket"}'
```

## 📋 完整端口列表

| 服务 | 端口 | 协议 | 用途 | Web UI |
|------|------|------|------|---------|
| **Milvus** | 19530 | gRPC | 主服务 | ❌ |
| **etcd** | 2379 | HTTP/gRPC | 元数据存储 | ❌ |
| **etcd** | 2380 | HTTP | Peer通信 | ❌ |
| **etcd** | 4001 | HTTP | 备用端口 | ❌ |
| **Pulsar** | 6650 | Pulsar | 消息队列 | ❌ |
| **Pulsar** | 18080 | HTTP | 管理界面 | ✅ |
| **MinIO** | 9000 | HTTP | 对象存储API | ❌ |
| **MinIO** | 9001 | HTTP | Web控制台 | ✅ |
| **Azurite** | 10000 | HTTP | Azure存储 | ❌ |
| **Jaeger** | 16686 | HTTP | 追踪界面 | ✅ |
| **Jaeger** | 4317 | gRPC | OTLP接收 | ❌ |
| **Jaeger** | 4318 | HTTP | OTLP接收 | ❌ |
| **Jaeger** | 14268 | HTTP | Jaeger Thrift | ❌ |
| **Jaeger** | 6831 | UDP | Jaeger Agent | ❌ |
| **GCP Native** | 4443 | HTTP | GCP存储模拟 | ❌ |

## 🔍 故障排除

### 检查服务状态
```bash
# 检查所有服务状态
./scripts/start_milvus_local.sh status

# 检查特定端口
nc -z localhost 19530 && echo "Milvus is running" || echo "Milvus is not running"

# 检查所有端口
for port in 19530 2379 6650 9000 9001 10000 16686 4443; do
    nc -z localhost $port && echo "Port $port is open" || echo "Port $port is closed"
done
```

### 常见问题

#### 1. 无法连接到Milvus
```bash
# 检查Milvus是否运行
./scripts/start_milvus_local.sh status

# 查看Milvus日志
./scripts/start_milvus_local.sh logs

# 重启Milvus
./scripts/start_milvus_local.sh restart
```

#### 2. Web UI无法访问
```bash
# 检查服务状态
./scripts/open_milvus_ui.sh

# 重启依赖服务
./scripts/start_milvus_local.sh deps-down
./scripts/start_milvus_local.sh deps-up
```

#### 3. 端口被占用
```bash
# 查找占用端口的进程
lsof -i :19530

# 结束占用进程
kill -9 <PID>
```

## 🎯 最佳实践

### 1. 开发流程
```bash
# 1. 启动所有服务
./scripts/start_milvus_local.sh up

# 2. 打开Web界面进行监控
./scripts/open_milvus_ui.sh open

# 3. 开发和测试你的应用
# ... your development work ...

# 4. 查看日志和追踪
./scripts/start_milvus_local.sh logs
# 访问 http://localhost:16686 查看Jaeger追踪

# 5. 停止所有服务
./scripts/start_milvus_local.sh down
```

### 2. 监控和调试
- 使用Jaeger追踪界面监控请求性能
- 通过MinIO控制台检查数据存储情况
- 利用Pulsar管理界面监控消息队列状态

### 3. 快速访问命令
```bash
# 添加到你的 ~/.bashrc 或 ~/.zshrc
alias milvus-up="./scripts/start_milvus_local.sh up"
alias milvus-down="./scripts/start_milvus_local.sh down"
alias milvus-status="./scripts/start_milvus_local.sh status"
alias milvus-ui="./scripts/open_milvus_ui.sh open"
alias milvus-logs="./scripts/start_milvus_local.sh logs"
```

## 📚 相关文档

- [Milvus官方文档](https://milvus.io/docs)
- [PyMilvus API参考](https://pymilvus.readthedocs.io/)
- [MinIO文档](https://min.io/docs/minio/linux/index.html)
- [Apache Pulsar文档](https://pulsar.apache.org/docs/en/standalone/)
- [Jaeger文档](https://www.jaegertracing.io/docs/) 