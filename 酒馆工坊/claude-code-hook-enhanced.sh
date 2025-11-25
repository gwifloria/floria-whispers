#!/opt/homebrew/bin/bash

##############################################################################
# Claude Code 自动日志记录 Hook - V3 增强版
# 
# 新增功能：
# - Token 使用统计
# - 改进的消息过滤规则
# - 自动任务分类
# - 跨平台兼容性（macOS/Linux）
# - 性能优化（缓存读取）
# - 任务中断/错误记录
#
# 依赖：bash, jq (用于解析 JSON)
##############################################################################

# ==================== 配置区域 ====================
VAULT_PATH="$HOME/wonderland/eriko-echo"
PROJECTS_DIR="$VAULT_PATH/Projects/CodeTesting"
DAILY_LOG_DIR="$PROJECTS_DIR/ClaudeCode-Daily"

# 项目名称映射
declare -A PROJECT_MAP=(
  ["red-note"]="RedNote"
  ["a-red-note"]="ARedNote"
  ["tech"]="Tech"
  ["interview"]="Interview"
  ["wonderland-nexus"]="wonderland-nexus"
)

# 任务分类标签（根据提示词关键字自动分类）
declare -A TASK_CATEGORIES=(
  ["fix"]="🐛 Bug修复"
  ["bug"]="🐛 Bug修复"
  ["error"]="🐛 Bug修复"
  ["feature"]="✨ 新功能"
  ["add"]="✨ 新功能"
  ["create"]="✨ 新功能"
  ["refactor"]="♻️ 重构"
  ["optimize"]="♻️ 重构"
  ["improve"]="♻️ 重构"
  ["test"]="🧪 测试"
  ["doc"]="📝 文档"
  ["document"]="📝 文档"
  ["readme"]="📝 文档"
  ["review"]="👀 代码审查"
  ["analyze"]="🔍 分析"
  ["debug"]="🔧 调试"
)

# ==================== 配置区域结束 ====================

DEBUG_LOG="$HOME/.claude/hooks/logger_debug.log"
ENABLE_DEBUG=${CLAUDE_LOGGER_DEBUG:-1}

mkdir -p "$DAILY_LOG_DIR"
mkdir -p "$(dirname "$DEBUG_LOG")"

##############################################################################
# 辅助函数
##############################################################################

get_project_name() {
  local project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
  local dir_name=$(basename "$project_dir")
  local project_lower=$(echo "$project_dir" | tr '[:upper:]' '[:lower:]')

  for key in "${!PROJECT_MAP[@]}"; do
    if [[ "$project_lower" == *"$key"* ]]; then
      echo "${PROJECT_MAP[$key]}"
      return
    fi
  done

  echo "$dir_name"
}

get_today_log_path() {
  local today=$(date +%Y-%m-%d)
  echo "$DAILY_LOG_DIR/$today.md"
}

get_project_log_path() {
  local project_name="$1"
  local project_dir="$PROJECTS_DIR/$project_name"
  mkdir -p "$project_dir"
  echo "$project_dir/ClaudeCode-Log.md"
}

get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

# 自动检测任务类别
detect_task_category() {
  local prompt="$1"
  local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
  
  # 按优先级检测关键词
  for key in "${!TASK_CATEGORIES[@]}"; do
    if [[ "$prompt_lower" == *"$key"* ]]; then
      echo "${TASK_CATEGORIES[$key]}"
      return
    fi
  done
  
  echo "📌 其他"
}

ensure_today_log_exists() {
  local log_path="$1"

  if [[ ! -f "$log_path" ]]; then
    local today=$(date +%Y-%m-%d)
    cat > "$log_path" << EOF
# Claude Code 日志 - ${today}

## 📅 日期：${today}

---

## 🎯 今日任务总览

[在这里简要总结今天所有的 Claude Code 任务]

---

## 📦 项目记录

---

## 📊 今日统计

- **任务总数**：0 个
- **完成任务**：0 个
- **总耗时**：0 小时
- **Token 消耗**：0

## 💡 今日收获

1.

## 🤔 遇到的问题

1.

## ✅ 明日计划

- [ ]

---

📝 **复盘提示**：
- 哪些任务进展顺利？为什么？
- 哪些任务遇到困难？如何解决的?
- 有什么可以改进的地方？
EOF
  fi
}

