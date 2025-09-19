```bash
#!/bin/bash
# 全新 Claude Code 监控完整系统
# 保存为: ~/Scripts/deploy_fresh_cc_monitor.sh

echo "🚀 部署全新 Claude Code 监控系统..."

# 创建目录
mkdir -p ~/Scripts
mkdir -p ~/Library/Application\ Support/SwiftBar

# ==================== 1. 主监控脚本 ====================
cat > ~/Scripts/cc_monitor.sh << 'MONITOR_EOF'
#!/bin/bash
# Claude Code 主监控脚本

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
    
    case "$status" in
        "waiting")
            osascript -e "display notification \"$message\" with title \"⏸️ 待确认\" sound name \"Glass\""
            ;;
        "completed")
            osascript -e "display notification \"$message\" with title \"✅ 完成\" sound name \"Hero\""
            ;;
    esac
}

echo "🎯 Claude Code 监控已启动 - $(date)"

# 主监控循环
while true; do
    # 检测 Claude 进程（进程名就是 "claude"）
    if pgrep -x "claude" > /dev/null; then
        # 获取 Claude 进程详情，确保是交互模式
        claude_info=$(ps aux | grep -E " claude$" | grep -v grep)
        
        if echo "$claude_info" | grep -q "ttys"; then
            # Claude 在交互模式，尝试获取窗口内容
            window_content=$(osascript -e '
            tell application "iTerm2"
                try
                    set currentTab to current tab of front window
                    set lastLines to (last 3 paragraphs of contents of current session of currentTab) as string
                    return lastLines
                on error
                    return ""
                end try
            end tell
            ' 2>/dev/null || echo "")
            
            # 状态判断
            if echo "$window_content" | grep -qi "continue\|confirm\|proceed\|(y/n)\|press.*enter\|waiting\|Continue?"; then
                update_status "waiting" "需要你的确认..."
            elif echo "$window_content" | grep -qi "thinking\|analyzing\|planning\|generating\|Let me"; then
                echo "planning" > "$STATUS_FILE"
            elif echo "$window_content" | grep -qi "running\|executing\|processing\|working"; then
                echo "running" > "$STATUS_FILE"
            else
                # 默认为运行状态
                echo "running" > "$STATUS_FILE"
            fi
            
            # 更新计数器
            counter=$(cat "$COUNTER_FILE")
            echo $((counter + 1)) > "$COUNTER_FILE"
            
            # 调试日志
            echo "[$(date '+%H:%M:%S')] Claude 运行中 - 状态: $(cat "$STATUS_FILE")" >> /tmp/cc_monitor.log
        else
            # Claude 进程存在但不在交互模式
            echo "idle" > "$STATUS_FILE"
            echo "0" > "$COUNTER_FILE"
        fi
    else
        # Claude 进程不存在
        current_status=$(cat "$STATUS_FILE" 2>/dev/null || echo "idle")
        if [ "$current_status" != "idle" ]; then
            update_status "completed" "Claude 任务完成"
            echo "idle" > "$STATUS_FILE"
            echo "0" > "$COUNTER_FILE"
            echo "[$(date '+%H:%M:%S')] Claude 已停止" >> /tmp/cc_monitor.log
        fi
    fi
    
    sleep 3
done
MONITOR_EOF

# ==================== 2. SwiftBar 显示脚本 ====================
cat > ~/Library/Application\ Support/SwiftBar/cc_status.3s.sh << 'SWIFTBAR_EOF'
#!/bin/bash
# Claude Code SwiftBar 显示脚本

STATUS_FILE="/tmp/cc_status"
COUNTER_FILE="/tmp/cc_counter"

# 旋转动画字符
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
        echo "运行: $((counter * 3))秒"
        ;;
    "waiting")
        echo "⏸️ 待确认 | color=red"
        echo "---"
        echo "⚠️ 需要你的确认!"
        echo "运行: $((counter * 3))秒"
        echo "---"
        echo "切换到 iTerm2 | bash='/usr/bin/osascript' param1='-e' param2='tell application \"iTerm2\" to activate'"
        ;;
    "running")
        echo "⚡ ${spinner_char}"
        echo "---"
        echo "状态: 执行中"
        echo "运行: $((counter * 3))秒"
        ;;
    "completed")
        echo "✅"
        echo "---"
        echo "状态: 已完成"
        ;;
    "idle"|*)
        echo "💤"
        echo "---"
        echo "Claude 未运行"
        ;;
esac
SWIFTBAR_EOF

# ==================== 3. 启动脚本 ====================
cat > ~/Scripts/start_cc_monitor.sh << 'START_EOF'
#!/bin/bash
# 启动 Claude Code 监控系统

echo "🚀 启动 Claude Code 监控系统..."

# 终止现有监控进程
pkill -f cc_monitor
sleep 1

# 清理状态文件
echo "idle" > /tmp/cc_status
echo "0" > /tmp/cc_counter

# 启动新监控
nohup ~/Scripts/cc_monitor.sh > /tmp/cc_monitor.log 2>&1 &

# 启动 SwiftBar（如果未运行）
if ! pgrep -f SwiftBar > /dev/null; then
    echo "启动 SwiftBar..."
    open -a SwiftBar
fi

echo "✅ 监控系统已启动"
echo "📋 查看日志: tail -f /tmp/cc_monitor.log"
echo "📊 查看状态: cat /tmp/cc_status"
START_EOF

# ==================== 4. 停止脚本 ====================
cat > ~/Scripts/stop_cc_monitor.sh << 'STOP_EOF'
#!/bin/bash
# 停止 Claude Code 监控系统

echo "🛑 停止 Claude Code 监控系统..."

# 终止监控进程
pkill -f cc_monitor

# 重置状态
echo "idle" > /tmp/cc_status
echo "0" > /tmp/cc_counter

echo "✅ 监控系统已停止"
STOP_EOF

# ==================== 5. 调试脚本 ====================
cat > ~/Scripts/debug_cc_monitor.sh << 'DEBUG_EOF'
#!/bin/bash
# Claude Code 监控调试脚本

echo "🔍 Claude Code 监控调试信息"
echo "================================="

echo "1. Claude 进程状态:"
if pgrep -x "claude" > /dev/null; then
    echo "✅ Claude 进程运行中"
    ps aux | grep -E " claude$" | grep -v grep
else
    echo "❌ Claude 进程未运行"
fi
echo ""

echo "2. 监控进程状态:"
if pgrep -f cc_monitor > /dev/null; then
    echo "✅ 监控进程运行中"
    ps aux | grep cc_monitor | grep -v grep
else
    echo "❌ 监控进程未运行"
fi
echo ""

echo "3. 当前状态文件:"
echo "STATUS: $(cat /tmp/cc_status 2>/dev/null || echo '文件不存在')"
echo "COUNTER: $(cat /tmp/cc_counter 2>/dev/null || echo '文件不存在')"
echo ""

echo "4. SwiftBar 脚本:"
if [ -f ~/Library/Application\ Support/SwiftBar/cc_status.3s.sh ]; then
    echo "✅ SwiftBar 脚本存在"
else
    echo "❌ SwiftBar 脚本不存在"
fi
echo ""

echo "5. 最近监控日志:"
if [ -f /tmp/cc_monitor.log ]; then
    echo "最后5行日志:"
    tail -5 /tmp/cc_monitor.log
else
    echo "❌ 日志文件不存在"
fi
DEBUG_EOF

# ==================== 设置权限 ====================
chmod +x ~/Scripts/cc_monitor.sh
chmod +x ~/Scripts/start_cc_monitor.sh
chmod +x ~/Scripts/stop_cc_monitor.sh
chmod +x ~/Scripts/debug_cc_monitor.sh
chmod +x ~/Library/Application\ Support/SwiftBar/cc_status.3s.sh

echo ""
echo "✅ 全新 Claude Code 监控系统部署完成!"
echo ""
echo "📋 使用说明:"
echo "   启动监控: ~/Scripts/start_cc_monitor.sh"
echo "   停止监控: ~/Scripts/stop_cc_monitor.sh"
echo "   调试信息: ~/Scripts/debug_cc_monitor.sh"
echo "   查看日志: tail -f /tmp/cc_monitor.log"
echo ""
echo "🎯 下一步:"
echo "   1. 确保 SwiftBar 已安装: brew install --cask swiftbar"
echo "   2. 启动监控: ~/Scripts/start_cc_monitor.sh"
echo "   3. 测试 Claude 对话，观察菜单栏状态变化"
```