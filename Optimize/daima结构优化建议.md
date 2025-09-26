

&gt; 基于 ~130 个 TypeScript/React 文件、6 665 行 TSX 代码的中等规模项目，聚焦开发体验与可维护性。

---

## 📊 当前项目情况
| 维度         | 数据                          |
| ---------- | --------------------------- |
| 总文件数       | 130+ 个 `.ts/.tsx`           |
| 总代码量       | ~6 665 行 TSX                |
| 组件/函数/常量导出 | 250+ 个                      |
| 目录结构       | Next.js 15 App Router（相对清晰） |
|            |                             |

---

## 🎯 主要优化方向

###  1. 统一组件导出模式
- [x] 

| 问题     | 缺少统一 `index.ts` 导出文件，导入路径长短不一、易出错                                                                                                                                                          |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **建议** | 1. `src/components/index.ts` 统一导出所有通用组件&lt;br&gt;2. 为 `src/services`、`src/hooks`、`src/utils` 添加「桶导出」&lt;br&gt;3. 消费侧统一写法：&lt;br&gt;`import { SmartIcon, PageHeader } from "@/components";` |

---

### 2. Hook 与 Utility 函数归类
- [ ] 

| 问题 | 通用 Hook 散落在页面目录（如 `useLetterComments`、`useLabs`、`useThrottle`） |
|---|---|
| **建议** | 1. 通用 Hook 全部迁移至 `src/hooks/`&lt;br&gt;2. 业务强相关 Hook 保留在对应页面，就近维护&lt;br&gt;3. 新建 `src/utils/` 统一管理纯函数工具库 |

---

### 3. 类型定义统一管理
- [x] 


| 问题     | 类型文件分散、重复定义风险高                                                                           |
| ------ | ---------------------------------------------------------------------------------------- |
| **建议** | 1. 全局共享类型移至 `src/types/`&lt;br&gt;2. 业务私有类型留在模块内部&lt;br&gt;3. 每个类型文件夹提供 `index.ts` 做集中导出 |

---

### 4. 常量文件规范化
- [x] 

| 问题 | 命名不统一（`constant.ts` vs `constants.ts`） |
|---|---|
| **建议** | 1. 统一使用 `constants.ts`&lt;br&gt;2. 建立 `src/constants/index.ts` 做桶导出&lt;br&gt;3. 按业务域分组 + 全大写蛇形命名，例如 `USER_STATUS` |

---

### 5. API 路由结构优化
- [x] 

| 问题     | 部分路由嵌套过深，可读性下降                                                                                                                     |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| **建议** | 1. 保持 RESTful 风格，适度扁平化&lt;br&gt;2. 新增 `src/middleware.ts` 统一处理认证、异常、日志&lt;br&gt;3. 引入 `next-swagger-doc` 或 `trpc-openapi` 自动生成接口文档 |

---

### 6. 测试文件组织
- [ ] 

| 问题     | 测试文件散落、覆盖率低                                                                                                                                              |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **建议** | 1. 统一命名：`*.test.ts`、`*.spec.ts` 放同级 `__tests__` 文件夹&lt;br&gt;2. 补充集成测试（Playwright / Cypress）&lt;br&gt;3. 提供 `src/test-utils/` 封装 mocks、render 函数、MSW 处理器 |

---

## 📈 预期收益
- **开发效率**：缩短导入路径，减少心智负担
- **维护性**：文件组织一致，降低上手成本
- **可扩展性**：模块边界清晰，新功能即插即用
- **代码质量**：类型集中管理 + 测试覆盖提升，减少隐性 Bug

---

## ⚡ 实施优先级
| 优先级 | 内容 | 预期收益 |
|---|---|---|
| 🔴 高 | 组件导出统一化 | 立即见效，减少路径碎片化 |
| 🟡 中 | Hook & 工具函数整理 | 长期可维护，复用率↑ |
| 🟢 低 | 常量文件规范化 | 渐进优化，命名一致即可 |

---

&gt; 按「高→中→低」顺序迭代，可在 1–2 个 Sprint 内完成主体改造，后续配合 Code Review 流程固化规范。


```markdown
# 项目优化计划

## 1. 类型定义整合优化

### 发现的问题
- **重复的 ByteNotes/Murmurs 类型定义**：
  - `src/app/blog/constants.ts` 中定义了 `CatKey = "ByteNotes" | "Murmurs"`
  - `src/types/blog.ts` 中重复定义了 `category: "ByteNotes" | "Murmurs"`
  - 多个文件中都有相同的类型引用
- **分散的类型定义**：
  - `GitHubItem` 在 `blog/constants.ts` 中定义，但更适合放在 `types/blog.ts` 或 `types/common.ts`

### 优化方案
1. **统一博客相关类型到 `src/types/blog.ts`**：
   - 将 `CatKey`, `BlogCategory`, `CateGroup`, `GitHubItem` 移动到 `types/blog.ts`
   - 更新所有引用这些类型的文件
2. **其他模块检查**：
   - 检查 `lab`, `gallery`, `contact`, `letters` 等模块的类型重复情况

## 2. Claude Code 命令配置

### 当前状态
✅ **已配置完善** - 你的 `.claude/settings.local.json` 配置非常好：

```json
{
  "permissions": {
    "allow": [
      "Bash(yarn typecheck)", "Bash(yarn lint)",
      "Bash(yarn test)", "Bash(yarn build)",
      "Bash(git status)", "Bash(git diff)",
      "Bash(npm run *)", "Bash(yarn *)"
    ],
    "hooks": {
      "after-edit": "yarn lint --fix && yarn typecheck && yarn test && yarn build",
      "PostToolUse": {
        "Edit|Write|MultiEdit": "自动运行代码检查和构建"
      }
    }
  }
}
```

### 建议改进
- 考虑添加 commit 命令权限：`"Bash(git commit -m *)"`
- 优化 hooks 执行顺序，避免重复运行

## 3. 项目结构优化建议

### 3.1 常量管理优化
- ✅ **已有良好的 `src/constants/index.ts` 统一导出**
- **建议**：将模块特定的常量逐步迁移到中心化管理

### 3.2 测试覆盖率提升

#### 当前测试文件：
- `src/app/tools/useThrottle.test.tsx`
- `src/services/github.simple.test.ts`
- `src/app/blog/components/PinControl.test.tsx`
- `src/components/BugFeedbackButton/BugFeedbackButton.test.tsx`

#### 建议增加测试：
- **核心 API 路由测试**
- **关键组件单元测试**
- **集成测试覆盖**

### 3.3 性能优化机会
1. **图像优化**：已使用 Next.js Image，但可考虑 blur placeholder
2. **代码分割**：动态导入非关键组件
3. **缓存策略**：API 响应缓存优化

### 3.4 代码组织改进
1. **类型定义集中化**（如上所述）
2. **共享 utilities 提取**
3. **组件 props 接口标准化**

## 实施优先级

| 优先级 | 任务 | 影响 |
|--------|------|------|
| 🔴 **高** | 类型定义整合 | 减少重复，提高维护性 |
| 🟡 **中** | 测试覆盖率提升 | 提高代码可靠性 |
| 🟢 **低** | 性能优化和代码组织改进 | 提升用户体验和开发效率 |

> 这个计划将显著提高代码质量、维护性和开发效率。
```