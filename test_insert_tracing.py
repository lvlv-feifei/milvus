#!/usr/bin/env python3
"""
Milvus Insert 全过程测试脚本
用于理解 insert 的完整链路，包括日志分析和 tracing 分析
"""

import time
import json
import logging
from pymilvus import MilvusClient
import random

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MilvusInsertAnalyzer:
    def __init__(self, uri="http://127.0.0.1:19530", token="root:Milvus"):
        self.client = MilvusClient(uri=uri, token=token)
        self.collection_name = "insert_analysis_test"
        
    def setup_collection(self):
        """设置测试集合"""
        logger.info("=== 1. 设置测试集合 ===")
        
        # 删除已存在的集合
        try:
            self.client.drop_collection(self.collection_name)
            logger.info(f"删除已存在的集合: {self.collection_name}")
        except:
            pass
        
        # 创建新集合
        logger.info(f"创建新集合: {self.collection_name}")
        self.client.create_collection(
            collection_name=self.collection_name,
            dimension=128,
            auto_id=True,
            primary_field_name="id",
            vector_field_name="vector"
        )
        
        # 获取集合信息
        collection_info = self.client.describe_collection(self.collection_name)
        logger.info(f"集合信息: {collection_info}")
        
    def generate_test_data(self, num_rows=1000):
        """生成测试数据"""
        logger.info(f"=== 2. 生成测试数据 ({num_rows} 行) ===")
        
        data = []
        for i in range(num_rows):
            data.append({
                "vector": [random.random() for _ in range(128)],
                "text": f"document_{i}",
                "score": random.randint(1, 100)
            })
        
        logger.info(f"生成了 {len(data)} 条测试数据")
        return data
        
    def insert_with_analysis(self, data, batch_size=100):
        """执行 insert 操作并分析"""
        logger.info(f"=== 3. 执行 Insert 操作 (批次大小: {batch_size}) ===")
        
        total_rows = len(data)
        inserted_count = 0
        
        for i in range(0, total_rows, batch_size):
            batch = data[i:i+batch_size]
            
            logger.info(f"插入批次 {i//batch_size + 1}/{(total_rows-1)//batch_size + 1}")
            logger.info(f"当前批次数据量: {len(batch)}")
            
            # 记录开始时间
            start_time = time.time()
            
            try:
                # 执行插入
                result = self.client.insert(
                    collection_name=self.collection_name,
                    data=batch
                )
                
                # 记录结束时间
                end_time = time.time()
                duration = end_time - start_time
                
                logger.info(f"插入成功: {result}")
                logger.info(f"插入耗时: {duration:.4f}s")
                logger.info(f"插入速率: {len(batch)/duration:.2f} rows/s")
                
                inserted_count += len(batch)
                
                # 短暂休息，便于观察日志
                time.sleep(0.1)
                
            except Exception as e:
                logger.error(f"插入失败: {e}")
                break
                
        logger.info(f"总共插入 {inserted_count} 条记录")
        
    def analyze_collection_stats(self):
        """分析集合统计信息"""
        logger.info("=== 4. 分析集合统计信息 ===")
        
        # 获取集合统计
        stats = self.client.get_collection_stats(self.collection_name)
        logger.info(f"集合统计信息: {stats}")
        
        # 列出所有分区
        partitions = self.client.list_partitions(self.collection_name)
        logger.info(f"分区列表: {partitions}")
        
    def test_search_after_insert(self):
        """测试插入后的搜索"""
        logger.info("=== 5. 测试插入后的搜索 ===")
        
        # 生成搜索向量
        search_vector = [random.random() for _ in range(128)]
        
        try:
            # 执行搜索
            search_result = self.client.search(
                collection_name=self.collection_name,
                data=[search_vector],
                limit=5,
                output_fields=["text", "score"]
            )
            
            logger.info(f"搜索结果: {search_result}")
            
        except Exception as e:
            logger.error(f"搜索失败: {e}")
            
    def cleanup(self):
        """清理测试数据"""
        logger.info("=== 6. 清理测试数据 ===")
        try:
            self.client.drop_collection(self.collection_name)
            logger.info(f"删除测试集合: {self.collection_name}")
        except Exception as e:
            logger.error(f"清理失败: {e}")
            
    def run_comprehensive_test(self):
        """运行完整的测试"""
        logger.info("开始 Milvus Insert 全过程分析测试")
        logger.info("=" * 60)
        
        try:
            # 1. 设置集合
            self.setup_collection()
            
            # 2. 生成测试数据
            test_data = self.generate_test_data(num_rows=500)
            
            # 3. 执行插入
            self.insert_with_analysis(test_data, batch_size=50)
            
            # 4. 分析统计
            self.analyze_collection_stats()
            
            # 5. 测试搜索
            self.test_search_after_insert()
            
            logger.info("=" * 60)
            logger.info("🎉 Insert 全过程分析测试完成!")
            
        except Exception as e:
            logger.error(f"测试过程中发生错误: {e}")
            
        finally:
            # 6. 清理
            self.cleanup()

