
---

# 🟦 一、React 核心机制类（高频、必问）

---

## **1. React 的渲染流程是什么？更新为什么是异步的？**

### 📌 标准答法：

React 渲染分两阶段：

### **① render phase（可中断）**

- 根据 state/props 计算新的虚拟 DOM（Fiber tree）
    
- 这一阶段纯计算，无 DOM 操作
    
- React18/19 支持并发 → render 阶段 **可被打断、重启**
    

### **② commit phase（不可中断）**

- 将 diff 结果真实更新到 DOM
    
- 执行 layout effect、ref 回调
    

---

### ⚠️ 为什么更新是异步的？

为了性能 & 并发：

- 批处理（batch updates）减少重绘次数
    
- 避免频繁 DOM 更新
    
- 让 React 可以执行调度（scheduler）
    
- 让更高优先级任务（用户输入）可以中断 render
    

---

## **2. React 中 state 为什么可能“拿不到最新值”？**

原因有 3 个：

### ✔ ① setState 是异步批处理

React 会把多次 setState 合并，等事件结束后再更新。

### ✔ ② 闭包导致拿到旧值

函数组件中的回调捕获旧的 state。

### ✔ ③ useEffect 执行晚（commit 后）

所以 effect 里读到的是渲染完成后的结果。

---

## **3. 为什么直接修改 state 对象页面不会更新？**

因为：

### **React 依赖“引用变化”判断 state 是否改变。**

如果你写：

```js
state.count = 1;
setState(state);
```

引用没变 → React 判定“无需渲染”。

### 正确写法：

```js
setState(prev => ({ ...prev, count: 1 }));
```

---

## **4. 虚拟 DOM 到底是不是快？意义是什么？**

√ 虚拟 DOM **不是为了提高性能而生，而是为了工程可维护性。**

它的意义：

1. **跨平台抽象 layer**（ReactDOM、ReactNative、ReactPDF…）
    
2. **减少手动 DOM 管理**，避免内存泄漏、手动 diff
    
3. **配合 Fiber 实现并发、可中断渲染**
    
4. **统一 diff 策略**，按需更新
    

---

## **5. React 中 key 的作用是什么？为什么不能用 index？**

### key 用于：

- 保持元素 identity（是否复用 DOM）
    
- 决定是否复用子组件的 state
    

### 🚫 index 会导致的问题：

- 添加/删除时，错误复用组件
    
- 输入框内容错位
    
- 动画闪烁
    

---

# 🟩 二、Hooks 深度题（高级开发必问）

---

## **6. useEffect 和 useLayoutEffect 的区别？**

|特性|useLayoutEffect|useEffect|
|---|---|---|
|执行时机|DOM 更新后、浏览器绘制前|绘制后执行|
|场景|读取/计算布局、避免闪烁|数据请求、订阅|
|是否阻塞绘制|✔ 会|✘ 不会|

### 总结：

- useLayoutEffect 适合 **需要“视觉无闪动”** 的场景
    
- useEffect 适合异步逻辑
    

---

## **7. useMemo 和 useCallback 的区别？什么时候滥用？**

### ✔ useMemo 缓存“值”

```js
const list = useMemo(() => calc(), [deps]);
```

### ✔ useCallback 缓存“函数”

```js
const fn = useCallback(() => doSomething(), [deps]);
```

### 卡点：

它们只有在“子组件 memo 化”或“重计算开销大”时才必要。  
**无脑使用反而增加性能开销（创建依赖数组 + 多一次比较）。**

---

## **8. useRef 到底有什么用？和 state 的区别？**

|useRef|state|
|---|---|
|改变不会触发渲染|改变会触发渲染|
|存 DOM 或可变数据|存 UI 状态|
|生命周期内引用稳定|需要 setState|

### 面试关键词：

> **ref 是 React 的 escape hatch（逃生舱）** —— 允许存可变值不影响渲染。

---

## **9. 自定义 Hook 是怎么保证状态隔离？**

每次组件调用 hook 时，React 为组件维护一套独立的 hook state。  
自定义 hook 只是一组内置 hooks 的组合，所以 **每次调用都会生成一份新的独立状态**。

---

## **10. React 如何判断依赖数组变化？**

使用 **Object.is** 逐项比较。  
因此对象/数组/函数每次都变化（引用变），会导致 effect 重新执行。

---

# 🟧 三、React 18 并发特性（高级岗常问）

---

## **11. 什么是 concurrent mode？为什么需要它？**

### React18 开启并发后：

- 渲染可被中断
    
- 高优先级任务可先执行（如输入）
    
- 大量渲染变得更平滑
    

技术底层：

- Fiber + Scheduler
    
- 时间切片（time slicing）
    

---

## **12. useTransition 的使用场景？**

用于让某些更新“变为低优先级”。

例子：搜索列表：

