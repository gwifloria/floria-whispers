



![[Pasted image 20250905162809.png]]

1. 图片大小优化 WebP/Avif
		a. 写了一个 prebuild 脚本，这样在打包过程中不需要去手动操作图片大小，找到的图片基本上能直接用，代码里依旧引入 png，线上代码自己
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

  // 你可以根据图片类型区分质量，这里给一个均衡配置

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

  // 可选：为 JPG/PNG 重写元数据/优化（保持原始作为最终兜底）

  // await input.jpeg({ quality: 80, mozjpeg: true }).toFile(`${base}.opt.jpg`)
}

await mkdir(OUT_DIR, { recursive: true })

await walk(SRC_DIR)

console.log("✅ AVIF/WebP 生成完成")

```

这里改一下 nextconfig 配置
```javascript
const nextConfig = {
  images: {
    formats: ["image/avif", "image/webp"],
  },
}


```



```html
<image
  src="/images/small-envelop.png"
  alt=""
  width="{96}"
  height="{72}"
  aria-hidden
  className="w-16 h-auto drop-shadow-md"
/>

```
编写代码时候依旧是 png

![[Pasted image 20250909091839.png]]
２ LCP request discovery
		a. 首屏图片懒加载
	占据首屏较多空间的图片添加ｐｒｉｏｒｉｔｙ属性，
３.　aria属性
![[Pasted image 20250908112050.png]]




![[Pasted image 20250908114238.png]]


  
### Heading elements are not in a sequentially-descending order
Properly ordered headings that do not skip levels convey the semantic structure of the page, making it easier to navigate and understand when using assistive technologies. [Learn more about heading order](https://dequeuniversity.com/rules/axe/4.10/heading-order).





### Layout shift culprits

Layout shifts occur when elements move absent any user interaction. [Investigate the causes of layout shifts](https://web.dev/articles/optimize-cls?utm_source=lighthouse&utm_medium=devtools), such as elements being added, removed, or their fonts changing as the page loads.CLS




  
#### Page is blocked from indexing

Search engines are unable to include your pages in search results if they don't have permission to crawl them. [Learn more about crawler directives](https://developer.chrome.com/docs/lighthouse/seo/is-crawlable/?utm_source=lighthouse&utm_medium=devtools).