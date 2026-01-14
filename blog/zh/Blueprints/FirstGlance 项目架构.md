一、项目概述​

​

First Glance 是一款 Chrome 新标签页扩展，集成滴答清单（Dida365/TickTick）API，提供专注任务管理体验。支持完全离线的游客模式。​

​​

二、核心功能​

1. 双视图架构​

​

|   |   |
|---|---|
|视图类型​|核心特点​|
|Focus 视图​|极简沉浸式：数字时钟 + 时间问候语 + 最多 3 个聚焦任务 + 番茄钟 + 励志语句​|
|List 视图​|完整管理：可折叠侧边栏 + Smart Filters（Today/Tomorrow/This Week/Overdue/Inbox）+ 项目树 + 任务分组列表​|

​

2. 番茄钟计时系统​

- 工作 / 休息模式可配置（默认 25/5 分钟）​

- 跨标签页同步（通过 Chrome Storage 事件监听）​

- 支持操作：开始、暂停、继续、跳过、重置​

3. 主题系统（5 种内置主题）​

- 椰奶白 (milk)：Journal 风格，纹理 + 贴纸装饰​

- 米色 (beige)：日志风格​

- 粉红 (pink)：现代明亮​

- 蓝色 (blue)：清爽大气​

- 深色 (dark)：OLED 友好​

4. 多适配器架构​

- DidaListAdapter：连接滴答清单 API​

- LocalAdapter：完全本地离线（游客模式，限 3 个任务）​

- 规划中：Notion、Todoist 适配器​

5. 其他特性​

- 国际化支持（中文 / English）​

- 入门引导流程​

- 快速添加任务​

- 任务搜索​

​​

三、技术栈​

​

|   |   |
|---|---|
|类别​|技术栈详情​|
|核心框架​|React 19 + TypeScript 5.7 + Vite 6.4​|
|扩展标准​|Chrome Extension Manifest V3​|
|UI 框架​|Ant Design 5.22 + Tailwind CSS 4.1​|
|状态管理​|React Context（多层架构）​|
|国际化​|i18next 25.7​|
|包管理​|pnpm 9.15 + Turbo 2.3（Monorepo）​|
|代码规范​|ESLint 9 + Prettier 3.7 + Husky + lint-staged​|

​

​​

四、项目结构​

​

apps/​

├── extension/ # Chrome 扩展主体​

│ └── src/​

│ ├── newtab/ # 新标签页入口​

│ ├── background/ # Service Worker（OAuth、Token刷新）​

│ ├── components/ # React 组件（41个）​

│ ├── hooks/ # 自定义 Hooks（11个）​

│ ├── contexts/ # React Context（5个）​

│ ├── api/adapters/ # 任务数据适配器​

│ ├── themes/ # 主题定义​

│ ├── i18n/ # 国际化资源​

│ └── utils/ # 工具函数（任务筛选/排序/分组）​

└── web/ # 项目官网（Astro）​

​

​​

五、GitHub Actions 自动化​

1. deploy-web.yml - 网站部署​

- 触发条件：push 到 main 分支​

- 执行流程：构建 Astro 站点 → 部署到 GitHub Pages​

2. bump-version.yml - 版本管理​

- 触发条件：手动选择版本类型（patch/minor/major）​

- 执行流程：​

a. npm version​

b. 同步更新 manifest.json​

c. 创建 Git tag，触发发布流程​

3. release.yml - Chrome 扩展发布​

- 触发条件：创建 v* 格式的 Git tag​

- 执行流程：​

a. Lint + TypeScript 检查​

b. 构建扩展​

c. 打包 ZIP​

d. 自动上传 Chrome Web Store​

e. 创建 GitHub Release​

​​

六、关键技术实现​

​

|   |   |
|---|---|
|特性​|实现方式​|
|番茄钟跨标签页同步​|chrome.storage.onChanged 事件监听​|
|主题动态切换​|CSS 变量 + useEffect 动态注入​|
|任务视图计算优化​|单次遍历 + 缓存 + useMemo​|
|Token 自动刷新​|Chrome Alarms API，每 30 分钟检查​|
|错误恢复​|远程失败时使用本地缓存​|

​

​​

七、项目统计​

​

|   |   |
|---|---|
|指标​|数值​|
|React 组件​|41 个​|
|TypeScript 文件​|71 个​|
|自定义 Hooks​|11 个​|
|支持语言​|2（中 / 英）​|
|内置主题​|5 个​|
|GitHub Actions​|3 个 workflow​|

​