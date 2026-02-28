

 Context

 AI Buddy 对话式交互已完成，用户希望 AI 建议可以「一键采纳」——直接执行优先级调整、创建子任务等操作。这涉及两个尚未在 Buddy
 中集成的能力：优先级修改和子任务管理。需要 TickTick 优先验证，Todoist 跟进。

 现状分析

 已具备

 ┌────────────────┬──────────────────┬────────────────────────────────────────────────────┐
 │      能力      │       状态       │                        说明                        │
 ├────────────────┼──────────────────┼────────────────────────────────────────────────────┤
 │ 优先级修改     │ adapter 层已支持 │ updateTask(id, { priority }) 两个 adapter 都实现了 │
 ├────────────────┼──────────────────┼────────────────────────────────────────────────────┤
 │ 任务创建       │ adapter 层已支持 │ createTask({ title, projectId })                   │
 ├────────────────┼──────────────────┼────────────────────────────────────────────────────┤
 │ AI 多轮对话    │ 已完成           │ sendBuddyRequest 支持 history                      │
 ├────────────────┼──────────────────┼────────────────────────────────────────────────────┤
 │ 任务数据上下文 │ 已完成           │ AI system prompt 包含任务列表                      │
 └────────────────┴──────────────────┴────────────────────────────────────────────────────┘

 需新增

 ┌───────────────────────┬───────────────────────────────────────────────────────────────────┐
 │         能力          │                               说明                                │
 ├───────────────────────┼───────────────────────────────────────────────────────────────────┤
 │ AI 输出结构化操作建议 │ 当前只输出纯文本，无法提取可执行操作                              │
 ├───────────────────────┼───────────────────────────────────────────────────────────────────┤
 │ 操作按钮 UI           │ BuddyMessage 无 action button 渲染                                │
 ├───────────────────────┼───────────────────────────────────────────────────────────────────┤
 │ 子任务创建 — TickTick │ 通过 updateTask 更新 items[]（checklist），需扩展 UpdateTaskInput │
 ├───────────────────────┼───────────────────────────────────────────────────────────────────┤
 │ 子任务创建 — Todoist  │ 通过 createTask({ parentId }) 创建子任务，需扩展 CreateTaskInput  │
 └───────────────────────┴───────────────────────────────────────────────────────────────────┘

 ---
 技术方案：AI 操作建议提取

 推荐方案：Prompt 引导 + 结构化区段解析

 核心思路：修改 system prompt，要求 AI 在自然语言建议后附加一个固定格式的「建议操作」区段。客户端解析该区段提取操作，再与实际任务列表匹配验证。

 为什么不用其他方案：
 - JSON response_format：不是所有 OpenAI 兼容 API 都支持（Gemini 兼容层、本地模型等）
 - 纯文本模糊匹配：可靠性低，维护成本高
 - Function calling：同样依赖模型能力，无法保证兼容性

 AI 输出格式：
 [自然语言建议，3-5 句话]

 :::actions
 set_priority|任务标题|high
 add_subtask|任务标题|步骤1,步骤2,步骤3
 :::

 解析策略：
 1. 用 :::actions / ::: 分隔符提取操作区段
 2. 逐行解析 type|taskTitle|params
 3. 将 taskTitle 与实际任务列表匹配（精确匹配优先，模糊匹配兜底）
 4. 匹配失败的行静默忽略
 5. 无 :::actions 区段 → 降级为纯文本（无操作按钮），不影响体验

 容错：AI 不输出 actions 区段完全不影响正常对话，只是没有操作按钮。

 ---
 开发阶段

 Phase 1：优先级一键采纳

 独立可交付，TickTick + Todoist 均可用（adapter 层已支持）

 改动清单（路径前缀 apps/extension/src/）：

 6. types/buddy.ts — 扩展类型
   - 新增 BuddyAction 联合类型：{ type: 'set_priority', taskId, taskTitle, priority, label }
   - BuddyMessage 增加 actions?: BuddyAction[]
 2. services/buddyActionParser.ts — 新建，操作提取
   - extractActions(text: string, tasks: Task[]): { cleanText: string, actions: BuddyAction[] }
   - 解析 :::actions 区段
   - set_priority|任务标题|high/medium/low/none → 匹配任务 → 生成 action
   - 导出 matchTaskByTitle(title: string, tasks: Task[]) 工具函数
 3. services/aiService.ts — 修改 system prompt
   - buildSystemPrompt 末尾增加操作格式说明
   - 要求 AI 在有具体建议时附加 :::actions 区段
   - priority 关键词：high/medium/low/none（统一用英文避免多语言歧义）
 4. components/Buddy/BuddyMessage.tsx — 增加 action 渲染
   - 新增 props：actions?: BuddyAction[], onAction?: (action: BuddyAction) => Promise<void>
   - assistant 消息底部渲染操作卡片
   - 每个 action 卡片：任务名 + 操作描述 + 「采纳」按钮
   - 按钮状态：idle → executing(loading) → done(checkmark) / error
 5. components/Buddy/BuddyPanel.tsx — 串联逻辑
   - AI 回复后调用 extractActions(reply, allTasks)
   - 将 cleanText 和 actions 存入 message
   - 实现 handleExecuteAction：调用 actions.updateTask(taskId, { priority })
   - 执行成功后刷新任务数据
 6. i18n/locales/{zh-CN,en}/buddy.json — 新增文案
   - action.adopt / action.adopted / action.failed
   - action.setPriority：「将优先级设为{{level}}」

 验证：
 - pnpm typecheck && pnpm build
 - TickTick 手动测试：AI 建议调整优先级 → 操作按钮出现 → 点击采纳 → 任务优先级更新
 - Todoist 手动测试：同上，确认优先级转换正确（内部 5 → Todoist 4）
 - 降级测试：AI 不输出 actions 区段 → 纯文本正常显示，无按钮

 ---
 Phase 2：子任务管理 — TickTick

 TickTick 使用 checklist（items[]），通过 updateTask 更新

 改动清单：

 1. api/adapters/types.ts — 扩展 UpdateTaskInput
   - 新增 items?: ChecklistItem[]
 2. types/buddy.ts — 新增 action 类型
   - { type: 'add_subtasks', taskId, taskTitle, subtitles: string[] }
 3. services/buddyActionParser.ts — 新增子任务解析
   - add_subtask|任务标题|步骤1,步骤2,步骤3 → 拆分为多个子任务
   - 合并同一父任务的子任务为一个 add_subtasks action
 4. services/aiService.ts — 补充 prompt
   - low mood 策略增强：明确要求 AI 用 add_subtask 格式输出拆解建议
   - 格式示例：add_subtask|写周报|打开模板,填写本周事项,检查并发送
 5. components/Buddy/BuddyMessage.tsx — 子任务 action 渲染
   - 展示父任务名 + 子任务列表 + 「全部添加」按钮
 6. components/Buddy/BuddyPanel.tsx — 子任务执行
   - 读取当前任务的 items[]
   - 追加新的 ChecklistItem（生成 id, status=0, sortOrder 递增）
   - 调用 actions.updateTask(taskId, { items: [...existing, ...newItems] })

 验证：
 - TickTick 手动测试：AI 建议拆解任务 → 子任务列表出现 → 点击添加 → checklist 项出现在 TickTick
 - 确认已有 checklist 项不被覆盖（追加而非替换）

 ---
 Phase 3：子任务管理 — Todoist 适配

 Todoist 子任务是独立 task + parentId，模型不同需要分支处理

 改动清单：

 1. api/adapters/types.ts — 扩展 CreateTaskInput
   - 新增 parentId?: string
 2. api/adapters/todoist/TodoistAdapter.ts — 传递 parentId
   - transformCreateTaskToTodoist 中处理 parentId 字段
   - 对应 Todoist API 的 parent_id 参数
 3. components/Buddy/BuddyPanel.tsx — 子任务执行分支
   - 通过 useAppMode().currentProvider 判断适配器类型
   - TickTick：updateTask(id, { items: [...] }) — 更新 checklist
   - Todoist：循环 createTask({ title, projectId, parentId }) — 创建子任务

 验证：
 - Todoist 手动测试：AI 建议拆解 → 点击添加 → 子任务出现在 Todoist（嵌套在父任务下）
 - TickTick 回归：确认 checklist 方式不受影响

 ---
 Phase 4：打磨优化（可选，按反馈优先级排序）

 - 批量采纳：多个 action 时显示「全部采纳」按钮
 - 采纳后反馈：action 执行后任务列表自动刷新，用户立即看到变化
 - 游客模式兜底：LocalAdapter 不支持 updateTask，检测并禁用操作按钮 + tooltip 提示
 - 撤销支持：优先级调整后短暂显示「撤销」选项
 - 解析优化：根据实际模型表现调整 prompt 和解析逻辑

 ---
 开发顺序总结

 Phase 1: 优先级一键采纳
   ├─ 基础设施（类型、解析器、prompt）
   ├─ UI（action 按钮渲染 + 执行）
   ├─ TickTick 测试 ✓
   └─ Todoist 测试 ✓
     ↓
 Phase 2: 子任务 — TickTick
   ├─ 扩展 UpdateTaskInput（items）
   ├─ 子任务解析 + UI
   └─ TickTick 测试 ✓
     ↓
 Phase 3: 子任务 — Todoist
   ├─ 扩展 CreateTaskInput（parentId）
   ├─ 适配器分支逻辑
   └─ Todoist 测试 ✓
     ↓
 Phase 4: 打磨（按需）

 每个 Phase 独立可交付，可单独 commit/release。

 关键文件

 ┌────────────────────────────────────────┬────────────┐
 │                  文件                  │ 涉及 Phase │
 ├────────────────────────────────────────┼────────────┤
 │ types/buddy.ts                         │ 1, 2       │
 ├────────────────────────────────────────┼────────────┤
 │ services/buddyActionParser.ts（新建）  │ 1, 2       │
 ├────────────────────────────────────────┼────────────┤
 │ services/aiService.ts                  │ 1, 2       │
 ├────────────────────────────────────────┼────────────┤
 │ components/Buddy/BuddyMessage.tsx      │ 1, 2       │
 ├────────────────────────────────────────┼────────────┤
 │ components/Buddy/BuddyPanel.tsx        │ 1, 2, 3    │
 ├────────────────────────────────────────┼────────────┤
 │ api/adapters/types.ts                  │ 2, 3       │
 ├────────────────────────────────────────┼────────────┤
 │ api/adapters/todoist/TodoistAdapter.ts │ 3          │
 ├────────────────────────────────────────┼────────────┤
 │ i18n/locales/{zh-CN,en}/buddy.json     │ 1, 2       │
 └────────────────────────────────────────┴────────────┘