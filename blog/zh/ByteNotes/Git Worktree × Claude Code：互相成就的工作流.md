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

在研究 Claude Code 的最佳实践中，知道 Git Worktree 和 Claude 的搭配可以很大程度上激发 Claude 的最大潜能。但我之前好像用得不多，仔细剖析了一下自己：发现主要是两个问题：

**1. 命令太长了**

```bash
git worktree add ../wonderland-nexus-feature-a -b feature-a
```

每次都要完整敲出项目名、路径、分支名，重复且容易打错。

**2. .env.local 不会自动同步**

这是 Git Worktree 的特性决定的——每个 worktree 是独立的文件系统目录，而 `.env.local` 被 `.gitignore` 忽略，不会被 git 同步过去。

问题是我的项目启动依赖这些本地环境变量配置。每次新建一个 worktree，下次都要再手动把这文件复制一遍，真的有点麻烦（AI 果然让人越来越懒）。

但因为这点问题就放弃使用 worktree 这个工作流，感觉像是捡了芝麻丢了西瓜。

所以我觉得这也可以自动化。我自己过去在 shell 里敲 git 命令时，已经配置过 `gp`（git push）`gl`（git pull）这类 alias，深知少敲几个字符有多么爽。

干脆让 Claude 帮我写了个自动化方案，**尽可能让我少敲一点字**。

---

## V1：自动同步 .env.local

第一版的核心思路是：用一个 shell 脚本处理同步逻辑，再通过 git alias 把它和 `git worktree add` 串起来。

**同步脚本** (`scripts/sync-env-to-worktree.sh`)：

- 自动检测主 worktree 的位置
- 遍历所有需要同步的 `.env.local` 文件
- 复制到目标 worktree 对应的位置

**Git Alias** (`.git/config`)：

```ini
[alias]
    wt = "!f() { \
        git worktree add \"$@\" && \
        WORKTREE_PATH=$(echo \"$@\" | awk '{print $1}') && \
        ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
    }; f"
```

当执行 `git wt` 时，会先创建 worktree，然后自动调用同步脚本。

使用方式：

```bash
git wt ../wonderland-nexus-feature-A feature-A
# 创建 worktree 后自动触发同步脚本
```

另外在 `package.json` 里也加了个 npm script 作为备用：

```json
{
  "scripts": {
    "sync-env": "bash scripts/sync-env-to-worktree.sh"
  }
}
```

这样如果忘了用 `git wt`，或者主 worktree 的 `.env.local` 更新了，还可以手动同步：

```bash
yarn sync-env ../wonderland-nexus-feat-like
```

这样就不用每次手动复制了。但**命令本身还是很长，我还想再偷懒一点**。

---

## V2：简化命令输入

仔细观察了一下我的使用习惯，我们通常会使用一个 feat 点去做分支命名。那么：worktree 的路径通常是 `../项目名-feat名`
这就导致了 feat 名要敲两遍
1. 路径里项目命名
2. `-b` 后面定义分支名

```bash
git wt ../wonderland-nexus-feature-A feature-A
# 创建 worktree 后自动触发同步脚本
```
如上，两遍 feat-A

那我觉得这也可以继续优化，就把我的需求喂给了 Claude Code，让我只敲一个 feat 名，帮我自动补全文件夹命名及分支名

更新后的 Git Alias：

```ini
[alias]
    wt = "!f() { \
        if [ $# -eq 1 ]; then \
            BRANCH=\"$1\"; \
            WORKTREE_PATH=\"../wonderland-nexus-$BRANCH\"; \
            git worktree add \"$WORKTREE_PATH\" -b \"$BRANCH\"; \
        else \
            git worktree add \"$@\"; \
            WORKTREE_PATH=\"$1\"; \
        fi && \
        ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
    }; f"
```

逻辑很简单：检测参数数量，如果只有一个参数就走简化模式，自动推断路径和分支名；多个参数就走完整模式，透传给原生命令。