ensure_project_log_exists() {
  local log_path="$1"
  local project_name="$2"

  if [[ ! -f "$log_path" ]]; then
    local today=$(date +%Y-%m-%d)
    cat > "$log_path" << EOF
# Claude Code 开发日志 - ${project_name}

> 📌 项目说明：[简要描述这个项目是做什么的]
> 📅 创建时间：${today}

---

## 📋 任务记录

---

## 📊 项目统计

- **总任务数**：0 个
- **已完成**：0 个
- **进行中**：0 个
- **累计耗时**：0 小时
- **Token 消耗**：0

## 💡 经验总结

### 成功经验

### 踩过的坑

### 最佳实践

---

📌 **使用说明**：
- 每次使用 Claude Code 完成任务后，自动添加新的任务记录
- 保持时间倒序排列（最新的在最上面）
EOF
  fi
}

insert_after_marker() {
  local file_path="$1"
  local marker="$2"
  local content="$3"

  if [[ ! -f "$file_path" ]]; then
    return
  fi

  local tmp_content=$(mktemp)
  echo "$content" > "$tmp_content"

  local tmp_file="${file_path}.tmp"
  local found=0

  while IFS= read -r line; do
    echo "$line"
    if [[ "$line" =~ $marker ]] && [[ $found -eq 0 ]]; then
      cat "$tmp_content"
      found=1
    fi
  done < "$file_path" > "$tmp_file"

  mv "$tmp_file" "$file_path"
  rm -f "$tmp_content"
}

append_to_latest_task() {
  local file_path="$1"
  local content="$2"

  if [[ ! -f "$file_path" ]]; then
    return
  fi

  local last_task_line=$(grep -n "^#### 任务" "$file_path" | tail -1 | cut -d: -f1)

  if [[ -n "$last_task_line" ]]; then
    local next_section=$(awk -v start="$last_task_line" '
      BEGIN { found=0 }
      NR > start && /^(####|##)/ { print NR; found=1; exit }
      END { if (!found && NR > start) print NR+1 }
    ' "$file_path" | tr -d '\n\r' | xargs)

    if [[ -n "$next_section" ]] && [[ "$next_section" =~ ^[0-9]+$ ]]; then
      local tmp_content=$(mktemp)
      echo "$content" > "$tmp_content"

      local tmp_file="${file_path}.tmp"
      local line_num=0

      while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ $line_num -eq $next_section ]]; then
          cat "$tmp_content"
        fi
        echo "$line"
      done < "$file_path" > "$tmp_file"

      mv "$tmp_file" "$file_path"
      rm -f "$tmp_content"
    fi
  fi
}

##############################################################################
# Token 统计功能
##############################################################################

