

## 第一步：检查 Claude Code 版本

```bash
# 检查 Claude Code 版本和位置
claude-code --version
which claude-code

# 如果使用 cc 别名
cc --version
which cc
```

## 第二步：安装 SwiftBar

```bash
# 安装 SwiftBar
brew install --cask swiftbar

# 启动 SwiftBar（会在菜单栏出现）
open -a SwiftBar
```

## 第三步：创建监控脚本，可以一键搞定

### 主监控脚本（V1有 bug） `cc_monitor.sh`

```bash
#!/bin/bash
# 保存为: ~/Scripts/cc_monitor.sh

STATUS_FILE="/tmp/cc_status"
COUNTER_FILE="/tmp/cc_counter"

# 初始化
echo "idle" > "$STATUS_FILE"
echo "0" > "$COUNTER_FILE"

# 状态更新函数
update_status() {
    local status="$1"
    local message="$2"
    echo "$status" > "$STATUS_FILE"
    
    # 重要状态发送通知
    case "$status" in
        "waiting")
            osascript -e "display notification \"$message\" with title \"⏸️ 待确认\" sound name \"Glass\""
            ;;
        "completed")
            osascript -e "display notification \"$message\" with title \"✅ 完成\" sound name \"Hero\""
            ;;
    esac
}

# 主监控循环
while true; do
    if pgrep -f "claude-code\|cc" > /dev/null; then
        # 检查 iTerm2 窗口标题判断状态
        window_title=$(osascript -e 'tell application "iTerm2" to get name of front window' 2>/dev/null || echo "")
        
        # 状态判断
        if echo "$window_title" | grep -qi "continue\|confirm\|proceed\|(y/n)"; then
            update_status "waiting" "需要你的确认..."
        elif echo "$window_title" | grep -qi "running\|executing"; then
            echo "running" > "$STATUS_FILE"
        elif echo "$window_title" | grep -qi "planning\|analyzing"; then
            echo "planning" > "$STATUS_FILE"
        else
            echo "running" > "$STATUS_FILE"
        fi
        
        # 更新计数器
        counter=$(cat "$COUNTER_FILE")
        echo $((counter + 1)) > "$COUNTER_FILE"
    else
        # Claude Code 未运行
        if [ "$(cat "$STATUS_FILE")" != "idle" ]; then
            update_status "completed" "任务完成"
            echo "idle" > "$STATUS_FILE"
            echo "0" > "$COUNTER_FILE"
        fi
    fi
    
    sleep 5
done
```

