今年6月开始，我尝试为 aiprogram 付费。

我尝试的软件顺序是 Copilot → GPT-5 → ClaudeCode（20 刀版本）（以下简称 CC）。  
目前长期为 ClaudeCode 付费——他在项目整体规划和编码能力上都强出一大截。尤其是有 Plan Mode 这种模式，让人和 CC 在编码前就能有一个大致思路，而不是随意写到哪算到哪。

但不论是任何 AI 还是人，在接到需求时都需要一个思考过程：先解读需求，再在自己脑中搜索解决办法，所以在他打工的过程中，我们可能“无事可做”。
很多人会说，等待时可以喝杯咖啡、上个厕所、做点别的事等。但人一天可能没有那么多“碎片”要处理；更何况在信息碎片化爆炸的时代，很多人会去刷社媒、回消息、逛淘宝。

或许像 deep thinking（深度思考）这样的事可以交给代码来辅助，但人仍然主导深度思考。我相信很多人，像我一样，会把代码丢到后台“去打工”，自己去做别的事。十分钟后突然拍脑袋：诶？我刚刚在干嘛？而 AI 软件可能早就工作完成了，我们却还沉浸在其他碎片化的事情里。十分钟可能并不长，但在频繁切换应用、刷这个网站、瞄那个页面、顺手看看终端的情况下，时间就这样被浪费掉了。

我们使用 AI 工具，本质上是为了提升效率（快速检索更多解决办法）、减少机械劳动（重复性、简单的代码修改），但这并不等于减少脑力思考。哪种方案更好？或许还是需要你自己判断。

早期使用 Clash 时，总有上下行数据不断刷新，让我很烦——好在它有开关可以关闭这个展示。所以我在想：或许 AI 编程工具也需要“适度打扰”我一下。在它空闲时提醒我：继续思考、让它开始工作、检阅它生成的代码或想法。

网上有很多弹出系统通知的，但是我又嫌这种通知太烦了……

于是我打算尝试监听 ClaudeCode 的进程，并把状态显示在导航栏。我把这个想法丢给 Claude，他推荐我用 SwiftBar（一款开源软件）来实现。

结合 ClaudeCode的 hooks 功能

当Hooks 触发UserSumbitPrompt或者PreToolUse："matcher": "Grep|Glob|Edit|MultiEdit|Write|Read|Bash|Task"时候

SwiftBar展示-》 processing

当Hooks 触发Hooks:Notification
SwiftBar展示-》⚠️

当Hooks 触发 Stop 后，展示💤，表示当前正处于闲置状态

不过我仍不确定是否有更好的监听方法。我在想：在 AI 时代，很多人反复钻研 AI 的过程中会遇到一个问题——最终正确的解决办法会被记录并发布到网上吗？还是直接进入下一个任务，忘掉刚刚踩过的坑？当越来越少的人愿意静下心来分享自己踩过的坑，AI 真能越来越聪明吗？


附上相关 md



# ClaudeCode 监控器

  

[English](README.md) | [简体中文](README.zh-CN.md)

  

**macOS 菜单栏实时显示 ClaudeCode 状态**

  

无需切换窗口查看 Claude 是否完成，再也不会错过确认提示。

  

