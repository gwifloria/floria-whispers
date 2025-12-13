# Large File Compression Upload Design Document

## Overview

Solving the problem of flomo exported ZIP files being too large (containing many images) to upload. By using client-side pre-compression, large files are compressed to under 10MB before uploading.

---

## Architecture Diagram

```plaintext
┌─────────────────────────────────────────────────────────────────────┐
│                        WhisperUploadTab.tsx                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  1. User drag-and-drop uploads ZIP file                        │  │
│  │         ↓                                                       │  │
│  │  2. Check if file size > 5MB?                                   │  │
│  │         ├── No → Upload directly to /api/whispers/upload        │  │
│  │         └── Yes → Call compressZipImages()                      │  │
│  │                        ↓                                        │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │            zipCompressor.ts                              │  │  │
│  │  │  ┌─────────────────────────────────────────────────┐    │  │  │
│  │  │  │  Stage 1: Unzip ZIP (JSZip)                      │    │  │  │
│  │  │  │  Stage 2: Separate images vs other files         │    │  │  │
│  │  │  │  Stage 3: Compress images (browser-image-compression) │ │  │
│  │  │  │           └── WebWorker (background thread, non-blocking UI) │ │
│  │  │  │  Stage 4: Repack ZIP                             │    │  │  │
│  │  │  └─────────────────────────────────────────────────┘    │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                        ↓                                        │  │
│  │  3. Check if compressed < 10MB? → Upload to /api/whispers/upload │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Files

| File | Responsibility |
|------|----------------|
| src/utils/zipCompressor.ts | ZIP decompression, image compression, repacking |
| src/app/admin/whispers/components/WhisperUploadTab.tsx | Upload UI, progress display, error handling |

---

## Key Technical Points

### 1. WebWorker Image Compression

```typescript
// zipCompressor.ts:62-68
const compressionOptions = {
  maxSizeMB: 0.2,           // Max 200KB per image
  maxWidthOrHeight: 1280,   // Max width/height 1280px
  useWebWorker: true,       // ✨ Key: Use WebWorker
  fileType: "image/jpeg",   // Convert to JPEG uniformly
  initialQuality: 0.7,      // Initial quality 70%
};
```

**Why use WebWorker?**

```plaintext
Main Thread (UI)                WebWorker (Background)
    │                              │
    │  postMessage(image data) ──→ │
    │                              │ ← Compression calculation (CPU intensive)
    │  ←── onmessage(compressed result) │
    │                              │
    ▼                              ▼
UI stays responsive           Doesn't block main thread
Progress bar updates smoothly
```

**Consequences without WebWorker:**

- UI freezes when compressing large images
- Progress bar doesn't move
- User thinks the page crashed

### 2. Smart Skip for Small Files

```typescript
// zipCompressor.ts:86-93
if (blob.size < 50 * 1024) {  // < 50KB skip
  newZip.file(name, blob);
  continue;
}
```

**Optimization effect**: Avoids redundant compression of already small images, saves time.

### 3. Immutable Data + Progress Callback

```typescript
// zipCompressor.ts:70-79
for (let i = 0; i < imageEntries.length; i++) {
  onProgress?.({
    stage: "compressing",
    current: i + 1,
    total: imageEntries.length,
    currentFile: fileName,
  });
  // ... compression logic
}
```

**UI display example**:

```plaintext
Compressing images (23/156)
photo_2024_03_15.jpg
████████████░░░░░░░░ 15%
```

### 4. Threshold Control

```typescript
// WhisperUploadTab.tsx:113-136
const COMPRESSION_THRESHOLD = 5 * 1024 * 1024;   // 5MB triggers compression
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024;        // 10MB upload limit

if (file.size > COMPRESSION_THRESHOLD) {
  // Execute compression
  const result = await compressZipImages(file, onProgress);

  // Check if still over limit after compression
  if (result.compressedZip.size > MAX_UPLOAD_SIZE) {
    setError({ message: "File still too large", ... });
    return;
  }
}
```

---

## Data Flow

```plaintext
User selects 30MB ZIP
      │
      ▼
┌─────────────────┐
│ 30MB > 5MB?    │ ── Yes ──→ Start compression
└─────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 1: extracting                             │
│ JSZip.loadAsync() decompress to memory          │
└─────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 2: Separate files                         │
│ Images: [photo1.jpg, photo2.png, ...] (156)     │
│ Other: [index.html, data.json, ...]             │
└─────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 3: compressing (WebWorker)                │
│ Compress images one by one, callback updates progress │
│ 2.5MB → 180KB, 1.8MB → 150KB, ...              │
└─────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────┐
│ Stage 4: repacking                              │
│ Repack as ZIP (DEFLATE level 6)                 │
└─────────────────────────────────────────────────┘
      │
      ▼
Compression result: 30MB → 7.2MB (76% compression ratio)
      │
      ▼
Upload to /api/whispers/upload
```

---

## Dependencies

| Library | Purpose | Features |
|---------|---------|----------|
| jszip | ZIP decompress/pack | Pure JS, browser compatible |
| browser-image-compression | Image compression | Built-in WebWorker support |

---

## Error Handling

```typescript
// WhisperUploadTab.tsx:47-90
const parseErrorDetails = (errorMessage, details) => {
  // MongoDB connection error
  if (fullError.includes("ESERVFAIL") || ...) {
    return { suggestions: ["Check network connection", ...] };
  }
  // File format error
  if (fullError.includes("ZIP") || ...) {
    return { suggestions: ["Make sure it's a flomo exported ZIP", ...] };
  }
  // ...
};
```

**User-friendly error message rules**:

- Don't display technical errors directly
- Provide actionable suggestions

---

## Performance Data

| Original Size | After Compression | Compression Ratio | Time |
|---------------|-------------------|-------------------|------|
| 30MB | 7.2MB | 76% | ~15s |
| 50MB | 9.8MB | 80% | ~25s |
| 15MB | 4.1MB | 73% | ~8s |

> Test environment: M1 MacBook Pro, Chrome 120

---

## Summary

| Design Decision | Reason |
|-----------------|--------|
| Client-side compression instead of server-side | Reduce bandwidth consumption, avoid server timeout |
| WebWorker | UI doesn't freeze, real-time progress updates |
| 5MB threshold trigger | Balance compression benefits and user wait time |
| Skip < 50KB images | Small image compression has low benefit, wastes time |
| Convert to JPEG uniformly | Better compression ratio, good compatibility |