### V2改进版 `cc_monitor.sh`
```bash
#!/bin/bash
# 改进版 Claude Code 监控脚本
# 保存为: ~/Scripts/cc_monitor_v2.sh

STATUS_FILE="/tmp/cc_status"
COUNTER_FILE="/tmp/cc_counter"
LAST_OUTPUT_FILE="/tmp/cc_last_output"

# 初始化
echo "idle" > "$STATUS_FILE"
echo "0" > "$COUNTER_FILE"
echo "" > "$LAST_OUTPUT_FILE"

# 状态更新函数
update_status() {
    local status="$1"
    local message="$2"
    echo "$status" > "$STATUS_FILE"
    
    case "$status" in
        "waiting")
            osascript -e "display notification \"$message\" with title \"⏸️ 待确认\" sound name \"Glass\""
            ;;
        "completed")
            osascript -e "display notification \"$message\" with title \"✅ 完成\" sound name \"Hero\""
            ;;
    esac
}

# 检测 Claude 进程状态
detect_claude_status() {
    # 方法1: 检测进程名为 "claude" 的进程
    if pgrep -x "claude" > /dev/null; then
        # 获取 Claude 进程信息
        claude_pid=$(pgrep -x "claude")
        claude_info=$(ps -p "$claude_pid" -o pid,tty,time,command 2>/dev/null)
        
        # 检查是否有 TTY（交互模式）
        if echo "$claude_info" | grep -q "ttys"; then
            return 0  # Claude 正在运行
        fi
    fi
    
    # 方法2: 检测包含 claude 关键词的进程
    if ps aux | grep -E "[^a-zA-Z]claude[^a-zA-Z]" | grep -v grep > /dev/null; then
        return 0  # Claude 正在运行
    fi
    
    return 1  # Claude 未运行
}

# 检测 Claude 交互状态
detect_interaction_state() {
    # 检查当前活动窗口的标题
    local window_title=""
    window_title=$(osascript -e 'tell application "iTerm2" to get name of front window' 2>/dev/null || echo "")
    
    # 检查窗口内容（更高级的检测）
    local window_content=""
    window_content=$(osascript -e '
    tell application "iTerm2"
        try
            set currentTab to current tab of front window
            set lastLines to (last 5 paragraphs of contents of current session of currentTab) as string
            return lastLines
        on error
            return ""
        end try
    end tell
    ' 2>/dev/null || echo "")
    
    # 合并所有检测信息
    local all_text="$window_title $window_content"
    
    # 状态判断
    if echo "$all_text" | grep -qi "continue\|confirm\|proceed\|(y/n)\|press.*enter\|waiting.*input"; then
        echo "waiting"
    elif echo "$all_text" | grep -qi "thinking\|analyzing\|planning\|generating"; then
        echo "planning"
    elif echo "$all_text" | grep -qi "running\|executing\|processing\|working"; then
        echo "running"
    elif echo "$all_text" | grep -qi "completed\|finished\|done\|success"; then
        echo "completed"
    else
        # 默认状态：如果 Claude 在运行但无法确定具体状态
        echo "running"
    fi
}

# 主监控循环
echo "🚀 Claude Code 监控已启动..."

while true; do
    if detect_claude_status; then
        # Claude 正在运行，检测交互状态
        current_state=$(detect_interaction_state)
        
        case "$current_state" in
            "waiting")
                update_status "waiting" "需要你的确认..."
                ;;
            "planning")
                echo "planning" > "$STATUS_FILE"
                ;;
            "running")
                echo "running" > "$STATUS_FILE"
                ;;
            "completed")
                # 不要立即设为完成，因为 Claude 可能还在运行
                echo "running" > "$STATUS_FILE"
                ;;
        esac
        
        # 更新计数器
        counter=$(cat "$COUNTER_FILE")
        echo $((counter + 1)) > "$COUNTER_FILE"
        
    else
        # Claude 未运行
        if [ "$(cat "$STATUS_FILE")" != "idle" ]; then
            update_status "completed" "Claude Code 任务完成"
            echo "idle" > "$STATUS_FILE"
            echo "0" > "$COUNTER_FILE"
        fi
    fi
    
    # 调试信息（可选）
    current_status=$(cat "$STATUS_FILE")
    current_counter=$(cat "$COUNTER_FILE")
    echo "[$(date '+%H:%M:%S')] 状态: $current_status, 计数: $current_counter" >> /tmp/cc_monitor_debug.log
    
    sleep 3  # 缩短检测间隔以提高响应速度
done
```
### SwiftBar 菜单栏显示脚本

```bash
#!/bin/bash
# 保存为: ~/Library/Application Support/SwiftBar/cc_status.5s.sh

STATUS_FILE="/tmp/cc_status"
COUNTER_FILE="/tmp/cc_counter"

# 旋转动画
SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# 读取状态
status=$(cat "$STATUS_FILE" 2>/dev/null || echo "idle")
counter=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")

# 计算动画帧
spinner_index=$((counter % 10))
spinner_char="${SPINNER[$spinner_index]}"

# 显示状态
case "$status" in
    "planning")
        echo "🤔 ${spinner_char}"
        echo "---"
        echo "状态: 规划中"
        echo "运行: $((counter * 5))秒"
        ;;
    "waiting")
        echo "⏸️ 待确认 | color=red"
        echo "---"
        echo "⚠️ 需要你的确认!"
        echo "运行: $((counter * 5))秒"
        echo "切换到 iTerm2 | bash='/usr/bin/osascript' param1='-e' param2='tell application \"iTerm2\" to activate'"
        ;;
    "running")
        echo "⚡ ${spinner_char}"
        echo "---"
        echo "状态: 执行中"
        echo "运行: $((counter * 5))秒"
        ;;
    "completed")
        echo "✅"
        echo "---"
        echo "状态: 已完成"
        ;;
    *)
        echo "💤"
        echo "---"
        echo "Claude Code 未运行"
        ;;
esac
```

## 第四步：一键部署脚本

