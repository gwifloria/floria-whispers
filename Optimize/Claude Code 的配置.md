基于我们之前看到的 Claude Code 文件结构，你可以通过几种方式配置自动监测流程：

## 🎯 **推荐配置位置和方法**

### 1. **Hooks 配置（最佳方案）**

在项目根目录创建 `.claude/hooks.json`：

```json
{
  "PostToolUse": [
    {
      "matcher": ".*",
      "command": "~/.claude/scripts/post-execution-monitor.sh",
      "description": "执行完成后的监测流程"
    }
  ],
  "Stop": [
    {
      "matcher": ".*", 
      "command": "~/.claude/scripts/final-monitor.sh",
      "description": "Claude 完成所有任务后的最终监测"
    }
  ]
}
```

### 2. **创建监测脚本**

创建 `~/.claude/scripts/post-execution-monitor.sh`：

```bash
#!/bin/bash
# post-execution-monitor.sh

echo "🔍 开始执行监测流程..."

# 1. 运行测试
echo "📋 运行测试套件..."
npm test 2>/dev/null || yarn test 2>/dev/null || echo "⚠️ 未找到测试命令"

# 2. 检查代码质量
echo "🔍 检查代码质量..."
npm run lint 2>/dev/null || echo "⚠️ 未找到 lint 命令"

# 3. 类型检查
echo "🔧 TypeScript 类型检查..."
npm run type-check 2>/dev/null || npx tsc --noEmit 2>/dev/null || echo "⚠️ 未找到类型检查"

# 4. 构建验证
echo "🏗️ 构建验证..."
npm run build 2>/dev/null || echo "⚠️ 构建检查跳过"

# 5. Git 状态检查
echo "📁 Git 状态..."
git status --porcelain

echo "✅ 监测流程完成"
```

### 3. **全局配置（所有项目通用）**

在 `~/.claude/settings.json` 中配置：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "command": "~/.claude/global-monitor.sh",
        "description": "全局监测流程"
      }
    ]
  },
  "permissions": {
    "defaultMode": "plan"
  },
  "defaultCommands": {
    "postExecution": "~/.claude/scripts/universal-monitor.sh"
  }
}
```

### 4. **项目特定配置**

在项目的 `.claude/settings.local.json`：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "command": "./scripts/check-after-edit.sh",
        "description": "文件编辑后检查"
      },
      {
        "matcher": "Bash(npm.*|yarn.*)",
        "command": "./scripts/check-after-install.sh", 
        "description": "包安装后检查"
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "command": "./scripts/final-project-check.sh",
        "description": "项目最终检查"
      }
    ]
  }
}
```

## 🔧 **监测脚本示例**

### 通用监测脚本

```bash
#!/bin/bash
# ~/.claude/scripts/universal-monitor.sh

PROJECT_TYPE=""

# 检测项目类型
if [ -f "package.json" ]; then
    PROJECT_TYPE="node"
elif [ -f "requirements.txt" ]; then
    PROJECT_TYPE="python"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
fi

echo "🔍 检测到项目类型: $PROJECT_TYPE"

case $PROJECT_TYPE in
    "node")
        echo "📦 Node.js 项目监测..."
        npm run lint --silent 2>/dev/null || echo "⚠️ 跳过 lint"
        npm test --silent 2>/dev/null || echo "⚠️ 跳过测试"
        npm run type-check --silent 2>/dev/null || echo "⚠️ 跳过类型检查"
        ;;
    "python")
        echo "🐍 Python 项目监测..."
        python -m flake8 . 2>/dev/null || echo "⚠️ 跳过 flake8"
        python -m pytest 2>/dev/null || echo "⚠️ 跳过测试"
        ;;
    "rust")
        echo "🦀 Rust 项目监测..."
        cargo check 2>/dev/null || echo "⚠️ 跳过检查"
        cargo test 2>/dev/null || echo "⚠️ 跳过测试"
        ;;
    *)
        echo "📁 通用检查..."
        git status --porcelain
        ;;
esac

echo "✅ 监测完成"
```

### 针对你的博客项目

```bash
#!/bin/bash
# .claude/scripts/blog-monitor.sh

echo "📝 博客项目监测流程..."

# 1. Next.js 构建检查
echo "🏗️ Next.js 构建验证..."
npm run build > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
else
    echo "❌ 构建失败"
fi

# 2. TypeScript 检查
echo "🔧 TypeScript 检查..."
npx tsc --noEmit
if [ $? -eq 0 ]; then
    echo "✅ 类型检查通过"
else
    echo "❌ 类型错误"
fi

# 3. 数据获取测试
echo "📡 数据获取测试..."
node -e "
const { DataAccess } = require('./lib/data-access');
DataAccess.server.getPosts()
  .then(() => console.log('✅ 数据获取正常'))
  .catch(() => console.log('❌ 数据获取失败'));
" 2>/dev/null

# 4. 路由检查
echo "🛣️ 路由检查..."
if [ -d "app" ]; then
    echo "✅ App Router 结构正常"
else
    echo "⚠️ 未找到 app 目录"
fi

echo "✅ 博客项目监测完成"
```

## 🎯 **自定义命令集成**

创建 `.claude/commands/monitor.md`：

```markdown
在每次重要操作后执行完整的项目监测流程：

1. 运行所有测试套件
2. 检查代码质量和格式
3. 验证 TypeScript 类型
4. 确认构建成功
5. 检查 Git 状态
6. 验证核心功能

请在完成后显示详细的监测报告。
```

然后可以手动调用：`/monitor`

## ⚙️ **激活配置**

### 1. 使能 Hooks

```bash
# 确保脚本可执行
chmod +x ~/.claude/scripts/*.sh
chmod +x .claude/scripts/*.sh

# 测试 hooks 配置
claude --mcp-debug  # 启动时会显示配置加载情况
```

### 2. 验证配置

在 Claude Code 中运行：

```
/hooks
```

这会显示当前配置的所有 hooks。

### 3. 测试监测流程

```bash
# 手动测试脚本
~/.claude/scripts/universal-monitor.sh
```

## 📋 **配置优先级**

Claude Code 的配置加载顺序：

1. `~/.claude/settings.json` (全局配置)
2. `.claude/settings.local.json` (项目特定)
3. `.claude/hooks.json` (项目 hooks)
4. 命令行参数

## 💡 **最佳实践建议**

1. **渐进式监测**：从简单检查开始，逐步增加复杂度
2. **快速失败**：重要检查失败时立即报告
3. **静默模式**：避免过多输出干扰主要任务
4. **可配置性**：允许在不同项目中自定义监测流程

这样配置后，Claude Code 在每次执行完工具操作后都会自动运行你的监测流程，确保代码质量和功能正常！

你想先从哪种监测流程开始配置？