优化后只需要输入分支名：

```bash
git wt feat-A
# 自动推断路径：../wonderland-nexus-feat-A
# 自动创建分支：-b feat-A
# 自动同步 .env.local
```

输入量一下子减少了 70%。当然，如果有特殊需求，完整模式还是保留着的：

```bash
git wt ~/custom-path -b custom-branch  # 完全兼容原来的用法
```

到这里已经很好用了，但我又发现了一个可以在分支命名上优化的点。

---

## V3：支持分支名用 `/` 分隔

我偶尔会用 Git 的 GUI 工具（比如 SourceTree，包括 github 上的展示也是如此）：

如果分支名用 `/` 分隔（比如 `feat/xxx`），在 GUI 里会自动分组显示成文件夹结构：

```
📁 feat
  ├─ like-button
  └─ share-feature
📁 fix
  └─ navbar-bug
```

这样看起来很清晰，同类型的分支会被归到一起。这也是 Git Flow 推荐的命名方式。

但我也需要保留文件夹的命名方式。

**最终方案**：让 Git 分支名保留 `/`，而 worktree 的文件夹路径自动把 `/` 转换成 `-`：

```ini
[alias]
    wt = "!f() { \
        if [ $# -eq 1 ]; then \
            BRANCH=\"$1\"; \
            WORKTREE_NAME=$(echo \"$BRANCH\" | tr '/' '-'); \
            WORKTREE_PATH=\"../wonderland-nexus-$WORKTREE_NAME\"; \
            git worktree add \"$WORKTREE_PATH\" -b \"$BRANCH\"; \
        else \
            git worktree add \"$@\"; \
            WORKTREE_PATH=\"$1\"; \
        fi && \
        ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
    }; f"
```

关键改动是加了这行：

```bash
WORKTREE_NAME=$(echo \"$BRANCH\" | tr '/' '-')
```

用 `tr` 命令把分支名里的 `/` 转换成 `-`。

```bash
git wt feat/like-button
# Git 分支名：feat/like-button（GUI 中会分组显示）
# Worktree 路径：../wonderland-nexus-feat-like-button（文件系统友好）
```

---

## V4：Worktree多线进行，如何对应验证功能

用上了 git worktree 之后，我开始同时让 Claude 在不同分支上并行开发不同功能。这也意味着我在检查时可能会同时起多个服务，但有时候我并不确定哪个浏览器窗口对应的是哪个 feat。

那干脆在页面上直接显示当前分支名好了。

**1. 构建时注入分支名**

修改 `apps/web/next.config.mjs`，在 `env` 配置中添加：

```js
env: {
  NEXT_PUBLIC_GIT_BRANCH: (() => {
    try {
      return require('child_process')
        .execSync('git rev-parse --abbrev-ref HEAD')
        .toString().trim();
    } catch {
      return 'unknown';
    }
  })(),
},
```

**2. 创建开发环境指示器组件**

新建 `apps/web/src/components/DevBranchIndicator.tsx`：

- 仅在开发环境显示（`NODE_ENV === 'development'`）
- 固定在页面右下角，半透明悬浮样式
- 显示当前分支名
- 可折叠/展开，不影响正常页面操作

**3. 在根布局中引入**

在 `apps/web/src/app/layout.tsx` 的 body 末尾添加 `<DevBranchIndicator />` 组件。

这样每个窗口右下角都会显示当前分支名，一眼就能分清哪个是哪个。

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

## 小结

说实话这些需求都很小，但优化好了，日常使用的体验提升是实实在在的。

再回顾我做的这些东西，本质都是为了**偷懒偷懒再偷懒**
但这代表我是个懒人吗？
我觉得不是，因为这些恰好都是典型的重复性工作，我觉得这是 AI 最先该帮助我们解决的任务。

![[Pasted image 20251201082332.png]]

![[Pasted image 20251201082256.png]]
