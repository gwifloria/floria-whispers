

## 1. LRU Cache Storage (utils/storage/lru.ts)

This is the key design to avoid memory overflow:

### Dual Store Architecture

- Main store: Stores actual data
- Usage store: Records access timestamps (`__${storeName}_usage`)

### Key Features

- maxSize: Configurable maximum entry count (default 1000, max 50000)
- evict(): Automatically evicts least used entries when exceeding maxSize
- resize(newSize): Supports dynamic cache size adjustment

## 2. Cache Key Generation (utils/hasher.ts)

Uses SHA-256 hash to calculate cache keys, including these dimensions:

- promptId + modelId
- Text content
- Context (preceding and following text)
- Page domain
- Source/target language

## 3. Cleanup Logic

### Auto Cleanup (LRU Eviction)

```typescript
// evict() method in lru.ts
async evict(n = 1): Promise<void> {
    const store = this.usage.db.transaction(this.usage.storeName).objectStore(this.usage.storeName)
    const cursor = store.index("lastUsed").openCursor()
    // Sort by lastUsed timestamp, delete oldest n entries
}
```

### Manual Cleanup

- Users can adjust cacheSize in settings page
- Debug page provides "Clear Cache" button
- Supports disableCache debug option

## 4. Memory Management Strategies

| Strategy | Implementation |
|----------|---------------|
| Size Limit | maxSize parameter controls max entry count |
| LRU Eviction | Delete based on lastUsed timestamp index sorting |
| Dynamic Adjustment | resize() method supports runtime size adjustment |
| Fine-grained Caching | Thin Cache mechanism, array translation only caches/reads single entries |

## Key Code Locations

| File | Line Numbers | Function |
|------|--------------|----------|
| utils/storage/lru.ts | Full file | LRU storage implementation |
| utils/storage/kv.ts | Full file | Basic IndexedDB KV storage |
| background/services/translate.ts | 137-141 | Cache initialization |
| background/services/translate.ts | 269-275 | Dynamic cache size adjustment |
| utils/hasher.ts | Full file | Cache key generation |

## Reusable Implementation Pattern

```typescript
// 1. Create LRU cache
const cache = createLRUStorage<TranslationResult>(
    "your-cache-db",
    "translation-cache",
    1000  // Max entry count
);

// 2. Update access time on read
const result = await cache.get(cacheKey);

// 3. Auto-check size on write, evict if exceeded
await cache.set(cacheKey, translationResult);

// 4. Support dynamic size adjustment
cache.resize(newSize);
```

## Core Points to Avoid Memory Overflow

1. Enforce size limit - Don't allow unlimited growth
2. LRU eviction - Automatically delete least recently used entries
3. Use IndexedDB - Data stored on disk not in memory
4. SHA-256 hash keys - Fixed length, avoids long text as keys
