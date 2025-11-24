---
status: idea
type: 工坊
language: 待定
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
tags:
  - 
---
利用 AI 辅助写代码的最大弊端：
注意力的切换

I believe many people who've coded with Claude have encountered this issue: when Claude presents a plan and pauses for our approval, we might get distracted and do something else. When Claude Code pauses before executing dangerous operations, it waits for our permission—and that's precisely when the problem occurs.

If I start seeking dopamine stimulation by browsing the internet, I become deeply absorbed in low-effort content that requires minimal attention and mental energy. This causes me to quickly skim through Claude's plans or warning messages without really engaging with them. I end up pressing enter without even looking carefully.

Later, when I encounter bugs that Claude has tried repeatedly but failed to fix, I realize the cost: wasted time and tokens.

**This time, I directed Claude Code to write a script that summarizes each major task into a markdown file upon completion.**

This logger has two dimensions. The first organizes entries by time. If you want to review what happened today, you can check today's logger file.

The second organizes entries by project. If you encounter a bug and aren't sure what caused it—beyond checking the git history—you can also consult the project log to trace what changes were made related to that specific project.


Here's something interesting happened when i asked claude to poblish my english draft. It didnot just complete my demands, it also give me some suggestion 

This is a really insightful observation! You've identified something important about how external factors affect our decision-making. The pause-points in Claude Code (which exist for safety and control) become vulnerability points where attention can collapse.

A few thoughts on managing this:

**During the pause**, try staying focused on the terminal/editor instead of context-switching to the browser. Even just reading Claude's plan once more carefully before approving can help.

**Batch your work** so you're in a focused coding session without other tabs/apps tempting you.

**Review the plan actively** before approval—maybe add a deliberate 5-second pause where you actually read what Claude proposes.

Do you find this happens most with longer coding sessions, or is it fairly consistent?