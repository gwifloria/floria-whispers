# 文章阅读笔记说明

## 如何使用

### 从网页保存文章到 Obsidian

**方法一：使用 Web Clipper 插件**
1. 安装 Obsidian Web Clipper 插件
2. 在浏览器中点击插件图标
3. 直接保存到 `English Learning/Articles/` 文件夹

**方法二：使用 MCP 工具**
如果你在和 Claude 聊天时提到某篇文章，我可以直接帮你：
- 抓取文章内容
- 创建笔记
- 提取关键词汇

### 阅读流程

**第一遍：快速浏览**
- 只标出不认识的词和让你停顿的句子
- 不查词典，先猜意思
- 目标：理解大意

**第二遍：精读（可选）**
- 查关键词（不是所有词）
- 记录到 Vocabulary 部分
- 提炼 Key Points

**第三遍：输出（可选）**
- 用自己的话总结文章
- 尝试用新词造句
- 写在 My Thoughts

## 笔记原则

### ✅ 推荐做法
- 读100篇，只精读10篇
- 优先享受阅读，而不是记笔记
- 只记录真正让你有感触的内容
- 词汇只记你真正想记住的

### ❌ 避免做法
- 不要每个词都查
- 不要把每篇文章都做成完美笔记
- 不要为了学习而强迫自己读不感兴趣的内容
- 不要一次性记太多词汇

## 文件组织

```
English Learning/
├── Articles/
│   ├── Tech/          # 技术类文章
│   ├── Psychology/    # 心理学
│   ├── Writing/       # 写作技巧
│   └── Misc/          # 其他
```

## 推荐阅读源

### 技术 & 科技
- Hacker News (news.ycombinator.com)
- Paul Graham's Essays (paulgraham.com/articles.html)
- Wait But Why (waitbutwhy.com)

### 深度文章
- The Atlantic (theatlantic.com)
- The New Yorker (newyorker.com)
- Aeon (aeon.co)

### 轻松有趣
- Brain Pickings (themarginalian.org)
- Farnam Street (fs.blog)

## 进度追踪

```dataview
TABLE status, date, category
FROM "English Learning/Articles"
SORT date DESC
LIMIT 10
```

---
创建日期：2025-10-13