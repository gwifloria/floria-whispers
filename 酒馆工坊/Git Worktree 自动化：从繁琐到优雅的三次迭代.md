---
status: idea
type: 工坊
language: 待定
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
tags:
  - 
---

## 痛点

在研究 claudecode 的最佳实践中，知道 Git Worktree 和 claude 的搭配可以很大程度上激发 claude 的最大潜能。但我之前用得不多，仔细剖析自己不愿意用的愿意，发现主要是两个问题：

**1. 命令太长了**

```bash
git worktree add ../wonderland-nexus-feature-a -b feature-a
```

每次都要完整敲出项目名、路径、分支名，重复且容易打错。

**2. .env.local 不会自动同步**

这是 Git Worktree 的特性决定的——每个 worktree 是独立的文件系统目录，而 `.env.local` 被 `.gitignore` 忽略，自然不会被 git 同步过去。

问题是我的项目启动依赖这些本地环境变量配置


每次新建一个 worktree，下次都要再手动把这文件复制一遍，真的有点麻烦，（AI 果然让人越来越懒）
但因为这点小麻烦就放弃 使用 worktree 这个好工具，感觉像是捡了芝麻丢了西瓜。

所以我觉得这也可以自动化。我自己过去在 shell 里敲 git 命令时，已经配置过 `gp`（git push）、`gl`（git pull）这类 alias，深知少敲几个字符有多么爽。

干脆让 Claude 帮我写了个自动化方案，在做的过程中也发现了可以一步步迭代优化的点。

---

## V1：自动同步 .env.local

第一版的核心思路是：用一个 shell 脚本处理同步逻辑，再通过 git alias 把它和 `git worktree add` 串起来。

同步脚本 (scripts/sync-env-to-worktree.sh)：

- 自动检测主 worktree 的位置
- 遍历所有需要同步的 `.env.local` 文件
- 复制到目标 worktree 对应的位置

**Git Alias** (`.git/config`)：

```bash
git wt ../wonderland-nexus-feature feature-branch
# 创建 worktree 后自动触发同步脚本
```

这样就不用每次手动复制了。但命令本身还是很长，用起来还是不够爽。

---

## V2：简化命令输入

仔细观察了一下我的使用习惯：worktree 的路径通常是 `../项目名-分支名`，而分支名在命令里要敲两遍（路径里一次，`-b` 后面一次），那我觉得这也可以继续优化，就把我的需求喂给了 claudecode

优化后只需要输入分支名：

```bash
git wt feat-xxx
# 自动推断路径：../wonderland-nexus-feat-xxx
# 自动创建分支：-b feat-xxx
# 自动同步 .env.local
```

输入量一下子减少了 70%。当然，如果有特殊需求，完整模式还是保留着的：

```bash
git wt ~/custom-path -b custom-branch  # 完全兼容原来的用法
```

到这里已经很好用了，但我又发现了一个可以优化的点。

---

## V3：支持分支名用 `/` 分隔

我偶尔会用 Git 的 GUI 工具（比如 SourceTree），发现一个细节：如果分支名用 `/` 分隔（比如 `feat/xxx`），在 GUI 里会自动分组显示成文件夹结构：

```
📁 feat
  ├─ like-button
  └─ share-feature
📁 fix
  └─ navbar-bug
```

这样看起来很清晰，同类型的分支会被归到一起。这也是 Git Flow  推荐的命名方式。

但我也需要保留文件夹的命名方式

**最终方案**：让 Git 分支名保留 `/`，而 worktree 的文件夹路径自动把 `/` 转换成 `-`：

```bash
git wt feat/like-button
# Git 分支名：feat/like-button（GUI 中会分组显示）
# Worktree 路径：../wonderland-nexus-feat-like-button（文件系统友好）
```


---

## 最终的使用方式

```bash
# 日常使用（一个参数搞定一切）
git wt feat/new-feature

# 特殊需求（完整模式仍然可用）
git wt ~/custom-path -b branch

# 补救措施（忘了用 git wt 或者主 worktree 更新了配置）
yarn sync-env ../some-worktree
```

---

