#!/usr/bin/env python3
"""
Test Milvus Connection Script
测试 Milvus 连接脚本
"""

from pymilvus import MilvusClient
import logging
import random

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_milvus_connection():
    """测试 Milvus 连接"""
    try:
        logger.info("正在连接到 Milvus...")

        # 1. Create a milvus client
        client = MilvusClient(
            uri="http://localhost:19530",
            token="root:Milvus"
        )

        logger.info("✅ 成功连接到 Milvus!")

        # 2. Create a collection (如果不存在)
        collection_name = "test_collection"

        # 检查集合是否已存在
        collections = client.list_collections()
        logger.info(f"当前集合列表: {collections}")

        if collection_name not in collections:
            logger.info(f"正在创建集合: {collection_name}")
            client.create_collection(
                collection_name=collection_name,
                dimension=5
            )
            logger.info(f"✅ 成功创建集合: {collection_name}")
        else:
            logger.info(f"集合 {collection_name} 已存在")

        # 3. List collections again
        collections = client.list_collections()
        logger.info(f"更新后的集合列表: {collections}")

        # 4. 获取集合信息
        if collection_name in collections:
            collection_info = client.describe_collection(collection_name)
            logger.info(f"集合信息: {collection_info}")

        # 5. 插入一些测试数据
        logger.info("正在插入测试数据...")
        test_data = [
            {
                "id": i,
                "vector": [random.random() for _ in range(5)],  # 5维向量
                "text": f"document_{i}"
            }
            for i in range(10)
        ]

        insert_result = client.insert(collection_name=collection_name, data=test_data)
        logger.info(f"✅ 插入数据结果: {insert_result}")

        # 6. 进行向量搜索测试 (修复 search_data 参数错误)
        logger.info("正在进行向量搜索测试...")

        # 生成搜索向量 - 正确的格式应该是5维浮点数列表
        search_vector = [random.random() for _ in range(5)]
        search_vectors = [search_vector]  # search需要向量列表，即使只搜索一个向量

        logger.info(f"搜索向量: {search_vector}")

        # 执行搜索
        search_result = client.search(
            collection_name=collection_name,
            data=search_vectors,  # 正确的search_data格式：向量列表
            limit=3,
            output_fields=["id", "text"]
        )

        logger.info(f"✅ 搜索结果: {search_result}")

        # 7. 查询测试
        logger.info("正在进行查询测试...")
        query_result = client.query(
            collection_name=collection_name,
            filter="id in [0, 1, 2]",
            output_fields=["id", "text", "vector"]
        )
        logger.info(f"✅ 查询结果: {query_result}")

        logger.info("🎉 Milvus 连接测试成功完成!")
        return True

    except Exception as e:
        logger.error(f"❌ Milvus 连接测试失败: {str(e)}")
        logger.error(f"错误类型: {type(e).__name__}")
        import traceback
        logger.error(f"详细错误信息:\n{traceback.format_exc()}")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("Milvus 连接测试")
    print("=" * 50)

    success = test_milvus_connection()

    if success:
        print("\n🎉 测试成功! Milvus 服务正常运行")
    else:
        print("\n❌ 测试失败! 请检查 Milvus 服务状态")
        print("确保 Milvus 服务在 localhost:19530 上运行")