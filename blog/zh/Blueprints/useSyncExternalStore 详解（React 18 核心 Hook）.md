

## 一、代码架构图解

plaintext

```plaintext
┌─────────────────────────────────────────────────────────────┐
│                    模块级共享状态                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  readSlugsSnapshot = Set<string>  ← 已读文章的 slug 集合  ││
│  │  subscribers = Set<callback>      ← 订阅者列表            ││
│  │  isInitialized = false            ← 是否已从 localStorage 初始化 ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                                ↑
           ┌────────────────────┼────────────────────┐
           │                    │                    │
      ┌────┴────┐          ┌────┴────┐          ┌────┴────┐
      │ Sidebar │          │ BlogPost│          │ 其他组件 │
      │ 组件    │          │ 组件    │          │         │
      └─────────┘          └─────────┘          └─────────┘
           │                    │
      useReadStatus()      useReadStatus()
           │                    │
           └────────────────────┴─── 所有组件共享同一份状态！
```

## 二、为什么用 useSyncExternalStore？

### 问题背景（普通 useState 的缺陷）

tsx

```tsx
// ❌ 问题：每个组件有自己的状态副本
function Sidebar() {
  const [readSlugs, setReadSlugs] = useState(new Set()); // 副本 A
}

function BlogPost() {
  const [readSlugs, setReadSlugs] = useState(new Set()); // 副本 B
}
// Sidebar 更新了，BlogPost 不知道！
```

### 解决方案（共享外部状态）

tsx

```tsx
// ✅ 所有组件共享同一个 readSlugsSnapshot
let readSlugsSnapshot = new Set();  // 模块级变量，全局唯一

function useReadStatus() {
  const readSlugs = useSyncExternalStore(
    subscribe,      // 如何订阅变化
    getSnapshot,    // 如何获取当前值
    getServerSnapshot  // SSR 时的值
  );
}
```

## 三、核心代码逐行解析

### 1. 模块级共享状态（第 7-10 行）

typescript

运行

```typescript
let readSlugsSnapshot: Set<string> = new Set();  // 存储已读的 slug
let isInitialized = false;                        // 防止重复初始化
const subscribers = new Set<() => void>();        // 订阅者回调函数
```

> 这些变量在模块加载时创建一次，所有组件共享。

### 2. 发布 - 订阅模式（第 13-39 行）

typescript

运行

```typescript
// 通知所有订阅者："状态变了！"
function emitChange() {
  subscribers.forEach((callback) => callback());
}

// 订阅函数：组件挂载时调用
function subscribe(callback: () => void) {
  subscribers.add(callback);
  initializeFromStorage();  // 首次订阅时从 localStorage 读取
  return () => subscribers.delete(callback);  // 返回取消订阅函数
}
```

### 3. 标记已读（第 53-69 行）

typescript

运行

```typescript
function markAsRead(slug: string) {
  if (readSlugsSnapshot.has(slug)) return;  // 已读就跳过

  // ⚠️ 关键：创建新 Set，不能直接 .add()
  const next = new Set(readSlugsSnapshot);
  next.add(slug);
  readSlugsSnapshot = next;  // 替换引用

  localStorage.setItem(...);  // 持久化
  emitChange();  // 通知所有订阅者重新渲染
}
```

> 为什么要创建新 Set？ React 用引用比较判断是否需要更新。如果只 .add ()，引用不变，React 认为没变化。

### 4. SSR 处理（第 47-50, 82-86 行）

typescript

运行

```typescript
const emptySet = new Set<string>();
function getServerSnapshot() {
  return emptySet;  // SSR 时返回空 Set
}

// Hook 中
const isRead = useCallback((slug: string): boolean => {
  if (!isInitialized) return true;  // SSR 时默认"已读"，不显示 new 标签
  return readSlugs.has(slug);
}, [readSlugs]);
```

> 为什么 SSR 返回 true？ 避免 hydration 不匹配：
> 
> - 服务端：不知道 localStorage，无法判断
> - 客户端：知道 localStorage
> - 如果返回不同值，React 会报 hydration 错误

## 四、数据流图

plaintext

```plaintext
用户点击文章
        │
        ▼
  markAsRead("some-slug")
        │
        ▼
  ┌─────────────────────────────┐
  │ 1. 创建新 Set（不可变更新）   │
  │ 2. 保存到 localStorage      │
  │ 3. emitChange() 通知订阅者   │
  └─────────────────────────────┘
        │
        ▼ (所有订阅者的 callback 被调用)
        │
  ┌─────┴─────┐
  ▼           ▼
  Sidebar    其他组件
  重新渲染    重新渲染
```

## 五、使用示例（SideBar.tsx 第 175 行）

tsx

```tsx
// 只有 7 天内更新 且 未读 才显示 "new" 标签
{isWithinDays(file.updatedAt, 7) && !isRead(file.path) && (
  <span className="... bg-orange-100 text-orange-600 ...">
    new
  </span>
)}
```

## 六、总结：为什么这样写？

|需求|解决方案|
|---|---|
|跨组件共享状态|模块级变量 + useSyncExternalStore|
|持久化|localStorage|
|避免 hydration 错误|SSR 时返回默认值|
|触发 React 更新|不可变更新（创建新 Set）|