def print_analysis_guide():
    """打印分析指南"""
    print("\n" + "="*60)
    print("📋 MILVUS INSERT 全过程分析指南")
    print("="*60)
    
    print("\n🔍 1. 日志分析命令:")
    print("# 查看 Proxy Insert 日志")
    print("grep -i 'proxy.*insert' /tmp/standalone.log")
    print()
    print("# 查看 Insert 操作日志")
    print("grep -i 'insert' /tmp/standalone.log | head -20")
    print()
    print("# 查看 DataNode Insert 处理日志")
    print("grep -i 'insert into growing segment' /tmp/standalone.log")
    print()
    print("# 查看特定集合的操作")
    print("grep 'insert_analysis_test' /tmp/standalone.log")
    print()
    print("# 查看 Insert 任务执行日志")
    print("grep 'insertTask' /tmp/standalone.log")
    print()
    print("# 查看 Insert 错误日志")
    print("grep -i 'error' /tmp/standalone.log | grep -i insert")
    print()
    print("# 查看 Insert 相关的 traceID")
    print("grep -i 'insert' /tmp/standalone.log | grep -o 'traceID=[a-f0-9]*' | head -5")
    
    print("\n🔍 2. JAEGER UI 分析:")
    print("1. 访问: http://localhost:16686")
    print("2. Service: 选择 'milvus-proxy'")
    print("3. Operation: 选择 'Proxy-Insert'")
    print("4. 查看 span 层级:")
    print("   - Proxy-Insert (根 span)")
    print("   - Proxy-Insert-PreExecute")
    print("   - Proxy-Insert-Execute")
    print("   - DataNode 相关 spans")
    print("5. 关键 traceID: 从上面的日志命令中获取")
    
    print("\n🔍 3. 性能指标关注点:")
    print("- Insert 总耗时")
    print("- 数据重新打包耗时")
    print("- Message Stream 发送耗时")
    print("- DataNode 写入存储耗时")
    print("- 段分配和管理耗时")
    
    print("\n🔍 4. 错误排查:")
    print("- 检查集合是否存在")
    print("- 验证数据格式是否正确")
    print("- 确认存储空间是否足够")
    print("- 查看网络连接状态")
    
    print("\n🔍 5. 启用 DEBUG 日志:")
    print("当前日志级别是 INFO，如需查看更详细的 DEBUG 信息：")
    print("1. 编辑 configs/milvus.yaml")
    print("2. 将 log.level 从 'info' 改为 'debug'")
    print("3. 重启 Milvus: ./scripts/start_milvus_local.sh restart")
    print("4. 或者设置环境变量: export MILVUS_LOG_LEVEL=debug")
    print("="*60)

if __name__ == "__main__":
    # 打印分析指南
    print_analysis_guide()
    
    # 等待用户确认
    input("\n按 Enter 键开始测试...")
    
    # 运行测试
    analyzer = MilvusInsertAnalyzer()
    analyzer.run_comprehensive_test()
    
    # 最后提示
    print("\n📋 测试完成后，请：")
    print("1. 查看 Milvus 日志文件")
    print("2. 访问 Jaeger UI 查看 tracing 信息")
    print("3. 分析性能瓶颈和优化点") 