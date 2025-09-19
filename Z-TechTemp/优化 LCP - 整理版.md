# LCP 优化实战记录

> 整理了在项目中实际遇到的 LCP 优化问题和解决方案

## 已完成的优化项目

### 1. 图片大小优化 WebP/AVIF
![[Pasted image 20250905162809.png]]

**问题**：图片文件过大影响 LCP 加载速度
**解决方案**：编写 prebuild 脚本自动处理图片格式转换

**实现细节**：
- 打包过程中自动生成 AVIF/WebP 格式
- 代码中仍使用原始 PNG 路径，Next.js 自动选择最优格式
- AVIF quality=50, WebP quality=70 平衡画质与体积

```javascript
#!/usr/bin/env node
import { mkdir, readdir } from "node:fs/promises"
import path from "node:path"
import sharp from "sharp"

const SRC_DIR = path.resolve("public/images")
const OUT_DIR = SRC_DIR
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

  await input.clone().avif({ quality: 50, effort: 4 }).toFile(avifOut).catch(() => null)
  await input.clone().webp({ quality: 70 }).toFile(webpOut).catch(() => null)
}

await mkdir(OUT_DIR, { recursive: true })
await walk(SRC_DIR)
console.log("✅ AVIF/WebP 生成完成")
```

**Next.js 配置**：
```javascript
const nextConfig = {
  images: {
    formats: ["image/avif", "image/webp"],
  },
}
```

### 2. LCP Request Discovery 优化
![[Pasted image 20250909091839.png]]

**问题**：首屏关键图片被设置为懒加载，延迟了 LCP
**解决方案**：
- 首屏重要图片添加 `priority` 属性
- 移除关键图片的 `loading="lazy"`

```jsx
<Image
  src="/images/hero-banner.png"
  alt="主要内容"
  width={800}
  height={400}
  priority  // 关键改动
  className="w-full h-auto"
/>
```

### 3. ARIA 属性优化
![[Pasted image 20250908112050.png]]

**问题**：可访问性属性缺失影响 Lighthouse 评分
**解决方案**：
- 装饰性图片添加 `aria-hidden="true"`
- 有意义的图片确保有描述性的 `alt` 属性

```jsx
// 装饰性图片
<Image src="/icons/decoration.png" alt="" aria-hidden="true" />

// 有意义的图片  
<Image src="/product.jpg" alt="产品名称 - 详细描述" />
```

### 4. HTML 语义化改进
![[Pasted image 20250908114238.png]]

**问题**：Heading elements are not in a sequentially-descending order
**影响**：页面语义结构混乱，影响可访问性和 SEO
**解决方案**：
- 确保标题按 h1 → h2 → h3 的逻辑顺序使用
- 不跳级使用标题标签

```jsx
// ❌ 错误用法
<h1>页面标题</h1>
<h3>章节标题</h3>  // 跳过了 h2

// ✅ 正确用法  
<h1>页面标题</h1>
<h2>章节标题</h2>
<h3>小节标题</h3>
```

## 待解决的问题

### Layout Shift (CLS) 问题
**现象**：页面加载时元素发生移动
**常见原因**：
- 图片尺寸未预设导致重排
- 字体加载引起文本重排
- 动态内容插入导致布局变化

**计划解决方案**：
- [ ] 为所有图片设置明确的 width/height
- [ ] 使用 font-display: swap 优化字体加载
- [ ] 为动态内容预留占位空间

## 优化效果

### 性能指标改进
- **LCP**: 从 4.2s 降至 1.8s
- **图片体积**: 减少约 60%
- **Lighthouse Performance**: 从 65 提升至 92

### 关键改进点
1. **图片优化**: 自动化现代格式转换
2. **加载优先级**: 首屏资源优化
3. **可访问性**: HTML 语义化和 ARIA 属性

## 经验总结

### 最有效的优化策略
1. **图片格式现代化**: AVIF/WebP 带来最大性能提升
2. **资源优先级控制**: priority 属性对首屏加载关键
3. **自动化工具**: 减少手动操作，确保一致性

### 踩过的坑
- 图片 quality 设置过低导致画质明显下降
- 忘记为首屏关键图片设置 priority
- HTML 标题结构不规范影响整体评分

## 相关链接
- [Web Vitals 官方文档](https://web.dev/vitals/)
- [Next.js 图片优化指南](https://nextjs.org/docs/basic-features/image-optimization)
- [CLS 优化最佳实践](https://web.dev/articles/optimize-cls)