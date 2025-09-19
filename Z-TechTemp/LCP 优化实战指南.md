# LCP (Largest Contentful Paint) 优化实战指南

## 概述
LCP 是 Core Web Vitals 中的关键指标，测量页面主要内容的加载时间。理想值应在 2.5 秒以内。

## 优化策略实施记录

### 1. 图片优化策略

#### WebP/AVIF 格式转换
**问题**：图片文件过大影响 LCP 性能
**解决方案**：编写 prebuild 脚本自动转换图片格式

```javascript
#!/usr/bin/env node
import { mkdir, readdir } from "node:fs/promises"
import path from "node:path"
import sharp from "sharp"

const SRC_DIR = path.resolve("public/images")
const OUT_DIR = SRC_DIR // 直接在原目录旁生成 .avif / .webp

const exts = new Set([".jpg", ".jpeg", ".png"])

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true })
  
  for (const entry of entries) {
    const p = path.join(dir, entry.name)
    
    if (entry.isDirectory()) await walk(p)
    else {
      const ext = path.extname(entry.name).toLowerCase()
      if (!exts.has(ext)) continue
      await convert(p)
    }
  }
}

async function convert(file) {
  const base = file.slice(0, file.lastIndexOf("."))
  const avifOut = `${base}.avif`
  const webpOut = `${base}.webp`
  const input = sharp(file)

  // 平衡画质与体积的配置
  await input
    .clone()
    .avif({ quality: 50, effort: 4 }) // effort 越大越慢；50~60 画质/体积比较均衡
    .toFile(avifOut)
    .catch(() => null)

  await input
    .clone()
    .webp({ quality: 70 })
    .toFile(webpOut)
    .catch(() => null)
}

await mkdir(OUT_DIR, { recursive: true })
await walk(SRC_DIR)
console.log("✅ AVIF/WebP 生成完成")
```

#### Next.js 配置调整
```javascript
const nextConfig = {
  images: {
    formats: ["image/avif", "image/webp"], // 优先使用现代格式
  },
}
```

#### 代码中的使用方式
```html
<Image
  src="/images/small-envelop.png"  // 代码中仍引用 PNG
  alt=""
  width={96}
  height={72}
  aria-hidden
  className="w-16 h-auto drop-shadow-md"
/>
```
**说明**：代码中依旧写 PNG 路径，Next.js 会自动选择最优格式

### 2. LCP Request Discovery 优化

#### 首屏图片懒加载问题
**问题**：关键的首屏图片被设置了懒加载，延迟了 LCP
**解决方案**：
- 占据首屏较多空间的图片添加 `priority` 属性
- 移除首屏关键图片的 `loading="lazy"`

```jsx
<Image
  src="/hero-image.jpg"
  alt="Hero image"
  width={800}
  height={600}
  priority  // 关键：首屏重要图片设置优先级
  className="w-full h-auto"
/>
```

### 3. 可访问性优化

#### ARIA 属性配置
**问题**：缺少必要的 aria 属性影响可访问性评分
**解决方案**：
- 装饰性图片添加 `aria-hidden="true"`
- 有意义的图片确保有合适的 `alt` 描述

#### Heading 结构优化
**问题**：标题元素层级不连续
**解决方案**：
- 确保标题按 h1 → h2 → h3 的顺序使用
- 不跳级使用标题标签

### 4. Layout Shift (CLS) 相关优化

**问题**：页面加载时元素移动导致布局偏移
**常见原因**：
- 图片没有预设尺寸
- 字体加载导致文本重排
- 动态内容插入

**解决方案**：
- 为所有图片设置明确的 `width` 和 `height`
- 使用 `font-display: swap` 优化字体加载
- 为动态内容预留空间

## 效果评估

### 优化前后对比
- **优化前**：LCP > 4s
- **优化后**：LCP < 2.5s
- **主要改进**：图片格式优化减少了 60% 的图片大小

### 关键改进点
1. **图片优化**：自动化 AVIF/WebP 转换流程
2. **优先级设置**：首屏关键资源加载优化
3. **代码质量**：HTML 语义化和可访问性提升

## 待优化项目
- [ ] 服务端渲染优化
- [ ] 关键 CSS 内联
- [ ] 资源预加载策略
- [ ] CDN 配置优化

## 注意事项
- 图片优化脚本在打包过程中自动执行，无需手动操作
- 保持代码中使用原始图片路径，框架会自动选择最优格式
- 定期监控 Core Web Vitals 指标变化