# 缓存设计与内存管理方案

## 1. LRU 缓存存储 (utils/storage/lru.ts)

这是避免内存溢出的关键设计：

### 双 store 架构

- 主 store: 存储实际数据
- 使用 store: 记录访问时间戳 (`__${storeName}_usage`)

### 关键特性

- maxSize: 可配置的最大条目数 (默认 1000，最大 50000)
- evict (): 当超出 maxSize 时，自动驱逐最少使用的条目
- resize (newSize): 支持动态调整缓存大小

## 2. 缓存键生成 (utils/hasher.ts)

使用 SHA-256 哈希计算缓存键，包含以下维度：

- promptId + modelId
- 文本内容
- 上下文 (前后文本)
- 页面域名
- 源 / 目标语言

## 3. 清理逻辑

### 自动清理 (LRU 驱逐)

typescript

运行

```typescript
// lru.ts 中的 evict() 方法
async evict(n = 1): Promise<void> {
    const store = this.usage.db.transaction(this.usage.storeName).objectStore(this.usage.storeName)
    const cursor = store.index("lastUsed").openCursor()
    // 按 lastUsed 时间戳排序，删除最旧的 n 条
}
```

### 手动清理

- 用户可在设置页面调整 cacheSize
- Debug 页面提供 "清空缓存" 按钮
- 支持 disableCache 调试选项

## 4. 内存管理策略

|策略|实现方式|
|---|---|
|大小限制|maxSize 参数控制最大条目数|
|LRU 淘汰|基于 lastUsed 时间戳索引排序删除|
|动态调整|resize () 方法支持运行时调整大小|
|细粒度缓存|Thin Cache 机制，数组翻译时只缓存 / 读取单条|

## 关键代码位置

|文件|行号|功能|
|---|---|---|
|utils/storage/lru.ts|全文件|LRU 存储实现|
|utils/storage/kv.ts|全文件|基础 IndexedDB KV 存储|
|background/services/translate.ts|137-141|缓存初始化|
|background/services/translate.ts|269-275|缓存大小动态调整|
|utils/hasher.ts|全文件|缓存键生成|

## 可借鉴的实现方案

typescript

运行

```typescript
// 1. 创建 LRU 缓存
const cache = createLRUStorage<TranslationResult>(
    "your-cache-db",
    "translation-cache",
    1000  // 最大条目数
);

// 2. 读取时更新访问时间
const result = await cache.get(cacheKey);

// 3. 写入时自动检查大小，超出则 evict
await cache.set(cacheKey, translationResult);

// 4. 支持动态调整大小
cache.resize(newSize);
```

## 避免内存溢出的核心要点

1. 强制大小上限 - 不允许无限增长
2. LRU 淘汰 - 自动删除最久未使用的条目
3. 使用 IndexedDB - 数据存在磁盘而非内存
4. SHA-256 哈希键 - 固定长度，避免长文本作为键