```bash
#!/bin/bash
# 保存为: ~/Scripts/setup_cc_monitor.sh

echo "🚀 开始部署 Claude Code 监控系统..."

# 创建目录
mkdir -p ~/Scripts
mkdir -p ~/Library/Application\ Support/SwiftBar

# 创建主监控脚本
cat > ~/Scripts/cc_monitor.sh << 'EOF'
#!/bin/bash
STATUS_FILE="/tmp/cc_status"
COUNTER_FILE="/tmp/cc_counter"

echo "idle" > "$STATUS_FILE"
echo "0" > "$COUNTER_FILE"

update_status() {
    local status="$1"
    local message="$2"
    echo "$status" > "$STATUS_FILE"
    
    case "$status" in
        "waiting")
            osascript -e "display notification \"$message\" with title \"⏸️ 待确认\" sound name \"Glass\""
            ;;
        "completed")
            osascript -e "display notification \"$message\" with title \"✅ 完成\" sound name \"Hero\""
            ;;
    esac
}

while true; do
    if pgrep -f "claude-code\|cc" > /dev/null; then
        window_title=$(osascript -e 'tell application "iTerm2" to get name of front window' 2>/dev/null || echo "")
        
        if echo "$window_title" | grep -qi "continue\|confirm\|proceed\|(y/n)"; then
            update_status "waiting" "需要你的确认..."
        elif echo "$window_title" | grep -qi "running\|executing"; then
            echo "running" > "$STATUS_FILE"
        elif echo "$window_title" | grep -qi "planning\|analyzing"; then
            echo "planning" > "$STATUS_FILE"
        else
            echo "running" > "$STATUS_FILE"
        fi
        
        counter=$(cat "$COUNTER_FILE")
        echo $((counter + 1)) > "$COUNTER_FILE"
    else
        if [ "$(cat "$STATUS_FILE")" != "idle" ]; then
            update_status "completed" "任务完成"
            echo "idle" > "$STATUS_FILE"
            echo "0" > "$COUNTER_FILE"
        fi
    fi
    
    sleep 5
done
EOF

# 创建 SwiftBar 脚本
cat > ~/Library/Application\ Support/SwiftBar/cc_status.5s.sh << 'EOF'
#!/bin/bash

STATUS_FILE="/tmp/cc_status"
COUNTER_FILE="/tmp/cc_counter"
SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

status=$(cat "$STATUS_FILE" 2>/dev/null || echo "idle")
counter=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")

spinner_index=$((counter % 10))
spinner_char="${SPINNER[$spinner_index]}"

case "$status" in
    "planning")
        echo "🤔 ${spinner_char}"
        echo "---"
        echo "状态: 规划中"
        echo "运行: $((counter * 5))秒"
        ;;
    "waiting")
        echo "⏸️ 待确认 | color=red"
        echo "---"
        echo "⚠️ 需要你的确认!"
        echo "运行: $((counter * 5))秒"
        echo "切换到 iTerm2 | bash='/usr/bin/osascript' param1='-e' param2='tell application \"iTerm2\" to activate'"
        ;;
    "running")
        echo "⚡ ${spinner_char}"
        echo "---"
        echo "状态: 执行中"
        echo "运行: $((counter * 5))秒"
        ;;
    "completed")
        echo "✅"
        echo "---"
        echo "状态: 已完成"
        ;;
    *)
        echo "💤"
        echo "---"
        echo "Claude Code 未运行"
        ;;
esac
EOF

# 设置权限
chmod +x ~/Scripts/cc_monitor.sh
chmod +x ~/Library/Application\ Support/SwiftBar/cc_status.5s.sh

# 创建启动脚本
cat > ~/Scripts/start_cc_monitor.sh << 'EOF'
#!/bin/bash
pkill -f cc_monitor.sh
nohup ~/Scripts/cc_monitor.sh > /dev/null 2>&1 &

if ! pgrep -f SwiftBar > /dev/null; then
    open -a SwiftBar
fi

echo "✅ Claude Code 监控系统已启动"
EOF

chmod +x ~/Scripts/start_cc_monitor.sh

echo "✅ 部署完成！"
echo ""
echo "📋 下一步："
echo "1. 安装 SwiftBar: brew install --cask swiftbar"
echo "2. 启动监控: ~/Scripts/start_cc_monitor.sh"
echo "3. 查看菜单栏的 Claude Code 状态图标"
```

## 第五步：设置开机自启动

```bash
# 创建 LaunchAgent
cat > ~/Library/LaunchAgents/com.user.ccmonitor.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.ccmonitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$HOME/Scripts/start_cc_monitor.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# 启动服务
launchctl load ~/Library/LaunchAgents/com.user.ccmonitor.plist
launchctl start com.user.ccmonitor
```

## 使用说明

### 快速开始

```bash
# 1. 运行一键部署
bash ~/Scripts/setup_cc_monitor.sh

# 2. 安装 SwiftBar
brew install --cask swiftbar

# 3. 启动监控
~/Scripts/start_cc_monitor.sh
```

### 状态说明

- 💤 - Claude Code 未运行
- 🤔 ⠋ - 规划中（带旋转动画）
- ⚡ ⠋ - 执行中（带旋转动画）
- ⏸️ - **待确认**（红色，可点击跳转）
- ✅ - 任务完成

### 调试命令

```bash
# 查看当前状态
cat /tmp/cc_status

# 重启监控
pkill -f cc_monitor.sh && ~/Scripts/start_cc_monitor.sh

# 查看日志
tail -f /tmp/cc_monitor_debug.log
```