```js
const [isPending, startTransition] = useTransition();

startTransition(() => {
  setFiltered(bigData.filter(...));
});
```

好处：输入框不卡顿，渲染延迟但流畅。

---

## **13. useDeferredValue 的用途？**

让一个值“延迟同步”，适合：

- 大量渲染
    
- 输入防抖
    
- 搜索过滤
    

它和 useTransition 区别：  
**useDeferredValue 是“被动延迟”，useTransition 是“主动标记”。**

---

## **14. Suspense 是如何处理异步的？**

原理：  
当组件遇到 “未 resolve 的 promise”，会抛出该 promise →  
React 捕获 → 显示 fallback → promise resolve → 渲染真实内容。

常用场景：

- React.lazy
    
- RSC 数据加载
    
- Streaming SSR
    

---

# 🟨 四、渲染行为 & 性能优化

---

## **15. React 组件什么时候会重新渲染？**

1. state 变化
    
2. props 变化
    
3. context 变化
    
4. 父组件重新渲染（默认子组件也执行函数体）
    
5. Redux/ Zustand 中订阅的变化
    

---

## **16. 如何避免不必要的渲染？**

技巧：

✔ React.memo  
✔ useCallback / useMemo  
✔ 拆组件（状态粒度化）  
✔ 虚拟列表（windowing）  
✔ 减少 context 范围  
✔ 使用 signals（future trend）

---

## **17. 列表上万条如何优化？**

- 虚拟滚动（react-window）
    
- 分片渲染（scheduler + requestIdleCallback）
    
- Web Worker + Suspense
    
- RSC 渲染大数据（不下发 bundle）
    

---

## **18. context 为什么会导致过度渲染？如何优化？**

因为 context 更新会导致 **所有订阅组件重新渲染**。

解决：

- 拆分 context
    
- use-context-selector
    
- 用 Zustand / Jotai store 替代
    
- signals/atom 架构
    

---

# 🟦 五、工程化 & SSR（必问）

---

## **19. CSR / SSR / SSG / ISR 的区别？**

|模式|渲染时机|特点|
|---|---|---|
|CSR|浏览器|首屏慢，但后续快|
|SSR|服务器|首屏快、SEO 好|
|SSG|构建时|性能最佳，纯静态|
|ISR|构建后按需增量生成|数据可更新|

---

## **20. Next.js 中 getServerSideProps / getStaticProps 的使用场景？**

- getServerSideProps：每次请求时拿数据（动态页面）
    
- getStaticProps：构建时拿数据（博客、文档）
    
- getStaticPaths：动态静态路径
    

---

## **21. React SSR 如何处理 hydration？**

流程：

1. 服务端生成 HTML
    
2. 客户端加载 JavaScript
    
3. React 进行 hydration（为 HTML 绑定事件）
    

注意点：

- 不能使用随机数、时间等产生 mismatch
    
- 不能依赖 window 对象
    

---

# 🟦 六、实战场景题

---

## **22. 如何实现全局请求 loading（顶部进度条）？**

方案：

1. axios/fetch interceptor 拦截请求
    
2. 全局 loading store（context or Zustand）
    
3. 顶部使用 nprogress 或 progress bar
    
4. 请求数量计数 + 完成后 decrement
    

---

## **24. 大文件上传怎么做？**

重点关键词：

- 切片（Blob.slice）
    
- 并发上传（Promise.all）
    
- 断点续传（记录已完成分片）
    
- md5 校验（spark-md5）
    
- WebSocket 实时进度通知
    

---

## **25. 无限滚动加载需要哪些技术？**

- IntersectionObserver 监听触底
    
- 防抖节流
    
- loading / error / retry
    
- 虚拟列表减少渲染
    

---

# 🟥 七、代码走查题

---

## **27. 这段代码会渲染几次？**

```jsx
useEffect(() => {
  console.log(count);
}, [count]);
```

每次点击按钮：

1. setState → 触发一次重新渲染
    
2. commit → 执行 effect  
    → 打印一次
    

**总共 1 次渲染 + 1 次 effect 执行**

---

## **28. 为什么这个会无限渲染？**

```jsx
useEffect(() => {
  setState(Math.random());
}, []);
```

因为：

- effect 在 commit 后执行
    
- setState → 触发重新渲染 → commit
    
- 又执行 effect → 又 setState
    
- 无限循环
    

---

## **29. 子组件接收函数 props 导致性能问题，如何优化？**

因为每次父组件重新渲染都会创建新函数引用。

解决：

✔ useCallback 缓存函数  
✔ 或直接让子组件用 React.memo  
✔ 或把 handler 下放到子组件内部

---

# 🟦 想继续吗？

如果你愿意，我可以继续生成：

### 🔥 **React19 高频面试题 50 题（带答案）**

### 🔥 **按你经验做一套 React19 模拟面试（我来问你答）**

### 🔥 **一份 React19 面试速查表（可打印版）**

你想要哪个？