![Menu Bar Preview](https://img.shields.io/badge/macOS-Menu%20Bar-blue?logo=apple)

![License](https://img.shields.io/badge/license-MIT-green)

  

---

  

## 功能特性

  

- 🔄 **实时状态** - 同时跟踪多个 ClaudeCode 项目

- ⚠️ **智能警报** - 确认提示在菜单栏闪烁（不可能错过）

- ⠋ **动画指示器** - 精美的 6 帧顺时针动画显示 Claude 正在工作

- 🎯 **优先级显示** - 自动显示所有会话中最紧急的状态

- 📊 **多会话** - 独立状态跟踪，管理无限项目

- 🚀 **零影响** - 最小资源占用（< 5MB RAM），故障安全设计

- 🔧 **安全设置** - 智能配置合并，自动备份

  

## 状态类型

  

| 优先级 | 图标 | 状态 | 描述 | 看到时的行动 |

|----------|------|--------|-------------|-------------------|

| 🔴 **P1** | ⚠️ | **需要注意** | 需要用户确认 | 放下手头工作——Claude 需要你！ |

| 🟡 **P2** | ⠇⠦⠴⠸⠙⠋ | **处理中** | Claude 正在积极工作 | 放松，喝杯咖啡，Claude 搞定了 |

| 🟢 **P3** | ✅ | **已完成** | 任务完成，准备查看 | 准备好时检查结果 |

| ⚪ **P4** | 💤 | **空闲** | 等待你的下一个提示 | Claude 已准备好接受你的下一个任务 |

| ⚫ **—** | 💤0 | **未激活** | 未检测到会话 | 在任意项目中启动 ClaudeCode |

  

### 处理动画

  

处理指示器使用每秒更新的流畅**顺时针旋转**：

  

```

帧 1: ⠇ (左列) ●●○

帧 2: ⠦ (左下) ○●●

帧 3: ⠴ (右下) ○○●

帧 4: ⠸ (右列) ○●●

帧 5: ⠙ (右上) ●○○

帧 6: ⠋ (左上) ●●○

(循环)

```

  

每一帧保持一个"锚点"固定，同时移动两个点，创造出对眼睛友好的流畅圆周运动。

  

## 前置要求

  

- 具有菜单栏访问权限的 macOS

- 已安装并配置 [ClaudeCode](https://claude.ai/code)

- [Homebrew](https://brew.sh)（推荐用于自动安装）

  

将自动安装的依赖：

- [SwiftBar](https://github.com/swiftbar/SwiftBar) - 菜单栏插件系统

- `jq` - JSON 处理器

  

## 快速安装

  

```bash

# 克隆仓库

git clone <repository-url>

cd claude-monitor

  

# 运行安装脚本

./install.sh

```

  

安装程序将：

1. 检查并安装依赖（SwiftBar、jq）

2. 选择安装范围（全局或特定项目）

3. 备份现有的 ClaudeCode 配置

4. 配置状态监控的 hooks

5. 安装 SwiftBar 插件

6. 可选启动监控器

  

## 使用方法

  

### 启动监控器

  

```bash

~/.claude-monitor/scripts/swiftbar_manager.sh start

```

  

### 查看状态

  

点击菜单栏图标查看：

- 带计数的总体状态摘要

- 各个项目的状态

- 快速导航到项目目录

- 清理和刷新选项

  

### 管理监控器

  

```bash

# 停止监控

~/.claude-monitor/scripts/swiftbar_manager.sh stop

  

# 重启

~/.claude-monitor/scripts/swiftbar_manager.sh restart

  

# 检查状态

~/.claude-monitor/scripts/swiftbar_manager.sh status

```

  

## 工作原理

  

ClaudeCode 监控器与 ClaudeCode 的内置 hooks 系统无缝集成：

  

```

┌─────────────┐ ┌──────────────┐ ┌─────────────┐

│ ClaudeCode │ event │ Hook Bridge │ update │ Status │

│ (CLI) │────────>│ (转换器) │────────>│ Manager │

│ │ │ │ │ (JSON) │

└─────────────┘ └──────────────┘ └──────┬──────┘

│ read

▼

┌─────────────┐

│ SwiftBar │

│ 菜单栏 UI │

└─────────────┘

```

  

### 事件流程

  

**当你提交提示时：**

1. `UserPromptSubmit` hook 触发 → 更新状态为 **⠇ 处理中**

2. SwiftBar 每 1 秒读取状态 → 显示动画旋转器

3. Claude 完成 → `Stop` hook 触发 → 状态变为 **✅ 已完成**

4. 你开始新任务 → 状态返回 **💤 空闲**

  

**当 Claude 需要确认时：**

1. `Notification` hook 触发 → 状态跳转到 **⚠️ 需要注意**（最高优先级）

2. 菜单栏显示警告图标 → 不可能错过

3. 你响应 → Hook 更新状态 → 动画继续

  

### 配置的 Hooks

  

| Hook 事件 | 触发时机 | 状态更新 | 优先级 |

|------------|---------|---------------|----------|

| `UserPromptSubmit` | 你发送提示 | ⠋ **处理中** | P2 |

| `Notification` | Claude 需要确认 | ⚠️ **需要注意** | P1（最高） |

| `Stop` | Claude 完成整个响应 | ✅ **已完成** | P3 |

| `SessionStart` | 新的 ClaudeCode 会话 | 💤 **空闲** | P4 |

| `SessionEnd` | ClaudeCode 退出 | *（移除会话）* | — |

  

> **注意**：`SubagentStop` **有意不配置**。Sub-agent 完成并不意味着主任务完成——Claude 可能启动多个 sub-agents 或在之后继续处理。

  

### 数据存储

  

状态存储在 `~/.claude-monitor/sessions.json` 的 JSON 中：

```json

{

"a3a5596b": {

"project_name": "my-web-app",

"project_path": "/Users/you/projects/my-web-app",

"status": "processing",

"priority": 3,

"timestamp": 1706345678

}

}

```

  

每个会话通过项目路径的 MD5 哈希标识，确保跨 hook 调用的一致跟踪。

  

## 菜单栏显示逻辑

  

菜单栏显示所有活动会话中**优先级最高**的状态：

  

1. **⚠️ 2** - 2 个项目需要注意（最高优先级）

2. **⠁ 1** - 1 个项目处理中

3. **✅ 3** - 3 个项目已完成

4. **💤** - 所有项目空闲

5. **💤0** - 无活动会话

  

点击图标查看每个项目的详细状态。

  

## 故障排查

  

### 启用调试模式

  

```bash

export CLAUDE_MONITOR_DEBUG=1

tail -f ~/.claude-monitor/debug.log

```

  

### 常见问题

  

**菜单栏图标未出现：**

```bash

# 检查 SwiftBar 是否运行

pgrep -f SwiftBar

  

# 重启 SwiftBar

~/.claude-monitor/scripts/swiftbar_manager.sh restart

```

  

**状态未更新：**

```bash

# 手动测试 hook

~/.claude/hooks/update_status.sh processing

  

# 检查 hook 配置

cat ~/.claude/settings.json | jq .hooks

  

# 验证会话是否被跟踪

cat ~/.claude-monitor/sessions.json | jq .

```

  

**多个重复会话：**

```bash

# 清理过期会话

~/.claude-monitor/lib/status_manager.sh clean

  

# 或完全重置

rm ~/.claude-monitor/sessions.json

```

  

### 获取帮助

  

1. 查看 [docs/README.md](docs/README.md) 获取详细文档

2. 查阅 [docs/development-guide.md](docs/development-guide.md) 了解技术细节

3. 参见 [docs/bug-analysis.md](docs/bug-analysis.md) 了解已知问题和解决方案

  

## 卸载

  

完全移除 ClaudeCode 监控器：

  

```bash

./uninstall.sh

```

  

这将：

- 移除所有已安装的文件

- 从备份还原原始 ClaudeCode 配置

- 清理 SwiftBar 插件

- 移除运行时数据

  

## 配置

  

### 安装范围

  

**全局安装（推荐）**

- 系统范围监控所有 ClaudeCode 会话

- 使用 `~/.claude/settings.json`

- 跨所有项目工作

  

**项目特定安装**

- 仅监控特定项目中的 ClaudeCode

- 使用项目目录中的 `./.claude/settings.json`

- 每个项目需要单独设置

  

### 自定义

  

编辑配置文件以自定义行为：

  

```bash

# Status manager 设置

~/.claude-monitor/lib/status_manager.sh

  

# Hook 行为

~/.claude/hooks/update_status.sh

  

# 菜单栏显示

~/Library/Application Support/SwiftBar/claude_monitor.1s.sh

```

  

## 架构

  

```

┌─────────────────────┐

│ SwiftBar 菜单栏 │ (显示层)

└──────────┬──────────┘

│ 读取

▼

┌─────────────────────┐

│ Status Manager │ (数据层 - JSON 存储)

└──────────┬──────────┘

▲ 更新

│

┌─────────────────────┐

│ Hook Bridge │ (事件层)

└──────────┬──────────┘

▲ 触发

│

┌─────────────────────┐

│ ClaudeCode Hooks │ (事件源)

└─────────────────────┘

```

  

## 贡献

  

欢迎贡献！请阅读 [docs/development-guide.md](docs/development-guide.md) 了解开发设置和编码指南。

  

## 许可证

  

MIT License - 详见 LICENSE 文件

  

## 致谢

  

- 为 Anthropic 的 [ClaudeCode](https://claude.ai/code) 构建

- 使用 [SwiftBar](https://github.com/swiftbar/SwiftBar) 进行菜单栏集成

- 受到 AI 辅助开发中更好工作流感知需求的启发

  

---

  

**注意**：此工具设计为完全无干扰。如果监控系统发生任何错误，它们永远不会影响 ClaudeCode 的操作。监控器会优雅且安静地失败。