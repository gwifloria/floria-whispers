
## 概述

解决 flomo 导出 ZIP 文件过大（包含大量图片）导致无法上传的问题。通过客户端预压缩，将大文件压缩到 10MB 以内再上传。

---

## 架构图

plaintext

```plaintext
┌─────────────────────────────────────────────────────────────────────┐
│                        WhisperUploadTab.tsx                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  1. 用户拖拽上传 ZIP 文件                                       │  │
│  │         ↓                                                       │  │
│  │  2. 检测文件大小 > 5MB?                                         │  │
│  │         ├── 否 → 直接上传到 /api/whispers/upload               │  │
│  │         └── 是 → 调用 compressZipImages()                      │  │
│  │                        ↓                                        │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │            zipCompressor.ts                              │  │  │
│  │  │  ┌─────────────────────────────────────────────────┐    │  │  │
│  │  │  │  Stage 1: 解压 ZIP (JSZip)                       │    │  │  │
│  │  │  │  Stage 2: 分离图片 vs 其他文件                    │    │  │  │
│  │  │  │  Stage 3: 压缩图片 (browser-image-compression)   │    │  │  │
│  │  │  │           └── WebWorker (后台线程，不阻塞 UI)     │    │  │  │
│  │  │  │  Stage 4: 重新打包 ZIP                           │    │  │  │
│  │  │  └─────────────────────────────────────────────────┘    │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                        ↓                                        │  │
│  │  3. 检测压缩后 < 10MB? → 上传到 /api/whispers/upload           │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 核心文件

|文件|职责|
|---|---|
|src/utils/zipCompressor.ts|ZIP 解压、图片压缩、重新打包|
|src/app/admin/whispers/components/WhisperUploadTab.tsx|上传 UI、进度展示、错误处理|

---

## 关键技术点

### 1. WebWorker 图片压缩

typescript

运行

```typescript
// zipCompressor.ts:62-68
const compressionOptions = {
  maxSizeMB: 0.2,           // 单张图片最大 200KB
  maxWidthOrHeight: 1280,   // 最大宽高 1280px
  useWebWorker: true,       // ✨ 关键：使用 WebWorker
  fileType: "image/jpeg",   // 统一转 JPEG
  initialQuality: 0.7,      // 初始质量 70%
};
```

**为什么用 WebWorker？**

plaintext

```plaintext
主线程 (UI)                    WebWorker (后台)
    │                              │
    │  postMessage(图片数据)  ──→  │
    │                              │ ← 压缩计算（CPU 密集）
    │  ←── onmessage(压缩结果)     │
    │                              │
    ▼                              ▼
UI 保持响应                    不阻塞主线程
进度条流畅更新
```

**不用 WebWorker 的后果：**

- 压缩大图片时 UI 卡死
- 进度条不动
- 用户以为页面崩溃了

### 2. 智能跳过小文件

typescript

运行

```typescript
// zipCompressor.ts:86-93
if (blob.size < 50 * 1024) {  // < 50KB 跳过
  newZip.file(name, blob);
  continue;
}
```

**优化效果**：避免对已经很小的图片重复压缩，节省时间。

### 3. 不可变数据 + 进度回调

typescript

运行

```typescript
// zipCompressor.ts:70-79
for (let i = 0; i < imageEntries.length; i++) {
  onProgress?.({
    stage: "compressing",
    current: i + 1,
    total: imageEntries.length,
    currentFile: fileName,
  });
  // ... 压缩逻辑
}
```

**UI 展示示例**：

plaintext

```plaintext
正在压缩图片 (23/156)
photo_2024_03_15.jpg
████████████░░░░░░░░ 15%
```

### 4. 阈值控制

typescript

运行

```typescript
// WhisperUploadTab.tsx:113-136
const COMPRESSION_THRESHOLD = 5 * 1024 * 1024;   // 5MB 触发压缩
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024;        // 10MB 上传限制

if (file.size > COMPRESSION_THRESHOLD) {
  // 执行压缩
  const result = await compressZipImages(file, onProgress);

  // 检查压缩后是否仍超限
  if (result.compressedZip.size > MAX_UPLOAD_SIZE) {
    setError({ message: "文件仍然过大", ... });
    return;
  }
}
```

---

## 数据流

plaintext

```plaintext
用户选择 30MB ZIP
      │
      ▼
┌─────────────────┐
│ 30MB > 5MB?    │ ── 是 ──→ 开始压缩
└─────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 1: extracting                             │
│ JSZip.loadAsync() 解压到内存                     │
└─────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 2: 分离文件                                │
│ 图片: [photo1.jpg, photo2.png, ...]  (156张)    │
│ 其他: [index.html, data.json, ...]              │
└─────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 3: compressing (WebWorker)                │
│ 逐张压缩图片，回调更新进度                         │
│ 2.5MB → 180KB, 1.8MB → 150KB, ...              │
└─────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 4: repacking                              │
│ 重新打包为 ZIP (DEFLATE level 6)                │
└─────────────────────────────────────────────────┘
      │
      ▼
压缩结果: 30MB → 7.2MB (压缩率 76%)
      │
      ▼
上传到 /api/whispers/upload
```

---

## 依赖库

|库|用途|特点|
|---|---|---|
|jszip|ZIP 解压 / 打包|纯 JS，浏览器兼容|
|browser-image-compression|图片压缩|内置 WebWorker 支持|

---

## 错误处理

typescript

运行

```typescript
// WhisperUploadTab.tsx:47-90
const parseErrorDetails = (errorMessage, details) => {
  // MongoDB 连接错误
  if (fullError.includes("ESERVFAIL") || ...) {
    return { suggestions: ["检查网络连接", ...] };
  }
  // 文件格式错误
  if (fullError.includes("ZIP") || ...) {
    return { suggestions: ["确保是 flomo 导出的 ZIP", ...] };
  }
  // ...
};
```

**用户友好的错误提示规则**：

- 不直接显示技术错误
- 提供可操作的建议

---

## 性能数据

|原始大小|压缩后|压缩率|耗时|
|---|---|---|---|
|30MB|7.2MB|76%|~15s|
|50MB|9.8MB|80%|~25s|
|15MB|4.1MB|73%|~8s|

> 测试环境：M1 MacBook Pro, Chrome 120

---

## 总结

|设计决策|原因|
|---|---|
|客户端压缩而非服务端|减少带宽消耗，避免服务端超时|
|WebWorker|UI 不卡顿，进度实时更新|
|5MB 阈值触发|平衡压缩收益和用户等待时间|
|跳过 <50KB 图片|小图片压缩收益低，浪费时间|
|统一转 JPEG|更好的压缩率，兼容性好|