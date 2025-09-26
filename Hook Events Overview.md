

Claude Code provides several hook events that run at different points in the workflow:

- **PreToolUse**: Runs before tool calls (can block them)
- **PostToolUse**: Runs after tool calls complete
- **UserPromptSubmit**: Runs when the user submits a prompt, before Claude processes it
- **Notification**: Runs when Claude Code sends notifications
- **Stop**: Runs when Claude Code finishes responding
- **SubagentStop**: Runs when subagent tasks complete
- **PreCompact**: Runs before Claude Code is about to run a compact operation
- **SessionStart**: Runs when Claude Code starts a new session or resumes an existing session
- **SessionEnd**: Runs when Claude Code session ends

Each event receives different data and can control Claude’s behavior in different ways.