![[Pasted image 20250905161456.png]]

paper-beige-texture 是我最开始上传的版本，后续已经自己优化过了，但是采用的是 background url,
```html
<div

aria-hidden

className="pointer-events-none absolute max-w-5xl left-1/2 -translate-x-1/2 top-0 mx-auto w-full min-w-[960px] xl:rotate-90 xl:translate-y-1/4 aspect-[7/5] z-0 bg-no-repeat bg-center"

style={{

backgroundImage: `url('/textures/paper-beige-texture-trimmed.png')`,

backgroundSize: "contain",

opacity: 0.8,

}}

/>
```
![[Pasted image 20250905161608.png]]
![[Pasted image 20250905161556.png]]


可以看到用 <Image>的读取的是_next路径下打包的产物，放在 public 文件夹里读取的话也不会进行资源更新