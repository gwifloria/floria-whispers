![[Pasted image 20250905161456.png]]



![[Pasted image 20250905162809.png]]

1. 图片大小优化 WebP/Avif
		a. 写了一个 prebuild 脚本，这样在打包过程中不需要去手动操作图片大小，找到的图片基本上能直接用，代码里依旧引入 png，线上代码自己
```javascript
const nextConfig = {
	
	images: {
	
		formats: ["image/avif", "image/webp"],
	}
},
```
```html
<Image

	src="/images/small-envelop.png"
	
	alt=""
	
	width={96}
	
	height={72}
	
	aria-hidden
	
	className="w-16 h-auto drop-shadow-md"

/>
```
编写代码时候依旧是 png

![[Pasted image 20250909091839.png]]
1. LCP request discovery
		a. 首屏图片懒加载
![[Pasted image 20250905184517.png]]![[Pasted image 20250908112050.png]]

![[Pasted image 20250908112731.png]]


![[Pasted image 20250908114238.png]]


  
### Heading elements are not in a sequentially-descending order
Properly ordered headings that do not skip levels convey the semantic structure of the page, making it easier to navigate and understand when using assistive technologies. [Learn more about heading order](https://dequeuniversity.com/rules/axe/4.10/heading-order).


![[Pasted image 20250908125603.png]]


Layout shift culprits

Layout shifts occur when elements move absent any user interaction. [Investigate the causes of layout shifts](https://web.dev/articles/optimize-cls?utm_source=lighthouse&utm_medium=devtools), such as elements being added, removed, or their fonts changing as the page loads.CLS

![[Pasted image 20250908132314.png]]


在整个页面玩