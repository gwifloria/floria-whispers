---
status: idea
type: 工坊
language: 待定
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
tags:
  - 
---
知道 claude worktree 好用，但是之前用得没有那么多
1. 我的项目是 turbo，一些环境变量配置在.env.local，在新建分支时，项目的启动依赖.env.local本地的环境变量配置，但是
	1. git worktree add ../project-feature-a -b feature-a我觉得这个命令很长
	2.  Git Worktree 特性
   - 每个 worktree 是独立的文件系统目录
   - .env.local 被 .gitignore 忽略，不会被 git 同步
   - 因此每次新建一个worktree 下次都要再手动复制一遍，我觉得有点麻烦

但是因为芝麻丢了西瓜很可惜，我就干脆又让 claude 帮我完善了一个脚本
借助 git alias去配置，实现 git worktree创建时就自动帮我把本地变量文件 cv 过去

配置完之后我发现可以进行下一步优化
新建的文件夹通常是 project-name-feat-xxx，分支名通常是feat-xxx
敲两遍 feat 也很烦，那我们的指令可以进一步优化
因此有了 v2

因为我有时候也会用 git的 gui 工具，在分支名为 feat/xxx 时，在 gui 显示会像一个 folder，同样是 feat/下会被归类到同一个可折叠 folder，因此我觉得这个指令需要优化成：新建的文件夹以-命名，新建的分支以/区分，因此有了 v3

