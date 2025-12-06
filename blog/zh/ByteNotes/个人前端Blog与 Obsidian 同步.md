
今年终于把个人博客搭起来了。

说"终于"，是因为这事我拖了很久，不是不会做，是不知道怎么做好。

---

## 一、为什么拖了这么久

**关于记录习惯**

我平时用 Obsidian 记录，已经习惯了它的编辑体验。如果要做个人网站，就意味着：
- 要么放弃 Obsidian，在网站后台写
- 要么两边都写，手动同步

第一个选项不现实——我不可能放弃已经用习惯的工具。第二个选项太麻烦——光是想到"我要记得两边同时更新"，这多余的一步工作就会让我望而却步。

并且，如果要做网站编辑器，我还得开发一套存储方案、编辑器功能……于是我就干脆不做了。

**关于心理障碍**

现在回头看，我当时是典型的**完美主义思维**：
- 过度放大了过程的麻烦程度
- 把"可能会碰到的问题"都想得很严重
- 想"一口气吃成胖子"，觉得要一次性解决所有问题

其实**也许我根本不需要把事情想得那么复杂。**

---

## 二、灵光乍现

Obsidian 的 Git 同步功能大家都知道，我在做个人网站的时候发现 Git 仓库也可以当免费的存储服务使用，就突然意识到：**我的个人网站可以直接去拉取我 obsidian 的仓库列表就可以了**

**我不需要在个人网站上"编辑"内容，只需要"展示"内容。**

具体来说：
1. 我在 Obsidian 里写文章（照常）
2. 用 Obsidian 的 Git 插件，自动提交到 GitHub
3. 个人网站直接从 GitHub 拉取内容展示

这样一来：
- ✅ 我还是在熟悉的 Obsidian 里写
- ✅ 不需要开发编辑器
- ✅ 不需要开发存储系统
- ✅ 不需要担心两边同步

**简单说：Obsidian 是我的工坊，GitHub 是仓库，个人网站是展览厅。**

---

## 三、技术实现

### 系统架构

```mermaid
graph TB
    A[Obsidian 本地编辑] --> B[Obsidian Git 插件]
    B --> C[自动提交到 GitHub 仓库]
    C --> D[GitHub Repository<br/>存储 Markdown 文件]
    
    E[个人网站前端] --> F[API 代理层<br/>/api/github-service]
    F --> G[GitHub API<br/>使用 GITHUB_TOKEN]
    G --> D
    
    D --> G
    G --> F
    F --> E
    
    E --> H[渲染展示内容]
    
    style A fill:#e1f5ff
    style D fill:#fff4e6
    style E fill:#f3e5f5
    style F fill:#fce4ec
    style H fill:#e8f5e9
```

看起来挺复杂？其实只有三步：
1. **Obsidian → GitHub**（自动同步）
2. **网站 → GitHub**（读取内容）
3. **网站 → 浏览器**（展示给读者）

### 完整流程


```mermaid
sequenceDiagram
    participant User as 用户
    participant Obsidian as Obsidian
    participant GitPlugin as Git 插件
    participant GitHub as GitHub 仓库
    participant Website as 个人网站
    participant API as API 代理
    participant GitHubAPI as GitHub API
    
    Note over User,GitHub: 内容创作流程
    User->>Obsidian: 1. 编辑 Markdown
    Obsidian->>GitPlugin: 2. 保存文件
    GitPlugin->>GitHub: 3. 自动 git push
    
    Note over Website,GitHubAPI: 内容展示流程
    User->>Website: 4. 访问个人网站
    Website->>API: 5. 请求文章列表
    API->>GitHubAPI: 6. 携带 Token 请求
    GitHubAPI->>GitHub: 7. 获取仓库内容
    GitHub-->>GitHubAPI: 8. 返回文件列表
    GitHubAPI-->>API: 9. 返回数据
    API-->>Website: 10. 返回处理后的数据
    Website-->>User: 11. 渲染展示内容
    
    Note over User,GitHub: 内容更新流程
    User->>Obsidian: 12. 修改文章
    Obsidian->>GitPlugin: 13. 保存
    GitPlugin->>GitHub: 14. 自动推送更新
    User->>Website: 15. 刷新网站
    Website->>API: 16. 重新请求
    API->>GitHubAPI: 17. 获取最新内容
    GitHub-->>Website: 18. 展示更新后内容
```

简单来说：
- **我在 Obsidian 写 → Git 自动推送 → 网站自动更新**
- 全程自动化，我只需要专注写作

### 关于 GitHub API

这里有个技术细节需要注意：

GitHub API 有请求限制：
- 不带 Token：60 次/小时
- 带 Token：5000 次/小时

所以我的方案是：
1. 在环境变量里配置 `GITHUB_TOKEN`
2. 前端调用自己的 `/api/github-service` 代理
3. 代理层携带 Token 去请求 GitHub API
4. 避免 Token 暴露在客户端

---

## 四、方案优势

### 1. 单一数据源

我只在 Obsidian 中编辑，Git 自动同步。不需要在多个地方维护内容


### 2. 开发成本低

个人网站只需要"读"功能，不需要：
- ❌ 开发复杂的编辑器
- ❌ 开发存储系统
- ❌ 开发用户管理
- ❌ 开发同步逻辑

### 3. 技术栈熟悉

整个方案用的都是我熟悉的技术：
- Obsidian（日常在用）
- Git（前端必备）
- GitHub API（标准接口）
- Markdown 渲染（前端基础）

---

## 五、技术栈总结

给想参考的朋友一个清单：

**内容管理端**
- Obsidian（Markdown 编辑器）
- Obsidian Git 插件（自动同步）

**存储层**
- GitHub Repository（内容存储）
- Git（版本控制）

**后端**
- API 代理
- 环境变量（存储 `GITHUB_TOKEN`）

**前端**
- 个人网站（内容展示）
- Markdown 渲染器（解析和渲染）

**核心流程：**
```
Obsidian 编辑 
  → Git 自动推送 
    → GitHub 存储 
      → API 获取 
        → 网站展示
```

---

## 写在最后
我真是天才

**完美是优秀的敌人。**

**开始，比完美更重要。**