extract_token_usage() {
  local transcript_content="$1"
  
  if [[ -z "$transcript_content" ]]; then
    echo "未知"
    return
  fi
  
  # 提取最后一条消息的 token 信息
  local token_info=$(echo "$transcript_content" | tail -1 | jq -r '
    if .message.usage then
      "输入: \(.message.usage.input_tokens // 0) | 输出: \(.message.usage.output_tokens // 0) | 总计: \((.message.usage.input_tokens // 0) + (.message.usage.output_tokens // 0))"
    else
      "未知"
    end
  ' 2>/dev/null)
  
  if [[ -n "$token_info" ]] && [[ "$token_info" != "null" ]]; then
    echo "$token_info"
  else
    echo "未知"
  fi
}

##############################################################################
# 消息过滤功能（增强版）
##############################################################################

# 判断消息是否应该被过滤（返回0表示应该过滤，1表示保留）
should_filter_message() {
  local content="$1"

  # 规则1：过短的消息（小于30字符）
  if [[ ${#content} -lt 30 ]]; then
    echo "too_short"
    return 0
  fi

  # 规则2：空白消息
  local trimmed=$(echo "$content" | xargs)
  if [[ -z "$trimmed" ]]; then
    echo "empty_message"
    return 0
  fi

  # 规则3：包含 API Error
  if [[ "$content" =~ "API Error" ]]; then
    echo "api_error"
    return 0
  fi

  # 规则4：包含 HTTP 错误码
  if [[ "$content" =~ (403|401|500|502|503|504) ]]; then
    echo "http_error"
    return 0
  fi

  # 规则5：包含登录相关系统消息
  if [[ "$content" =~ "Please run /login"|"Login successful"|"login is running" ]]; then
    echo "login_message"
    return 0
  fi

  # 规则6：仅包含命令提示
  if [[ "$content" =~ ^"Caveat: The messages below" ]]; then
    echo "system_caveat"
    return 0
  fi

  # 规则7：纯工具调用提示（可选）
  if [[ "$content" =~ ^"I'll help you with that" ]] && [[ ${#content} -lt 100 ]]; then
    echo "generic_help_message"
    return 0
  fi

  # 规则8：过滤常见的无效响应
  if [[ "$content" =~ ^"Let me"|^"I'll start"|^"I'm going to" ]] && [[ ${#content} -lt 50 ]]; then
    echo "incomplete_thought"
    return 0
  fi

  # 保留此消息
  return 1
}

##############################################################################
# 消息提取功能（优化版）
##############################################################################

extract_last_assistant_response() {
  local transcript_content="$1"
  local max_attempts=10  # 增加检查次数到10条

  if [[ $ENABLE_DEBUG -eq 1 ]]; then
    echo "[DEBUG] Extracting assistant response from cached content" >> "$DEBUG_LOG"
  fi

  if [[ -z "$transcript_content" ]]; then
    echo "[无法读取会话记录]"
    return
  fi

  # 跨平台兼容：优先使用 tac（GNU），回退到 tail -r（BSD/macOS）
  local reversed_content=""
  if command -v tac &> /dev/null; then
    reversed_content=$(echo "$transcript_content" | tac)
  else
    # macOS 使用 tail -r
    reversed_content=$(echo "$transcript_content" | tail -r)
  fi

  # 获取所有包含 type:text 的 assistant 消息
  local all_text_messages=$(echo "$reversed_content" | grep '"type":"text"')

  if [[ -z "$all_text_messages" ]]; then
    if [[ $ENABLE_DEBUG -eq 1 ]]; then
      echo "[DEBUG] No text messages found in transcript" >> "$DEBUG_LOG"
    fi
    echo "[未找到 Assistant 文本回复]"
    return
  fi

  # 逐条检查消息，找到第一条符合条件的
  local attempt=0
  while IFS= read -r line && [[ $attempt -lt $max_attempts ]]; do
    attempt=$((attempt + 1))

    # 提取消息内容
    local content=$(echo "$line" | jq -r '.message.content[] | select(.type=="text") | .text' 2>/dev/null)

    if [[ -z "$content" ]] || [[ "$content" == "null" ]]; then
      if [[ $ENABLE_DEBUG -eq 1 ]]; then
        echo "[DEBUG] Attempt $attempt: Failed to parse content" >> "$DEBUG_LOG"
      fi
      continue
    fi

    # 检查是否应该过滤
    local filter_reason=$(should_filter_message "$content")
    local filter_result=$?

    if [[ $filter_result -eq 0 ]]; then
      if [[ $ENABLE_DEBUG -eq 1 ]]; then
        echo "[DEBUG] Attempt $attempt: Filtered ($filter_reason) - ${#content} chars" >> "$DEBUG_LOG"
      fi
      continue
    fi

    # 找到有效消息
    if [[ $ENABLE_DEBUG -eq 1 ]]; then
      echo "[DEBUG] Attempt $attempt: Valid message found - ${#content} chars" >> "$DEBUG_LOG"
    fi

    # 智能截断：保留更多内容，但有合理限制
    local max_length=2000
    if [[ ${#content} -gt $max_length ]]; then
      echo "${content:0:$max_length}

...(内容较长已截断，完整内容请查看会话记录)"
    else
      echo "$content"
    fi
    return

  done <<< "$all_text_messages"

  # 如果所有消息都被过滤了
  if [[ $ENABLE_DEBUG -eq 1 ]]; then
    echo "[DEBUG] All $attempt messages were filtered" >> "$DEBUG_LOG"
  fi
  echo "[本次会话未找到有效的任务总结]"
}

##############################################################################
# 主要功能函数
##############################################################################

log_task_start() {
  local input_json="$1"
  local project_name=$(get_project_name)
  local timestamp=$(get_timestamp)
  local today=$(date +%Y-%m-%d)

  local prompt="Unknown task"
  local session_id="unknown"

  if command -v jq &> /dev/null && [[ -n "$input_json" ]]; then
    prompt=$(echo "$input_json" | jq -r '.prompt // "Unknown task"')
    session_id=$(echo "$input_json" | jq -r '.session_id // "unknown"')
  fi

  # 自动检测任务分类
  local task_category=$(detect_task_category "$prompt")

  local task_entry="
### 项目：${project_name}

#### 任务 ${task_category} - ${today}
- **开始时间**：${timestamp}
- **会话ID**：\`${session_id}\`
- **任务描述**：
\`\`\`
${prompt}
\`\`\`

"

  local today_log=$(get_today_log_path)
  ensure_today_log_exists "$today_log"
  insert_after_marker "$today_log" "## 📦 项目记录" "$task_entry"

  local project_log=$(get_project_log_path "$project_name")
  ensure_project_log_exists "$project_log" "$project_name"
  insert_after_marker "$project_log" "## 📋 任务记录" "$task_entry"

  echo "✅ 已记录任务开始 - 项目: $project_name | 分类: $task_category"
  echo "📝 今日日志: $today_log"
  echo "📦 项目日志: $project_log"
}

log_task_complete() {
  local input_json="$1"
  local project_name=$(get_project_name)
  local timestamp=$(get_timestamp)

  # 提取 transcript 路径
  local transcript_path=""
  if command -v jq &> /dev/null && [[ -n "$input_json" ]]; then
    transcript_path=$(echo "$input_json" | jq -r '.transcript_path // ""')
  fi

  # 性能优化：一次性读取文件内容并缓存
  local transcript_content=""
  if [[ -n "$transcript_path" ]] && [[ -f "$transcript_path" ]]; then
    transcript_content=$(cat "$transcript_path")
  fi

  # 从缓存内容中提取信息
  local assistant_response="[无回复内容]"
  local token_usage="未知"
  
  if [[ -n "$transcript_content" ]]; then
    assistant_response=$(extract_last_assistant_response "$transcript_content")
    token_usage=$(extract_token_usage "$transcript_content")
  fi

  local completion_entry="
- **完成时间**：${timestamp}
- **执行结果**：✅ 成功完成
- **Token 使用**：${token_usage}

- **Claude 完成总结**：
\`\`\`markdown
${assistant_response}
\`\`\`

- **会话记录**：
  \`${transcript_path}\`

---

"

  local today_log=$(get_today_log_path)
  append_to_latest_task "$today_log" "$completion_entry"

  local project_log=$(get_project_log_path "$project_name")
  append_to_latest_task "$project_log" "$completion_entry"

  echo "✅ 任务已完成并记录 (含 Token 统计) - 项目: $project_name"
  echo "📊 Token 使用: $token_usage"
  echo "📝 查看今日日志: $today_log"
  echo "📦 查看项目日志: $project_log"
}

log_task_interrupted() {
  local input_json="$1"
  local project_name=$(get_project_name)
  local timestamp=$(get_timestamp)

  local completion_entry="
- **中断时间**：${timestamp}
- **执行结果**：⚠️ 任务中断或取消

---

"

  local today_log=$(get_today_log_path)
  append_to_latest_task "$today_log" "$completion_entry"

  local project_log=$(get_project_log_path "$project_name")
  append_to_latest_task "$project_log" "$completion_entry"

  echo "⚠️  任务已中断并记录 - 项目: $project_name"
  echo "📝 查看今日日志: $today_log"
  echo "📦 查看项目日志: $project_log"
}

##############################################################################
# 主程序
##############################################################################

main() {
  if [[ $ENABLE_DEBUG -eq 1 ]]; then
    echo "" >> "$DEBUG_LOG"
    echo "=== Hook V3 Enhanced Executed at $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$DEBUG_LOG"
    echo "Environment Variables:" >> "$DEBUG_LOG"
    echo "  CLAUDE_HOOK_EVENT=${CLAUDE_HOOK_EVENT:-<not set>}" >> "$DEBUG_LOG"
    echo "  CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-<not set>}" >> "$DEBUG_LOG"
    echo "  PWD=$(pwd)" >> "$DEBUG_LOG"
  fi

  local input_json=""
  if [[ ! -t 0 ]]; then
    input_json=$(cat)

    if [[ $ENABLE_DEBUG -eq 1 ]] && [[ -n "$input_json" ]]; then
      echo "STDIN Input (first 30 lines):" >> "$DEBUG_LOG"
      echo "$input_json" | head -30 >> "$DEBUG_LOG"
    fi
  fi

  local event_type="${CLAUDE_HOOK_EVENT:-unknown}"

  if [[ -n "$input_json" ]] && command -v jq &> /dev/null; then
    local json_event=$(echo "$input_json" | jq -r '.hook_event_name // ""' 2>/dev/null)
    if [[ -n "$json_event" ]]; then
      event_type="$json_event"
    fi
  fi

  if [[ $ENABLE_DEBUG -eq 1 ]]; then
    echo "Event Type: $event_type" >> "$DEBUG_LOG"
  fi

  case "$event_type" in
    UserPromptSubmit)
      log_task_start "$input_json"
      ;;
    Stop)
      log_task_complete "$input_json"
      ;;
    Cancel|Error|Interrupted)
      log_task_interrupted "$input_json"
      ;;
    *)
      if [[ $ENABLE_DEBUG -eq 1 ]]; then
        echo "Unknown event: $event_type (skipped)" >> "$DEBUG_LOG"
      fi
      ;;
  esac

  exit 0
}

# 错误处理：记录错误并继续
trap 'echo "❌ Hook V3 错误 at line $LINENO: $BASH_COMMAND" | tee -a "$DEBUG_LOG" >&2' ERR

main
