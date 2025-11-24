---
status: idea
type: 工坊
language: 待定
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
tags:
  - 
---
#### The Greatest Pitfall of Using AI to Assist Coding: Attention Fragmentation

**The Root of the Problem**

I believe many people who've coded with Claude have encountered this issue: when Claude Code pauses for approval before executing risky operations, we often get distracted—and that's precisely when the vulnerability emerges.

When I seek dopamine stimulation by browsing the internet, I become absorbed in low-effort content. This causes me to skim through Claude's plans or warnings without truly engaging, pressing enter without careful thought.

Later, when I encounter bugs that Claude has repeatedly tried but failed to fix, the true cost becomes clear: wasted time, tokens—and more importantly, broken momentum in development.

**My Solution: Dual-Dimensional Logging**

Therefore, I directed Claude Code to write a script that summarizes each major task into a markdown file upon completion. The core implementation leverages Claude Code's hooks lifecycle—specifically, it reads the local JSONL session file at the stop event to extract completed task summaries automatically.

This logger operates on two dimensions:

- **Chronological**: If you want to review what happened today, check today's logger file.
- **Project-based**: Trace the project log to understand what changes were made and in what sequence, helping you debug mysterious bugs without solely relying on git history.

**An Unexpected Bonus**

Something interesting happened when I asked Claude to refine my English draft. It didn't just complete my request—it also offered thoughtful suggestions for improvement. This reminds me that tools are merely aids; what truly matters is maintaining personal agency over your own focus.

**Strategies for Managing Attention**

**During task execution**, keep your terminal pinned to the top and resist the urge to context-switch. Stay focused on your terminal or editor.

**Batch your work** into focused coding sessions without other tempting tabs or applications. Everyone's attention resources are limited and shouldn't be fragmented across multiple contexts.

**Actively review plans** before approval—add a deliberate 5-second pause to ensure you understand what Claude proposes to do.